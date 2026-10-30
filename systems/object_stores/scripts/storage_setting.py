"""List, create or delete a Zetaris storage setting for an S3-compatible store.

Zetaris has no SQL statement to create a storage setting, only to use one
(`MATERIALIZE USL TABLE ... storageSettingId = '<id>'`), so this calls the REST
endpoint `/storage-setting`. It reads from .env.local: ZETARIS_REST_URL,
ZETARIS_ORG_ID, ZETARIS_API_KEY and S3_ENDPOINT_URL / S3_ACCESS_KEY / S3_SECRET_KEY
/ S3_BUCKET. Nothing secret is printed.

Run from the repository root:

    .venv/bin/python systems/object_stores/scripts/storage_setting.py list
    .venv/bin/python systems/object_stores/scripts/storage_setting.py create --name my-setting
    .venv/bin/python systems/object_stores/scripts/storage_setting.py show <id>
    .venv/bin/python systems/object_stores/scripts/storage_setting.py delete <id>
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import uuid
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

sys.path.insert(0, str(Path(__file__).resolve().parent))
import s3_settings as s3  # noqa: E402
import zetaris_sql  # noqa: E402

zetaris_sql.load_env()

SECRET_FIELDS = {"awsSecretAccessKey", "awsAccessKeyId", "awsSessionToken"}


def call(method: str, path: str, body=None):
    base = os.environ.get("ZETARIS_REST_URL", "http://localhost:8888/api/v1.0").rstrip("/")
    headers = {
        "Authorization": f"Bearer {os.environ['ZETARIS_API_KEY']}",
        "X-Org-ID": os.environ.get("ZETARIS_ORG_ID", "1"),
        "X-Request-ID": str(uuid.uuid4()),
        "Accept": "application/json",
    }
    data = None
    if body is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(body).encode()
    try:
        with urlopen(Request(base + path, data=data, headers=headers, method=method), timeout=60) as r:
            text = r.read().decode()
            return r.status, (json.loads(text) if text else None)
    except HTTPError as e:
        return e.code, e.read(2000).decode(errors="replace")
    except URLError as e:
        return 0, str(e.reason)


def default_name() -> str:
    """s3-compat- plus your folder, so each person has their own setting."""
    return "s3-compat-" + s3.base_prefix().rstrip("/").replace("/", "-")


def create_body(st: s3.Settings, name: str | None = None, path: str | None = None, scope: str = "Owner", path_style: bool = True) -> dict:
    """The POST /storage-setting request body."""
    config = {"awsAccessKeyId": st.access_key, "awsSecretAccessKey": st.secret_key, "s3Endpoint": st.endpoint}
    if st.addressing == "path" and path_style:
        config["useS3PathStyleAccess"] = "true"
    return {
        "storageName": name or default_name(),
        "storageType": "S3",
        "storagePath": path or f"s3a://{st.bucket}/{s3.base_prefix().rstrip('/')}",
        "scope": scope,
        "config": config,
    }


def redact(obj):
    if isinstance(obj, dict):
        return {k: ("<redacted>" if k in SECRET_FIELDS else redact(v)) for k, v in obj.items()}
    if isinstance(obj, list):
        return [redact(v) for v in obj]
    return obj


def show(status, body):
    print(f"HTTP {status}")
    print(json.dumps(redact(body), indent=2) if not isinstance(body, str) else body)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("list")
    c = sub.add_parser("create")
    c.add_argument("--name", help="setting name (default: s3-compat- plus your folder, so each person has their own)")
    c.add_argument("--path", help="storagePath (default s3a://<S3_BUCKET>/<your folder>)")
    c.add_argument("--scope", default="Owner", choices=["Owner", "Org"])
    c.add_argument("--no-path-style", action="store_true", help="omit useS3PathStyleAccess (it is omitted anyway when S3_ADDRESSING=virtual)")
    c.add_argument("--dry-run", action="store_true", help="print the request without sending")
    for n in ("show", "delete"):
        sub.add_parser(n).add_argument("id")
    a = ap.parse_args()

    zetaris_sql.require("ZETARIS_API_KEY")
    if a.cmd == "list":
        show(*call("GET", "/storage-setting"))
    elif a.cmd == "show":
        show(*call("GET", f"/storage-setting/{a.id}"))
    elif a.cmd == "delete":
        show(*call("DELETE", f"/storage-setting/{a.id}"))
    else:
        st = s3.load()
        body = create_body(st, a.name, a.path, a.scope, path_style=not a.no_path_style)
        if a.dry_run:
            print("POST /storage-setting (dry run, nothing sent)")
            print(json.dumps(redact(body), indent=2))
        else:
            show(*call("POST", "/storage-setting", body))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
