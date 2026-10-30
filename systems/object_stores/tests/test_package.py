"""Tests for package.py. Standard library only; no instance and no .env.local.

Every value below is invented. The tests seed each kind of leak on purpose and
require the build to fail and write nothing.

    python3 -m unittest discover systems/object_stores/tests
"""

import datetime
import io
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import package as pk  # noqa: E402
import settings_docs as sd  # noqa: E402

DATE = datetime.date(2026, 10, 30)
ENV = {
    "PACKAGE_PARTNER": "acme",
    "S3_STORE_VENDOR": "Acme",
    "S3_STORE_PRODUCT": "StoreX",
    "S3_ADDRESSING": "virtual",
    "S3_REGION": "eu-west-1",
    "S3_ACCESS_KEY": "AKIAFAKEFAKEFAKE0001",
    "S3_SECRET_KEY": "fake/secret+value/not/real/0002",
    "S3_BUCKET": "acme-test-bucket-0003",
    "S3_ENDPOINT_URL": "https://s3.acme-store.example:9021",
    "S3_PREFIX": "acme-folder-0004",
    "ZETARIS_PASSWORD": "pw-not-real-0005",
    "ZETARIS_API_KEY": "key-not-real-0006",
    "ZETARIS_USER_AGENT": "acme-test jane.doe@acme-corp.example",
    "ZETARIS_ORG_ID": "1",
    "ZETARIS_REST_URL": "http://localhost:8888/api/v1.0",
}
PNG = b"\x89PNG\r\n\x1a\n" + b"\x00" * 32


def quiet(*_a, **_k):
    pass


class ConfigTests(unittest.TestCase):
    def test_valid(self):
        c = pk.Config(ENV, None, DATE)
        self.assertEqual((c.top, c.zip_name), ("zetaris-acme-object-store-test", "zetaris-acme-object-store-test-20261030.zip"))
        self.assertEqual(c.values["STORE_NAME"], "Acme StoreX")

    def test_bad_values_refused(self):
        for patch in ({"PACKAGE_PARTNER": ""}, {"PACKAGE_PARTNER": "Acme Corp"}, {"PACKAGE_PARTNER": "../x"}, {"PACKAGE_PARTNER": "-a"},
                      {"S3_ADDRESSING": "bogus"}, {"S3_REGION": "Bad Region"}, {"PACKAGE_DENY_WORDS": "ok,x"},
                      {"S3_STORE_PRODUCT": "a\nb"}):
            with self.assertRaises(pk.BuildError, msg=patch):
                pk.Config({**ENV, **patch}, None, DATE)

    def test_partner_can_come_from_the_command_line(self):
        self.assertEqual(pk.Config({**ENV, "PACKAGE_PARTNER": ""}, "other", DATE).partner, "other")

    def test_logo_checks(self):
        with tempfile.TemporaryDirectory() as d:
            ok, fake, big, wrong = Path(d) / "l.png", Path(d) / "f.png", Path(d) / "b.png", Path(d) / "l.gif"
            ok.write_bytes(PNG)
            fake.write_bytes(b"not a png at all")
            big.write_bytes(PNG + b"\x00" * pk.MAX_LOGO)
            wrong.write_bytes(PNG)
            self.assertEqual(pk.Config({**ENV, "PACKAGE_LOGO": str(ok)}, None, DATE).logo_file, "assets/partner/logo.png")
            for bad in (fake, big, wrong, Path(d) / "missing.png"):
                with self.assertRaises(pk.BuildError, msg=bad.name):
                    pk.Config({**ENV, "PACKAGE_LOGO": str(bad)}, None, DATE)


def undefined_globals(source: str, name: str) -> list[str]:
    """Names a function reads as globals that the module never defines or imports
    and that are not builtins: the NameError that only shows when the line runs."""
    import builtins
    import symtable

    top = symtable.symtable(source, name, "exec")
    known = {sym.get_name() for sym in top.get_symbols() if sym.is_assigned() or sym.is_imported() or sym.is_namespace()}
    known |= set(dir(builtins)) | {"__file__", "__name__", "__doc__", "__spec__"}
    bad: list[str] = []

    def walk(t):
        for child in t.get_children():
            for sym in child.get_symbols():
                if sym.is_global() and sym.is_referenced() and sym.get_name() not in known:
                    bad.append(f"{child.get_name()}: {sym.get_name()}")
            walk(child)

    walk(top)
    return bad


