# Parquet & CSV Data Sources for Zetaris Quick-Starts

A catalog of real, S3-native (or S3-compatible) Parquet and CSV data sources you can point a small Zetaris deployment at directly — no download portal, no signup wall, just a bucket or endpoint URL. Each entry lists the license, the exact path to the data, a docs link, and the matching onboarding script in `sql/` that registers it as a queryable Zetaris table.

**License key:** 🟢 open, use it freely (read the note for any attribution requirement) · 🟡 open with a condition worth reading before you build on it · 🔴 not included — see the note for why

**About the SQL:** every `CREATE LIGHTNING FILESTORE TABLE` statement in `sql/` uses the syntax documented in the Zetaris knowledge base (`kbase.zetaris.com`) and the Cloud Data Fabric / Lightning SQL manuals (`data-fabric.readthedocs.io`). See `HOWTO.md` for the full syntax reference and two open questions worth testing yourself: whether Zetaris supports credential-less reads of public buckets, and whether it accepts plain HTTPS paths.

---

## Quick-reference table

| # | Dataset | Domain | License | Format | Direct data URL / path | Docs & instructions | Onboarding script |
|---|---|---|---|---|---|---|---|
| 1 | NYC TLC Trip Records | Transportation | 🟡 Ambiguous (see below) | Parquet | `https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2025-01.parquet` (CloudFront); `s3://nyc-tlc` (S3 mirror, see note below) | [TLC trip record data page](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page) · [data dictionary (yellow)](https://www.nyc.gov/assets/tlc/downloads/pdf/data_dictionary_trip_records_yellow.pdf) · [AWS registry entry](https://registry.opendata.aws/nyc-tlc-trip-records-pds/) | `sql/01_nyc_tlc.sql` |
| 2 | NOAA GHCN-Daily | Climate | 🟢 CC0-1.0 | CSV (native) | `s3://noaa-ghcn-pds/csv/by_year/2025.csv` | [AWS registry entry](https://registry.opendata.aws/noaa-ghcn/) · [GHCN-Daily readme](https://docs.opendata.aws/noaa-ghcn-pds/readme.html) · [format spec](https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt) | `sql/02_noaa_ghcn.sql` |
| 3 | Catalyst Cooperative PUDL | Energy/utilities | 🟢 CC-BY-4.0 | Parquet (+ SQLite) | `s3://pudl.catalyst.coop/stable/core_eia__codes_energy_sources.parquet` (one example table — see Data Access docs for the full list) | [PUDL Data Access docs](https://docs.catalyst.coop/pudl/en/stable/data_access.html) · [AWS registry entry](https://registry.opendata.aws/catalyst-cooperative-pudl/) · [Data Dictionary](https://docs.catalyst.coop/pudl/en/stable/data_dictionaries/pudl_db.html) | `sql/03_pudl.sql` |
| 4 | Foursquare Open Source Places | Geospatial/POI | 🟢 Apache-2.0 | Parquet | `https://data.source.coop/fused/fsq-os-places/2024-11-19/places/79.parquet` (one shard — the directory has many) | [Foursquare OS Places docs](https://docs.foursquare.com/data-products/docs/fsq-places-open-source) · [Access instructions](https://docs.foursquare.com/data-products/docs/access-fsq-os-places) · [Source Cooperative repo](https://source.coop/fused/fsq-os-places) | `sql/04_foursquare_places.sql` |
| 5 | Overture Maps Foundation | Geospatial/maps | 🟡 Mixed by theme (CDLA-Permissive-2.0 / ODbL / varies) | GeoParquet | `s3://overturemaps-us-west-2/release/2026-08-19.0/theme=places/type=place/*` (release folder changes monthly — see docs) | [Overture Quickstart](https://docs.overturemaps.org/getting-data/) · [DuckDB guide](https://docs.overturemaps.org/getting-data/duckdb/) · [Attribution/license table](https://docs.overturemaps.org/attribution/) | `sql/05_overture_maps.sql` |
| 6 | Common Crawl columnar index | Web/text metadata | 🟡 Common Crawl ToU (index only — see below) | Parquet | `s3://commoncrawl/cc-index/table/cc-main/warc/crawl=CC-MAIN-2025-33/subset=warc/*.parquet` (swap the crawl ID — see docs for the current one) | [Columnar Index docs](https://commoncrawl.org/columnar-index) · [cc-index-table README](https://github.com/commoncrawl/cc-index-table/blob/main/README.md) · [Terms of Use](https://commoncrawl.org/terms-of-use/) | `sql/06_common_crawl_index.sql` |
| 7 | Ookla Speedtest Global Performance | Telecom | 🟡 CC BY-NC-SA 4.0 (non-commercial) | Parquet (+ Shapefile) | `s3://ookla-open-data/parquet/performance/type=fixed/year=2026/quarter=2/2026-04-01_performance_fixed_tiles.parquet` | [ookla-open-data GitHub](https://github.com/teamookla/ookla-open-data) · [README (path patterns, schema)](https://github.com/teamookla/ookla-open-data/blob/master/README.md) · [AWS registry entry](https://registry.opendata.aws/speedtest-global-performance/) | `sql/07_ookla_speedtest.sql` |
| 8 | GBIF species occurrences | Biodiversity | 🟡 Aggregate CC-BY-NC (mixed per record) | Parquet | `s3://gbif-open-data-us-east-1/occurrence/2026-09-01/occurrence.parquet/*` (snapshot date changes monthly — see docs) | [GBIF AWS public data guide](https://github.com/gbif/occurrence/blob/master/aws-public-data.md) · [Citation guidelines](https://www.gbif.org/citation-guidelines) · [AWS registry entry](https://registry.opendata.aws/gbif/) | `sql/08_gbif.sql` |
| 9 | AWS Public Blockchain Data | Blockchain/crypto | 🟡 Unresolved (see below) | Parquet | `s3://aws-public-blockchain/v1.0/btc/transactions/date=2026-09-01/*.snappy.parquet` | [AWS registry entry](https://registry.opendata.aws/aws-public-blockchain/) · [Analytics guidance/README](https://github.com/aws-solutions-library-samples/guidance-for-digital-assets-on-aws/blob/main/analytics/README.md) | `sql/09_aws_public_blockchain.sql` |

Every date/version/release fragment in the "direct data URL" column above (`2025-01`, `2026-08-19.0`, `CC-MAIN-2025-33`, `2026-09-01`, etc.) moves — these sources update on their own cadence (monthly, quarterly, daily). Before an event or demo, run the listing command shown in each SQL script's header comment (`aws s3 ls --no-sign-request s3://...`) to confirm the latest available partition rather than relying on the date shown here.

---

## 1. 🟡 NYC TLC Trip Record Data

- **What it is:** NYC Taxi & Limousine Commission monthly trip records, published natively as Parquet.
- **License:** no formal permissive license is attached — the AWS registry's License field points to NYC's generic website Terms of Use, while NYC Open Data's own FAQ says "no restrictions." The two don't fully reconcile. Practical guidance: query it live, don't re-host a copy.
- **A note on the S3 mirror:** the `s3://nyc-tlc` mirror has been reported unreachable before (a July 2022 community report — [thread](https://dask.discourse.group/t/s3-nyc-tlc-seems-to-have-disappeared/890)), and its current internal key layout isn't confirmed (older tooling references a `trip data/` prefix with a literal space in it). Treat the CloudFront URL as primary, and the S3 mirror as "test it first."
- **A note on Zetaris access (see HOWTO.md):** `CREATE LIGHTNING FILESTORE TABLE` takes an S3 (`s3a://`) or Azure Blob (`wasb://`) path, not a plain `https://` URL — so `sql/01_nyc_tlc.sql` targets the S3 mirror, with a fallback plan if it doesn't respond.
- **Docs:** [TLC trip record data page](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page) · [Yellow trip data dictionary (PDF)](https://www.nyc.gov/assets/tlc/downloads/pdf/data_dictionary_trip_records_yellow.pdf)

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

## 6. 🟡 Common Crawl columnar index (cc-index)

- **What it is:** not the raw web crawl, but a Parquet index over it — URL, WARC offset, MIME type, HTTP status, timestamp — built for exactly this kind of "query billions of rows" demo, without touching actual page content.
- **License:** the [Terms of Use](https://commoncrawl.org/terms-of-use/) grant a limited license to the Service, but crawled content itself "may be subject to separate terms of use... from the owners of such Crawled Content." The index (Common Crawl's own generated metadata) is the part to use for a demo; the underlying WARC page text is where third-party rights come into play.
- **Docs:** [Columnar Index announcement/docs](https://commoncrawl.org/columnar-index) · [cc-index-table README](https://github.com/commoncrawl/cc-index-table/blob/main/README.md) (has the current crawl-ID naming convention)

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
- **License:** unresolved. The [registry entry](https://registry.opendata.aws/aws-public-blockchain/)'s License field links to an MIT-licensed *code-sample* repo (`aws-samples/digital-assets-examples`), not a data-licensing document — no independent statement that the blockchain data itself is CC0/public-domain exists yet. Recommended treatment: point at the live S3 bucket for a demo, don't re-host a copy, same as NYC TLC.
- **Docs:** [AWS registry entry](https://registry.opendata.aws/aws-public-blockchain/) · [Analytics guidance README](https://github.com/aws-solutions-library-samples/guidance-for-digital-assets-on-aws/blob/main/analytics/README.md) (has the full per-chain path structure)

---

**See also:** `HOWTO.md` for the Zetaris onboarding walkthrough, and the main [Zetaris Quick-Start Data Sources](../quickstart-data-manifest.md) guide for everything outside Parquet/CSV — Kafka, logs, JSON/REST, SQL RDBMS, PDFs, and the government open-data sections.
