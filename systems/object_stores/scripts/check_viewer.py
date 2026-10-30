"""Static checks for the viewer template. Standard library only; no browser.

    python3 systems/object_stores/scripts/check_viewer.py

It renders the template three ways (generic, with a long vendor and product, and
with a hostile name) and checks that:

  * every token and include resolves, and a hostile name is escaped, not injected
  * ids are unique, and every data-target, aria-controls and aria-labelledby
    points at an element that exists
  * every asset the page loads is one the server will serve, and exists
  * nothing is loaded from another site
  * the text colors keep WCAG AA contrast (4.5:1) on the backgrounds they sit on
  * the recipe in the page and HOWTO.md.tmpl give the same commands: every command in
    the HOWTO appears in the recipe, and every python3 or .venv/bin/python command in
    a recipe copy box is in the HOWTO

Layout (text that must stay inside its box, connectors that must not cross a
label, a page that must not scroll sideways) needs a real browser. Open the page
from serve_viewer.py, paste viewer/check_fit.js into the console, and run
`await checkViewerFit()`. It must return ok: true at desktop and phone width,
and with a long store name.
"""

from __future__ import annotations

import html
import re
import sys
from html.parser import HTMLParser
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import render as renderer  # noqa: E402
import serve_viewer as sv  # noqa: E402

PAIRS = [  # (text token, background token, what it is)
    ("--fg", "--bg", "body text"),
    ("--muted", "--bg", "secondary text"),
    ("--muted", "--surface", "secondary text on tinted panels"),
    ("--accent", "--bg", "links and the eyebrow"),
    ("#ffffff", "--accent", "button and active tab text"),
    ("#ffffff", "--accent-hover", "button text on hover"),
    ("--good", "--good-tint", "PASS pills and verdict"),
    ("--orange", "--orange-tint", "warning pills and callouts"),
    ("--orange", "--bg", "foreign key label"),
    ("--cyan-text", "--cyan-tint", "info pills"),
    ("--code-fg", "--code-bg", "code"),
    ("--code-muted", "--code-bg", "code labels"),
    ("--code-pass", "--code-bg", "PASS in code"),
    ("--code-info", "--code-bg", "READY in code"),
    ("#ffffff", "--ent-head", "ERD header text"),
    ("--ent-sub", "--ent-head", "ERD header subtitle"),
    ("--muted", "--surface-2", "idle status dot"),
    ("--bad", "--bad-tint", "FAIL pills and a failed verdict"),
    ("--bad", "--bg", "failed text on white"),
]


def tokens(css: str) -> dict[str, str]:
    root = re.search(r":root\s*\{(.*?)\n\}", css, re.S).group(1)
    return dict(re.findall(r"(--[a-z0-9-]+)\s*:\s*([^;]+);", root))


def resolve(name: str, tok: dict[str, str]) -> str:
    if name.startswith("#"):
        return name
    v = tok[name].strip()
    m = re.fullmatch(r"var\((--[a-z0-9-]+)\)", v)
    return resolve(m.group(1), tok) if m else v


def luminance(hex_color: str) -> float:
    h = hex_color.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    lin = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)


def contrast(a: str, b: str) -> float:
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


