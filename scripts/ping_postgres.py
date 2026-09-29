from __future__ import annotations

import os
import sys
from time import perf_counter

from dotenv import load_dotenv


def main() -> int:
    load_dotenv()
    password = os.environ.get("PGPASSWORD")
    try:
        host = os.environ.get("PGHOST")
        database = os.environ.get("PGDATABASE")
        username = os.environ.get("PGUSER")
        if not host or not database or not username or not password:
            raise RuntimeError(
                "Set PGHOST, PGDATABASE, PGUSER, and PGPASSWORD in .env."
            )

        raw_port = os.environ.get("PGPORT", "5432")
        try:
            port = int(raw_port)
        except ValueError as error:
            raise RuntimeError(
                "PGPORT must be an integer between 1 and 65535."
            ) from error
        if not 1 <= port <= 65535:
            raise RuntimeError("PGPORT must be an integer between 1 and 65535.")

        sslmode = os.environ.get("PGSSLMODE", "disable")
        if sslmode not in {"disable", "verify-full"}:
            raise RuntimeError("PGSSLMODE must be disable or verify-full.")

        try:
            import psycopg
        except ImportError as error:
            raise RuntimeError(
                "Install the PostgreSQL driver with "
                "`python3 -m pip install -r scripts/requirements.txt`."
            ) from error

        started = perf_counter()
        with psycopg.connect(
            host=host,
            port=port,
            dbname=database,
            user=username,
            password=password,
            sslmode=sslmode,
            connect_timeout=10,
            options="-c statement_timeout=10000",
        ) as connection:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1 AS ping")
                row = cursor.fetchone()
        if not row or row[0] != 1:
            raise RuntimeError("Unexpected response to SELECT 1.")

        elapsed_ms = round((perf_counter() - started) * 1000)
        print(f"PostgreSQL connection OK ({elapsed_ms} ms).")
        return 0
    except Exception as error:
        message = str(error) if str(error) else "Unknown connection error"
        if password:
            message = message.replace(password, "[redacted]")
        print(f"PostgreSQL ping failed: {message}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
