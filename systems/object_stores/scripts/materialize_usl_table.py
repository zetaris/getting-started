"""Materialize a USL table to an S3-compatible bucket with SQL.

Builds `MATERIALIZE USL TABLE ... TO STORAGE (...)` from .env.local (S3_*) and
sends it over JDBC or REST. Secrets are put in the statement, never printed.

The manual's example passes only `storageSettingId`. On the S3-compatible store tested
that fails with "No AWS Credentials provided", so the working form
(see --variant) also passes the S3 credentials and endpoint inline.

    .venv/bin/python systems/object_stores/scripts/materialize_usl_table.py \\
        lightning.metastore.usl_demo.sic_edgar_usl.sic_code --dry-run
    .venv/bin/python systems/object_stores/scripts/materialize_usl_table.py \\
        lightning.metastore.usl_demo.sic_edgar_usl.sic_code --variant inline

Variants: setting-id (manual example), inline and inline-hadoop (credentials as
extra top-level keys), options-json and options-json-hadoop (credentials inside
the optionsBase64 JSON; aws* names or fs.s3a.* names).
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import s3_settings as s3  # noqa: E402
import zetaris_sql as z  # noqa: E402

OPTIONS_B64 = "eyJoZWFkZXIiOiJ0cnVlIn0="  # {"header":"true"}


def q(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def build(st: s3.Settings, table: str, path: str, variant: str, setting_id: str | None, fmt: str, record_type: str) -> str:
    opts = [("recordType", record_type), ("path", path), ("format", fmt)]
    if setting_id:
        opts.append(("storageSettingId", setting_id))
    if variant == "inline":
        opts += [
            ("awsAccessKeyId", st.access_key),
            ("awsSecretAccessKey", st.secret_key),
            ("s3Endpoint", st.endpoint),
            ("useS3PathStyleAccess", st.path_style),
        ]
    elif variant == "inline-hadoop":
        opts += [
            ("fs.s3a.access.key", st.access_key),
            ("fs.s3a.secret.key", st.secret_key),
            ("fs.s3a.endpoint", st.endpoint),
            ("fs.s3a.path.style.access", st.path_style),
        ]
    options_b64 = OPTIONS_B64
    if variant in ("options-json", "options-json-hadoop"):
        # The manual says optionsBase64 is a base64 JSON object of write AND storage options.
        if variant == "options-json":
            blob = {"header": "true", "awsAccessKeyId": st.access_key,
                    "awsSecretAccessKey": st.secret_key, "s3Endpoint": st.endpoint,
                    "useS3PathStyleAccess": st.path_style}
        else:
            blob = {"header": "true", "fs.s3a.access.key": st.access_key,
                    "fs.s3a.secret.key": st.secret_key, "fs.s3a.endpoint": st.endpoint,
                    "fs.s3a.path.style.access": st.path_style}
        options_b64 = base64.b64encode(json.dumps(blob).encode()).decode()
    opts.append(("optionsBase64", options_b64))
    body = ",\n  ".join(f"{k} = {q(v)}" for k, v in opts)
    return f"MATERIALIZE USL TABLE {table} TO STORAGE (\n  {body}\n)"


def mask(text: str) -> str:
    import re
    text = re.sub(r"optionsBase64 = '[^']{40,}'", "optionsBase64 = '<base64 JSON with credentials>'", text)
    for name in ("S3_ACCESS_KEY", "S3_SECRET_KEY"):
        v = os.environ.get(name)
        if v:
            text = text.replace(v, "<redacted>")
    return text


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("table", help="namespace.usl.table, e.g. lightning.metastore.usl_demo.sic_edgar_usl.sic_code")
    ap.add_argument("--variant", default="inline", choices=["setting-id", "inline", "inline-hadoop", "options-json", "options-json-hadoop"])
    ap.add_argument("--path", help="default s3a://<bucket>/<your folder>/<namespace>/<usl>/<table>, for example s3a://bucket/usl-test-jane/usl_demo/sic_edgar_usl/sic_code")
    ap.add_argument("--setting-id", default=os.environ.get("S3_STORAGE_SETTING_ID"),
                    help="storage setting id (or set S3_STORAGE_SETTING_ID)")
    ap.add_argument("--format", default="parquet")
    ap.add_argument("--record-type", default="all", choices=["all", "valid"])
    ap.add_argument("--channel", default="jdbc", choices=["jdbc", "rest"])
    ap.add_argument("--jar")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    st = s3.load()
    parts = a.table.split(".")
    if len(parts) < 3:
        raise SystemExit("Name the table as namespace.usl.table, for example lightning.metastore.usl_demo.sic_edgar_usl.sic_code.")
    folder = s3.base_prefix()
    path = a.path or f"s3a://{st.bucket}/{folder}{parts[-3]}/{parts[-2]}/{parts[-1]}"
    sql = build(st, a.table, path, a.variant, a.setting_id, a.format, a.record_type)
    print(mask(sql))
    if a.dry_run:
        print("\n(dry run: nothing sent)")
        return 0

    # Make your folder visible before Zetaris writes into it. A failure here is
    # only a warning: the write itself creates the folder.
    try:
        c = s3.make_client(st)
        made = s3.ensure_folder(c, st.bucket, folder)
        print(f"Your folder s3://{st.bucket}/{folder} " + ("was created." if made else "already exists."))
    except Exception as e:  # noqa: BLE001
        print(f"Note: could not create the folder marker ({s3.short(e)}); the write will still create the folder.")
    z.reexec_in_venv_if_needed(a.channel)
    ch = z.open_channel(a.channel, a.jar or os.environ.get("ZETARIS_JDBC_JAR"))
    try:
        res = ch.run(sql, limit=5)
    except z.ZetarisError as e:
        print("ERROR:", mask(str(e)))
        return 1
    finally:
        ch.close()
    for row in res.rows or []:
        print("RESULT:", mask(" | ".join(str(c) for c in row))[:900])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
