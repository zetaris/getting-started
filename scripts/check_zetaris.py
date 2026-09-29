from __future__ import annotations

import sys


def main() -> int:
    try:
        from zetaris_api import zetaris_request

        databases = zetaris_request("/api/proxy/lightning-database/databases")
        if not isinstance(databases, list):
            raise RuntimeError("Unexpected database-list response.")
        print(
            f"Zetaris connection OK. Visible Lightning databases: {len(databases)}."
        )
        return 0
    except Exception as error:
        print(error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