class SelectionTests(unittest.TestCase):
    def setUp(self):
        self.cfg = pk.Config(ENV, None, DATE)
        self.files = pk.build_files(self.cfg)

    def test_expected_files_are_in(self):
        for name in ("README.md", "HOWTO.md", "MANIFEST.txt", "SHA256SUMS", "systems/object_stores/.env.example",
                     "systems/object_stores/viewer/index.html", "systems/object_stores/viewer/index.html.tmpl",
                     "systems/object_stores/scripts/serve_viewer.py", "systems/object_stores/scripts/probe_s3.py",
                     "systems/object_stores/viewer/assets/fonts/plus-jakarta-sans.ttf",
                     "systems/object_stores/viewer/assets/brand/zetaris-indigo.svg",
                     "scripts/onboard.py", "scripts/zetaris_sql.py", "open_data/manifest.json"):
            self.assertIn(name, self.files)

    def test_repository_only_files_are_out(self):
        for name in ("systems/object_stores/scripts/package.py", "systems/object_stores/scripts/settings_docs.py",
                     "systems/object_stores/scripts/check_viewer.py", "systems/object_stores/HOWTO.md.tmpl",
                     "systems/object_stores/PACKAGE_README.md.tmpl", ".env.local"):
            self.assertNotIn(name, self.files)
        self.assertFalse([n for n in self.files if n.startswith("systems/object_stores/tests/")])

    def test_no_shipped_python_file_reads_an_undefined_name(self):
        """Catches a deleted constant or a missing import in any file the package ships."""
        for name, data in self.files.items():
            if name.endswith(".py"):
                self.assertEqual(undefined_globals(data.decode(), name), [], name)

    def test_the_undefined_name_check_can_fail(self):
        self.assertEqual(undefined_globals("def f():\n    return MISSING\n", "x.py"), ["f: MISSING"])
        self.assertEqual(undefined_globals("X = 1\ndef f():\n    return X + len([])\n", "x.py"), [])

    def test_no_shipped_file_names_a_path_the_package_lacks(self):
        self.assertEqual(pk.dangling_paths(self.files), [])

    def test_the_path_check_can_fail_and_skips_what_it_should(self):
        files = {"README.md": b"run scripts/gone.py and see systems/here.txt and reports/x.json and scripts/<name>.py",
                 "systems/here.txt": b"x", "scripts/zetaris_sql.py": b"scripts/requirements.txt", "MANIFEST.txt": b"scripts/package.py",
                 "a.sql": b"-- docs/missing.md"}
        self.assertEqual(pk.dangling_paths(files), ["README.md: scripts/gone.py"])

    def test_repo_only_parts_of_the_kit_readme_are_stripped(self):
        readme = self.files["systems/object_stores/README.md"].decode()
        for word in ("package.py", "check_viewer", "settings_docs", "unittest discover", "repo-only", "website/assets"):
            self.assertNotIn(word, readme)
        self.assertIn("## The viewer", readme)
        self.assertIn("## Your own folder in the bucket", readme)

    def test_strip_repo_only_rules(self):
        text = "a\nkeep\ndrop me <!--repo-only-->\n<!--repo-only-start-->\nx\ny\n<!--repo-only-end-->\nz"
        self.assertEqual(pk.strip_repo_only(text), "a\nkeep\nz")
        for bad in ("<!--repo-only-start-->\nx", "x\n<!--repo-only-end-->",
                    "<!--repo-only-start-->\n<!--repo-only-start-->\n<!--repo-only-end-->"):
            with self.assertRaises(pk.BuildError):
                pk.strip_repo_only(bad)

    def test_install_hint_names_a_file_the_package_holds(self):
        """The preflight tells people which requirements file to install. In the
        package that must be one that is inside it (a partner hit a missing path)."""
        self.assertNotIn("scripts/requirements.txt", self.files)
        self.assertIn("systems/object_stores/requirements.txt", self.files)
        src = self.files["scripts/zetaris_sql.py"].decode()
        self.assertIn("def requirements_file", src)
        self.assertIn('"systems/object_stores/requirements.txt"', src)
        pre = self.files["scripts/preflight.py"].decode()
        self.assertNotIn("install -r scripts/requirements.txt", pre)

    def test_manifest_lists_exactly_the_resolved_sources(self):
        import json
        ids = [s["id"] for s in json.loads(self.files["open_data/manifest.json"])["sources"]]
        self.assertEqual(ids[-1], "sic_edgar_usl")
        self.assertEqual(set(ids), {"company_dns", "edgar_facts", "edgar_profiles", "sic_edgar_usl"})
        for s in json.loads(self.files["open_data/manifest.json"])["sources"]:
            self.assertIn(s["script"], self.files)

    def test_names_are_baked_and_the_example_env_shows_overrides(self):
        for name in ("README.md", "HOWTO.md", "systems/object_stores/viewer/index.html"):
            self.assertIn(b"Acme StoreX", self.files[name])
        env = self.files["systems/object_stores/.env.example"].decode()
        self.assertIn("\nS3_ADDRESSING=virtual\n", env)
        self.assertIn("\nS3_REGION=eu-west-1\n", env)
        self.assertIn("\nS3_STORE_PRODUCT=StoreX\n", env)
        self.assertIn("\n# S3_PREFIX=", env)

    def test_generic_build_has_no_names_and_default_example_env(self):
        files = pk.build_files(pk.Config({"PACKAGE_PARTNER": "plain"}, None, DATE))
        self.assertIn(b"your S3-compatible object store", files["HOWTO.md"])
        env = files["systems/object_stores/.env.example"].decode()
        self.assertIn("\n# S3_ADDRESSING=path\n", env)
        self.assertIn("\n# S3_REGION=us-east-1\n", env)

    def test_logo_is_added_and_shown(self):
        with tempfile.TemporaryDirectory() as d:
            logo = Path(d) / "x.png"
            logo.write_bytes(PNG)
            files = pk.build_files(pk.Config({**ENV, "PACKAGE_LOGO": str(logo)}, None, DATE))
        self.assertEqual(files["systems/object_stores/viewer/assets/partner/logo.png"], PNG)
        self.assertIn(b'src="assets/partner/logo.png"', files["systems/object_stores/viewer/index.html"])

    def test_zip_is_deterministic_and_date_dependent(self):
        a, b = pk.zip_bytes(self.files, self.cfg), pk.zip_bytes(dict(reversed(list(self.files.items()))), self.cfg)
        self.assertEqual(a, b)
        other = pk.Config(ENV, None, datetime.date(2026, 10, 31))
        self.assertNotEqual(a, pk.zip_bytes(self.files, other))
        names = [i.filename for i in zipfile.ZipFile(io.BytesIO(a)).infolist()]
        self.assertEqual(names, sorted(names))
        self.assertTrue(all(n.startswith("zetaris-acme-object-store-test/") for n in names))


