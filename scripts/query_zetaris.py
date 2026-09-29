from __future__ import annotations

import json
import os
from pathlib import Path
import sys


USAGE = 'Usage: query_zetaris.py "SELECT 1" | --file path/to/query.sql'


def main() -> int:
    try:
        from zetaris_api import zetaris_request

        args = sys.argv[1:]
        if len(args) == 2 and args[0] == "--file":
            sql = Path(args[1]).read_text(encoding="utf-8")
        elif len(args) == 1 and args[0] != "--file":
            sql = args[0]
        else:
            raise RuntimeError(USAGE)
        if not sql.strip():
            raise RuntimeError("SQL must not be empty.")

        raw_limit = os.environ.get("ZETARIS_QUERY_LIMIT", "1000")
        try:
            limit = int(raw_limit)
        except ValueError as error:
            raise RuntimeError(
                "ZETARIS_QUERY_LIMIT must be a positive integer."
            ) from error
        if limit < 1:
            raise RuntimeError("ZETARIS_QUERY_LIMIT must be a positive integer.")

        body: dict[str, object] = {"sql": sql, "limit": limit}
        engine_id = os.environ.get("ZETARIS_ENGINE_ID")
        if engine_id:
            body["engineId"] = engine_id

        result = zetaris_request(
            "/api/proxy/sql-editor/sqls/run-query", "POST", body
        )
        print(json.dumps(result, indent=2, ensure_ascii=False))
        return 0
    except Exception as error:
        print(error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
