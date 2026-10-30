"""Settings and client shared by the object-store scripts.

Every script reads the same settings from .env.local (the repo root, or the
top-level checkout in a worktree) through this module, so addressing style,
region and CA trust are set in one place and cannot differ between scripts.

    S3_ENDPOINT_URL, S3_BUCKET, S3_ACCESS_KEY, S3_SECRET_KEY    required
    S3_PREFIX        your own folder in the bucket (default usl-test-<login>)
    S3_REGION        default us-east-1; most non-AWS stores ignore it
    S3_ADDRESSING    path (default) or virtual
    S3_CA_BUNDLE     PEM file of trusted CAs, for a private CA

The keys are never printed. These helpers never turn TLS verification off (only
probe_s3.py --insecure does, for diagnosis).
"""

from __future__ import annotations

import getpass
import os
import re
import ssl
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "scripts"))
import zetaris_sql  # noqa: E402

try:
    import boto3  # noqa: E402
    from botocore.config import Config  # noqa: E402
    from botocore.exceptions import ClientError  # noqa: E402
except ImportError as e:
    raise SystemExit(f"{e.name} is not installed in this Python. Use the venv from step 2 of the HOWTO: .venv/bin/python <script>")

REQUIRED = ("S3_ENDPOINT_URL", "S3_ACCESS_KEY", "S3_SECRET_KEY", "S3_BUCKET")
ADDRESSING_STYLES = ("path", "virtual")
DEFAULT_REGION = "us-east-1"


@dataclass(frozen=True)
class Settings:
    endpoint: str
    access_key: str
    secret_key: str
    bucket: str
    region: str
    addressing: str  # "path" or "virtual"
    ca_bundle: str | None

    @property
    def path_style(self) -> str:
        """The value Zetaris expects for useS3PathStyleAccess."""
        return "true" if self.addressing == "path" else "false"


def load() -> Settings:
    """Load .env.local and return the settings. Exits with a clear message if a
    required setting is missing or a value is not usable."""
    zetaris_sql.load_env()
    zetaris_sql.require(*REQUIRED)
    addressing = os.environ.get("S3_ADDRESSING", "").strip().lower() or "path"
    if addressing not in ADDRESSING_STYLES:
        raise SystemExit(f"S3_ADDRESSING must be one of {', '.join(ADDRESSING_STYLES)}, not {addressing!r}.")
    ca = os.environ.get("S3_CA_BUNDLE", "").strip() or None
    if ca and not Path(ca).is_file():
        raise SystemExit(f"S3_CA_BUNDLE is set but {ca!r} is not a file.")
    return Settings(
        endpoint=os.environ["S3_ENDPOINT_URL"].rstrip("/"),
        access_key=os.environ["S3_ACCESS_KEY"],
        secret_key=os.environ["S3_SECRET_KEY"],
        bucket=os.environ["S3_BUCKET"],
        region=os.environ.get("S3_REGION", "").strip() or DEFAULT_REGION,
        addressing=addressing,
        ca_bundle=ca,
    )


def tls_verify(s: Settings, ca_bundle: str | None = None) -> str | bool:
    """What to pass to boto3 as `verify`. Order: the --ca-bundle option, then
    S3_CA_BUNDLE, then the CA file Python itself trusts (botocore's own list can
    lag behind newer public roots), then botocore's default. Never False."""
    return ca_bundle or s.ca_bundle or ssl.get_default_verify_paths().cafile or True


def client(url: str, key: str, secret: str, region: str, style: str, verify: str | bool):
    cfg = Config(
        region_name=region,
        s3={"addressing_style": style},
        signature_version="s3v4",
        retries={"max_attempts": 1},
        connect_timeout=10,
        read_timeout=20,
        # Newer boto3 adds CRC checksums that many S3-compatible stores reject.
        request_checksum_calculation="when_required",
        response_checksum_validation="when_required",
    )
    return boto3.client(
        "s3",
        endpoint_url=url,
        aws_access_key_id=key,
        aws_secret_access_key=secret,
        config=cfg,
        verify=verify,
    )


def make_client(s: Settings, ca_bundle: str | None = None):
    """A client built from the settings."""
    return client(s.endpoint, s.access_key, s.secret_key, s.region, s.addressing, tls_verify(s, ca_bundle))


def base_prefix() -> str:
    """Your own folder in the bucket, ending in "/". Everything the test writes
    goes under it, so people who share a bucket do not collide.

    It is S3_PREFIX when set, otherwise "usl-test-" plus your login name. It is
    lower-cased and limited to letters, digits, ".", "_", "-" and "/".
    """
    raw = os.environ.get("S3_PREFIX", "").strip()
    if not raw:
        try:
            user = getpass.getuser()
        except Exception:
            user = "user"
        raw = "usl-test-" + user
    p = re.sub(r"[^a-z0-9._/-]+", "-", raw.lower())
    p = re.sub(r"/{2,}", "/", p).strip("/")
    if not p or any(part in ("", ".", "..") for part in p.split("/")):
        raise SystemExit(f"S3_PREFIX {raw!r} is not a usable folder name. Use letters, digits, '-' and '_', for example jane-usl-test.")
    return p + "/"


def ensure_folder(c, bucket: str, prefix: str) -> bool:
    """Create the folder marker (an empty object whose key ends in "/", which is
    what S3 consoles show as a folder). Returns True if it was created, False if
    it was already there. S3 has no real directories: the folder exists in
    listings as soon as any object is written under the prefix, and the marker
    makes it visible while it is still empty."""
    try:
        c.head_object(Bucket=bucket, Key=prefix)
        return False
    except ClientError as e:
        status = e.response.get("ResponseMetadata", {}).get("HTTPStatusCode")
        if status != 404 and e.response.get("Error", {}).get("Code") not in ("404", "NoSuchKey", "NotFound"):
            raise
    c.put_object(Bucket=bucket, Key=prefix, Body=b"")
    return True


def short(error: BaseException) -> str:
    if isinstance(error, ClientError):
        e = error.response.get("Error", {})
        status = error.response.get("ResponseMetadata", {}).get("HTTPStatusCode")
        return f"HTTP {status} {e.get('Code')}: {e.get('Message', '')}"[:200]
    return f"{type(error).__name__}: {error}"[:200]
