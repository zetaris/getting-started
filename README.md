# getting-started

Designed to help developers using Zetaris quickly get up and running, with real, permissively-licensed data sources you can query within minutes of standing up a small Zetaris deployment.

## Status

This repo is being built out one data category at a time rather than all at once — see [docs/plans/FUTURES.md](docs/plans/FUTURES.md) for the full roadmap and why it's sequenced this way.

**Implemented (verified against a live Zetaris instance):** nothing yet — Parquet/CSV is in progress, see below.

**In progress:**
- **Parquet / CSV** — [`open_data/parquet_csv/`](open_data/parquet_csv/): 9 scripted sources (NYC TLC, NOAA GHCN-Daily, PUDL, Foursquare Places, Overture Maps, Common Crawl, Ookla Speedtest, GBIF, AWS Public Blockchain Data), each with a `CREATE LIGHTNING FILESTORE TABLE` script, plus 3 candidates pulled forward from later categories (a Singapore data.gov.sg CSV dataset, the Open Food Facts bulk export, a Sentinel-2 GeoParquet index) — not yet scripted. Nothing here is verified end-to-end against a live instance yet. Plan: [docs/plans/recipes/00-parquet-csv.md](docs/plans/recipes/00-parquet-csv.md).

**Planned, not started:** JSON/REST APIs, SQL RDBMS, logs, NASA, Singapore, data.gov, EU, UK, Canada/Australia/Mexico/Africa, PDFs — see FUTURES.md for the full priority order and each category's plan.

**Deferred:** Kafka / streaming — intentionally held back until it's confirmed a hobby-edition Zetaris instance can actually ingest from a broker. See [docs/plans/recipes/11-kafka-streaming.md](docs/plans/recipes/11-kafka-streaming.md).

## Getting Zetaris running

A Zetaris installation & configuration guide (AWS free-tier mini install and a local `docker compose` install) is being written — see [docs/plans/zetaris-installation-guide.md](docs/plans/zetaris-installation-guide.md). Not ready yet; check back or follow that plan's progress.

## Repo layout

Intentionally minimal right now — folders are added as each category in the roadmap actually ships, rather than scaffolded up front. See `docs/plans/` for the full picture of where this is headed.
