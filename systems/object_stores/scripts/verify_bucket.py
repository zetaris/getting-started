"""List objects under a prefix in the S3-compatible bucket and, for Parquet
files, read the row count and schema from the footer. Read-only.

Needs boto3 and pyarrow (.venv):

    .venv/bin/pip install boto3 pyarrow
    .venv/bin/python systems/object_stores/scripts/verify_bucket.py usl_demo/sic_edgar_usl/sic_code
    .venv/bin/python systems/object_stores/scripts/verify_bucket.py ""   # whole bucket
"""

from __future__ import annotations

import argparse
import io
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import s3_settings as s3  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("prefix", nargs="?", default=None, help="folder to list (default: your own folder; \"\" lists the whole bucket)")
    ap.add_argument("--ca-bundle")
    a = ap.parse_args()
    st = s3.load()
    bucket = st.bucket
    if a.prefix is None:
        a.prefix = s3.base_prefix()
    c = s3.make_client(st, a.ca_bundle)

    objs = []
    for page in c.get_paginator("list_objects_v2").paginate(Bucket=bucket, Prefix=a.prefix):
        objs += page.get("Contents", [])
    print(f"s3://{bucket}/{a.prefix}  {len(objs)} objects, {sum(o['Size'] for o in objs):,} bytes")
    for o in objs:
        print(f"  {o['Size']:>10,}  {o['LastModified']:%Y-%m-%d %H:%M}  {o['Key']}")

    pq_keys = [o["Key"] for o in objs if o["Key"].endswith(".parquet")]
    if pq_keys:
        try:
            import pyarrow.parquet as pq
        except ImportError:
            print("\n(pip install pyarrow to read Parquet row counts)")
            return 0
        total = 0
        for k in pq_keys:
            body = c.get_object(Bucket=bucket, Key=k)["Body"].read()
            f = pq.ParquetFile(io.BytesIO(body))
            total += f.metadata.num_rows
            schema = ", ".join(f"{n}:{t}" for n, t in zip(f.schema_arrow.names, f.schema_arrow.types))
            print(f"\n{k}\n  rows={f.metadata.num_rows:,}  columns={len(f.schema_arrow.names)}\n  {schema}")
        print(f"\nTotal Parquet rows: {total:,}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
