"""Tests for render.py. Standard library only; no instance and no .env.local.

    python3 -m unittest discover systems/object_stores/tests
"""

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import render as r  # noqa: E402

KIT = Path(__file__).resolve().parents[1]


class StoreValues(unittest.TestCase):
    def test_generic_when_empty(self):
        v = r.store_values()
        self.assertEqual(v["STORE_NAME"], "your S3-compatible object store")
        self.assertEqual(v["STORE_LABEL"], "S3 object store")

    def test_vendor_and_product_joined(self):
        v = r.store_values("Acme", "StoreX")
        self.assertEqual((v["STORE_NAME"], v["STORE_LABEL"]), ("Acme StoreX", "Acme StoreX"))

    def test_label_is_shortened_but_name_is_not(self):
        v = r.store_values("Example Vendor Corporation", "Example Scale-Out Store 9000")
        self.assertEqual(len(v["STORE_LABEL"]), r.MAX_LABEL)
        self.assertTrue(v["STORE_LABEL"].endswith("…"))
        self.assertEqual(v["STORE_NAME"], "Example Vendor Corporation Example Scale-Out Store 9000")

    def test_unsafe_names_refused(self):
        for bad in ("a\nb", "a\x00b", "x" * (r.MAX_NAME + 1)):
            with self.assertRaises(r.RenderError):
                r.store_values("", bad)


class Render(unittest.TestCase):
    def test_replaces_tokens(self):
        self.assertEqual(r.render("on {{STORE_NAME}}", r.store_values("A", "B")), "on A B")
        self.assertEqual(r.render("on {{ STORE_NAME }}", r.store_values("A", "B")), "on A B")

    def test_unknown_token_refused(self):
        with self.assertRaises(r.RenderError):
            r.render("{{NOPE}}", r.store_values())

    def test_value_cannot_smuggle_a_token(self):
        with self.assertRaises(r.RenderError):
            r.render("{{STORE_NAME}}", r.store_values("{{STORE_NAME}}", ""))

    def test_values_are_escaped_for_markup(self):
        out = r.render("<p>{{STORE_NAME}}</p>", r.store_values("", "<img src=x onerror=alert(1)>"), r.escape_html)
        self.assertNotIn("<img", out)
        self.assertIn("&lt;img", out)

    def test_script_close_in_a_name_is_escaped(self):
        out = r.render("<p>{{STORE_NAME}}</p>", r.store_values("", "</script><script>alert(1)"), r.escape_html)
        self.assertNotIn("</script>", out)


class Includes(unittest.TestCase):
    def test_include_is_escaped_and_confined(self):
        with tempfile.TemporaryDirectory() as d:
            base = Path(d) / "tpl"
            (base / "fx").mkdir(parents=True)
            (base / "fx" / "a.txt").write_text("<b>1 < 2</b>\n")
            (Path(d) / "secret.txt").write_text("outside")
            self.assertEqual(r.render_includes("[<!--include:fx/a.txt-->]", base, r.escape_html), "[&lt;b&gt;1 &lt; 2&lt;/b&gt;]")
            with self.assertRaises(r.RenderError):
                r.render_includes("<!--include:../secret.txt-->", base)
            with self.assertRaises(r.RenderError):
                r.render_includes("<!--include:missing.txt-->", base)


class PartnerLogo(unittest.TestCase):
    def test_markup(self):
        m = r.partner_logo_markup("assets/partner/logo.png", 'Acme "X"')
        self.assertIn('src="assets/partner/logo.png"', m)
        self.assertIn("Acme &quot;X&quot; logo", m)
        self.assertEqual(r.partner_logo_markup(None, "x"), "")

    def test_only_the_fixed_path_is_allowed(self):
        for bad in ("assets/partner/other.png", "../logo.png", "http://x/logo.png", "assets/partner/logo.exe", 'assets/partner/logo.png"onload="x'):
            with self.assertRaises(r.RenderError):
                r.partner_logo_markup(bad, "x")


class Viewer(unittest.TestCase):
    TEMPLATE = KIT / "viewer" / "index.html.tmpl"

    def test_generic_page_has_no_logo_or_store_name(self):
        page = r.render_viewer(self.TEMPLATE, {})
        self.assertNotIn("partnerSlot", page)
        self.assertIn("S3 object store", page)
        self.assertNotIn("{{", page)
        self.assertNotIn("<!--include", page)

    def test_named_page_with_logo(self):
        page = r.render_viewer(self.TEMPLATE, {"S3_STORE_VENDOR": "Acme", "S3_STORE_PRODUCT": "StoreX"}, "assets/partner/logo.svg")
        self.assertIn("Acme StoreX", page)
        self.assertIn('id="partnerSlot"', page)
        self.assertNotIn(r.PARTNER_MARK, page)

    def test_fixture_is_escaped_into_the_page(self):
        page = r.render_viewer(self.TEMPLATE, {})
        self.assertIn("&lt;your folder&gt;", page)


if __name__ == "__main__":
    unittest.main()


class RecipeMatchesHowto(unittest.TestCase):
    """The page's recipe and HOWTO.md.tmpl give the same commands."""

    def setUp(self):
        import check_viewer as cv
        self.cv = cv

    def test_the_real_files_agree(self):
        self.assertEqual(self.cv.recipe_differences(self.cv.HOWTO.read_text(encoding="utf-8"),
                                                    self.cv.sv.TEMPLATE.read_text(encoding="utf-8")), [])

    def test_a_command_missing_from_the_recipe_is_found(self):
        howto = "```bash\npython3 scripts/a.py --x \\\n  --y\n# comment\n.venv/bin/python b.py\n```"
        page = '<p>python3 scripts/a.py --x --y</p>'
        self.assertEqual(self.cv.recipe_differences(howto, page), ["in the HOWTO but not in the recipe: .venv/bin/python b.py"])

    def test_a_changed_flag_in_the_recipe_is_found_both_ways(self):
        howto = "```bash\npython3 scripts/a.py --x\n```"
        page = '<div class="code"><button class="copy" data-target="c1">Copy</button><pre id="c1">python3 scripts/a.py --z</pre></div>'
        got = self.cv.recipe_differences(howto, page)
        self.assertEqual(len(got), 2)
        self.assertTrue(got[0].startswith("in the HOWTO but not in the recipe"))
        self.assertTrue(got[1].startswith("in the recipe but not in the HOWTO"))

    def test_html_escapes_and_non_commands_are_ignored(self):
        howto = "```bash\npython3 run.py -e \"SELECT 1 FROM t WHERE a < 2\"\n```"
        page = '<div class="code"><button class="copy" data-target="c1">Copy</button><pre id="c1">python3 run.py -e "SELECT 1 FROM t WHERE a &lt; 2"\nS3_BUCKET=&lt;bucket&gt;</pre></div>'
        self.assertEqual(self.cv.recipe_differences(howto, page), [])
