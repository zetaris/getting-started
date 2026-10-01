#!/usr/bin/env python3
"""
Download the Open Food Facts bulk product export and cache it locally.

The manifest recommends the bulk export over the live REST API for anything
beyond single-product lookups (custom User-Agent + per-endpoint rate limits
make the live API a poor fit for bulk pulls). This script fetches the
nightly-generated export directly -- no REST polling needed, just a static
HTTPS download -- and can optionally carve out a small row-sampled CSV so a
quickstart demo isn't stuck decompressing a ~9 GB file.

IMPORTANT: despite the .csv extension, Open Food Facts' export is TAB-
separated, not comma-separated. Pass the tab delimiter through to whatever
reads it downstream (a Zetaris FORMAT CSV registration, pandas, DuckDB, ...).

License: Open Database License (ODbL) -- attribution required, and if you
redistribute a combined database built from this export, that combined
database must also be open (share-alike).
https://forum.openfoodfacts.org/t/conditions-to-use-the-open-food-facts-api/443

Usage:
    python3 fetch_openfoodfacts.py
    python3 fetch_openfoodfacts.py --sample-rows 5000
    python3 fetch_openfoodfacts.py --skip-full-download --sample-rows 5000
    python3 fetch_openfoodfacts.py --url https://static.openfoodfacts.org/data/openfoodfacts-products.jsonl.gz

No third-party dependencies -- stdlib only, so it runs with any Python 3.8+.
"""

from __future__ import annotations

import argparse
import gzip
import pathlib
import sys
import urllib.request

DEFAULT_EXPORT_URL = "https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz"
DEFAULT_CACHE_DIR = pathlib.Path(__file__).resolve().parents[1] / "tmp" / "cache" / "openfoodfacts"
USER_AGENT = "zetaris-quickstart-data/1.0 (quickstart demo; contact via repo issues)"


def download_file(url: str, dest_path: pathlib.Path) -> int:
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    total = 0
    with urllib.request.urlopen(req, timeout=300) as resp, open(dest_path, "wb") as out:
        while True:
            chunk = resp.read(1 << 20)
            if not chunk:
                break
            out.write(chunk)
            total += len(chunk)
            if total % (1 << 27) < (1 << 20):  # ~every 128MB
                print(f"  ... {total / (1 << 20):.0f} MB so far")
    return total


def write_sample(gz_path: pathlib.Path, sample_path: pathlib.Path, num_rows: int) -> None:
    with gzip.open(gz_path, "rt", encoding="utf-8", errors="replace", newline="") as src, open(
        sample_path, "w", encoding="utf-8", newline=""
    ) as dst:
        header = next(src)
        dst.write(header)
        for _, line in zip(range(num_rows), src):
            dst.write(line)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--url", default=DEFAULT_EXPORT_URL, help="Export URL to download (default: the gzipped CSV export).")
    parser.add_argument(
        "--cache-dir",
        default=str(DEFAULT_CACHE_DIR),
        help=f"Local directory to save into (default: {DEFAULT_CACHE_DIR}).",
    )
    parser.add_argument(
        "--sample-rows",
        type=int,
        default=0,
        help="If >0, also write a small <n>-row CSV sample alongside the full gzipped export, streamed from the "
        "gzip without a separate full decompression step. Good for a quickstart demo that doesn't need all ~9 GB.",
    )
    parser.add_argument(
        "--skip-full-download",
        action="store_true",
        help="Skip downloading the full export (use with --sample-rows if the .gz is already cached locally).",
    )
    args = parser.parse_args()

    cache_dir = pathlib.Path(args.cache_dir)
    gz_dest = cache_dir / pathlib.Path(args.url).name

    if not args.skip_full_download:
        print(f"Downloading {args.url}")
        print(f"  -> {gz_dest}  (compressed ~0.9 GB -- this will take a while)")
        size = download_file(args.url, gz_dest)
        print(f"Done. Saved {size:,} bytes.")
    elif not gz_dest.exists():
        print(f"--skip-full-download given but {gz_dest} doesn't exist.", file=sys.stderr)
        return 1

    if args.sample_rows > 0:
        sample_dest = cache_dir / f"sample_{args.sample_rows}rows.csv"
        print(f"Writing a {args.sample_rows}-row sample to {sample_dest} ...")
        write_sample(gz_dest, sample_dest, args.sample_rows)
        print("Done. Reminder: this file is TAB-separated despite the .csv name.")

    print()
    print("Source: Open Food Facts -- https://world.openfoodfacts.org/")
    print("License: Open Database License (ODbL) -- attribution required; a combined database built from")
    print("this export and redistributed must also be open (share-alike).")
    print("https://forum.openfoodfacts.org/t/conditions-to-use-the-open-food-facts-api/443")
    return 0


if __name__ == "__main__":
    sys.exit(main())
