"""Verify materialized USL tables end to end, from the source API to the Parquet
objects in the S3-compatible bucket. Read-only.

sic_code chain
    company-dns API (live, V3 and V4) > company_dns.sic_codes_raw
    > company_dns.sic_codes_table view > USL sic_code > Parquet
company chain
    SEC EDGAR submissions API (live, one call per CIK listed in the repo's
    11_edgar_company_profiles_create.sql) > sec_data.*_submissions_raw
    > edgar.all_companies_profile_table view > USL company > Parquet

For each chain it prints a row count per stage and compares the actual keys
(SIC codes, CIKs) between stages, so a matching count that hides different rows
still fails. Parquet files are also compared with the USL table row by row.
The profile view joins to the SIC hierarchy, so it is expected to omit any
company whose SIC code is not in sic_code (IBM, 3570). The script derives that
expectation from the data. Exit code 0 only when every stage matches.

    .venv/bin/python systems/object_stores/scripts/verify_chain.py
    .venv/bin/python systems/object_stores/scripts/verify_chain.py --table company
"""

from __future__ import annotations

import argparse
import io
import json
import os
import re
import sys
import time
from pathlib import Path
from urllib.request import Request, urlopen

sys.path.insert(0, str(Path(__file__).resolve().parent))
import s3_settings as s3  # noqa: E402
import zetaris_sql as z  # noqa: E402
from quiet import quiet_stderr  # noqa: E402

ROOT = s3.ROOT
SIC_API = "https://company-dns.mediumroast.io/{v}/na/sic/code/%25"
SEC_API = "https://data.sec.gov/submissions/CIK{cik}.json"
PROFILE_SQL = ROOT / "open_data/rest_apis/sql/rate_limited/11_edgar_company_profiles_create.sql"
DEFAULT_USL = "lightning.metastore.usl_demo.sic_edgar_usl"


def http_json(url: str):
    ua = os.environ.get("ZETARIS_USER_AGENT", "").strip().strip('"')
    if not z.valid_user_agent(ua):
        raise SystemExit("Set ZETARIS_USER_AGENT in .env.local (app name and contact email).")
    with urlopen(Request(url, headers={"User-Agent": ua}), timeout=60) as r:
        return json.load(r)


class Report:
    def __init__(self, title: str) -> None:
        self.title, self.rows, self.ok = title, [], True

    def stage(self, name: str, count: int, expected: int, note: str = "") -> None:
        good = count == expected
        self.ok &= good
        self.rows.append((name, f"{count:,}", ("PASS" if good else f"FAIL (expected {expected:,})") + (f"  {note}" if note else "")))

    def info(self, name: str, count, note: str) -> None:
        self.rows.append((name, str(count), "INFO  " + note))

    def compare(self, name: str, left, right) -> None:
        good = left == right
        self.ok &= good
        if good:
            note = "identical"
        else:
            note = f"only left: {sorted(left - right)[:4]}  only right: {sorted(right - left)[:4]}"
        self.rows.append((name, "", ("PASS  " if good else "FAIL  ") + note))

    def print(self) -> None:
        w = max(len(r[0]) for r in self.rows)
        print(f"\n=== {self.title}\n{'STAGE'.ljust(w)}  {'ROWS':>7}  RESULT")
        for n, c, r in self.rows:
            print(f"{n.ljust(w)}  {c:>7}  {r}")


def parquet_rows(s3c, bucket: str, objs: list[dict], table: str):
    """Return {prefix: (columns, rows)} for each Parquet folder that belongs to `table`."""
    import pyarrow.parquet as pq

    folders: dict[str, list[str]] = {}
    for o in objs:
        parts = o["Key"].split("/")
        if o["Key"].endswith(".parquet") and table.lower() in [p.lower() for p in parts[:-1]]:
            folders.setdefault("/".join(parts[:-1]), []).append(o["Key"])
    out = {}
    for folder, keys in sorted(folders.items()):
        cols, rows = None, []
        for k in sorted(keys):
            t = pq.read_table(io.BytesIO(s3c.get_object(Bucket=bucket, Key=k)["Body"].read()))
            cols = t.column_names
            rows += [tuple("" if v is None else str(v) for v in r.values()) for r in t.to_pylist()]
        out[folder] = (cols, rows)
    return out


def usl_rows(ch, table: str, cols: list[str]):
    sql = f"SELECT {', '.join(cols)} FROM {table}"
    return [tuple("" if v is None else str(v) for v in r) for r in ch.run(sql, limit=10000).rows]


def check_parquet(rep: Report, ch, s3c, bucket, objs, usl_table: str, short: str, key_idx: int, expected: int):
    found = parquet_rows(s3c, bucket, objs, short)
    if not found:
        rep.ok = False
        rep.rows.append(("5  Parquet object", "0", "FAIL  none found in the listing"))
    for folder, (cols, rows) in found.items():
        keys = [r[key_idx] for r in rows]
        rep.stage(f"5  Parquet  {folder}", len(rows), expected, "" if len(set(keys)) == len(keys) else "DUPLICATE KEYS")
        rep.compare(f"   USL rows vs Parquet rows ({len(cols)} columns)", set(usl_rows(ch, usl_table, cols)), set(rows))


