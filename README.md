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
| [`quickstart-data-manifest.md`](quickstart-data-manifest.md) | The original source-research manifest — still the detail reference for categories not yet built |

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
Intentionally minimal right now — folders are added as each category in the roadmap actually ships, rather than scaffolded up front. See `docs/plans/` for the full picture of where this is headed.

## Deno scripts

Use [Deno](https://deno.com/agents.md) 2.9 or later for the TypeScript helper scripts. Check your installation with `deno --version`. Deno downloads script dependencies on first use; `deno.lock` pins their versions.

Run these commands from the repository root:

```sh
deno task check
deno task lint
deno task warmup:company-dns
```

The warmup task prepares the hosted Company DNS service before running `open_data/rest_apis/sql/10_company_dns_sic.sql`. It grants network access only to `company-dns.mediumroast.io:443` and environment access only to `COMPANY_DNS_BASE_URL`.

For a self-hosted service, set the URL and grant access to its host explicitly:

```sh
COMPANY_DNS_BASE_URL=http://localhost:8000 deno run --no-prompt --allow-net=localhost:8000 --allow-env=COMPANY_DNS_BASE_URL open_data/rest_apis/scripts/warmup_company_dns.ts
```

### Check a PostgreSQL connection

Create a local `.env` file using the PostgreSQL fields in `.env.example`. If `.env` already exists, add the fields to it. Set `PGHOST` to your server IP or hostname, then fill in `PGPORT`, `PGDATABASE`, `PGUSER`, and `PGPASSWORD`. Quote passwords containing spaces or `#`. The `.env` file is gitignored. Exported environment variables take precedence over `.env` values.

```sh
deno task ping:postgres
```

The script authenticates and runs `SELECT 1`, reports elapsed time, then closes the connection. It exits with code 1 on failure. Connection and server-side query timeouts are 10 seconds. This checks database access, not ICMP ping.

Set `PGSSLMODE=verify-full` if your server uses TLS with a trusted certificate matching the host. The default is `disable` for servers without TLS. The task grants network access and access to `PG*` environment variables. It uses the [Postgres.js driver](https://github.com/porsager/postgres).

### Connect to the Zetaris HTTP API and run SQL

Set the `ZETARIS_*` fields from `.env.example` in your local `.env`. `ZETARIS_BASE_URL` defaults to `http://localhost:3000`; set the numeric `ZETARIS_ORG_ID`. Provide either `ZETARIS_API_TOKEN` or `ZETARIS_USERNAME` and `ZETARIS_PASSWORD`. The scripts use the token directly when present; otherwise they call `POST /api/auth/login` with JSON credentials and use its access token. They send a fresh `X-Request-ID` and your `X-Org-ID` with each API request.

```sh
./scripts/check_zetaris.ts
./scripts/query_zetaris.ts "SELECT 1"
./scripts/query_zetaris.ts --file path/to/one-query.sql
```

Run these from the repository root. Each script's first line supplies the Deno flags, including `.env` loading and network permission. It also uses `--no-config` to avoid loading the separate PostgreSQL driver. If direct execution is unavailable, run `deno run --no-config --env-file=.env --allow-net --allow-env='ZETARIS*' scripts/check_zetaris.ts` instead.

The check lists visible Lightning databases to confirm authenticated API access. The query command sends the SQL text as one request to `POST /api/proxy/sql-editor/sqls/run-query` and prints its JSON response (`headers`, `data`, `total`, `timeUsed`). For a file with multiple statements, use one statement at a time if the endpoint rejects the batch. Set `ZETARIS_QUERY_LIMIT` to cap returned rows or `ZETARIS_ENGINE_ID` to select a compute engine. SQL runs with your Zetaris account's permissions, so review a file before passing it to the command.

API contract: [Zetaris API reference](http://localhost:8888/redoc/index.html#tag/SQL-Editor). The UI on port 3000 proxies the documented `/api/v1.0/...` endpoints under `/api/proxy/...`.
