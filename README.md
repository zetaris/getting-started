# getting-started

Designed to help developers using Zetaris quickly get up and running, with real, permissively-licensed data sources you can query within minutes of standing up a small Zetaris deployment.

## Status

**Installation:** documented and tested. See [Getting Zetaris running](#getting-zetaris-running) below.

**REST / JSON APIs** ([`open_data/rest_apis/`](open_data/rest_apis/)) — 6 of 9 candidate sources live-tested and working end to end:

- Live-tested, working: SEC EDGAR XBRL Company Facts, PokéAPI, NASA NeoWs, Eurostat, Statistics Canada WDS, Australian ABS Data API — plus the `company_dns` SIC hierarchy reference and its EDGAR-join company-profile product (see [`docs/plans/edgar-sic-enrichment-plan.md`](docs/plans/edgar-sic-enrichment-plan.md)).
- Partially tested: Open Food Facts live API (queries 1-7 confirmed, query 8 not yet reached).
- Not yet tested: NASA DONKI (its top-level-array response shape is still an open question).
- Blocked, documented as a failure case: Singapore data.gov.sg PM2.5 (HTTP 502, see [`failure_cases/`](open_data/rest_apis/failure_cases/)).

Full per-source detail and current status: [`rest-api-sources.md`](open_data/rest_apis/rest-api-sources.md).

**Parquet / CSV** ([`open_data/parquet_csv/`](open_data/parquet_csv/)) — 9 sources catalogued, most live-tested; 2 marked forbidden/update-pending in the source catalog. Detail: [`parquet-csv-data-sources.md`](open_data/parquet_csv/parquet-csv-data-sources.md).

**SQL scripts — CREATE/SELECT split:** every onboarding script in `rest_apis/sql/` and `parquet_csv/sql/` now ships as a pair — a `*_create.sql` (setup DDL: registering the source, building views) and a `*_select.sql` (verification and example analytical queries) — so standing up a source doesn't require scrolling past example queries first, and vice versa.

**Unified Semantic Layer (USL)** ([`open_data/usl/`](open_data/usl/)) — a contrast track alongside the REST+SchemaStore approach, rebuilding the same EDGAR+SIC data product with USL's `CREATE TABLE`/`FOREIGN KEY`/`ACTIVATE`/`REGISTER DQ`/`MATERIALIZE` lifecycle. Live-tested; a null-handling bug found during that run has been fixed, and the result is believed passing, pending final confirmation. See [`open_data/usl/HOWTO.md`](open_data/usl/HOWTO.md).

**Reference guide:** [`docs/guides/zetaris-sql-companion.md`](docs/guides/zetaris-sql-companion.md) — tips, gotchas, and confirmed platform limitations found across all the live testing above, meant to be read alongside the Zetaris Kbase while writing your own SQL.

**Planned, not started:** SQL RDBMS, logs, NASA (broader than NeoWs/DONKI), Singapore, data.gov, EU, UK, Canada/Australia/Mexico/Africa, PDFs — see [`docs/plans/FUTURES.md`](docs/plans/FUTURES.md) for the full priority order and each category's plan.

**Deferred:** Kafka / streaming — intentionally held back until it's confirmed a hobby-edition Zetaris instance can actually ingest from a broker. See [`docs/plans/recipes/11-kafka-streaming.md`](docs/plans/recipes/11-kafka-streaming.md).

## Getting Zetaris running

A tested installation and configuration guide is available: [`docs/install/updated_zetaris_installation_guide.md`](docs/install/updated_zetaris_installation_guide.md) (local Docker Compose install, fully tested; an AWS free-tier path, checked on paper but not yet run on AWS). Test results: [`docs/install/zetaris-installation-test-record.md`](docs/install/zetaris-installation-test-record.md).

## Documentation map

| Doc | What it's for |
|---|---|
| [`docs/install/`](docs/install/) | Installing and configuring Zetaris (local or AWS), and the record of what's been tested |
| [`docs/guides/zetaris-sql-companion.md`](docs/guides/zetaris-sql-companion.md) | SQL reference: shapes, quoting, gotchas, and confirmed platform limitations across REST, Parquet, SchemaStore, VDM, and USL |
| [`docs/plans/FUTURES.md`](docs/plans/FUTURES.md) | The full data-source roadmap, priority order, and status per category |
| [`docs/plans/`](docs/plans/) | Active plans for in-progress or upcoming work; [`docs/plans/archive/`](docs/plans/archive/) holds completed or superseded plans, kept as historical record |
| [`open_data/rest_apis/HOWTO.md`](open_data/rest_apis/HOWTO.md) | REST/JSON onboarding syntax reference and per-source status |
| [`open_data/parquet_csv/HOWTO.md`](open_data/parquet_csv/HOWTO.md) | Parquet/CSV onboarding syntax reference and per-source status |
| [`open_data/usl/HOWTO.md`](open_data/usl/HOWTO.md) | USL package: what it exercises, prerequisites, and known open items |
| [`docs/plans/archive/quickstart-data-manifest.md`](docs/plans/archive/quickstart-data-manifest.md) | The original source-research manifest — archived; its content has been dispersed into `docs/plans/recipes/*` and `FUTURES.md`, kept here only as the exhaustive backing reference (full URLs/citations) for categories not yet built |

## Repo layout

```
open_data/
  rest_apis/      REST/JSON API sources — HOWTO, source catalog, sql/*_create.sql + *_select.sql pairs
  parquet_csv/     Parquet/CSV file sources — same HOWTO/catalog/sql pattern
  usl/             Unified Semantic Layer contrast build (EDGAR+SIC, rebuilt with USL instead of REST+VDM)
docs/
  install/         Installation & configuration guide, plus its test record
  guides/          The Zetaris SQL companion reference guide
  plans/           Active roadmap and category plans (FUTURES.md, recipes/); archive/ for completed plans
```

Folders are added as each category in the roadmap actually ships, rather than scaffolded up front. See [`docs/plans/FUTURES.md`](docs/plans/FUTURES.md) for the full picture of where this is headed.