def chain_sic_code(ch, s3c, bucket, objs, usl: str) -> tuple[Report, set]:
    rep = Report("sic_code: company-dns API > view > USL > Parquet")
    v3, v4 = http_json(SIC_API.format(v="V3.0"))["data"], http_json(SIC_API.format(v="V4.0"))["data"]
    api = set(v3["sics"].keys())
    rep.stage("1a company-dns API V3 (live)", len(api), len(api), "reference count")
    rep.stage("1b company-dns API V4 (live)", len(v4), len(api))
    raw = ch.run("SELECT COUNT(*) FROM company_dns.sic_codes_raw", limit=1).rows[0][0]
    rep.info("2  Lightning REST table", raw, "holds the whole API response as one JSON row")
    view = [str(r[0]) for r in ch.run("SELECT sic_code FROM company_dns.sic_codes_table", limit=10000).rows]
    rep.stage("3  SchemaStore view sic_codes_table", len(view), len(api), "" if len(set(view)) == len(view) else "DUPLICATE KEYS")
    table = f"{usl}.sic_code"
    codes = [str(r[0]) for r in ch.run(f"SELECT sic_code FROM {table}", limit=10000).rows]
    rep.stage("4  USL table sic_code", len(codes), len(api), "" if len(set(codes)) == len(codes) else "DUPLICATE KEYS")
    rep.compare("   API V3 codes vs view codes", api, set(view))
    rep.compare("   view codes vs USL codes", set(view), set(codes))
    check_parquet(rep, ch, s3c, bucket, objs, table, "sic_code", 0, len(api))
    return rep, set(codes)


def chain_company(ch, s3c, bucket, objs, usl: str, sic_codes: set) -> Report:
    rep = Report("company: SEC EDGAR API > raw tables > view > USL > Parquet")
    ciks = list(dict.fromkeys(re.findall(r"submissions/CIK(\d{10})\.json", PROFILE_SQL.read_text(encoding="utf-8"))))
    api = {}
    for cik in ciks:
        d = http_json(SEC_API.format(cik=cik))
        api[str(d["cik"]).zfill(10)] = (str(d["cik"]).zfill(10), d["name"].strip(), str(d["sic"]), d["sicDescription"].strip())
        time.sleep(0.25)  # stay well inside SEC's request limit
    rep.stage("1  SEC EDGAR submissions API (live)", len(api), len(ciks), f"{len(ciks)} CIKs from {PROFILE_SQL.name}")
    raw_counts = [ch.run(f"SELECT COUNT(*) FROM sec_data.{n}_submissions_raw", limit=1).rows[0][0]
                  for n in ("apple", "ibm", "oracle", "walmart", "target", "ford", "tesla")]
    rep.info("2  Lightning REST tables (7)", sum(raw_counts), f"one JSON document each: {raw_counts}")
    # The view joins to the SIC hierarchy, so it omits companies whose SIC code has no row.
    unresolved = {c for c, (_, _, sic, _) in api.items() if sic not in sic_codes}
    expect_view = {c for c in api if c not in unresolved}
    view = [str(r[0]) for r in ch.run("SELECT * FROM edgar.all_companies_profile_table", limit=1000).rows]
    why = f"omits {len(unresolved)} company with SIC not in sic_code: {sorted(unresolved)}" if unresolved else ""
    rep.stage("3  SchemaStore view all_companies_profile_table", len(view), len(expect_view), why)
    table = f"{usl}.company"
    urows = usl_rows(ch, table, ["cik", "entity_name", "sic", "sic_description_edgar"])
    rep.stage("4  USL table company", len(urows), len(api), "" if len({r[0] for r in urows}) == len(urows) else "DUPLICATE KEYS")
    rep.compare("   API CIKs vs USL CIKs", set(api), {r[0] for r in urows})
    rep.compare("   API (cik, name, sic) vs USL", {a[:3] for a in api.values()}, {r[:3] for r in urows})
    rep.compare("   expected view CIKs vs view CIKs", expect_view, set(view))
    check_parquet(rep, ch, s3c, bucket, objs, table, "company", 0, len(api))
    return rep


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--table", default="all", choices=["all", "sic_code", "company"])
    ap.add_argument("--usl", default=DEFAULT_USL, help="namespace.usl that holds the tables")
    ap.add_argument("--prefix", default=None, help="bucket folder to list and check (default: your own folder)")
    ap.add_argument("--channel", default="jdbc", choices=["jdbc", "rest"])
    ap.add_argument("--jar")
    ap.add_argument("--ca-bundle")
    a = ap.parse_args()

    st = s3.load()
    z.reexec_in_venv_if_needed(a.channel)

    bucket = st.bucket
    if a.prefix is None:
        a.prefix = s3.base_prefix()
    s3c = s3.make_client(st, a.ca_bundle)
    objs = []
    for page in s3c.get_paginator("list_objects_v2").paginate(Bucket=bucket, Prefix=a.prefix):
        objs += page.get("Contents", [])
    print(f"s3://{bucket}/{a.prefix}  {len(objs)} objects, {sum(o['Size'] for o in objs):,} bytes")
    for o in objs:
        print(f"  {o['Size']:>10,}  {o['LastModified']:%Y-%m-%d %H:%M}  {o['Key']}")

    reports = []
    with quiet_stderr():
        ch = z.open_channel(a.channel, a.jar or os.environ.get("ZETARIS_JDBC_JAR"))
        try:
            sic_rep, codes = chain_sic_code(ch, s3c, bucket, objs, a.usl)
            if a.table in ("all", "sic_code"):
                reports.append(sic_rep)
            if a.table in ("all", "company"):
                reports.append(chain_company(ch, s3c, bucket, objs, a.usl, codes))
        finally:
            ch.close()

    for r in reports:
        r.print()
    ok = all(r.ok for r in reports)
    print("\nCHAIN OK" if ok else "\nCHAIN BROKEN")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
