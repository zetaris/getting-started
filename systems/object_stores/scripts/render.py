"""Fill {{TOKENS}} in a template with the names of an object store.

Used for the documents and, later, the viewer. It is a pure function from text
and values to text, so the packager and the viewer server render the same way.

Tokens:
    {{STORE_VENDOR}}   vendor name, or empty
    {{STORE_PRODUCT}}  product name, or empty
    {{STORE_NAME}}     vendor and product joined, or "your S3-compatible object store"

Rendering fails, instead of leaving something half-filled, if a template uses an
unknown token or any "{{" is left in the result. Values are checked: no control
characters, and at most 60 characters. Use a token only in prose and labels,
never inside a command someone will copy.

    python3 systems/object_stores/scripts/render.py TEMPLATE [--vendor V] [--product P]
"""

from __future__ import annotations

import argparse
import html
import re
import sys
from pathlib import Path
from typing import Callable

TOKEN = re.compile(r"\{\{\s*([A-Z_]+)\s*\}\}")
GENERIC_NAME = "your S3-compatible object store"
MAX_NAME = 60


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
    name = " ".join(x for x in (v, p) if x) or GENERIC_NAME
    return {"STORE_VENDOR": v, "STORE_PRODUCT": p, "STORE_NAME": name}


def escape_html(value: str) -> str:
    return html.escape(value, quote=True)


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


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("template")
    ap.add_argument("--vendor", default="")
    ap.add_argument("--product", default="")
    a = ap.parse_args()
    try:
        sys.stdout.write(render(Path(a.template).read_text(encoding="utf-8"), store_values(a.vendor, a.product)))
    except RenderError as e:
        print("render error:", e, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
