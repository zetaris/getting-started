"""Generate and check the documents that come from settings.json.

settings.json is the single list of settings for the object store kit. This
script turns it into:

  * .env.example            the example env file (user settings only)
  * the settings table in README.md, between the settings-table markers

and checks that nothing has drifted:

  * the schema is well formed (unique names, known groups, no default on a secret)
  * .env.example and the README table match what the schema generates
  * every S3_*, ZETARIS_* and PACKAGE_* name used in the scripts is in the schema
  * every *.tmpl template renders, with and without a store name

    python3 systems/object_stores/scripts/settings_docs.py --check
    python3 systems/object_stores/scripts/settings_docs.py --write

Needs only the standard library.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import textwrap
from pathlib import Path

HERE = Path(__file__).resolve().parent
KIT = HERE.parent
SCHEMA = KIT / "settings.json"
ENV_EXAMPLE = KIT / ".env.example"
README = KIT / "README.md"
START, END = "<!-- settings-table:start -->", "<!-- settings-table:end -->"
NAME_RE = re.compile(r"^[A-Z][A-Z0-9_]*$")
USED_RE = re.compile(r"\b(?:S3|ZETARIS|PACKAGE)_[A-Z][A-Z0-9_]*(?![\w.]*\.(?:md|tmpl|txt|py|json|html)\b)")
AUDIENCES = ("user", "maintainer")

sys.path.insert(0, str(HERE))
import render as renderer  # noqa: E402


def load() -> dict:
    return json.loads(SCHEMA.read_text(encoding="utf-8"))


def validate(schema: dict) -> list[str]:
    problems: list[str] = []
    groups = {g["id"] for g in schema.get("groups", [])}
    seen: set[str] = set()
    for s in schema.get("settings", []):
        n = s.get("name", "")
        if not NAME_RE.match(n):
            problems.append(f"bad setting name {n!r}")
        if n in seen:
            problems.append(f"{n} is listed twice")
        seen.add(n)
        if s.get("group") not in groups:
            problems.append(f"{n}: unknown group {s.get('group')!r}")
        if s.get("audience") not in AUDIENCES:
            problems.append(f"{n}: audience must be one of {AUDIENCES}")
        if s.get("secret") and s.get("default"):
            problems.append(f"{n}: a secret setting must not have a default")
        if not isinstance(s.get("bake"), bool):
            problems.append(f"{n}: bake must be true or false")
        if s.get("bake") and (s.get("secret") or s.get("audience") != "user"):
            problems.append(f"{n}: only a non-secret user setting can be baked into a package")
        if not s.get("description"):
            problems.append(f"{n}: no description")
    return problems


def user_settings(schema: dict, group: str | None = None) -> list[dict]:
    return [s for s in schema["settings"] if s["audience"] == "user" and (group is None or s["group"] == group)]


def env_example(schema: dict, overrides: dict[str, str] | None = None) -> str:
    """The example env file. `overrides` (baked settings only) are written as real
    lines, for a package built for a store that needs, say, S3_ADDRESSING=virtual."""
    overrides = overrides or {}
    out = [
        "# Copy this file to .env.local and fill it in.",
        "# .env.local holds secrets. Never commit it and never put it in a ZIP you share.",
        "# Every script reads it and never prints the keys.",
        "# Generated from settings.json. Edit settings.json, not this file.",
        "# A line without a leading # is required. A line with one is optional, and shows the default.",
    ]
    for g in schema["groups"]:
        items = user_settings(schema, g["id"])
        if not items:
            continue
        out += ["", f"# --- {g['title']} " + "-" * max(3, 74 - len(g["title"])), *textwrap.wrap(g["intro"], 76, initial_indent="# ", subsequent_indent="# ")]
        for s in items:
            desc = ("Secret. " if s["secret"] else "") + s["description"]
            out.append("")
            out += textwrap.wrap(desc, 76, initial_indent="# ", subsequent_indent="# ")
            if s.get("placeholder"):
                out.append(f"# Example: {s['placeholder']}")
            ov = overrides.get(s["name"], "") if s.get("bake") else ""
            if s["required"]:
                out.append(f"{s['name']}=")
            elif ov and ov != (s["default"] or ""):
                out.append(f"{s['name']}={ov}")
            else:
                out.append(f"# {s['name']}={s['default'] or ''}")
    return "\n".join(out) + "\n"


def settings_table(schema: dict) -> str:
    rows = ["| Setting | Required | Secret | Default | Meaning |", "|---|---|---|---|---|"]
    for s in user_settings(schema):
        default = f"`{s['default']}`" if s["default"] else ""
        rows.append(f"| `{s['name']}` | {'yes' if s['required'] else 'no'} | {'yes' if s['secret'] else 'no'} | {default} | {s['description']} |")
    return "\n".join(rows)


def readme_with(table: str, text: str) -> str:
    if START not in text or END not in text:
        raise SystemExit(f"{README.name} has no {START} ... {END} markers.")
    head, rest = text.split(START, 1)
    _, tail = rest.split(END, 1)
    return f"{head}{START}\n{table}\n{END}{tail}"


def names_used_in_scripts() -> dict[str, set[str]]:
    used: dict[str, set[str]] = {}
    for p in sorted(HERE.glob("*.py")):
        if p.name == Path(__file__).name:
            continue
        for n in USED_RE.findall(p.read_text(encoding="utf-8")):
            used.setdefault(n, set()).add(p.name)
    return used


def check_templates() -> list[str]:
    problems: list[str] = []
    for p in sorted([*KIT.glob("*.tmpl"), *KIT.glob("viewer/*.tmpl")]):
        text = p.read_text(encoding="utf-8")
        for label, vals in (("generic", renderer.store_values()), ("named", renderer.store_values("Example Vendor", "Example Store"))):
            try:
                renderer.render(renderer.render_includes(text, p.parent), vals)
            except renderer.RenderError as e:
                problems.append(f"{p.name} ({label}): {e}")
    return problems


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--check", action="store_true", help="fail if anything has drifted")
    g.add_argument("--write", action="store_true", help="regenerate .env.example and the README table")
    a = ap.parse_args()

    schema = load()
    problems = validate(schema)
    example, table = env_example(schema), settings_table(schema)
    readme_new = readme_with(table, README.read_text(encoding="utf-8"))

    if a.write:
        if problems:
            print("Schema problems, nothing written:\n  " + "\n  ".join(problems))
            return 1
        ENV_EXAMPLE.write_text(example, encoding="utf-8")
        README.write_text(readme_new, encoding="utf-8")
        print(f"wrote {ENV_EXAMPLE.relative_to(KIT.parent.parent)} and the table in {README.relative_to(KIT.parent.parent)}")
        return 0

    known = {s["name"] for s in schema["settings"]}
    for name, files in sorted(names_used_in_scripts().items()):
        if name not in known:
            problems.append(f"{name} is used in {', '.join(sorted(files))} but is not in settings.json")
    if not ENV_EXAMPLE.is_file() or ENV_EXAMPLE.read_text(encoding="utf-8") != example:
        problems.append(".env.example is out of date; run --write")
    if README.read_text(encoding="utf-8") != readme_new:
        problems.append("the settings table in README.md is out of date; run --write")
    problems += check_templates()
    if problems:
        print("DRIFT:\n  " + "\n  ".join(problems))
        return 1
    print(f"OK: {len(schema['settings'])} settings; .env.example, the README table, script names and templates all agree.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
