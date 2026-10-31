#!/usr/bin/env python3
"""Zetaris MCP server for Cursor and other MCP clients.

Gives a coding agent five tools that run against a live Zetaris instance:
list_databases, list_tables, describe_table, run_query and
register_source (CREATE LIGHTNING or CACHE TABLE). Python standard library
only. Reads the same settings as the other scripts here (ZETARIS_BASE_URL,
ZETARIS_ORG_ID, and ZETARIS_API_KEY or ZETARIS_USERNAME + ZETARIS_PASSWORD,
optional ZETARIS_ENGINE_ID) from the environment or the repository's
.env.local, loaded by zetaris_sql.load_env(). Set ZETARIS_MCP_LOG to a file
path to keep a JSON line per tool call.

Start it from the repository root as an MCP server, for example in Cursor's
.cursor/mcp.json: {"mcpServers": {"zetaris": {"command": "python3",
"args": ["scripts/zetaris_mcp.py"]}}}. See scripts/HOWTO.md.

Guard rails for agents:
- ZETARIS_TIMEOUT (default 50 s) caps each call, so the agent gets a clear
  answer before its own MCP client gives up.
- If a query runs past that cap it may still be running inside Zetaris.
  With ZETARIS_SPARK_UI set (for example http://127.0.0.1:4040), the server
  checks Spark's read-only status API and refuses new queries until that one
  has finished (or ZETARIS_COOLDOWN seconds, default 180, have passed), so an
  agent cannot pile retries onto a busy engine.
- ZETARIS_CATALOG names a JSON file of ready-made views
  ({"DATABASE": [{"name": ..., "about": ...}]}). SchemaStore views do not
  appear in SHOW LIGHTNING TABLES, so list_tables adds them from this file.
"""
from __future__ import annotations

import json
import os
import re
import sys
import time
import uuid
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

SERVER_INFO = {"name": "zetaris", "version": "0.2.1"}

READ_ONLY = re.compile(r"^\s*(SELECT|WITH|SHOW|DESCRIBE|DESC|EXPLAIN)\b", re.I)
REGISTER = re.compile(r"^\s*(CREATE\s+LIGHTNING|CACHE\s+TABLE)\b", re.I)
NAME = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)?$")


sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import zetaris_sql  # noqa: E402

zetaris_sql.load_env()  # .env.local, repo root or top-level checkout
TIMEOUT = int(os.environ.get("ZETARIS_TIMEOUT", "50"))
MAX_ROWS = int(os.environ.get("ZETARIS_MAX_ROWS", "200"))
ENGINE_ID = os.environ.get("ZETARIS_ENGINE_ID")
BASE_URL = os.environ.get("ZETARIS_BASE_URL", "http://localhost:3000").removesuffix("/")
ORG_ID = os.environ.get("ZETARIS_ORG_ID", "")
if not re.fullmatch(r"[0-9]+", ORG_ID):
    raise RuntimeError("Set ZETARIS_ORG_ID to the numeric organization ID in .env.local.")
if not re.fullmatch(r"https?://[^/]+", BASE_URL):
    raise RuntimeError("ZETARIS_BASE_URL must be an HTTP(S) origin without a path.")
_token: str | None = os.environ.get("ZETARIS_API_KEY") or None
SPARK_UI = os.environ.get("ZETARIS_SPARK_UI", "").rstrip("/")
_slow: list[tuple[str, float]] = []  # (SQL, time sent) of calls that ran past TIMEOUT


def _load_catalog() -> dict:
    path = os.environ.get("ZETARIS_CATALOG")
    if not path or not os.path.exists(path):
        return {}
    with open(path, encoding="utf-8") as f:
        return {k.upper(): v for k, v in json.load(f).items()}


COOLDOWN = int(os.environ.get("ZETARIS_COOLDOWN", "180"))


