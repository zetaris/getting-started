#!/usr/bin/env python3
"""Check that this machine and instance are ready before onboarding data.

    python3 scripts/preflight.py            # REST checks
    python3 scripts/preflight.py --jdbc     # also check JDBC (Java, jaydebeapi, driver JAR)
    python3 scripts/preflight.py --s3       # also check the object store settings (no network)

Read-only: it reports what is missing and installs or creates nothing. Exits 1
if any check fails. Credentials are checked for presence and never printed.
"""

from __future__ import annotations

import argparse
import json
import os
import socket
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import zetaris_sql as z  # noqa: E402

failures = 0


def report(ok: bool | None, label: str, detail: str = "") -> None:
    """ok=True pass, False fail, None informational."""
    global failures
    mark = {True: "PASS", False: "FAIL", None: "INFO"}[ok]
    failures += ok is False
    print(f"[{mark}] {label}" + (f": {detail}" if detail else ""))


def check_env(args) -> None:
    env = z.load_env(args.env_file)
    report(env is not None, "env file", str(env) if env else "no .env.local found (looked in: " + ", ".join(map(str, z.env_file_candidates())) + ")" + (f". {h}" if (h := z.stray_env_hint()) else ""))
    for name, why in (
        ("ZETARIS_API_KEY", "REST bearer key, created in the Zetaris GUI"),
        ("ZETARIS_USERNAME", "spec fetch and JDBC"),
        ("ZETARIS_PASSWORD", "spec fetch and JDBC"),
    ):
        report(bool(os.environ.get(name)), name, "set" if os.environ.get(name) else f"MISSING ({why})")
    ua = os.environ.get("ZETARIS_USER_AGENT")
    if not ua:
        report(None, "ZETARIS_USER_AGENT", "not set (needed by any script with the YOUR_APP_NAME placeholder, such as the company_dns scripts and SEC EDGAR: set it to 'app_name user@domain.tld')")
    elif z.valid_user_agent(ua):
        report(True, "ZETARIS_USER_AGENT", "set, in the form app_name user@domain.tld")
    else:
        report(False, "ZETARIS_USER_AGENT", "set, but it does not identify you: use 'app_name user@domain.tld' (company_dns V4 gives anything vaguer the strict rate limit)")


def check_s3() -> None:
    """The object store settings from systems/object_stores/settings.json: the
    required ones are present and the optional ones are usable. No network call;
    probe_s3.py is the test that reaches the store."""
    schema_file = z.ROOT / "systems" / "object_stores" / "settings.json"
    if not schema_file.is_file():
        report(False, "object store settings", f"{schema_file} is missing")
        return
    settings = [s for s in json.loads(schema_file.read_text(encoding="utf-8"))["settings"] if s["group"] == "object_store"]
    for s in settings:
        if s["required"]:
            ok = bool(os.environ.get(s["name"]))
            report(ok, s["name"], "set" if ok else f"MISSING ({s['description'].split('.')[0]})")
    endpoint = os.environ.get("S3_ENDPOINT_URL", "")
    if endpoint and not endpoint.startswith(("https://", "http://")):
        report(False, "S3_ENDPOINT_URL", "must start with https:// (or http:// for a store on a trusted network)")
    elif endpoint.startswith("http://"):
        report(None, "S3_ENDPOINT_URL", "uses http://, so the keys travel unencrypted")
    addressing = os.environ.get("S3_ADDRESSING", "").strip().lower() or "path"
    report(addressing in ("path", "virtual"), "S3_ADDRESSING", addressing if addressing in ("path", "virtual") else f"{addressing!r} is not path or virtual")
    ca = os.environ.get("S3_CA_BUNDLE", "").strip()
    if ca:
        report(Path(ca).is_file(), "S3_CA_BUNDLE", ca if Path(ca).is_file() else f"{ca!r} is not a file")
    else:
        report(None, "S3_CA_BUNDLE", "not set (the CA file Python trusts is used)")


def check_rest() -> None:
    try:
        ch = z.RestChannel()
    except z.ZetarisError as e:
        report(False, "REST", str(e))
        return
    try:
        ds = ch.datasources()
        names = [d.get("name") for d in (ds if isinstance(ds, list) else ds.get("data", []))]
        report(True, "REST datasources", f"HTTP 200, {len(names)} listed: {', '.join(map(str, names))}")
        report(ch.run("SELECT 1").rows == [["1"]], "REST SELECT 1")
        state(ch)
    except z.ZetarisError as e:
        hint = " (401: bad key; 400: bad X-Org-ID or request id)" if "HTTP 40" in str(e) else ""
        report(False, "REST", str(e) + hint)


def check_jdbc(args) -> None:
    host, port = "localhost", 10000
    try:
        socket.create_connection((host, port), timeout=3).close()
        report(True, f"JDBC port {port}", "open")
    except OSError:
        report(False, f"JDBC port {port}", "closed")
    home = z.find_java_home()
    report(home is not None, "Java (JDK 11+)", home or "none found. On macOS `java` can be a stub; try `brew install openjdk@17` (the temurin cask needs sudo)")
    venv = z.venv_python()
    report(venv is not None, ".venv", str(venv) if venv else f"missing; run `python3 -m venv .venv && .venv/bin/pip install -r {z.requirements_file()}`")
    try:
        import jaydebeapi  # noqa: F401
        have = True
    except ImportError:
        have = False
    report(have, "jaydebeapi", "importable" if have else f"not installed in this Python (create .venv and install {z.requirements_file()})")
    jar = args.jar or os.environ.get("ZETARIS_JDBC_JAR")
    if not jar:
        report(False, "driver JAR", "path not set. Ask the user; pass --jar or set ZETARIS_JDBC_JAR")
    else:
        report(Path(jar).is_file(), "driver JAR", jar if Path(jar).is_file() else f"not found: {jar}")
    if home and have and jar and Path(jar).is_file():
        try:
            ch = z.JdbcChannel(jar)
            report(ch.run("SELECT 1").rows in ([[1]], [["1"]]), "JDBC SELECT 1")
            state(ch)
            ch.close()
        except z.ZetarisError as e:
            report(False, "JDBC SELECT 1", str(e))


def state(ch) -> None:
    """What is already on the instance. SHOW DATASOURCES omits Lightning sources."""
    for sql, label in (
        ("SHOW DATASOURCES", "datasources"),
        ("SHOW LIGHTNING DATABASES", "lightning databases"),
        ("SHOW NAMESPACES OR TABLES IN lightning.metastore", "USL namespaces"),
    ):
        try:
            rows = ch.run(sql).rows
            report(None, label, ", ".join(str(r[0]) for r in rows) if rows else "none")
        except z.ZetarisError as e:
            report(None, label, f"query failed: {e}")


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--jdbc", action="store_true", help="also check JDBC prerequisites and connection")
    p.add_argument("--jar", help="JDBC driver JAR path (or set ZETARIS_JDBC_JAR)")
    p.add_argument("--s3", action="store_true", help="also check the object store settings (no network)")
    p.add_argument("--env-file", help="env file to load")
    args = p.parse_args()
    if args.jdbc:
        z.reexec_in_venv_if_needed("jdbc")  # hop into .venv when it has jaydebeapi
    check_env(args)
    check_rest()
    if args.jdbc:
        check_jdbc(args)
    if args.s3:
        check_s3()
    print()
    print("READY" if not failures else f"NOT READY: {failures} check(s) failed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
