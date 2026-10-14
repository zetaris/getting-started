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
| 3 | Catalyst Cooperative PUDL | Energy/utilities | 🟢 CC-BY-4.0 | Parquet (+ SQLite) | Known to fail | `s3://pudl.catalyst.coop/stable/core_eia__codes_energy_sources.parquet` (one example table — see Data Access docs for the full list) | [PUDL Data Access docs](https://docs.catalyst.coop/pudl/en/stable/data_access.html) · [AWS registry entry](https://registry.opendata.aws/catalyst-cooperative-pudl/) · [Data Dictionary](https://docs.catalyst.coop/pudl/en/stable/data_dictionaries/pudl_db.html) | `sql/known_to_fail/03_pudl_create.sql` |
| 4 | Foursquare Open Source Places | Geospatial/POI | 🟢 Apache-2.0 | Parquet | Known to fail | `https://data.source.coop/fused/fsq-os-places/2024-11-19/places/79.parquet` (one shard — the directory has many) | [Foursquare OS Places docs](https://docs.foursquare.com/data-products/docs/fsq-places-open-source) · [Access instructions](https://docs.foursquare.com/data-products/docs/access-fsq-os-places) · [Source Cooperative repo](https://source.coop/fused/fsq-os-places) | `sql/known_to_fail/04_foursquare_places_create.sql` |
| 5 | Overture Maps Foundation | Geospatial/maps | 🟡 Mixed by theme (CDLA-Permissive-2.0 / ODbL / varies) | GeoParquet | Known to fail | `s3://overturemaps-us-west-2/release/2026-08-19.0/theme=places/type=place/*` (release folder changes monthly — see docs) | [Overture Quickstart](https://docs.overturemaps.org/getting-data/) · [DuckDB guide](https://docs.overturemaps.org/getting-data/duckdb/) · [Attribution/licence table](https://docs.overturemaps.org/attribution/) | `sql/known_to_fail/05_overture_maps_create.sql` |
| 7 | Ookla Speedtest Global Performance | Telecom | 🟡 CC BY-NC-SA 4.0 (non-commercial) | Parquet (+ Shapefile) | Known to fail | `s3://ookla-open-data/parquet/performance/type=fixed/year=2026/quarter=2/2026-04-01_performance_fixed_tiles.parquet` | [ookla-open-data GitHub](https://github.com/teamookla/ookla-open-data) · [README (path patterns, schema)](https://github.com/teamookla/ookla-open-data/blob/master/README.md) · [AWS registry entry](https://registry.opendata.aws/speedtest-global-performance/) | `sql/known_to_fail/07_ookla_speedtest_create.sql` |
| 8 | GBIF species occurrences | Biodiversity | 🟡 Aggregate CC-BY-NC (mixed per record) | Parquet | Known to fail | `s3://gbif-open-data-us-east-1/occurrence/2026-09-01/occurrence.parquet/*` (snapshot date changes monthly — see docs) | [GBIF AWS public data guide](https://github.com/gbif/occurrence/blob/master/aws-public-data.md) · [Citation guidelines](https://www.gbif.org/citation-guidelines) · [AWS registry entry](https://registry.opendata.aws/gbif/) | `sql/known_to_fail/08_gbif_create.sql` |
| 9 | AWS Public Blockchain Data | Blockchain/crypto | 🟡 Unresolved (see below) | Parquet | Verified | `s3://aws-public-blockchain/v1.0/btc/transactions/date=2026-09-01/*.snappy.parquet` | [AWS registry entry](https://registry.opendata.aws/aws-public-blockchain/) · [Analytics guidance/README](https://github.com/aws-solutions-library-samples/guidance-for-digital-assets-on-aws/blob/main/analytics/README.md) | `sql/09_aws_public_blockchain_create.sql` |

**Verified** means the CREATE and matching SELECT statements ran on a live Zetaris instance. **Known to fail** means a blocking issue was reproduced; see the source's issue. Do not treat an unverified script as live-tested.

The script IDs match their filenames; gaps are intentional. NOAA and AWS Public Blockchain are verified. Five sources have recorded failures: PUDL and Ookla fail at registration; Foursquare and GBIF register but queries fail; Overture supports a bounded sample but cache and analytical queries fail or hang. See each linked issue for details. An earlier installation record says PUDL succeeded; that contradiction remains unresolved.

Partition, snapshot, and release paths change. Before use, run the listing command in the SQL script header instead of relying on the date shown here.

---

## 2. 🟢 NOAA Global Historical Climatology Network – Daily (GHCN-D)

- **What it is:** daily station observations from 1763 onward, distributed as CSV.
- **Licence:** CC0-1.0. See the [AWS registry](https://registry.opendata.aws/noaa-ghcn/).
- **Docs:** [GHCN-Daily readme](https://docs.opendata.aws/noaa-ghcn-pds/readme.html) · [column format spec](https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt)
- **Status:** live-tested; registration and all example queries passed. `CACHE TABLE` is required for the demonstrated queries because uncached scans were too slow.

## 3. 🟢 Catalyst Cooperative PUDL (Public Utility Data Liberation Project) — known to fail

- **What it is:** U.S. electricity, gas, and financial data assembled from EIA, EPA, FERC, PHMSA, and SEC sources.
- **Licence:** CC-BY-4.0 — [AWS Registry of Open Data entry](https://registry.opendata.aws/catalyst-cooperative-pudl/).
- **Format:** Parquet and SQLite are published from the same nightly/stable build.
- **Docs:** [PUDL Data Access guide](https://docs.catalyst.coop/pudl/en/stable/data_access.html) (has the full current table list and version-pinning instructions) · [Data Dictionary](https://docs.catalyst.coop/pudl/en/stable/data_dictionaries/pudl_db.html)
- **Status:** registration fails because Zetaris's connector rejects the dotted bucket name `pudl.catalyst.coop`, even with path-style access. The files remain downloadable outside Zetaris. An earlier installation record reports success; the conflict is unresolved. See [ISSUE-03](sql/known_to_fail/ISSUE-03-pudl.md).

## 4. 🟢 Foursquare Open Source Places — known to fail

- **What it is:** a global places-of-interest dataset hosted on Source Cooperative.
- **Licence:** Apache License 2.0 — [Foursquare's OS Places docs](https://docs.foursquare.com/data-products/docs/fsq-places-open-source).
- **Docs:** [Access instructions](https://docs.foursquare.com/data-products/docs/access-fsq-os-places) · [Source Cooperative repo browser](https://source.coop/fused/fsq-os-places)
- **Status:** registration succeeds, but cache and query attempts, including a bounded sample, return HTTP 500. The cause is unconfirmed. Check [ISSUE-04](sql/known_to_fail/ISSUE-04-foursquare.md).

## 5. 🟡 Overture Maps Foundation — known to fail

- **What it is:** monthly GeoParquet for places, buildings, transport, addresses, and divisions.
- **Licence:** varies by theme. Places uses CDLA-Permissive-2.0; Base, Buildings, Divisions, and Transportation use ODbL; Addresses varies by country. See the [attribution table](https://docs.overturemaps.org/attribution/).
- **Docs:** [Quickstart](https://docs.overturemaps.org/getting-data/) · [DuckDB guide](https://docs.overturemaps.org/getting-data/duckdb/) (has the current release-folder name — it changes roughly monthly)
- **Status:** registration and bounded samples work. Cache and analytical queries fail with HTTP 500 or hang; a bounded sample is not evidence that analysis works. See [ISSUE-05](sql/known_to_fail/ISSUE-05-overture.md).

## 7. 🟡 Ookla Speedtest Global Fixed and Mobile Network Performance — known to fail

- **What it is:** quarterly global broadband and mobile speed-test results on roughly 610 m Web Mercator tiles.
- **Licence:** CC BY-NC-SA 4.0, **non-commercial** — [AWS open-data-registry YAML](https://github.com/awslabs/open-data-registry/blob/main/datasets/speedtest-global-performance.yaml). Fine for a hobbyist demo or tutorial repo; not for a commercial deliverable without a separate licence from Ookla.
- **Docs:** [ookla-open-data GitHub](https://github.com/teamookla/ookla-open-data) · [README](https://github.com/teamookla/ookla-open-data/blob/master/README.md) (has the exact path pattern and schema reference)
- **Status:** both registrations return HTTP 500. The bucket name has no dots, so PUDL's cause does not apply; Ookla's cause is unconfirmed. See [ISSUE-07](sql/known_to_fail/ISSUE-07-ookla.md).

## 8. 🟡 GBIF (Global Biodiversity Information Facility) species occurrences — known to fail

- **What it is:** more than 1.6 billion species records from museums, herbaria, and citizen-science networks, refreshed monthly.
- **Licence:** the [AWS registry](https://github.com/awslabs/open-data-registry/blob/main/datasets/gbif.yaml) lists aggregate CC-BY-NC. Individual records may use CC0 or CC-BY; use CC-BY-NC as the conservative whole-snapshot terms.
- **Docs:** [GBIF AWS public data guide](https://github.com/gbif/occurrence/blob/master/aws-public-data.md) (has the current snapshot-date convention) · [Citation guidelines](https://www.gbif.org/citation-guidelines)
- **Status:** registration and GUI caching succeed; every query, including the filtered verification query, returns HTTP 500. `DESCRIBE` succeeds; the cause is unknown. See [ISSUE-08](sql/known_to_fail/ISSUE-08-gbif.md).

## 9. 🟡 AWS Public Blockchain Data

- **What it is:** daily, date-partitioned Parquet for Bitcoin, Ethereum, and other chains.
- **Licence:** unresolved. The [registry](https://registry.opendata.aws/aws-public-blockchain/) links to an MIT code sample, not a data licence. Do not re-host the data until its terms are confirmed.
- **Docs:** [AWS registry entry](https://registry.opendata.aws/aws-public-blockchain/) · [Analytics guidance README](https://github.com/aws-solutions-library-samples/guidance-for-digital-assets-on-aws/blob/main/analytics/README.md) (has the full per-chain path structure)
- **Status:** both tables registered and all example queries passed live.
- **Caching:** SQL `CACHE TABLE` worked on `eth_transactions` but failed on `btc_transactions`; the Data Explorer cache action had the opposite result. Both tables queried successfully. The timing difference was observed, but its cause is unknown; see the create script header for exact results.

---

**See also:** `HOWTO.md` for the Zetaris onboarding walkthrough, and [`docs/plans/FUTURES.md`](../../docs/plans/FUTURES.md) plus its `recipes/*.md` files for everything outside Parquet/CSV — Kafka, logs, JSON/REST, SQL RDBMS, PDFs, and the government open-data sections.
