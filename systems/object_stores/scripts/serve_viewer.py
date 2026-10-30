"""Serve the SIC EDGAR USL viewer and run SQL against a live Zetaris instance.

A browser cannot speak JDBC, and it must not hold your API key or password, so
this small local server sits in between. It renders viewer/index.html.tmpl for
each page request and serves one endpoint, POST /api/query, which runs a
statement through the same channel the other scripts use and returns the rows
as JSON.

The page is rendered with the store names from .env.local (S3_STORE_VENDOR and
S3_STORE_PRODUCT, both optional), read again on every request, so editing them
and reloading the page renames it without restarting the server.

Safety, by design:
  * Listens on 127.0.0.1 only.
  * Credentials stay on the server (read from .env.local or the environment).
  * Read-only by default: only SELECT, WITH, SHOW, DESCRIBE, EXPLAIN and LIST,
    one statement per call. Statements that create, change or drop anything are
    refused unless you start the server with --allow-write.
  * Requests must carry the viewer's own header, so another website open in your
    browser cannot send queries through it.
  * The page may load nothing from another site (Content-Security-Policy), and
    only three named asset files are served.
  * GET /api/report/latest serves the newest conformance report from reports/
    (written by report.py), so the Proof tab shows your own run without a file
    picker. Only a file named like report.py names them, at most 1 MB, parsed as
    a report, and checked again against every value in .env.local before it is
    sent; a report that fails any of this is refused, not served.

Run from the repository or package root, with the venv for JDBC:

    .venv/bin/python systems/object_stores/scripts/serve_viewer.py                 # JDBC, http://127.0.0.1:8765
    .venv/bin/python systems/object_stores/scripts/serve_viewer.py --channel rest  # REST instead of JDBC
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
sys.path.insert(0, str(HERE))
import leaks  # noqa: E402
import render as renderer  # noqa: E402
import zetaris_sql as z  # noqa: E402
from quiet import quiet_stderr  # noqa: E402

VIEWER_DIR = HERE.parent / "viewer"
TEMPLATE = VIEWER_DIR / "index.html.tmpl"
# Looked up in order, so a package can carry its own copy under viewer/assets/.
ASSET_DIRS = [VIEWER_DIR / "assets", ROOT / "website" / "assets"]
ASSETS = {
    "fonts/plus-jakarta-sans.ttf": "font/ttf",
    "fonts/OFL.txt": "text/plain; charset=utf-8",
    "brand/zetaris-indigo.svg": "image/svg+xml",
}
CSP = ("default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline'; img-src 'self' data:; "
       "font-src 'self'; connect-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'")
NAME_KEYS = ("S3_STORE_VENDOR", "S3_STORE_PRODUCT")

READ_ONLY_START = {"select", "with", "show", "describe", "desc", "explain", "list"}
WRITE_WORDS = re.compile(
    r"\b(insert|update|delete|merge|drop|create|alter|truncate|grant|revoke|materialize|"
    r"activate|compile|remove|register|cache|uncache|set|export|refresh|run)\b",
    re.I,
)
MAX_BODY = 64 * 1024
REPORT_NAME = re.compile(r"[a-z0-9][a-z0-9-]*-\d{8}-\d{6}\.json")
REPORT_KIND = "zetaris-object-store-report"
MAX_REPORT = 1024 * 1024
SCHEMA_FILE = HERE.parent / "settings.json"
HEADER = "X-SIC-Viewer"


def strip_literals(sql: str) -> str:
    """The statement with quoted strings and comments blanked, for keyword checks."""
    sql = re.sub(r"/\*.*?\*/", " ", sql, flags=re.S)
    sql = re.sub(r"--[^\n]*", " ", sql)
    sql = re.sub(r"'(?:[^'\\]|\\.|'')*'", "''", sql)
    sql = re.sub(r'"(?:[^"\\]|\\.)*"', '""', sql)
    return re.sub(r"`[^`]*`", "``", sql)


def check_statement(sql: str, allow_write: bool) -> str:
    """Return the cleaned statement, or raise ValueError with a reason."""
    sql = sql.strip().rstrip(";").strip()
    if not sql:
        raise ValueError("Type a statement first.")
    plain = strip_literals(sql)
    if ";" in plain:
        raise ValueError("One statement per call: remove the extra semicolon.")
    first = plain.split(None, 1)[0].lower()
    if allow_write:
        return sql
    if first not in READ_ONLY_START:
        raise ValueError(
            f"'{first.upper()}' is not allowed. This viewer is read-only: use SELECT, WITH, SHOW, "
            "DESCRIBE, EXPLAIN or LIST. Start the server with --allow-write to change this."
        )
    bad = WRITE_WORDS.search(plain)
    if bad and first in {"select", "with"}:
        raise ValueError(f"'{bad.group(1).upper()}' is not allowed in a read-only query.")
    return sql


def read_names(env_file: Path | None, shell: dict[str, str]) -> dict[str, str]:
    """The two store-name settings. A value set in the shell wins, as it does for
    every other setting; otherwise the file is read now, so edits show up."""
    found: dict[str, str] = {}
    if env_file and env_file.is_file():
        for line in env_file.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                if k.strip() in NAME_KEYS:
                    found[k.strip()] = v.strip().strip("'\"")
    return {k: shell.get(k) or found.get(k, "") for k in NAME_KEYS}


def partner_logo() -> str | None:
    """assets/partner/logo.<ext>, if the package carries a partner logo."""
    for ext in renderer.LOGO_EXTS:
        if (VIEWER_DIR / "assets" / "partner" / f"logo{ext}").is_file():
            return f"assets/partner/logo{ext}"
    return None


def render_page(names: dict[str, str]) -> str:
    """The viewer HTML for the given names. Raises renderer.RenderError."""
    return renderer.render_viewer(TEMPLATE, names, partner_logo())


def read_asset(rel: str) -> tuple[bytes, str] | None:
    m = re.fullmatch(r"partner/logo(\.[a-z]+)", rel)
    if m and m.group(1) in renderer.LOGO_EXTS:  # the package's own logo, never from website/
        f = VIEWER_DIR / "assets" / rel
        return (f.read_bytes(), renderer.LOGO_EXTS[m.group(1)]) if f.is_file() else None
    ctype = ASSETS.get(rel)  # exact names only, so no path can reach another file
    if not ctype:
        return None
    for d in ASSET_DIRS:
        f = d / rel
        if f.is_file():
            return f.read_bytes(), ctype
    return None


def forbidden(env_file: Path | None) -> list[tuple[str, str]]:
    """Every value that must never appear in a served report: the .env.local
    values (read now) and the same settings from the shell, as report.py does."""
    schema = json.loads(SCHEMA_FILE.read_text(encoding="utf-8"))
    env = leaks.read_env(env_file) if env_file and env_file.is_file() else {}
    env.update({s["name"]: os.environ[s["name"]] for s in schema["settings"] if os.environ.get(s["name"])})
    return leaks.forbidden_values(env, schema)[0]


def latest_report(reports_dir: Path, values: list[tuple[str, str]]) -> tuple[int, dict]:
    """(HTTP status, body) for the newest report in reports_dir. Anything that is
    not a plain, small, valid report with no leaked value is refused."""
    try:
        files = [f for f in reports_dir.iterdir()
                 if REPORT_NAME.fullmatch(f.name) and f.is_file() and not f.is_symlink()]
    except OSError:
        files = []
    if not files:
        return 404, {"ok": False, "error": "No report yet. Run report.py first."}
    f = max(files, key=lambda p: (p.stat().st_mtime, p.name))
    if f.stat().st_size > MAX_REPORT:
        return 422, {"ok": False, "error": f"{f.name} is larger than 1 MB, so it is not served."}
    text = f.read_text(encoding="utf-8", errors="replace")
    try:
        doc = json.loads(text)
    except ValueError:
        return 422, {"ok": False, "error": f"{f.name} is not valid JSON."}
    if not isinstance(doc, dict) or doc.get("kind") != REPORT_KIND:
        return 422, {"ok": False, "error": f"{f.name} is not a conformance report."}
    hits = leaks.found_in(text, values)
    if hits:
        return 409, {"ok": False, "error": f"{f.name} was not served: it still contains values from .env.local ({', '.join(hits)}). Delete it and run report.py again."}
    return 200, {"ok": True, "name": f.name, "report": doc}


class App:
    def __init__(self, channel_name: str, jar: str | None, allow_write: bool, row_limit: int) -> None:
        self.channel_name, self.jar, self.allow_write, self.row_limit = channel_name, jar, allow_write, row_limit
        self.channel = None

    def channel_ready(self):
        if self.channel is None:
            with quiet_stderr():  # the driver's harmless SLF4J warning
                self.channel = z.open_channel(self.channel_name, self.jar)
        return self.channel

    def run(self, sql: str, limit: int) -> dict:
        sql = check_statement(sql, self.allow_write)
        limit = max(1, min(int(limit or self.row_limit), 5000))
        started = time.time()
        try:
            res = self.channel_ready().run(sql, limit=limit + 1)
        except z.ZetarisError:
            self.channel = None  # reopen next time, in case the connection dropped
            raise
        rows = res.rows
        truncated = len(rows) > limit
        rows = rows[:limit]
        columns = res.columns or [f"col{i + 1}" for i in range(len(rows[0]))] if rows else (res.columns or [])
        return {
            "ok": True,
            "columns": columns,
            "rows": [[None if v is None else (v if isinstance(v, (int, float, bool)) else str(v)) for v in r] for r in rows],
            "rowCount": len(rows),
            "truncated": truncated,
            "limit": limit,
            "ms": int((time.time() - started) * 1000),
            "channel": self.channel_name,
        }


def make_handler(app: App, port: int, env_file: Path | None, shell: dict[str, str], reports_dir: Path | None = None):
    class Handler(BaseHTTPRequestHandler):
        server_version = "SicViewer/2"

        def log_message(self, fmt, *args):  # one short line per request, never the SQL
            sys.stderr.write("  %s %s\n" % (self.command, self.path.split("?")[0]))

        def _send(self, code: int, body: bytes, ctype: str, page: bool = False, asset: bool = False) -> None:
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Content-Type-Options", "nosniff")
            if asset:  # an SVG opened on its own must not run anything
                self.send_header("Content-Security-Policy", "default-src 'none'; sandbox")
            if page:
                self.send_header("Content-Security-Policy", CSP)
                self.send_header("Referrer-Policy", "no-referrer")
            self.end_headers()
            self.wfile.write(body)

        def _json(self, code: int, obj: dict) -> None:
            self._send(code, json.dumps(obj).encode(), "application/json")

        def _host_ok(self) -> bool:
            host = (self.headers.get("Host") or "").split(":")[0]
            return host in ("127.0.0.1", "localhost")

        def do_GET(self):
            path = self.path.split("?")[0]
            if not self._host_ok():
                return self._json(403, {"ok": False, "error": "Open the viewer at http://127.0.0.1:%d" % port})
            if path in ("/", "/index.html"):
                try:
                    html = render_page(read_names(env_file, shell))
                except renderer.RenderError as e:
                    return self._json(500, {"ok": False, "error": f"Cannot render the viewer: {e}"})
                except OSError:
                    return self._json(404, {"ok": False, "error": "viewer/index.html.tmpl is missing"})
                return self._send(200, html.encode("utf-8"), "text/html; charset=utf-8", page=True)
            if path.startswith("/assets/"):
                asset = read_asset(path[len("/assets/"):])
                if asset:
                    return self._send(200, asset[0], asset[1], asset=True)
                return self._json(404, {"ok": False, "error": "Not found"})
            if path == "/api/report/latest":
                code, body = latest_report(reports_dir or ROOT / "reports", forbidden(env_file))
                return self._json(code, body)
            if path == "/api/health":
                return self._json(200, {"ok": True, "channel": app.channel_name, "readOnly": not app.allow_write})
            return self._json(404, {"ok": False, "error": "Not found"})

        def do_POST(self):
            if self.path.split("?")[0] != "/api/query":
                return self._json(404, {"ok": False, "error": "Not found"})
            if not self._host_ok() or self.headers.get(HEADER) != "1":
                return self._json(403, {"ok": False, "error": "Forbidden"})
            try:
                n = int(self.headers.get("Content-Length") or 0)
                if n <= 0 or n > MAX_BODY:
                    raise ValueError("Request body is empty or too large.")
                body = json.loads(self.rfile.read(n).decode("utf-8"))
                out = app.run(str(body.get("sql", "")), body.get("limit"))
                return self._json(200, out)
            except ValueError as e:
                return self._json(400, {"ok": False, "error": str(e)})
            except z.ZetarisError as e:
                return self._json(502, {"ok": False, "error": str(e)})
            except Exception as e:  # keep the server alive; show the reason in the viewer
                return self._json(500, {"ok": False, "error": f"{type(e).__name__}: {e}"[:400]})

    return Handler


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--port", type=int, default=8765)
    ap.add_argument("--channel", default="jdbc", choices=["jdbc", "rest"])
    ap.add_argument("--jar", help="driver JAR for JDBC (default: ZETARIS_JDBC_JAR)")
    ap.add_argument("--limit", type=int, default=500, help="default rows returned (max 5000)")
    ap.add_argument("--reports", default=str(ROOT / "reports"), help="folder holding the reports to show in the Proof tab (default: reports/)")
    ap.add_argument("--allow-write", action="store_true", help="also allow statements that change the instance")
    a = ap.parse_args()

    shell = {k: os.environ[k] for k in NAME_KEYS if os.environ.get(k)}  # before .env.local is loaded
    env = z.load_env()
    z.reexec_in_venv_if_needed(a.channel)
    try:
        render_page(read_names(env, shell))  # fail now if the template or the names are bad
    except (renderer.RenderError, OSError) as e:
        print(f"Cannot render the viewer: {e}", file=sys.stderr)
        return 2
    app = App(a.channel, a.jar or os.environ.get("ZETARIS_JDBC_JAR"), a.allow_write, a.limit)
    try:
        app.channel_ready()  # fail now, with a clear message, not on the first query
        app.run("SELECT 1", 1)
    except (z.ZetarisError, ValueError) as e:
        print(f"Cannot connect over {a.channel.upper()}: {e}", file=sys.stderr)
        return 2
    srv = HTTPServer(("127.0.0.1", a.port), make_handler(app, a.port, env, shell, Path(a.reports)))
    print(f"Connected over {a.channel.upper()} (settings from {env or 'the environment'}).", flush=True)
    print(f"Mode: {'READ-WRITE' if a.allow_write else 'read-only'}.  Viewer: http://127.0.0.1:{a.port}   (Ctrl+C to stop)", flush=True)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
