# Recipe: Parquet / CSV filestore sources

> **Archived — stable.** Seven CREATE/SELECT pairs are live in `open_data/parquet_csv/`. Current per-source status lives in [`open_data/parquet_csv/parquet-csv-data-sources.md`](../../../open_data/parquet_csv/parquet-csv-data-sources.md) — that catalog is the source of truth going forward, not this recipe. Kept here as the original recipe plan and remaining-work notes.

**Status:** Active — seven current CREATE/SELECT pairs are listed in `open_data/parquet_csv/`.
**Priority:** 0
**Target:** `open_data/parquet_csv/`

The script IDs are `02`, `03`, `04`, `05`, `07`, `08`, and `09`. Keep these filenames stable. The catalog describes each source's license and path. Its license markers do not indicate whether a script has been live-tested.

The [installation test record](../../install/zetaris-installation-test-record.md) confirms that the PUDL energy-source table returned 10 rows on a fresh install without AWS credentials. This does not establish the live-test status of every other pair. Keep each source's runtime status explicit when evidence is available.

## Current SQL pairs

| ID | Source | CREATE script | Notes |
|---|---|---|---|
| 02 | NOAA GHCN-Daily | [`sql/02_noaa_ghcn_create.sql`](../../../open_data/parquet_csv/sql/02_noaa_ghcn_create.sql) | Native CSV; no header row. |
| 03 | Catalyst Cooperative PUDL | [`sql/03_pudl_create.sql`](../../../open_data/parquet_csv/sql/03_pudl_create.sql) | Public S3 source. An intervening dotted-bucket failure was superseded by a 2026-10-31 re-test; the script is verified in `sql/`. |
| 04 | Foursquare Open Source Places | [`sql/04_foursquare_places_create.sql`](../../../open_data/parquet_csv/sql/04_foursquare_places_create.sql) | Source Cooperative's S3-compatible endpoint. An intervening query-time HTTP 500 was superseded by a 2026-10-31 re-test on release `2024-11-19`; the script is verified in `sql/`. |
| 05 | Overture Maps Places | [`sql/05_overture_maps_create.sql`](../../../open_data/parquet_csv/sql/05_overture_maps_create.sql) | GeoParquet; current release path changes. An intervening analytical-query failure was superseded by a 2026-10-31 re-test on release `2026-10-21.0`; the script is verified in `sql/`. |
| 07 | Ookla Speedtest | [`sql/07_ookla_speedtest_create.sql`](../../../open_data/parquet_csv/sql/07_ookla_speedtest_create.sql) | CC BY-NC-SA 4.0, non-commercial. An intervening registration HTTP 500 was superseded by a 2026-10-31 re-test on 2026 quarter=2; the script is verified in `sql/`. |
| 08 | GBIF occurrences | [`sql/08_gbif_create.sql`](../../../open_data/parquet_csv/sql/08_gbif_create.sql) | Large monthly snapshot; citation required. An intervening query-time HTTP 500 was superseded by a 2026-10-31 re-test. The verified script registers one file of snapshot `2026-10-01` (`occurrence.parquet/004990`), not the 282 GiB directory. |
| 09 | AWS Public Blockchain Data | [`sql/09_aws_public_blockchain_create.sql`](../../../open_data/parquet_csv/sql/09_aws_public_blockchain_create.sql) | Data license remains unresolved; do not redistribute. |

Each CREATE file has a matching `_select.sql` file with verification and example queries. Follow [the HOWTO](../../../open_data/parquet_csv/HOWTO.md) and [the source catalog](../../../open_data/parquet_csv/parquet-csv-data-sources.md) for setup, current paths, and licenses.

## Fetch-only sources

These scripts download data to the local cache. They do not register a table in Zetaris.

- [`scripts/fetch_datagovsg.py`](../../../scripts/fetch_datagovsg.py) downloads a data.gov.sg dataset and prints the SODL attribution. The file must be moved to storage Zetaris can access before a SQL pair can be written. Moved here from `open_data/parquet_csv/scripts/` in a later session, alongside the repo's other helper scripts.
- [`scripts/fetch_openfoodfacts.py`](../../../scripts/fetch_openfoodfacts.py) downloads the Open Food Facts export or a small sample and prints its ODbL attribution. The export is tab-separated; a Zetaris registration needs a reachable file and confirmed delimiter handling. Moved here from `open_data/parquet_csv/scripts/` in a later session, alongside the repo's other helper scripts.
- A Sentinel-2 GeoParquet STAC index on Source Cooperative is a candidate. Confirm its current path and license treatment before adding scripts.

## Current requirements and open work

- Register each logical database with `CREATE LIGHTNING DATABASE` before a file table uses it. The HOWTO has the syntax and examples.
- Current SQL pairs use public-source options and contain no AWS credential values. The PUDL test record confirms credential-free access for that table; do not generalize that result beyond the evidence available.
- Confirm the current date, version, or release path with the listing command in each CREATE file before use.
- Resolve storage and format requirements for the two fetch-only sources before adding their SQL pairs. Confirm the Sentinel-2 path before scripting that candidate.
- Keep source-license notes and live-test evidence separate in the catalog and README.
