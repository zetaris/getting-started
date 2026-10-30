"""Find values that must never appear in something we hand to someone else.

Shared by package.py (a package must not carry your keys, bucket, endpoint,
folder or login name) and report.py (a report that a partner sends back must
not either). Standard library only.

A "forbidden value" is any value in .env.local that is not allowed to be shown:
every setting except those marked "bake" in settings.json, plus your login name
and home folder. Values shorter than MIN_IDENTITY characters (MIN_SECRET for
secrets) are too likely to match ordinary words, so they are reported as skipped
and not checked.

Problems are reported by setting name, never by value.
"""

from __future__ import annotations

import getpass
import re
from pathlib import Path

MIN_SECRET, MIN_IDENTITY = 6, 5
PLACEHOLDERS = {  # what a redacted value is replaced with, so text stays readable
    "S3_BUCKET": "<bucket>",
    "S3_ENDPOINT_URL": "<endpoint>",
    "S3_ENDPOINT_URL (host)": "<endpoint host>",
    "S3_PREFIX": "<your folder>",
    "your login name": "<user>",
    "your home folder": "<home>",
}


def read_env(path: Path) -> dict[str, str]:
    """Every NAME=value in the file. The values are not put in os.environ."""
    out: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        v = v.strip()
        if len(v) >= 2 and v[0] == v[-1] and v[0] in "'\"":
            v = v[1:-1]
        out[k.strip()] = v
    return out


def forbidden_values(env: dict[str, str], schema: dict) -> tuple[list[tuple[str, str]], list[str]]:
    """(label, value) pairs that must not appear, and the labels skipped for being
    too short to check reliably."""
    defaults = {s["name"]: (s["default"] or "") for s in schema["settings"]}
    secret = {s["name"]: s["secret"] for s in schema["settings"]}
    skip_names = {s["name"] for s in schema["settings"] if s.get("bake")} | {"PACKAGE_PARTNER", "PACKAGE_DENY_WORDS"}
    found: list[tuple[str, str]] = []
    short: list[str] = []

    def add(label: str, value: str, minimum: int) -> None:
        value = value.strip()
        if not value:
            return
        if len(value) < minimum:
            short.append(label)
        elif (label, value) not in found:
            found.append((label, value))

    for name, value in env.items():
        if name in skip_names or value == defaults.get(name, None):
            continue
        add(name, value, MIN_SECRET if secret.get(name, True) else MIN_IDENTITY)
    endpoint = env.get("S3_ENDPOINT_URL", "")
    if endpoint:
        add("S3_ENDPOINT_URL (host)", re.sub(r"^https?://", "", endpoint).split("/")[0].split(":")[0], MIN_IDENTITY)
    for m in re.findall(r"[\w.+-]+@[\w.-]+\.\w+", env.get("ZETARIS_USER_AGENT", "")):
        add("ZETARIS_USER_AGENT (email)", m, MIN_IDENTITY)
    try:
        add("your login name", getpass.getuser(), MIN_IDENTITY)
    except Exception:  # noqa: BLE001
        pass
    add("your home folder", str(Path.home()), MIN_IDENTITY)
    return found, sorted(set(short))


def redact(text: str, values: list[tuple[str, str]]) -> str:
    """The text with every forbidden value replaced by a placeholder. Longest
    values go first, so a path is replaced before a name inside it."""
    for label, value in sorted(values, key=lambda lv: -len(lv[1])):
        text = text.replace(value, PLACEHOLDERS.get(label, f"<{label}>"))
    return text


def found_in(text: str, values: list[tuple[str, str]]) -> list[str]:
    """The labels of forbidden values that appear in the text."""
    return [label for label, value in values if value in text]
