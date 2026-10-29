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