def _still_running(slow: list[tuple[str, float]]) -> list[tuple[str, float]]:
    """Which timed-out statements may still be running in Zetaris.

    A statement counts as finished once Spark's read-only status API shows it
    with no running job, or once COOLDOWN seconds have passed since it was sent
    (Zetaris can spend a while planning before Spark starts, so "no job yet" is
    not the same as "done")."""
    now = time.time()
    slow = [(s, t) for s, t in slow if now - t < COOLDOWN]
    if not SPARK_UI or not slow:
        return slow
    try:
        with urlopen(SPARK_UI + "/api/v1/applications", timeout=5) as r:
            app = json.loads(r.read())[0]["id"]
        with urlopen(f"{SPARK_UI}/api/v1/applications/{app}/jobs", timeout=5) as r:
            jobs = json.loads(r.read())
    except Exception:
        return slow
    out = []
    for s, t in slow:
        mine = [j for j in jobs if (j.get("description") or "").strip() == s.strip()]
        if mine and not any(j.get("status") == "RUNNING" for j in mine) and \
                max(j.get("completionTime") or "" for j in mine) >= time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime(t)):
            continue  # Spark ran it and it has finished
        out.append((s, t))
    return out


def _http(path: str, body: dict, token: str | None) -> dict:
    headers = {"Content-Type": "application/json", "X-Request-ID": str(uuid.uuid4())}
    if token:
        headers["Authorization"] = f"Bearer {token}"
        headers["X-Org-ID"] = ORG_ID
    req = Request(BASE_URL + path, data=json.dumps(body).encode(), headers=headers, method="POST")
    with urlopen(req, timeout=TIMEOUT) as resp:
        return json.loads(resp.read().decode("utf-8") or "{}")


def _login() -> str:
    global _token
    user, pw = os.environ.get("ZETARIS_USERNAME"), os.environ.get("ZETARIS_PASSWORD")
    if not user or not pw:
        raise RuntimeError("Set ZETARIS_API_KEY, or ZETARIS_USERNAME and ZETARIS_PASSWORD.")
    login = _http("/api/auth/login", {"username": user, "password": pw}, None)
    tok = login.get("idToken") or login.get("token") or login.get("accessToken")
    if not tok:
        m = re.search(r"[\w-]{8,}\.[\w-]{8,}\.[\w-]{8,}", json.dumps(login))
        tok = m.group(0) if m else None
    if not tok:
        raise RuntimeError("Zetaris login did not return a token.")
    _token = tok
    return tok


def run_sql(sql: str) -> dict:
    body: dict = {"sql": sql, "limit": MAX_ROWS}
    if ENGINE_ID:
        body["engineId"] = ENGINE_ID
    token = _token or _login()
    try:
        return _http("/api/proxy/sql-editor/sqls/run-query", body, token)
    except HTTPError as e:
        if e.code == 401 and not os.environ.get("ZETARIS_API_KEY"):
            return _http("/api/proxy/sql-editor/sqls/run-query", body, _login())
        detail = e.read(800).decode("utf-8", "replace")
        raise RuntimeError(f"Zetaris returned HTTP {e.code}: {detail}") from e
    except (URLError, OSError) as e:
        raise RuntimeError(f"Cannot reach Zetaris at {BASE_URL}: {e}") from e


def _log(entry: dict) -> None:
    path = os.environ.get("ZETARIS_MCP_LOG")
    if path:
        with open(path, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry) + "\n")


TOOLS = [
    {"name": "list_databases",
     "description": "List the databases registered in Zetaris. Start here to see what data is already available.",
     "inputSchema": {"type": "object", "properties": {}}},
    {"name": "list_tables",
     "description": "List the tables in one Zetaris database.",
     "inputSchema": {"type": "object", "properties": {"database": {"type": "string"}}, "required": ["database"]}},
    {"name": "describe_table",
     "description": "Show the columns and types of a Zetaris table, given as DATABASE.table.",
     "inputSchema": {"type": "object", "properties": {"table": {"type": "string"}}, "required": ["table"]}},
    {"name": "run_query",
     "description": "Run a read-only SQL query in Zetaris (SELECT, WITH, SHOW, DESCRIBE, EXPLAIN). "
                    "Zetaris SQL is Spark SQL; tables are DATABASE.table and one query can join tables "
                    "from different sources. Returns up to %d rows, the time taken and the exact SQL run." % MAX_ROWS,
     "inputSchema": {"type": "object", "properties": {"sql": {"type": "string"}}, "required": ["sql"]}},
    {"name": "register_source",
     "description": "Register a new data source in Zetaris with a CREATE LIGHTNING ... statement "
                    "(REST, FILESTORE or DATABASE), or cache a table with CACHE TABLE.",
     "inputSchema": {"type": "object", "properties": {"sql": {"type": "string"}}, "required": ["sql"]}},
]


