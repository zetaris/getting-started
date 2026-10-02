#!/usr/bin/env python3
"""Run a Zetaris SQL script one statement at a time.

    python3 scripts/run_sql.py open_data/rest_apis/sql/non_rate_limited/10_company_dns_sic_create.sql
    python3 scripts/run_sql.py --channel jdbc --jar /path/to/driver.jar FILE.sql
    python3 scripts/run_sql.py -e "SELECT 1"
    python3 scripts/run_sql.py --dry-run FILE.sql

Splits the script on semicolons (quote- and comment-aware), keeps a
multi-table COMPILE USL whole, fills in the user-agent placeholder from
ZETARIS_USER_AGENT, and stops at the first error. It never prints credentials.
Creating objects changes the instance, so use --dry-run first if unsure.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import zetaris_sql as z  # noqa: E402


def one_line(sql: str, n: int = 100) -> str:
    s = " ".join(sql.split())
    return s if len(s) <= n else s[: n - 3] + "..."


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("file", nargs="?", help="SQL file to run")
    p.add_argument("-e", "--execute", help="run this SQL text instead of a file")
    p.add_argument("--channel", choices=["rest", "jdbc"], default="rest")
    p.add_argument("--jar", help="JDBC driver JAR (or set ZETARIS_JDBC_JAR)")
    p.add_argument("--env-file", help="env file to load (default: .env.local, then .env, here or in the top-level checkout)")
    p.add_argument("--limit", type=int, default=20, help="max result rows to print per statement")
    p.add_argument("--skip-exists", action="store_true", help="treat 'already exists' errors as skipped, not failures")
    p.add_argument("--dry-run", action="store_true", help="print the statements without connecting")
    args = p.parse_args()

    if bool(args.file) == bool(args.execute):
        p.error("give either a SQL file or -e SQL")

    try:
        env = z.load_env(args.env_file)
        text = args.execute if args.execute else Path(args.file).read_text(encoding="utf-8")
        statements = z.split_statements(text)
        if not statements:
            raise z.ZetarisError("No SQL statements found.")

        if args.dry_run:
            try:
                statements = z.apply_user_agent(statements)
            except z.ZetarisError as e:
                print(f"warning: {e}", file=sys.stderr)
            for i, s in enumerate(statements, 1):
                print(f"{i:>3}. {one_line(s)}")
            print(f"{len(statements)} statements (dry run, nothing sent)")
            return 0

        statements = z.apply_user_agent(statements)
        z.reexec_in_venv_if_needed(args.channel)
        print(f"channel={args.channel} env={env or 'process environment'} statements={len(statements)}")
        channel = z.open_channel(args.channel, args.jar)
    except (z.ZetarisError, OSError) as e:
        print(f"error: {e}", file=sys.stderr)
        return 1

    failed = skipped = 0
    try:
        for i, stmt in enumerate(statements, 1):
            print(f"{i:>3}. {one_line(stmt)}")
            try:
                result = channel.run(stmt, limit=args.limit)
            except z.ZetarisError as e:
                if args.skip_exists and z.ALREADY_EXISTS.search(str(e)):
                    skipped += 1
                    print("     skipped (already exists)")
                    continue
                failed += 1
                print(f"     ERROR {e}", file=sys.stderr)
                break
            for row in result.rows[: args.limit]:
                print("     ", row)
            if len(result.rows) > args.limit:
                print(f"      ... {len(result.rows) - args.limit} more rows")
    finally:
        channel.close()

    ran = i - failed
    print(f"done: {ran}/{len(statements)} statements ok" + (f", {skipped} skipped" if skipped else "") + (", STOPPED on error" if failed else ""))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
