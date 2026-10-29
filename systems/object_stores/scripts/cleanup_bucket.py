"""Delete the objects this test wrote to an S3-compatible bucket, safely.

Dry-run by default: it lists what it would delete, with sizes, and deletes
nothing. Add --yes to delete.

Safety, by design:
  * Only objects under the prefixes you name are touched. The default is your
    own folder (S3_PREFIX, or usl-test-<your login name>/), which is where the
    test scripts write everything. Name other folders with --prefix, for example
    output from an older run that was written to usl_demo/.
  * A prefix is always treated as a folder (a trailing / is added), so
    `usl_demo` can never match `usl_demo_backup/`.
  * An empty prefix, `/` or `*` is refused, so the whole bucket cannot be emptied.
  * Nothing is deleted without --yes, and the target bucket and endpoint are
    printed first.
  * After deleting, it lists each prefix again and exits non-zero if anything is
    left.

Reads S3_ENDPOINT_URL, S3_ACCESS_KEY, S3_SECRET_KEY and S3_BUCKET from .env.local
and never prints the keys. Needs boto3 (.venv).

    .venv/bin/python systems/object_stores/scripts/cleanup_bucket.py                    # dry run, your own folder
    .venv/bin/python systems/object_stores/scripts/cleanup_bucket.py --yes              # delete it
    .venv/bin/python systems/object_stores/scripts/cleanup_bucket.py --prefix usl_demo/sic_edgar_usl/company/ --yes
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from urllib.parse import urlparse

sys.path.insert(0, str(Path(__file__).resolve().parent))
import s3_settings as s3  # noqa: E402
from botocore.exceptions import BotoCoreError, ClientError  # noqa: E402
from s3_settings import short  # noqa: E402

SHOW = 12  # keys to print per prefix before summarizing


def normalize(prefix: str) -> str:
    p = prefix.strip()
    if p in ("", "/", "*", "**") or p.strip("/*") == "":
        raise SystemExit(f"Refusing prefix {prefix!r}: it would match the whole bucket. Name a folder, for example usl_demo/.")
    if "*" in p or "?" in p:
        raise SystemExit(f"Refusing prefix {prefix!r}: wildcards are not supported. Give a plain folder name.")
    p = p.lstrip("/")
    return p if p.endswith("/") else p + "/"


def list_prefix(c, bucket: str, prefix: str) -> list[dict]:
    objs: list[dict] = []
    for page in c.get_paginator("list_objects_v2").paginate(Bucket=bucket, Prefix=prefix):
        objs += page.get("Contents", [])
    return objs


def delete_keys(c, bucket: str, keys: list[str]) -> list[str]:
    """Delete in batches of 1000. Falls back to one by one if the store rejects
    batch deletes. Returns the keys that could not be deleted."""
    failed: list[str] = []
    for i in range(0, len(keys), 1000):
        batch = keys[i:i + 1000]
        try:
            r = c.delete_objects(Bucket=bucket, Delete={"Objects": [{"Key": k} for k in batch], "Quiet": True})
            failed += [e["Key"] for e in r.get("Errors", [])]
        except (ClientError, BotoCoreError):
            for k in batch:
                try:
                    c.delete_object(Bucket=bucket, Key=k)
                except (ClientError, BotoCoreError):
                    failed.append(k)
    return failed


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--prefix", action="append", help="folder to clear; repeat for several (default: your own folder)")
    ap.add_argument("--yes", action="store_true", help="actually delete (without it, nothing is deleted)")
    ap.add_argument("--ca-bundle", help="PEM file of trusted CAs (default: S3_CA_BUNDLE, then the CA file Python trusts)")
    a = ap.parse_args()

    st = s3.load()
    prefixes = [normalize(p) for p in (a.prefix or [s3.base_prefix()])]
    prefixes = list(dict.fromkeys(prefixes))
    bucket, url = st.bucket, st.endpoint
    c = s3.make_client(st, a.ca_bundle)

    print(f"Target: bucket {bucket} at {urlparse(url).netloc}")
    print(f"Mode:   {'DELETE' if a.yes else 'dry run (nothing will be deleted)'}")
    found: dict[str, list[dict]] = {}
    try:
        for p in prefixes:
            found[p] = list_prefix(c, bucket, p)
    except (ClientError, BotoCoreError) as e:
        print("Cannot list the bucket:", short(e))
        return 2

    total_n = sum(len(v) for v in found.values())
    total_b = sum(o["Size"] for v in found.values() for o in v)
    print()
    for p, objs in found.items():
        size = sum(o["Size"] for o in objs)
        print(f"{p}  {len(objs)} objects, {size:,} bytes")
        for o in objs[:SHOW]:
            print(f"    {o['Size']:>10,}  {o['Key']}")
        if len(objs) > SHOW:
            print(f"    ... and {len(objs) - SHOW} more")
    print(f"\nTotal: {total_n} objects, {total_b:,} bytes under {len(prefixes)} prefix(es)")

    if total_n == 0:
        print("Nothing to delete.")
        return 0
    if not a.yes:
        print("\nDry run: nothing was deleted. Re-run with --yes to delete the objects listed above.")
        return 0

    failed: list[str] = []
    for p, objs in found.items():
        failed += delete_keys(c, bucket, [o["Key"] for o in objs])

    print("\nDeleted. Checking again:")
    left = 0
    for p in prefixes:
        n = len(list_prefix(c, bucket, p))
        left += n
        print(f"  {p}  {n} objects left")
    if failed or left:
        print(f"\nINCOMPLETE: {left} objects remain ({len(failed)} could not be deleted).")
        print("If the bucket is versioned, delete markers or old versions may remain; check your store's console.")
        return 1
    print("\nCLEAN: every listed prefix is empty.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
