# getting-started

Designed to help developers using Zetaris quickly get up and running, with real, permissively-licensed data sources you can query within minutes of standing up a small Zetaris deployment.

## Status

This repo is being built out one data category at a time rather than all at once — see [docs/plans/FUTURES.md](docs/plans/FUTURES.md) for the full roadmap and why it's sequenced this way.

**Implemented (verified against a live Zetaris instance):**
- **SEC EDGAR XBRL Company Facts API** (REST) — [`open_data/rest_apis/`](open_data/rest_apis/): live-tested against 7 companies via `CREATE LIGHTNING REST TABLE` + `CREATE SCHEMASTORE VIEW`. Plan: [docs/plans/recipes/01-rest-json-apis.md](docs/plans/recipes/01-rest-json-apis.md).

**In progress:**
- **Parquet / CSV** — [`open_data/parquet_csv/`](open_data/parquet_csv/): 9 scripted sources (NYC TLC, NOAA GHCN-Daily, PUDL, Foursquare Places, Overture Maps, Common Crawl, Ookla Speedtest, GBIF, AWS Public Blockchain Data), each with a `CREATE LIGHTNING FILESTORE TABLE` script, plus 3 candidates pulled forward from later categories (a Singapore data.gov.sg CSV dataset, the Open Food Facts bulk export, a Sentinel-2 GeoParquet index) — not yet scripted. Live testing has found and fixed several real issues (a missing `CREATE LIGHTNING DATABASE` prerequisite, S3 credential handling, a path-encoding bug); NYC TLC's S3 mirror is confirmed dead and needs a re-upload workaround; other sources still being worked through. Plan: [docs/plans/recipes/00-parquet-csv.md](docs/plans/recipes/00-parquet-csv.md).
- **JSON / REST APIs** — [`open_data/rest_apis/`](open_data/rest_apis/): EDGAR verified (see above); 8 more sources scripted but not yet tested (PokéAPI, Open Food Facts live API, Singapore PM2.5, NASA NeoWs, NASA DONKI, Eurostat, Statistics Canada WDS, Australian ABS) — several flagged high-risk pending verification (DONKI's top-level-array response, Eurostat/ABS's SDMX-family formats). Plan: [docs/plans/recipes/01-rest-json-apis.md](docs/plans/recipes/01-rest-json-apis.md).

**Planned, not started:** SQL RDBMS, logs, NASA, Singapore, data.gov, EU, UK, Canada/Australia/Mexico/Africa, PDFs — see FUTURES.md for the full priority order and each category's plan.

**Deferred:** Kafka / streaming — intentionally held back until it's confirmed a hobby-edition Zetaris instance can actually ingest from a broker. See [docs/plans/recipes/11-kafka-streaming.md](docs/plans/recipes/11-kafka-streaming.md).

## Getting Zetaris running

A Zetaris installation & configuration guide (AWS free-tier mini install and a local `docker compose` install) is being written — see [docs/plans/zetaris-installation-guide.md](docs/plans/zetaris-installation-guide.md). Not ready yet; check back or follow that plan's progress.

## Repo layout

Intentionally minimal right now — folders are added as each category in the roadmap actually ships, rather than scaffolded up front. See `docs/plans/` for the full picture of where this is headed.