class LeakTests(unittest.TestCase):
    def setUp(self):
        self.cfg = pk.Config(ENV, None, DATE)
        self.files = pk.build_files(self.cfg)
        self.schema = sd.load()
        with mock.patch("getpass.getuser", return_value="testuser-zzz"):
            self.values, self.short = pk.forbidden_values(ENV, self.schema, self.cfg)

    def labels(self):
        return {label for label, _ in self.values}

    def test_clean_build_passes(self):
        self.assertEqual(pk.leak_check(self.files, self.values, []), [])

    def test_what_is_collected(self):
        self.assertTrue({"S3_ACCESS_KEY", "S3_SECRET_KEY", "S3_BUCKET", "S3_PREFIX", "ZETARIS_PASSWORD", "S3_ENDPOINT_URL",
                         "S3_ENDPOINT_URL (host)", "ZETARIS_USER_AGENT (email)", "your login name"} <= self.labels())
        self.assertFalse(self.labels() & {"S3_ADDRESSING", "S3_REGION", "S3_STORE_VENDOR", "PACKAGE_PARTNER", "ZETARIS_ORG_ID", "ZETARIS_REST_URL"})

    def test_short_values_are_reported_not_checked(self):
        _, short = pk.forbidden_values({**ENV, "S3_BUCKET": "abc"}, self.schema, self.cfg)
        self.assertIn("S3_BUCKET", short)

    def seeded(self, extra: bytes):
        return pk.leak_check({**self.files, "docs/x.md": extra}, self.values, ["Rival"])

    def test_each_seeded_leak_is_found_without_printing_the_value(self):
        for label, value in self.values:
            found = self.seeded(b"prefix " + value.encode() + b" suffix")
            self.assertTrue(any(label in p for p in found), label)
            self.assertFalse(any(value in p for p in found), f"{label}: the problem text repeats the value")

    def test_secret_in_a_binary_file(self):
        found = pk.leak_check({**self.files, "assets/x.bin": b"\x00\x01" + ENV["S3_SECRET_KEY"].encode() + b"\xff"}, self.values, [])
        self.assertTrue(any("S3_SECRET_KEY" in p for p in found))

    def test_denied_word_any_case(self):
        self.assertTrue(any("'Rival'" in p for p in self.seeded(b"made for rIvAl corp")))

    def test_forbidden_files(self):
        for name in (".env.local", "x/.venv/bin/python", "scripts/__pycache__/a.pyc", "a/.DS_Store", "b/notes.swp", "c/server.key"):
            self.assertTrue(pk.leak_check({**self.files, name: b"x"}, [], []), name)

    def test_unresolved_token_in_rendered_output(self):
        for name in ("README.md", "HOWTO.md", "systems/object_stores/viewer/index.html", "systems/object_stores/.env.example"):
            self.assertTrue(pk.leak_check({**self.files, name: b"oops {{STORE_NAME}}"}, [], []), name)
        self.assertTrue(pk.leak_check({**self.files, "README.md": b"<!--partner-logo-->"}, [], []))
        # the template and the scripts legitimately contain tokens
        self.assertEqual(pk.leak_check(self.files, [], []), [])


