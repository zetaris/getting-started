# getting-started

Data recipes, connection helpers, and guides for making external data queryable in Zetaris and building a project from it. Source licenses and verification limits are recorded in the catalogs.

## Start here

Read [START-HERE.md](START-HERE.md) first. It supports both a locally installed platform and an existing instance. The event instance is shared; use assigned team names and permissions.

1. **Confirm access.** This repo does not supply the platform distribution, an account, or a JDBC driver. Follow the prerequisite checklist and the appropriate access path.
2. **Connect and execute one query.** Choose SQL Editor, agent JDBC, or the HTTP helpers in the [connection guide](docs/connections/README.md).
3. **Verify a small dataset.** Follow [your first dataset](docs/guides/first-dataset.md): the PUDL energy-code table, with a minimal PokéAPI JSON alternative. Execute complete statements separately and inspect actual rows.
4. **Choose your project.** Follow an [analysis, data-product, or application path](docs/guides/project-paths.md), then use the [demo template](docs/guides/demo-template.md).

CREATE/SELECT pairs are available for the active REST and file sources. Read their headers and select the statements you need. The HTTP helper's `--file` option sends the whole file as one request, and REST verification queries are generally commented out. Do not treat a whole recipe as an automatically executed migration.

Use [recipe readiness](docs/guides/recipe-readiness.md) to choose later sources and [troubleshooting](docs/guides/troubleshooting.md) for partial setup or errors. Support and submission details remain unresolved in the [organizer checklist](docs/guides/hackathon-organizer-checklist.md).

## Documentation map

