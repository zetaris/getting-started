"""Render the saved PUDL aggregate query response as a local HTML chart."""
from __future__ import annotations

import argparse
from html import escape
import json
from pathlib import Path
import sys


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    try:
        result = json.loads(args.input.read_text(encoding="utf-8"))
        if not isinstance(result, dict) or not isinstance(result.get("data"), list):
            raise ValueError("Expected a query response object with a data array.")
        if not result["data"]:
            raise ValueError("The query returned no rows; verify the source before rendering.")
        headers = result.get("headers", [])
        names = []
        if isinstance(headers, list):
            for header in headers:
                name = header.get("name") if isinstance(header, dict) else header
                names.append(name.lower() if isinstance(name, str) else "")
        rows = []
        for row in result["data"]:
            if isinstance(row, dict):
                values = {key.lower(): value for key, value in row.items()}
            elif isinstance(row, list) and len(row) == len(names):
                if len(set(names)) != len(names) or "" in names:
                    raise ValueError("Array rows need unique named headers.")
                values = dict(zip(names, row))
            else:
                raise ValueError("Expected object rows or array rows with matching headers.")
            if "fuel_units" not in values or "code_count" not in values:
                raise ValueError("Expected fuel_units and code_count columns from query.sql.")
            unit, count = values["fuel_units"], values["code_count"]
            if unit is not None and not isinstance(unit, str):
                raise ValueError("fuel_units must be a string or null.")
            if isinstance(count, str) and count.isascii() and count.isdigit():
                count = int(count)
            if isinstance(count, bool) or not isinstance(count, int) or count < 0:
                raise ValueError("code_count must be a nonnegative integer.")
            rows.append(("Unspecified (NULL)" if unit is None else unit, count))
        maximum = max(1, max(count for _, count in rows))
        bars = "".join(
            f'<tr><th scope="row">{escape(unit)}</th><td>{count}</td>'
            f'<td><meter aria-label="{escape(unit, quote=True)} reference codes" '
            f'min="0" max="{maximum}" value="{count}">{count}</meter></td></tr>'
            for unit, count in rows
        )
        page = '''<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>PUDL reference codes by fuel unit</title><style>
body{font:16px/1.6 system-ui,sans-serif;margin:2rem auto;padding:0 1rem;max-width:850px;color:#172638;background:#f5f8fa}
h1{line-height:1.2}table{width:100%;border-collapse:collapse;background:white}th,td{padding:.8rem;text-align:left;border-bottom:1px solid #dce4ea;overflow-wrap:anywhere}
meter{width:100%;min-width:80px;height:24px}caption{text-align:left;padding:.5rem 0}p{max-width:75ch}small{font-size:.875rem}
</style></head><body><h1>PUDL reference codes by fuel unit</h1>
<p>Counts of energy-source reference codes, not electricity generation or consumption. Null fuel units are shown explicitly.</p>
<table><caption>Query output supplied to this renderer</caption><thead><tr><th scope="col">Fuel unit</th><th scope="col">Code count</th><th scope="col">Relative count</th></tr></thead><tbody>'''
        page += bars + '''</tbody></table><p><small>Source: Catalyst Cooperative PUDL. Record the actual release and execution date with your demo. This page renders the supplied response; it does not verify platform access or the source.</small></p></body></html>'''
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(page, encoding="utf-8")
        print(f"Rendered {len(rows)} rows to {args.output}")
        return 0
    except (OSError, ValueError, TypeError) as error:
        print(f"Cannot render chart: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
