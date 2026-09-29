# Parquet & CSV Data Sources for Zetaris Quick-Starts

A catalog of the seven current Parquet and CSV SQL onboarding pairs. Each entry lists the license, data path, source documentation, and matching CREATE script in `sql/`.

**License key:** 🟢 open, use it freely (read the note for any attribution requirement) · 🟡 open with a condition worth reading before you build on it · 🔴 not included — see the note for why. These markers describe licensing, not runtime test status.

**About the SQL:** every runnable `CREATE LIGHTNING FILESTORE TABLE` statement in `sql/` uses the syntax documented in the Zetaris knowledge base (`kbase.zetaris.com`) and the Cloud Data Fabric / Lightning SQL manuals (`data-fabric.readthedocs.io`). See `HOWTO.md` for the public-bucket options, path rules, and verification steps.

---

## Quick-reference table

| Script ID | Dataset | Domain | License | Format | Direct data URL / path | Docs & instructions | Onboarding script |
|---|---|---|---|---|---|---|---|
| 2 | NOAA GHCN-Daily | Climate | 🟢 CC0-1.0 | CSV (native) | `s3://noaa-ghcn-pds/csv/by_year/2025.csv` | [AWS registry entry](https://registry.opendata.aws/noaa-ghcn/) · [GHCN-Daily readme](https://docs.opendata.aws/noaa-ghcn-pds/readme.html) · [format spec](https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt) | `sql/02_noaa_ghcn_create.sql` |
| 3 | Catalyst Cooperative PUDL | Energy/utilities | 🟢 CC-BY-4.0 | Parquet (+ SQLite) | `s3://pudl.catalyst.coop/stable/core_eia__codes_energy_sources.parquet` (one example table — see Data Access docs for the full list) | [PUDL Data Access docs](https://docs.catalyst.coop/pudl/en/stable/data_access.html) · [AWS registry entry](https://registry.opendata.aws/catalyst-cooperative-pudl/) · [Data Dictionary](https://docs.catalyst.coop/pudl/en/stable/data_dictionaries/pudl_db.html) | `sql/03_pudl_create.sql` |
| 4 | Foursquare Open Source Places | Geospatial/POI | 🟢 Apache-2.0 | Parquet | `https://data.source.coop/fused/fsq-os-places/2024-11-19/places/79.parquet` (one shard — the directory has many) | [Foursquare OS Places docs](https://docs.foursquare.com/data-products/docs/fsq-places-open-source) · [Access instructions](https://docs.foursquare.com/data-products/docs/access-fsq-os-places) · [Source Cooperative repo](https://source.coop/fused/fsq-os-places) | `sql/04_foursquare_places_create.sql` |
| 5 | Overture Maps Foundation | Geospatial/maps | 🟡 Mixed by theme (CDLA-Permissive-2.0 / ODbL / varies) | GeoParquet | `s3://overturemaps-us-west-2/release/2026-08-19.0/theme=places/type=place/*` (release folder changes monthly — see docs) | [Overture Quickstart](https://docs.overturemaps.org/getting-data/) · [DuckDB guide](https://docs.overturemaps.org/getting-data/duckdb/) · [Attribution/license table](https://docs.overturemaps.org/attribution/) | `sql/05_overture_maps_create.sql` |
| 7 | Ookla Speedtest Global Performance | Telecom | 🟡 CC BY-NC-SA 4.0 (non-commercial) | Parquet (+ Shapefile) | `s3://ookla-open-data/parquet/performance/type=fixed/year=2026/quarter=2/2026-04-01_performance_fixed_tiles.parquet` | [ookla-open-data GitHub](https://github.com/teamookla/ookla-open-data) · [README (path patterns, schema)](https://github.com/teamookla/ookla-open-data/blob/master/README.md) · [AWS registry entry](https://registry.opendata.aws/speedtest-global-performance/) | `sql/07_ookla_speedtest_create.sql` |
| 8 | GBIF species occurrences | Biodiversity | 🟡 Aggregate CC-BY-NC (mixed per record) | Parquet | `s3://gbif-open-data-us-east-1/occurrence/2026-09-01/occurrence.parquet/*` (snapshot date changes monthly — see docs) | [GBIF AWS public data guide](https://github.com/gbif/occurrence/blob/master/aws-public-data.md) · [Citation guidelines](https://www.gbif.org/citation-guidelines) · [AWS registry entry](https://registry.opendata.aws/gbif/) | `sql/08_gbif_create.sql` |
| 9 | AWS Public Blockchain Data | Blockchain/crypto | 🟡 Unresolved (see below) | Parquet | `s3://aws-public-blockchain/v1.0/btc/transactions/date=2026-09-01/*.snappy.parquet` | [AWS registry entry](https://registry.opendata.aws/aws-public-blockchain/) · [Analytics guidance/README](https://github.com/aws-solutions-library-samples/guidance-for-digital-assets-on-aws/blob/main/analytics/README.md) | `sql/09_aws_public_blockchain_create.sql` |

The script IDs match their filenames. Gaps are intentional; keep the existing IDs when adding or updating entries. The license markers do not indicate whether a script has been tested. The installation test record documents the PUDL energy-source table's successful live run; the presence of another script here does not claim it has been live-tested.

Every date/version/release fragment in the active "direct data URL" entries moves on its source's own cadence. Before an event or demo, run the listing command shown in the corresponding runnable SQL script's header comment (`aws s3 ls --no-sign-request s3://...`) to confirm the available partition rather than relying on the date shown here.

---

## 2. 🟢 NOAA Global Historical Climatology Network – Daily (GHCN-D)

- **What it is:** daily weather station observations, 1763–present. Native format is CSV, not Parquet — included here because it's the cleanest license in this set and a good "CSV in, Parquet out" onboarding example.
- **License:** CC0-1.0 Universal Public Domain Dedication — [AWS Registry of Open Data entry](https://registry.opendata.aws/noaa-ghcn/).
- **Docs:** [GHCN-Daily readme](https://docs.opendata.aws/noaa-ghcn-pds/readme.html) · [column format spec](https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt)

## 3. 🟢 Catalyst Cooperative PUDL (Public Utility Data Liberation Project)

- **What it is:** analysis-ready U.S. energy-system data — electricity, natural gas, and financial reporting — assembled from EIA, EPA, FERC, PHMSA, and SEC filings by Catalyst Cooperative, a worker-owned co-op.
- **License:** CC-BY-4.0 — [AWS Registry of Open Data entry](https://registry.opendata.aws/catalyst-cooperative-pudl/).
- **Format note:** ships as both Parquet *and* SQLite from the same nightly/stable build — useful if you also want a SQL RDBMS example (main manifest §5) from the same source.
- **Docs:** [PUDL Data Access guide](https://docs.catalyst.coop/pudl/en/stable/data_access.html) (has the full current table list and version-pinning instructions) · [Data Dictionary](https://docs.catalyst.coop/pudl/en/stable/data_dictionaries/pudl_db.html)

## 4. 🟢 Foursquare Open Source Places

- **What it is:** Foursquare's global places-of-interest dataset (100M+ POIs — venues, businesses, landmarks), hosted on Source Cooperative rather than Foursquare's own infrastructure.
- **License:** Apache License 2.0 — [Foursquare's OS Places docs](https://docs.foursquare.com/data-products/docs/fsq-places-open-source).
- **A note on Source Cooperative:** it hosts many datasets, each with its own license set by the publisher — Foursquare is the one covered here. Any other Source Cooperative dataset you add later needs its own license check, the same way Kaggle listings do (main manifest §8).
- **Docs:** [Access instructions](https://docs.foursquare.com/data-products/docs/access-fsq-os-places) · [Source Cooperative repo browser](https://source.coop/fused/fsq-os-places)

## 5. 🟡 Overture Maps Foundation

- **What it is:** open map data (places, buildings, transportation, addresses, divisions), published monthly as GeoParquet by the Linux-Foundation-hosted Overture Maps Foundation.
- **License — mixed by theme** ([attribution table](https://docs.overturemaps.org/attribution/)): Places theme is CDLA-Permissive-2.0 (clean); Base/Buildings/Divisions/Transportation are ODbL (attribution + share-alike); Addresses varies by contributing country. Stick to the Places theme for the simplest license story.
- **Docs:** [Quickstart](https://docs.overturemaps.org/getting-data/) · [DuckDB guide](https://docs.overturemaps.org/getting-data/duckdb/) (has the current release-folder name — it changes roughly monthly)

## 7. 🟡 Ookla Speedtest Global Fixed and Mobile Network Performance

- **What it is:** worldwide broadband/cellular speed-test results aggregated to ~610m web-mercator tiles, published quarterly.
- **License:** CC BY-NC-SA 4.0, **non-commercial** — [AWS open-data-registry YAML](https://github.com/awslabs/open-data-registry/blob/main/datasets/speedtest-global-performance.yaml). Fine for a hobbyist demo or tutorial repo; not for a commercial deliverable without a separate license from Ookla.
- **Docs:** [ookla-open-data GitHub](https://github.com/teamookla/ookla-open-data) · [README](https://github.com/teamookla/ookla-open-data/blob/master/README.md) (has the exact path pattern and schema reference)

## 8. 🟡 GBIF (Global Biodiversity Information Facility) species occurrences

- **What it is:** 1.6+ billion species-occurrence records aggregated from museums, herbaria, and citizen-science networks worldwide, refreshed as a monthly snapshot.
- **License:** the [AWS open-data-registry YAML](https://github.com/awslabs/open-data-registry/blob/main/datasets/gbif.yaml) states aggregate CC-BY-NC. Individual records may be CC0 or CC-BY instead; treat CC-BY-NC as the conservative floor for the whole snapshot.
- **Docs:** [GBIF AWS public data guide](https://github.com/gbif/occurrence/blob/master/aws-public-data.md) (has the current snapshot-date convention) · [Citation guidelines](https://www.gbif.org/citation-guidelines)

## 9. 🟡 AWS Public Blockchain Data

- **What it is:** daily-updated, date-partitioned Parquet extracts of on-chain data — Bitcoin, Ethereum, and 8+ other chains — maintained by AWS with data providers like SonarX.
- **License:** unresolved. The [registry entry](https://registry.opendata.aws/aws-public-blockchain/)'s License field links to an MIT-licensed *code-sample* repo (`aws-samples/digital-assets-examples`), not a data-licensing document — no independent statement that the blockchain data itself is CC0/public-domain exists yet. Do not re-host a copy until its data license is confirmed.
- **Docs:** [AWS registry entry](https://registry.opendata.aws/aws-public-blockchain/) · [Analytics guidance README](https://github.com/aws-solutions-library-samples/guidance-for-digital-assets-on-aws/blob/main/analytics/README.md) (has the full per-chain path structure)

---

**See also:** `HOWTO.md` for the Zetaris onboarding walkthrough, and [`docs/plans/FUTURES.md`](../../docs/plans/FUTURES.md) plus its `recipes/*.md` files for everything outside Parquet/CSV — Kafka, logs, JSON/REST, SQL RDBMS, PDFs, and the government open-data sections.