| Doc | What it's for |
|---|---|
| [`docs/install/`](docs/install/) | Installing and configuring Zetaris (local or AWS), and the record of what's been tested |
| [`docs/connections/README.md`](docs/connections/README.md) | SQL Editor, Cursor/Codex JDBC, and HTTP route choices; included recipe command reference |
| [`open_data/rest_apis/`](open_data/rest_apis/) | REST/JSON API sources — catalog, HOWTO, and `sql/*_create.sql` + `*_select.sql` pairs |
| [`open_data/parquet_csv/`](open_data/parquet_csv/) | Parquet/CSV file sources — same catalog/HOWTO/sql pattern |
| [`open_data/usl/`](open_data/usl/) | Unified Semantic Layer contrast build — the same EDGAR+SIC data product, rebuilt with USL instead of REST+VDM |
| [`scripts/`](scripts/) | TypeScript and Python helpers for the Zetaris HTTP API and a PostgreSQL connection check — see [Client scripts](#client-scripts) below |
| [`docs/guides/project-paths.md`](docs/guides/project-paths.md) | Optional project directions, including the [PUDL chart](examples/pudl-chart/README.md) and [EDGAR/PUDL/NOAA guide](docs/guides/create-edgar-pudl-noaa-usl.md) |
| [`docs/guides/zetaris-sql-companion.md`](docs/guides/zetaris-sql-companion.md) | SQL reference: shapes, quoting, gotchas, and confirmed platform limitations — read alongside the Zetaris Kbase while writing your own SQL |
| [`docs/plans/FUTURES.md`](docs/plans/FUTURES.md) | The full data-source roadmap, priority order, and status per category |
| [`docs/plans/`](docs/plans/) | Active plans for in-progress or upcoming work; [`docs/plans/archive/`](docs/plans/archive/) holds completed or superseded plans and the original source-research manifest, kept as historical record |

## Repo layout

```
open_data/
  rest_apis/      REST/JSON API sources — HOWTO, source catalog, sql/*_create.sql + *_select.sql pairs
  parquet_csv/     Parquet/CSV file sources — same HOWTO/catalog/sql pattern
  usl/             Unified Semantic Layer contrast build (EDGAR+SIC, rebuilt with USL instead of REST+VDM)
scripts/
  check_zetaris.*, query_zetaris.*, ping_postgres.*, zetaris_api.* — TypeScript and Python helpers
examples/
  pudl-chart/      One query through the HTTP helper to a local HTML chart
docs/
  connections/     Route choices, Cursor/Codex prompts, and recipe command reference
  install/         Installation & configuration guide, plus its test record
  guides/          First dataset, project paths, readiness, recovery, and demo guidance
  plans/           Active roadmap and category plans (FUTURES.md, recipes/); archive/ for completed plans
```

Folders are added as each category in the roadmap actually ships, rather than scaffolded up front — see [`docs/plans/FUTURES.md`](docs/plans/FUTURES.md) for where this is headed.

## Client scripts

The helpers are available in both Deno/TypeScript and Python. Both versions load
`.env`, preserve values already exported in the shell, use the same environment
variables, and provide the same checks and query behavior.

### Deno/TypeScript

Use [Deno](https://deno.com/agents.md) 2.9 or later for the TypeScript helper scripts. Check your installation with `deno --version`. Deno downloads script dependencies on first use; `deno.lock` pins their versions.

Run these commands from the repository root:

```sh
deno task check
deno task lint
deno task warmup:company-dns
```

The warmup task prepares the hosted Company DNS service before running `open_data/rest_apis/sql/non_rate_limited/10_company_dns_sic_create.sql`. It grants network access only to `company-dns.mediumroast.io:443` and environment access only to `COMPANY_DNS_BASE_URL`.

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

The check lists visible Lightning databases to confirm authenticated API access. The query command sends the SQL text as one request to `POST /api/proxy/sql-editor/sqls/run-query` and prints its JSON response (`headers`, `data`, `total`, `timeUsed`). Use one complete statement per file/request; the helper does not split files or roll back partial setup. Set `ZETARIS_QUERY_LIMIT` to cap returned rows or `ZETARIS_ENGINE_ID` to select a compute engine. SQL runs with your Zetaris account's permissions, so review a file before passing it to the command.

### Python

Python 3.9 or later is required. Install the environment-file loader and the
Psycopg PostgreSQL driver with:

```sh
python3 -m pip install -r scripts/requirements.txt
```

Run the Python equivalents from the repository root:

```sh
python3 scripts/check_zetaris.py
python3 scripts/query_zetaris.py "SELECT 1"
python3 scripts/query_zetaris.py --file path/to/one-query.sql
python3 scripts/ping_postgres.py
```

They read the same `.env` fields and enforce the same validation, 30-second HTTP
timeouts, and 10-second PostgreSQL connection and statement timeouts as the
TypeScript versions.

API contract: [Zetaris API reference](http://localhost:8888/redoc/index.html#tag/SQL-Editor). The UI on port 3000 proxies the documented `/api/v1.0/...` endpoints under `/api/proxy/...`.

## Status

| Category | Status | Detail |
|---|---|---|
| Install | ✅ Local Docker Compose fully tested; AWS checked on paper only | [`docs/install/`](docs/install/) |
| REST / JSON APIs | 9 of 11 marked verified in the catalog; DONKI unverified, PM2.5 known to fail | [`rest-api-sources.md`](open_data/rest_apis/rest-api-sources.md) |
| Parquet / CSV | 🟢 7 current CREATE/SELECT pairs; PUDL energy-source table live-tested | [`parquet-csv-data-sources.md`](open_data/parquet_csv/parquet-csv-data-sources.md) |
| SQL scripts | ✅ CREATE/SELECT split done across all sources | see Start here above |
| USL | 🟡 Live-tested, fix applied, pending final confirmation | [`open_data/usl/HOWTO.md`](open_data/usl/HOWTO.md) |
| TypeScript/Python scripts | ✅ Zetaris API + PostgreSQL connection helpers available | see Client scripts above |
| SQL RDBMS, logs, PDFs, broader NASA, Singapore, data.gov, EU, UK, Canada/Australia/Mexico/Africa | 📋 Planned, not started | [`docs/plans/FUTURES.md`](docs/plans/FUTURES.md) |
| Kafka / streaming | ⏸ Deferred until a hobby-edition Zetaris instance is confirmed to ingest from a broker | [`docs/plans/recipes/11-kafka-streaming.md`](docs/plans/recipes/11-kafka-streaming.md) |

These statuses describe recorded evidence, not a new live run. Each linked doc has the full per-source detail and caveats — this table is a summary, not the source of truth.