class BuildTests(unittest.TestCase):
    def run_build(self, out: Path, env=None, dry=False):
        with mock.patch("getpass.getuser", return_value="testuser-zzz"):
            return pk.build(env or ENV, None, DATE, out, dry, log=quiet)

    def test_writes_tree_and_zip_and_they_agree(self):
        with tempfile.TemporaryDirectory() as d:
            out = Path(d)
            self.assertEqual(self.run_build(out), 0)
            tree, z = out / "zetaris-acme-object-store-test", out / "zetaris-acme-object-store-test-20261030.zip"
            self.assertTrue(tree.is_dir() and z.is_file())
            cfg = pk.Config(ENV, None, DATE)
            files = pk.read_back(z.read_bytes(), cfg)
            on_disk = {p.relative_to(tree).as_posix() for p in tree.rglob("*") if p.is_file()}
            self.assertEqual(set(files), on_disk)
            self.assertTrue((tree / "MANIFEST.txt").read_text().startswith(pk.HEADER))
            self.assertFalse(list(out.rglob(".env*")) and [p for p in out.rglob(".env.local")])
            sums = files["SHA256SUMS"].decode().splitlines()
            self.assertEqual(len(sums), len(files) - 1)  # every file but itself

    def test_rebuild_replaces_its_own_folder_and_is_byte_identical(self):
        with tempfile.TemporaryDirectory() as d:
            out = Path(d)
            self.run_build(out)
            first = (out / "zetaris-acme-object-store-test-20261030.zip").read_bytes()
            self.assertEqual(self.run_build(out), 0)
            self.assertEqual((out / "zetaris-acme-object-store-test-20261030.zip").read_bytes(), first)

    def test_rebuild_keeps_the_persons_own_files_and_drops_stale_built_ones(self):
        with tempfile.TemporaryDirectory() as d:
            out = Path(d)
            self.run_build(out)
            tree = out / "zetaris-acme-object-store-test"
            (tree / ".env.local").write_text("S3_BUCKET=mine\n")
            (tree / ".venv" / "bin").mkdir(parents=True)
            (tree / ".venv" / "bin" / "python").write_text("x")
            (tree / "reports").mkdir()
            (tree / "reports" / "a-20260101-000000.json").write_text("{}")
            (tree / "stale.txt").write_text("from an older build")
            self.assertEqual(self.run_build(out), 0)
            self.assertEqual((tree / ".env.local").read_text(), "S3_BUCKET=mine\n")
            self.assertTrue((tree / ".venv" / "bin" / "python").is_file())
            self.assertTrue((tree / "reports" / "a-20260101-000000.json").is_file())
            self.assertFalse((tree / "stale.txt").exists())
            self.assertTrue((tree / "MANIFEST.txt").is_file())

    def test_refuses_to_overwrite_a_folder_it_did_not_build(self):
        with tempfile.TemporaryDirectory() as d:
            foreign = Path(d) / "zetaris-acme-object-store-test"
            foreign.mkdir()
            (foreign / "mine.txt").write_text("keep me")
            with self.assertRaises(pk.BuildError):
                self.run_build(Path(d))
            self.assertEqual((foreign / "mine.txt").read_text(), "keep me")

    def test_dry_run_writes_nothing(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertEqual(self.run_build(Path(d) / "out", dry=True), 0)
            self.assertFalse((Path(d) / "out").exists())

    def test_a_leak_fails_the_build_and_writes_nothing(self):
        real = pk.build_files

        def leaky(cfg):
            files = real(cfg)
            files["docs/guides/zetaris-lightning-sql-companion.md"] += b"\nthe key is " + ENV["S3_SECRET_KEY"].encode()
            return files

        with tempfile.TemporaryDirectory() as d, mock.patch.object(pk, "build_files", leaky):
            self.assertEqual(self.run_build(Path(d) / "out"), 1)
            self.assertFalse((Path(d) / "out").exists())

    def test_a_denied_word_fails_the_build(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertEqual(self.run_build(Path(d) / "out", {**ENV, "PACKAGE_DENY_WORDS": "zetaris"}), 1)
            self.assertFalse((Path(d) / "out").exists())


if __name__ == "__main__":
    unittest.main()