def call_tool(name: str, args: dict) -> str:
    if name == "list_databases":
        sql = "SHOW LIGHTNING DATABASES"
    elif name == "list_tables":
        db = str(args.get("database", ""))
        if not NAME.match(db):
            raise ValueError("database must be a plain name")
        sql = f"SHOW LIGHTNING TABLES {db}"
        views = _load_catalog().get(db.upper())
        if views:
            out = json.loads(_run_logged(name, sql))
            out["ready_views"] = views
            out["note"] = ("Ready-made views (query them as " + db + ".<name>). Prefer these over the raw "
                           "source tables: they are already flattened and joined, so queries take seconds.")
            return json.dumps(out, ensure_ascii=False)
    elif name == "describe_table":
        t = str(args.get("table", ""))
        if not NAME.match(t):
            raise ValueError("table must be DATABASE.table")
        sql = f"DESCRIBE {t}"
    elif name == "run_query":
        sql = str(args.get("sql", ""))
        if not READ_ONLY.match(sql):
            raise ValueError("run_query only runs SELECT, WITH, SHOW, DESCRIBE or EXPLAIN. "
                             "Use register_source for CREATE LIGHTNING or CACHE TABLE.")
    elif name == "register_source":
        sql = str(args.get("sql", ""))
        if not REGISTER.match(sql):
            raise ValueError("register_source only runs CREATE LIGHTNING ... or CACHE TABLE statements.")
    else:
        raise ValueError(f"unknown tool {name}")
    return _run_logged(name, sql)


def _run_logged(name: str, sql: str) -> str:
    busy = _still_running(_slow)
    _slow[:] = busy
    if busy:
        msg = ("Zetaris is still running your earlier query, which went past the %d s limit: %s ... "
               "Wait for it to finish, then send a narrower query (filter, aggregate, or use a ready-made "
               "view). Do not resend the same query." % (TIMEOUT, busy[0][0][:160]))
        _log({"ts": round(time.time(), 3), "tool": name, "sql": sql, "ok": False, "refused": "busy"})
        raise RuntimeError(msg)
    t0 = time.time()
    entry = {"ts": round(t0, 3), "tool": name, "sql": sql}
    try:
        res = run_sql(sql)
    except Exception as e:
        secs = round(time.time() - t0, 2)
        entry.update(ok=False, error=str(e)[:300], secs=secs)
        _log(entry)
        if secs >= TIMEOUT - 1:
            _slow.append((sql, t0))
            raise RuntimeError("The query went past the %d s limit and may still be running inside Zetaris. "
                               "Do not resend it. Make it lighter (filter, aggregate, or use a ready-made view), "
                               "and wait before the next query." % TIMEOUT) from e
        raise
    secs = round(time.time() - t0, 2)
    rows = res.get("data") or []
    entry.update(ok=True, secs=secs, rows=len(rows))
    _log(entry)
    return json.dumps({"columns": res.get("headers"), "rows": rows[:MAX_ROWS],
                       "row_count": len(rows), "seconds": secs, "sql": sql}, ensure_ascii=False)


def handle(msg: dict) -> dict | None:
    method, mid = msg.get("method"), msg.get("id")
    if mid is None:
        return None  # notification
    if method == "initialize":
        ver = (msg.get("params") or {}).get("protocolVersion", "2025-06-18")
        result = {"protocolVersion": ver, "capabilities": {"tools": {}}, "serverInfo": SERVER_INFO,
                  "instructions": "Use these tools for all data work: Zetaris is the source of truth."}
    elif method == "ping":
        result = {}
    elif method == "tools/list":
        result = {"tools": TOOLS}
    elif method == "tools/call":
        p = msg.get("params") or {}
        try:
            text = call_tool(p.get("name", ""), p.get("arguments") or {})
            result = {"content": [{"type": "text", "text": text}], "isError": False}
        except Exception as e:
            result = {"content": [{"type": "text", "text": f"Error: {e}"}], "isError": True}
    else:
        return {"jsonrpc": "2.0", "id": mid, "error": {"code": -32601, "message": f"Unknown method {method}"}}
    return {"jsonrpc": "2.0", "id": mid, "result": result}


def main() -> None:
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            reply = handle(json.loads(line))
        except Exception as e:
            reply = {"jsonrpc": "2.0", "id": None, "error": {"code": -32700, "message": str(e)}}
        if reply is not None:
            sys.stdout.write(json.dumps(reply) + "\n")
            sys.stdout.flush()


if __name__ == "__main__":
    main()
