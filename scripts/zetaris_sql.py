"""Shared helpers for run_sql.py and preflight.py: env loading, SQL statement
splitting, and a REST or JDBC channel to a Zetaris instance.

Standard library only, except JDBC, which needs `jaydebeapi` (see
scripts/requirements.txt) and a JDK. Secrets are read from the environment and
never printed.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import uuid
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent.parent
PLACEHOLDER_UA = "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
DEFAULT_REST_URL = "http://localhost:8888/api/v1.0"
DEFAULT_JDBC_URL = "jdbc:zetaris:lightning@localhost:10000"
DRIVER_CLASS = "com.zetaris.lightning.jdbc.LightningDriver"
ALREADY_EXISTS = re.compile(r"already exists", re.I)


class ZetarisError(RuntimeError):
    pass


# --- environment -----------------------------------------------------------


def _top_level_checkout() -> Path | None:
    """The main checkout when running inside a git worktree, else None."""
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--git-common-dir"],
            cwd=ROOT, capture_output=True, text=True, check=True,
        ).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return None
    top = (ROOT / out).resolve().parent
    return top if top != ROOT else None


def env_file_candidates() -> list[Path]:
    dirs = [ROOT] + ([top] if (top := _top_level_checkout()) else [])
    return [d / name for d in dirs for name in (".env.local", ".env")]


def load_env(env_file: str | None = None) -> Path | None:
    """Load the first env file found into os.environ without overriding
    variables that are already set. Returns the file used, or None."""
    paths = [Path(env_file)] if env_file else env_file_candidates()
    for path in paths:
        if not path.is_file():
            continue
        for line in path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            value = value.strip()
            if len(value) >= 2 and value[0] == value[-1] and value[0] in "'\"":
                value = value[1:-1]
            os.environ.setdefault(key.strip(), value)
        return path
    return None


def require(*names: str) -> None:
    missing = [n for n in names if not os.environ.get(n)]
    if missing:
        raise ZetarisError("Missing in the environment or .env.local: " + ", ".join(missing))


# --- SQL splitting ---------------------------------------------------------


def split_statements(text: str) -> list[str]:
    """Split SQL on semicolons outside quotes, dropping comments.

    Handles '..', "..", `..` quoting (a doubled quote is an escape) and both
    `-- line` and `/* block */` comments. A CREATE TABLE that follows
    COMPILE USL ... DDL is merged back into that statement, because a
    multi-table USL must be sent whole.
    """
    statements: list[str] = []
    buf: list[str] = []
    i, n, quote = 0, len(text), None
    while i < n:
        c = text[i]
        if quote:
            buf.append(c)
            if c == quote:
                quote = None
        elif c in "'\"`":
            quote = c
            buf.append(c)
        elif text.startswith("--", i):
            while i < n and text[i] != "\n":
                i += 1
            continue
        elif text.startswith("/*", i):
            end = text.find("*/", i + 2)
            i = n if end == -1 else end + 2
            continue
        elif c == ";":
            _push(statements, "".join(buf))
            buf = []
        else:
            buf.append(c)
        i += 1
    _push(statements, "".join(buf))
    return statements


def _push(statements: list[str], raw: str) -> None:
    stmt = raw.strip()
    if not stmt:
        return
    if (
        stmt.upper().startswith("CREATE TABLE")
        and statements
        and statements[-1].upper().startswith("COMPILE USL")
    ):
        statements[-1] += ";\n" + stmt
    else:
        statements.append(stmt)


def apply_user_agent(statements: list[str]) -> list[str]:
    """Replace the repo's user-agent placeholder with ZETARIS_USER_AGENT.

    Refuses to send the placeholder itself, since sources such as SEC EDGAR
    block it.
    """
    if not any(PLACEHOLDER_UA in s for s in statements):
        return statements
    ua = os.environ.get("ZETARIS_USER_AGENT", "").strip()
    if not ua:
        raise ZetarisError(
            "This script contains the user-agent placeholder "
            f"'{PLACEHOLDER_UA}'. Set ZETARIS_USER_AGENT in .env.local to "
            "'<app name> <contact email>'."
        )
    if '"' in ua or "'" in ua:
        raise ZetarisError("ZETARIS_USER_AGENT must not contain quotes.")
    return [s.replace(PLACEHOLDER_UA, ua) for s in statements]


# --- channels --------------------------------------------------------------


class Result:
    def __init__(self, rows: list[list[Any]] | None):
        self.rows = rows or []


class RestChannel:
    name = "rest"

    def __init__(self) -> None:
        require("ZETARIS_API_KEY")
        self.base = os.environ.get("ZETARIS_REST_URL", DEFAULT_REST_URL).rstrip("/")
        self.org = os.environ.get("ZETARIS_ORG_ID", "1")
        self._key = os.environ["ZETARIS_API_KEY"]

    def _call(self, path: str, body: dict | None = None) -> Any:
        req = Request(
            self.base + path,
            data=json.dumps(body).encode() if body is not None else None,
            method="POST" if body is not None else "GET",
            headers={
                "Authorization": f"Bearer {self._key}",
                "X-Org-ID": self.org,
                "X-Request-ID": str(uuid.uuid4()),
                "Content-Type": "application/json",
            },
        )
        try:
            with urlopen(req, timeout=600) as resp:
                return json.loads(resp.read().decode() or "null")
        except HTTPError as e:
            raise ZetarisError(f"HTTP {e.code}: {_short(e.read().decode(errors='replace'))}") from e
        except (URLError, OSError) as e:
            raise ZetarisError(f"Cannot reach {self.base}: {getattr(e, 'reason', e)}") from e

    def datasources(self) -> Any:
        return self._call("/datasource/datasources")

    def run(self, sql: str, limit: int = 100) -> Result:
        out = self._call(
            "/sql-editor/sqls/run",
            {"queryId": str(uuid.uuid4()), "sql": sql, "source": "SqlEditor", "limit": limit},
        )
        return Result(out.get("data") if isinstance(out, dict) else None)

    def close(self) -> None:
        pass


def find_java_home() -> str | None:
    """A usable JDK home. On macOS `java` on PATH can be a stub that reports
    'Unable to locate a Java Runtime' even when a Homebrew JDK is installed."""
    candidates = [os.environ.get("JAVA_HOME")]
    try:
        out = subprocess.run(["/usr/libexec/java_home"], capture_output=True, text=True)
        if out.returncode == 0:
            candidates.append(out.stdout.strip())
    except OSError:
        pass
    for formula in ("openjdk@17", "openjdk@21", "openjdk@11", "openjdk"):
        for prefix in ("/opt/homebrew", "/usr/local"):
            candidates.append(f"{prefix}/opt/{formula}/libexec/openjdk.jdk/Contents/Home")
    for home in candidates:
        if home and (Path(home) / "bin" / "java").is_file():
            return home
    return None


def venv_python() -> Path | None:
    py = ROOT / ".venv" / "bin" / "python"
    return py if py.is_file() else None


class JdbcChannel:
    name = "jdbc"

    def __init__(self, jar: str | None = None) -> None:
        require("ZETARIS_USERNAME", "ZETARIS_PASSWORD")
        self.jar = jar or os.environ.get("ZETARIS_JDBC_JAR")
        if not self.jar:
            raise ZetarisError(
                "Driver JAR path not set. Pass --jar or set ZETARIS_JDBC_JAR to the "
                "full path of the Zetaris JDBC driver JAR (ask the user; do not guess)."
            )
        if not Path(self.jar).is_file():
            raise ZetarisError(f"Driver JAR not found: {self.jar}")
        home = find_java_home()
        if not home:
            raise ZetarisError(
                "No JDK found. Install one (for example `brew install openjdk@17`) and set JAVA_HOME."
            )
        os.environ["JAVA_HOME"] = home
        try:
            import jaydebeapi
        except ImportError as e:
            raise ZetarisError(
                "jaydebeapi is not installed in this Python. Create a venv and run "
                "`.venv/bin/pip install -r scripts/requirements.txt`."
            ) from e
        self._conn = jaydebeapi.connect(
            DRIVER_CLASS,
            os.environ.get("ZETARIS_JDBC_URL", DEFAULT_JDBC_URL),
            [os.environ["ZETARIS_USERNAME"], os.environ["ZETARIS_PASSWORD"]],
            self.jar,
        )
        self._cur = self._conn.cursor()

    def run(self, sql: str, limit: int = 100) -> Result:
        try:
            self._cur.execute(sql)
        except Exception as e:  # jaydebeapi raises java exceptions
            raise ZetarisError(_short(str(e))) from e
        try:
            rows = self._cur.fetchall()
        except Exception:
            return Result(None)
        return Result([list(r) for r in rows[:limit]])

    def close(self) -> None:
        self._conn.close()


def open_channel(name: str, jar: str | None = None):
    if name == "rest":
        return RestChannel()
    if name == "jdbc":
        return JdbcChannel(jar)
    raise ZetarisError(f"Unknown channel: {name}")


def reexec_in_venv_if_needed(channel: str) -> None:
    """For JDBC, hop into .venv when this interpreter lacks jaydebeapi."""
    if channel != "jdbc":
        return
    try:
        import jaydebeapi  # noqa: F401
    except ImportError:
        py = venv_python()
        if py and Path(sys.prefix).resolve() != (ROOT / ".venv").resolve() and not os.environ.get("_ZETARIS_REEXEC"):
            os.environ["_ZETARIS_REEXEC"] = "1"
            os.execv(str(py), [str(py), *sys.argv])


def _short(text: str, n: int = 400) -> str:
    text = " ".join(text.split())
    return text if len(text) <= n else text[:n] + "..."