class Scan(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.ids: list[str] = []
        self.refs: list[tuple[str, str]] = []
        self.urls: list[str] = []

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if a.get("id"):
            self.ids.append(a["id"])
        for k in ("data-target", "aria-controls"):
            if a.get(k):
                self.refs.append((k, a[k]))
        for part in (a.get("aria-labelledby") or "").split():
            self.refs.append(("aria-labelledby", part))
        for k in ("src", "href"):
            if a.get(k):
                self.urls.append(a[k])


HOWTO = HERE.parent / "HOWTO.md.tmpl"
RUNNABLE = ("python3 ", ".venv/bin/")


def squash(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def howto_commands(howto: str) -> list[str]:
    """Each command line in the HOWTO's bash blocks, continuations joined, comments dropped."""
    cmds: list[str] = []
    for m in re.finditer(r"```bash\n(.*?)```", howto, re.S):
        for line in m.group(1).replace("\\\n", " ").split("\n"):
            line = line.strip()
            if line and not line.startswith("#"):
                cmds.append(squash(line))
    return cmds


def recipe_copy_commands(template: str) -> list[str]:
    """Each command line in the recipe's copy boxes (the ones with a Copy button)."""
    out: list[str] = []
    for m in re.finditer(r'<div class="code"><button[^>]*data-target="([^"]+)"[^>]*>.*?</button><pre id="\1">(.*?)</pre>', template, re.S):
        text = html.unescape(re.sub(r"<[^>]+>", "", m.group(2))).replace("\\\n", " ")
        out += [squash(l) for l in text.split("\n") if l.strip() and not l.strip().startswith("#")]
    return out


def recipe_differences(howto: str, template: str) -> list[str]:
    """Commands that one of the two lacks. Empty when the recipe and HOWTO agree."""
    visible = squash(html.unescape(re.sub(r"<[^>]+>", " ", template)).replace("\\\n", " "))
    hcmds = howto_commands(howto)
    diffs = [f"in the HOWTO but not in the recipe: {c}" for c in hcmds if c not in visible]
    diffs += [f"in the recipe but not in the HOWTO: {c}" for c in recipe_copy_commands(template)
              if c.startswith(RUNNABLE) and c not in hcmds]
    return diffs


def main() -> int:
    problems: list[str] = []
    ok: list[str] = []

    def check(cond: bool, good: str, bad: str) -> None:
        (ok if cond else problems).append(good if cond else bad)

    cases = {
        "generic": {},
        "long names": {"S3_STORE_VENDOR": "Example Vendor Corporation", "S3_STORE_PRODUCT": "Example Scale-Out Store 9000"},
    }
    pages: dict[str, str] = {}
    for label, names in cases.items():
        try:
            pages[label] = sv.render_page(names)
            ok.append(f"renders ({label})")
        except renderer.RenderError as e:
            problems.append(f"does not render ({label}): {e}")
    hostile = "<img src=x onerror=alert(1)>"
    try:
        page = sv.render_page({"S3_STORE_PRODUCT": hostile})
        check("<img src=x" not in page and "&lt;img src=x" in page, "a hostile name is escaped", "a hostile name was injected as markup")
    except renderer.RenderError as e:
        problems.append(f"hostile-name render failed: {e}")
    for bad in ("{{STORE_NAME}}", "line\nbreak", "x" * 61):
        try:
            sv.render_page({"S3_STORE_PRODUCT": bad})
            problems.append(f"an unsafe name was accepted: {bad[:20]!r}")
        except renderer.RenderError:
            pass
    ok.append("unsafe names are refused")

    page = pages.get("generic", "")
    scan = Scan()
    scan.feed(page)
    dup = {i for i in scan.ids if scan.ids.count(i) > 1}
    check(not dup, f"{len(scan.ids)} ids, all unique", f"duplicate ids: {sorted(dup)}")
    missing = [(k, v) for k, v in scan.refs if v not in scan.ids]
    check(not missing, f"{len(scan.refs)} id references all resolve", f"references to missing ids: {missing}")

    for url in scan.urls:
        if url.startswith("assets/"):
            check(sv.read_asset(url[len("assets/"):]) is not None, f"asset {url} is served", f"asset {url} is not served or missing")
        elif not url.startswith("#"):
            problems.append(f"loads something else: {url}")
    external = re.findall(r"(?:src|href)=\"(https?://[^\"]+)\"|url\((https?://[^)]+)\)", page)
    check(not external, "nothing is loaded from another site", f"external loads: {external}")

    tok = tokens(sv.TEMPLATE.read_text(encoding="utf-8"))
    for fg, bg, what in PAIRS:
        ratio = contrast(resolve(fg, tok), resolve(bg, tok))
        check(ratio >= 4.5, f"contrast {ratio:.1f}:1  {what}", f"contrast {ratio:.2f}:1 is below 4.5:1  {what} ({fg} on {bg})")

    diffs = recipe_differences(HOWTO.read_text(encoding="utf-8"), sv.TEMPLATE.read_text(encoding="utf-8"))
    check(not diffs, "the recipe and the HOWTO give the same commands", "the recipe and the HOWTO differ: " + "; ".join(diffs))

    for line in ok:
        print("[PASS]", line)
    for line in problems:
        print("[FAIL]", line)
    print("\nLayout is checked in a browser: paste viewer/check_fit.js and run `await checkViewerFit()`.")
    print("OK" if not problems else f"{len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
