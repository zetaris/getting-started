"""Probe an S3-compatible object store endpoint with boto3 and report which client
settings work, so the same settings can be given to Zetaris.

Reads S3_ENDPOINT_URL, S3_ACCESS_KEY, S3_SECRET_KEY and S3_BUCKET (and the
optional S3_REGION, S3_ADDRESSING, S3_CA_BUNDLE and S3_PREFIX) from .env.local
(the repo root, or the top-level checkout in a worktree). Never prints the keys.
The only write is one tiny object under a unique `zetaris-probe/` prefix, which
is deleted again, plus your own folder marker.

Run from the repository root, with boto3 installed (.venv):

    .venv/bin/python systems/object_stores/scripts/probe_s3.py
    .venv/bin/python systems/object_stores/scripts/probe_s3.py --no-write
"""

from __future__ import annotations

import argparse
import sys
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import s3_settings as s3  # noqa: E402
from botocore.exceptions import BotoCoreError, ClientError  # noqa: E402

REGIONS = ["us-east-1", "us-west-2", "eu-west-1"]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--no-write", action="store_true", help="read-only probe")
    ap.add_argument("--ca-bundle", help="PEM file of trusted CAs (default: S3_CA_BUNDLE, then the CA file Python trusts)")
    ap.add_argument("--insecure", action="store_true", help="skip TLS verification (diagnosis only)")
    args = ap.parse_args()

    st = s3.load()
    verify = False if args.insecure else s3.tls_verify(st, args.ca_bundle)
    folder = s3.base_prefix()
    print(f"endpoint={st.endpoint} bucket={st.bucket} tls_verify={verify}")
    print(f"configured: addressing={st.addressing} region={st.region}")
    print(f"your folder: s3://{st.bucket}/{folder}")

    # Try the configured style and region first, then the rest, so the write
    # test below uses the configured combination whenever it works.
    styles = [st.addressing] + [a for a in s3.ADDRESSING_STYLES if a != st.addressing]
    regions = [st.region] + [r for r in REGIONS if r != st.region]

    working = []
    for style in styles:
        for region in regions:
            c = s3.client(st.endpoint, st.access_key, st.secret_key, region, style, verify)
            tag = f"style={style:<7} region={region:<10}"
            try:
                c.head_bucket(Bucket=st.bucket)
                r = c.list_objects_v2(Bucket=st.bucket, MaxKeys=5)
                n = r.get("KeyCount", 0)
                print(f"[PASS] {tag} head_bucket + list ok ({n} keys shown)")
                working.append((style, region, c))
            except (ClientError, BotoCoreError) as e:
                print(f"[FAIL] {tag} {s3.short(e)}")

    if not working:
        print("\nNo combination worked. Check the endpoint, keys and bucket name.")
        return 1

    style, region, c = working[0]
    if (style, region) == (st.addressing, st.region):
        print(f"\nYour configured settings work: S3_ADDRESSING={style} S3_REGION={region}")
    else:
        print(f"\nYour configured settings did not work, but this combination did.\n"
              f"Set S3_ADDRESSING={style} and S3_REGION={region} in .env.local.")

    if args.no_write:
        print("\n(--no-write: your folder was not created and nothing was written)")
        return 0

    obj = f"{folder}zetaris-probe/{uuid.uuid4()}.txt"
    print(f"\nWrite test with style={style} region={region}: {obj}")
    try:
        c.put_object(Bucket=st.bucket, Key=obj, Body=b"zetaris probe")
        print("[PASS] put_object")
        body = c.get_object(Bucket=st.bucket, Key=obj)["Body"].read()
        print("[PASS] get_object", "matches" if body == b"zetaris probe" else "DIFFERS")
        c.delete_object(Bucket=st.bucket, Key=obj)
        print("[PASS] delete_object")
        made = s3.ensure_folder(c, st.bucket, folder)
        print(f"[PASS] your folder s3://{st.bucket}/{folder} " + ("created" if made else "already exists"))
    except (ClientError, BotoCoreError) as e:
        print(f"[FAIL] write test: {s3.short(e)}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
