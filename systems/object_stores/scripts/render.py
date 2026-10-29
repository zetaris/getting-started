"""Fill {{TOKENS}} in a template with the names of an object store.

Used for the documents and, later, the viewer. It is a pure function from text
and values to text, so the packager and the viewer server render the same way.

Tokens:
    {{STORE_VENDOR}}   vendor name, or empty
    {{STORE_PRODUCT}}  product name, or empty
    {{STORE_NAME}}     vendor and product joined, or "your S3-compatible object store"
    {{STORE_LABEL}}    a short form for diagram boxes: the name cut to 24 characters,
                       or "S3 object store"

A template can also pull in a text file with <!--include:path/to/file.txt-->. The
path is relative to the template, must stay inside it, and the content is
escaped like a value.

Rendering fails, instead of leaving something half-filled, if a template uses an
unknown token or any "{{" is left in the result. Values are checked: no control
characters, and at most 60 characters. Use a token only in prose and labels,
never inside a command someone will copy.

    python3 systems/object_stores/scripts/render.py TEMPLATE [--vendor V] [--product P] [--html]

--html escapes the values for markup (use it for the viewer).
"""

from __future__ import annotations

import argparse
import html
import re
import sys
from pathlib import Path
from typing import Callable

TOKEN = re.compile(r"\{\{\s*([A-Z_]+)\s*\}\}")
INCLUDE = re.compile(r"<!--include:([A-Za-z0-9_./-]+)-->")
GENERIC_NAME = "your S3-compatible object store"
GENERIC_LABEL = "S3 object store"
MAX_NAME = 60
MAX_LABEL = 24


class RenderError(ValueError):
    pass


def _clean(label: str, value: str) -> str:
    value = (value or "").strip()
    if len(value) > MAX_NAME:
        raise RenderError(f"{label} is longer than {MAX_NAME} characters.")
    if any(ord(c) < 32 or ord(c) == 127 for c in value):
        raise RenderError(f"{label} contains a control character.")
    return value


def store_values(vendor: str = "", product: str = "") -> dict[str, str]:
    """The token values for a vendor and product, either of which may be empty."""
    v, p = _clean("S3_STORE_VENDOR", vendor), _clean("S3_STORE_PRODUCT", product)
    joined = " ".join(x for x in (v, p) if x)
    label = joined if len(joined) <= MAX_LABEL else joined[: MAX_LABEL - 1].rstrip() + "\u2026"
    return {
        "STORE_VENDOR": v,
        "STORE_PRODUCT": p,
        "STORE_NAME": joined or GENERIC_NAME,
        "STORE_LABEL": label or GENERIC_LABEL,
    }


def escape_html(value: str) -> str:
    return html.escape(value, quote=True)


LOGO_EXTS = {".svg": "image/svg+xml", ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".webp": "image/webp"}
LOGO_FILE = re.compile(r"assets/partner/logo(\.svg|\.png|\.jpg|\.jpeg|\.webp)")
PARTNER_MARK = "<!--partner-logo-->"


def partner_logo_markup(logo_file: str | None, name: str) -> str:
    """The header markup for a partner logo, or nothing. `logo_file` must be
    exactly assets/partner/logo.<ext>, so a value can never choose another path."""
    if not logo_file:
        return ""
    if not LOGO_FILE.fullmatch(logo_file):
        raise RenderError(f"logo file {logo_file!r} must be assets/partner/logo.<svg|png|jpg|webp>")
    alt = "Partner logo" if name == GENERIC_NAME else f"{name} logo"
    return f'<div class="partner" id="partnerSlot"><img src="{escape_html(logo_file)}" alt="{escape_html(alt)}"></div>'


def render_includes(text: str, base: Path, escape: Callable[[str], str] | None = None) -> str:
    """Replace each <!--include:file--> with the file's content, escaped. The file
    must be inside `base`."""
    root = base.resolve()

    def sub(m: re.Match) -> str:
        target = (root / m.group(1)).resolve()
        if root not in target.parents:
            raise RenderError(f"include {m.group(1)!r} is outside {root}")
        try:
            body = target.read_text(encoding="utf-8").rstrip("\n")
        except OSError as e:
            raise RenderError(f"cannot include {m.group(1)!r}: {e.strerror}") from e
        return escape(body) if escape else body

    return INCLUDE.sub(sub, text)


def render(template: str, values: dict[str, str], escape: Callable[[str], str] | None = None) -> str:
    """Replace every token. `escape` is applied to each value (use escape_html for
    markup). Raises RenderError on an unknown token or a leftover "{{"."""
    def sub(m: re.Match) -> str:
        name = m.group(1)
        if name not in values:
            raise RenderError(f"unknown token {{{{{name}}}}}")
        return escape(values[name]) if escape else values[name]

    out = TOKEN.sub(sub, template)
    if "{{" in out:
        raise RenderError("unresolved '{{' left after rendering")
    return out


def render_viewer(template: Path, names: dict[str, str], logo_file: str | None = None) -> str:
    """The viewer page: includes, the partner logo and the store names, all
    escaped for markup. `names` holds S3_STORE_VENDOR and S3_STORE_PRODUCT."""
    values = store_values(names.get("S3_STORE_VENDOR", ""), names.get("S3_STORE_PRODUCT", ""))
    text = render_includes(template.read_text(encoding="utf-8"), template.parent, escape_html)
    text = text.replace(PARTNER_MARK, partner_logo_markup(logo_file, values["STORE_NAME"]))
    return render(text, values, escape_html)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("template")
    ap.add_argument("--vendor", default="")
    ap.add_argument("--product", default="")
    ap.add_argument("--html", action="store_true", help="escape values for markup")
    a = ap.parse_args()
    try:
        tpl = Path(a.template)
        esc = escape_html if a.html else None
        text = render_includes(tpl.read_text(encoding="utf-8"), tpl.parent, esc)
        sys.stdout.write(render(text, store_values(a.vendor, a.product), esc))
    except RenderError as e:
        print("render error:", e, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
