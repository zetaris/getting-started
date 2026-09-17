#!/usr/bin/env python3
"""
Fetch a data.gov.sg dataset via its initiate-download / poll-download REST API
and cache the resulting CSV locally.

data.gov.sg doesn't serve a static file URL per dataset -- you ask it to
prepare a download, poll until it's ready, then fetch the signed URL it
hands back. See https://guide.data.gov.sg/developer-guide/dataset-apis/download-dataset

Default dataset: "Resale flat prices based on registration date from
Jan-2017 onwards" (dataset_id d_8b84c4ee58e3cfc0ece0d773c8ca6abc) -- a
stable, actively-updated HDB dataset, good for a quickstart demo.
Find other dataset_ids from a dataset's data.gov.sg URL:
https://data.gov.sg/datasets/<dataset_id>/view

License: Singapore Open Data Licence (SODL) v1.0 -- https://data.gov.sg/open-data-licence
Attribution required; this script prints the attribution line to use.

Usage:
    python3 fetch_datagovsg.py
    python3 fetch_datagovsg.py --dataset-id d_2d5ff9ea31397b66239f245f57751537
    python3 fetch_datagovsg.py --cache-dir /tmp/my-cache --api-key YOUR_KEY

No third-party dependencies -- stdlib only, so it runs with any Python 3.8+.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
import time
import urllib.error
import urllib.request

API_BASE = "https://api-open.data.gov.sg/v1/public/api/datasets"
DEFAULT_DATASET_ID = "d_8b84c4ee58e3cfc0ece0d773c8ca6abc"
DEFAULT_CACHE_DIR = pathlib.Path(__file__).resolve().parents[3] / "tmp" / "cache" / "datagovsg"
USER_AGENT = "zetaris-quickstart-data/1.0"

# Public (unauthenticated) access is capped at 5 requests/minute -- space
# polls out comfortably under that unless an --api-key is supplied.
DEFAULT_POLL_INTERVAL_SECONDS = 12.0
DEFAULT_POLL_TIMEOUT_SECONDS = 180.0


def api_get(url: str, api_key: str | None) -> dict:
    headers = {"User-Agent": USER_AGENT}
    if api_key:
        headers["x-api-key"] = api_key
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {e.code} from {url}: {body}") from e


def initiate_download(dataset_id: str, api_key: str | None) -> str | None:
    """Kick off the download. Returns a download URL if the API hands one back
    immediately (observed live behavior), or None if a poll is still needed.

    Note: the published docs (guide.data.gov.sg) say to expect HTTP code 201
    on success; live testing (2026-09) actually returns code 0 with the
    download URL already included in `data.url` -- accept both.
    """
    url = f"{API_BASE}/{dataset_id}/initiate-download"
    resp = api_get(url, api_key)
    if resp.get("code") not in (0, 201):
        raise RuntimeError(f"initiate-download failed for {dataset_id}: {resp}")
    return resp.get("data", {}).get("url")


def poll_download(
    dataset_id: str,
    api_key: str | None,
    poll_interval: float,
    timeout: float,
) -> str:
    url = f"{API_BASE}/{dataset_id}/poll-download"
    deadline = time.monotonic() + timeout
    attempt = 0
    while True:
        resp = api_get(url, api_key)
        data = resp.get("data", {})
        download_url = data.get("url")
        if download_url:
            return download_url
        attempt += 1
        if time.monotonic() >= deadline:
            raise TimeoutError(
                f"Timed out after {timeout:.0f}s waiting for dataset {dataset_id} "
                f"to become downloadable (last status: {data.get('status')!r})"
            )
        print(f"  ... not ready yet (status={data.get('status')!r}), waiting {poll_interval:.0f}s")
        time.sleep(poll_interval)


def download_file(url: str, dest_path: pathlib.Path) -> int:
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    total = 0
    with urllib.request.urlopen(req, timeout=120) as resp, open(dest_path, "wb") as out:
        while True:
            chunk = resp.read(1 << 20)
            if not chunk:
                break
            out.write(chunk)
            total += len(chunk)
    return total


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        "--dataset-id",
        default=DEFAULT_DATASET_ID,
        help=f"data.gov.sg dataset_id, from the dataset's /view URL (default: {DEFAULT_DATASET_ID}, HDB Resale Flat Prices).",
    )
    parser.add_argument(
        "--cache-dir",
        default=str(DEFAULT_CACHE_DIR),
        help=f"Local directory to save the CSV into (default: {DEFAULT_CACHE_DIR}).",
    )
    parser.add_argument("--filename", default=None, help="Override the output filename (default: <dataset_id>.csv).")
    parser.add_argument("--api-key", default=None, help="Optional data.gov.sg API key (x-api-key header) for a higher rate limit.")
    parser.add_argument(
        "--poll-interval",
        type=float,
        default=DEFAULT_POLL_INTERVAL_SECONDS,
        help=f"Seconds between poll-download checks (default: {DEFAULT_POLL_INTERVAL_SECONDS}).",
    )
    parser.add_argument(
        "--poll-timeout",
        type=float,
        default=DEFAULT_POLL_TIMEOUT_SECONDS,
        help=f"Give up after this many seconds if the download never becomes ready (default: {DEFAULT_POLL_TIMEOUT_SECONDS}).",
    )
    args = parser.parse_args()

    print(f"Initiating download for dataset {args.dataset_id} ...")
    download_url = initiate_download(args.dataset_id, args.api_key)

    if download_url:
        print("Download URL was ready immediately, no polling needed.")
    else:
        print("Polling for the download URL ...")
        download_url = poll_download(args.dataset_id, args.api_key, args.poll_interval, args.poll_timeout)
    print(f"Got download URL: {download_url}")

    filename = args.filename or f"{args.dataset_id}.csv"
    dest = pathlib.Path(args.cache_dir) / filename
    print(f"Downloading to {dest} ...")
    size = download_file(download_url, dest)
    print(f"Done. Saved {size:,} bytes to {dest}")

    today = time.strftime("%Y-%m-%d")
    print()
    print("Attribution (Singapore Open Data Licence v1.0 requires this):")
    print(
        f'  "Contains information from data.gov.sg dataset {args.dataset_id} accessed on {today} '
        f'which is made available under the terms of the Singapore Open Data Licence version 1.0."'
    )
    print("  License: https://data.gov.sg/open-data-licence")
    return 0


if __name__ == "__main__":
    sys.exit(main())
