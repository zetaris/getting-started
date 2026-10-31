# Parquet & CSV Data Sources for Zetaris Quick-Starts

A catalog of the seven Parquet/CSV onboarding pairs, with licences, paths, verification status, and source documentation. See [`HOWTO.md`](HOWTO.md) for setup and checks.

**Licence key:** 🟢 open · 🟡 conditional or unresolved · 🔴 not included. These markers describe licensing, not runtime status.

**SQL:** runnable `CREATE LIGHTNING FILESTORE TABLE` examples follow the Zetaris Knowledge Base and Lightning SQL manuals. See `HOWTO.md` for public-bucket options and verification.

**Script folders:** active pairs live in `sql/`; recorded failures live in `sql/known_to_fail/`.

---

## Quick-reference table

| Script ID | Dataset | Domain | Licence | Format | Verification | Direct data URL / path | Docs & instructions | Onboarding script |
|---|---|---|---|---|---|---|---|---|
| 2 | NOAA GHCN-Daily | Climate | 🟢 CC0-1.0 | CSV (native) | Verified | `s3://noaa-ghcn-pds/csv/by_year/2025.csv` | [AWS registry entry](https://registry.opendata.aws/noaa-ghcn/) · [GHCN-Daily readme](https://docs.opendata.aws/noaa-ghcn-pds/readme.html) · [format spec](https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt) | `sql/02_noaa_ghcn_create.sql` |
| 3 | Catalyst Cooperative PUDL | Energy/utilities | 🟢 CC-BY-4.0 | Parquet (+ SQLite) | Verified | `s3://pudl.catalyst.coop/stable/core_eia__codes_energy_sources.parquet` (one example table — see Data Access docs for the full list) | [PUDL Data Access docs](https://docs.catalyst.coop/pudl/en/stable/data_access.html) · [AWS registry entry](https://registry.opendata.aws/catalyst-cooperative-pudl/) · [Data Dictionary](https://docs.catalyst.coop/pudl/en/stable/data_dictionaries/pudl_db.html) | `sql/03_pudl_create.sql` |
| 4 | Foursquare Open Source Places | Geospatial/POI | 🟢 Apache-2.0 | Parquet | Verified | `s3://fused/fsq-os-places/2024-11-19/places/` (release folder changes — newer folders were listed on 2026-10-31; see the script header) | [Foursquare OS Places docs](https://docs.foursquare.com/data-products/docs/fsq-places-open-source) · [Access instructions](https://docs.foursquare.com/data-products/docs/access-fsq-os-places) · [Source Cooperative repo](https://source.coop/fused/fsq-os-places) | `sql/04_foursquare_places_create.sql` |
| 5 | Overture Maps Foundation | Geospatial/maps | 🟡 Mixed by theme (CDLA-Permissive-2.0 / ODbL / varies) | GeoParquet | Verified | `s3://overturemaps-us-west-2/release/2026-10-21.0/theme=places/type=place/` (release folder changes monthly — see docs) | [Overture Quickstart](https://docs.overturemaps.org/getting-data/) · [DuckDB guide](https://docs.overturemaps.org/getting-data/duckdb/) · [Attribution/licence table](https://docs.overturemaps.org/attribution/) | `sql/05_overture_maps_create.sql` |
| 7 | Ookla Speedtest Global Performance | Telecom | 🟡 CC BY-NC-SA 4.0 (non-commercial) | Parquet (+ Shapefile) | Verified | `s3://ookla-open-data/parquet/performance/type=fixed/year=2026/quarter=2/2026-04-01_performance_fixed_tiles.parquet` (one quarter file — mobile is the same quarter under `type=mobile`) | [ookla-open-data GitHub](https://github.com/teamookla/ookla-open-data) · [README (path patterns, schema)](https://github.com/teamookla/ookla-open-data/blob/master/README.md) · [AWS registry entry](https://registry.opendata.aws/speedtest-global-performance/) | `sql/07_ookla_speedtest_create.sql` |
| 8 | GBIF species occurrences | Biodiversity | 🟡 Aggregate CC-BY-NC (mixed per record) | Parquet | Verified | `s3://gbif-open-data-us-east-1/occurrence/2026-10-01/occurrence.parquet/004990` (one file of a monthly snapshot — see docs) | [GBIF AWS public data guide](https://github.com/gbif/occurrence/blob/master/aws-public-data.md) · [Citation guidelines](https://www.gbif.org/citation-guidelines) · [AWS registry entry](https://registry.opendata.aws/gbif/) | `sql/08_gbif_create.sql` |
| 9 | AWS Public Blockchain Data | Blockchain/crypto | 🟡 Unresolved (see below) | Parquet | Verified | `s3://aws-public-blockchain/v1.0/btc/transactions/date=2026-09-01/*.snappy.parquet` | [AWS registry entry](https://registry.opendata.aws/aws-public-blockchain/) · [Analytics guidance/README](https://github.com/aws-solutions-library-samples/guidance-for-digital-assets-on-aws/blob/main/analytics/README.md) | `sql/09_aws_public_blockchain_create.sql` |

**Verified** means the CREATE and matching SELECT statements ran on a live Zetaris instance. **Known to fail** means a blocking issue was reproduced; see the source's issue. Do not treat an unverified script as live-tested.

The script IDs match their filenames; gaps are intentional. NOAA, PUDL, Foursquare, Overture Maps, Ookla, GBIF, and AWS Public Blockchain are verified. A 2026-10-31 re-test of PUDL agreed with the earlier installation record: the dotted bucket registers and both verification queries return rows. The same day's re-test of Foursquare, Overture Maps, and Ookla succeeded with bounded queries. GBIF's filtered `LIMIT` against the full 2026-09-01 directory returned rows, and every example query succeeded against one file of snapshot 2026-10-01. Ookla's earlier registration HTTP 500 did not reproduce.

Partition, snapshot, and release paths change. Before use, run the listing command in the SQL script header instead of relying on the date shown here.

---

## 2. 🟢 NOAA Global Historical Climatology Network – Daily (GHCN-D)

- **What it is:** daily station observations from 1763 onward, distributed as CSV.
- **Licence:** CC0-1.0. See the [AWS registry](https://registry.opendata.aws/noaa-ghcn/).
- **Docs:** [GHCN-Daily readme](https://docs.opendata.aws/noaa-ghcn-pds/readme.html) · [column format spec](https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt)
- **Status:** live-tested; registration and all example queries passed. `CACHE TABLE` is required for the demonstrated queries because uncached scans were too slow.

## 3. 🟢 Catalyst Cooperative PUDL (Public Utility Data Liberation Project)

- **What it is:** U.S. electricity, gas, and financial data assembled from EIA, EPA, FERC, PHMSA, and SEC sources.
- **Licence:** CC-BY-4.0 — [AWS Registry of Open Data entry](https://registry.opendata.aws/catalyst-cooperative-pudl/).
- **Format:** Parquet and SQLite are published from the same nightly/stable build.
- **Docs:** [PUDL Data Access guide](https://docs.catalyst.coop/pudl/en/stable/data_access.html) (has the full current table list and version-pinning instructions) · [Data Dictionary](https://docs.catalyst.coop/pudl/en/stable/data_dictionaries/pudl_db.html)
- **Status:** live-tested 2026-10-31. A new table on `s3a://pudl.catalyst.coop/stable/core_eia__codes_energy_sources.parquet` registered with path-style access. Both verification queries returned 10 rows. `COUNT(*)` matched the Parquet footers: 42 energy-source codes and 666,788 yearly-generator rows.

## 4. 🟢 Foursquare Open Source Places

- **What it is:** a global places-of-interest dataset hosted on Source Cooperative. The release README describes more than 100 million places.
- **Licence:** Apache License 2.0 — [Foursquare's OS Places docs](https://docs.foursquare.com/data-products/docs/fsq-places-open-source).
- **Docs:** [Access instructions](https://docs.foursquare.com/data-products/docs/access-fsq-os-places) · [Source Cooperative repo browser](https://source.coop/fused/fsq-os-places) · [Places schema](https://docs.foursquare.com/data-products/docs/places-os-data-schema)
- **Status:** live-tested 2026-10-31 on release `2024-11-19` (still listed that day, along with `2024-12-03`, `2025-01-10`, and `2025-02-06`). `DESCRIBE` returned 24 columns. A Manhattan window (`latitude` 40.70 to 40.82, `longitude` -74.02 to -73.93) held 352,530 places. Each analytical query still reads the 81-file prefix (10.394 GiB) and took about 63–75 seconds. An earlier query-time HTTP 500 did not reproduce. Confirm the release folder before use. The earlier failure record is [ISSUE-04](sql/known_to_fail/ISSUE-04-foursquare.md).

## 5. 🟡 Overture Maps Foundation

- **What it is:** monthly GeoParquet for places, buildings, transport, addresses, and divisions.
- **Licence:** varies by theme. Places uses CDLA-Permissive-2.0; Base, Buildings, Divisions, and Transportation use ODbL; Addresses varies by country. See the [attribution table](https://docs.overturemaps.org/attribution/).
- **Docs:** [Quickstart](https://docs.overturemaps.org/getting-data/) · [DuckDB guide](https://docs.overturemaps.org/getting-data/duckdb/) (has the current release-folder name — it changes roughly monthly) · [Places schema](https://docs.overturemaps.org/schema/reference/places/place/)
- **Status:** live-tested 2026-10-31 on release `2026-10-21.0`. The August 2026 release folder is no longer in the bucket. Category is `basic_category` plus `taxonomy.primary` (there is no `categories` column). `DESCRIBE` returned 16 columns. A Manhattan bbox (`bbox.xmin` -74.02 to -73.93, `bbox.ymin` 40.70 to 40.82) held 259,457 places. Each analytical query still reads the 16-file prefix (11.08 GiB) and took about 84–95 seconds. Confirm the release folder before use.

## 7. 🟡 Ookla Speedtest Global Fixed and Mobile Network Performance

- **What it is:** quarterly global broadband and mobile speed-test results on roughly 610 m Web Mercator tiles.
- **Licence:** CC BY-NC-SA 4.0, **non-commercial** — [AWS open-data-registry YAML](https://github.com/awslabs/open-data-registry/blob/main/datasets/speedtest-global-performance.yaml). Fine for a hobbyist demo or tutorial repo; not for a commercial deliverable without a separate licence from Ookla.
- **Docs:** [ookla-open-data GitHub](https://github.com/teamookla/ookla-open-data) · [README](https://github.com/teamookla/ookla-open-data/blob/master/README.md) (has the exact path pattern and schema reference)
- **Status:** live-tested 2026-10-31 on 2026 quarter=2. Both files were still listed (fixed 353,986,294 bytes, mobile 184,560,046 bytes). `year=2026` also listed quarter=1 and quarter=3. `DESCRIBE` returned 11 columns on each table. A Manhattan window (`tile_x` -74.02 to -73.93, `tile_y` 40.70 to 40.82) held 406 fixed tiles (77,758 tests) and 385 mobile tiles (15,686 tests). Each example query reads one quarter file and took about 4–19 seconds. A fresh registration with the same OPTIONS succeeded; re-running CREATE on the existing tables returned "already exists" rather than the earlier HTTP 500. Confirm the quarter file before use. The earlier failure record is [ISSUE-07](sql/known_to_fail/ISSUE-07-ookla.md).

## 8. 🟡 GBIF (Global Biodiversity Information Facility) species occurrences

- **What it is:** more than 1.6 billion species records from museums, herbaria, and citizen-science networks, refreshed monthly.
- **Licence:** the [AWS registry](https://github.com/awslabs/open-data-registry/blob/main/datasets/gbif.yaml) lists aggregate CC-BY-NC. Individual records may use CC0 or CC-BY; use CC-BY-NC as the conservative whole-snapshot terms. Cite the snapshot: the 2026-10-01 `citation.txt` reads `GBIF.org (1 October 2026) GBIF Occurrence Download https://doi.org/10.15468/dl.tup2g6`.
- **Docs:** [GBIF AWS public data guide](https://github.com/gbif/occurrence/blob/master/aws-public-data.md) (has the current snapshot-date convention) · [Citation guidelines](https://www.gbif.org/citation-guidelines)
- **Status:** live-tested 2026-10-31. Snapshot `2026-10-01` is 10,448 files and 282.17 GiB, so the script registers one file, `occurrence.parquet/004990` (47,796,744 bytes). `DESCRIBE` returned 50 columns. That file has 538,620 rows; `countrycode = 'AU' AND class = 'Aves'` keeps 17,402 rows and 589 scientific names. Each example query took about 1.0–1.6 seconds. A filtered `LIMIT 10` on the already-registered 2026-09-01 directory also returned 10 rows and did not reproduce an earlier HTTP 500. Aggregates were not run on the directory. The earlier failure record is [ISSUE-08](sql/known_to_fail/ISSUE-08-gbif.md).

## 9. 🟡 AWS Public Blockchain Data

- **What it is:** daily, date-partitioned Parquet for Bitcoin, Ethereum, and other chains.
- **Licence:** unresolved. The [registry](https://registry.opendata.aws/aws-public-blockchain/) links to an MIT code sample, not a data licence. Do not re-host the data until its terms are confirmed.
- **Docs:** [AWS registry entry](https://registry.opendata.aws/aws-public-blockchain/) · [Analytics guidance README](https://github.com/aws-solutions-library-samples/guidance-for-digital-assets-on-aws/blob/main/analytics/README.md) (has the full per-chain path structure)
- **Status:** both tables registered and all example queries passed live.
- **Caching:** SQL `CACHE TABLE` worked on `eth_transactions` but failed on `btc_transactions`; the Data Explorer cache action had the opposite result. Both tables queried successfully. The timing difference was observed, but its cause is unknown; see the create script header for exact results.

---

**See also:** `HOWTO.md` for the Zetaris onboarding walkthrough, and [`docs/plans/FUTURES.md`](../../docs/plans/FUTURES.md) plus its `recipes/*.md` files for everything outside Parquet/CSV — Kafka, logs, JSON/REST, SQL RDBMS, PDFs, and the government open-data sections.
