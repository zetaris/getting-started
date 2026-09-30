# getting-started

Real, permissively-licensed data sources you can query within minutes of standing up a small Zetaris deployment — a tested install guide, ready-to-run SQL onboarding scripts, TypeScript helper scripts for the Zetaris API, and a reference guide for the SQL gotchas found along the way.

## Quickstart

1. **Install Zetaris.** Follow [`docs/install/updated_zetaris_installation_guide.md`](docs/install/updated_zetaris_installation_guide.md) (local Docker Compose, fully tested) and sign in to the SQL Workspace.
2. **Pick a source and run its `_create.sql`.** Every source ships as a pair of scripts — e.g. [`open_data/rest_apis/sql/non_rate_limited/02_pokeapi_create.sql`](open_data/rest_apis/sql/non_rate_limited/02_pokeapi_create.sql) registers PokéAPI and builds the flattened views.
3. **Run the matching `_select.sql`** — e.g. [`02_pokeapi_select.sql`](open_data/rest_apis/sql/non_rate_limited/02_pokeapi_select.sql) — to verify it worked and see example analytical queries against real data.

That `*_create.sql` / `*_select.sql` split (setup DDL vs. verification/example queries) is consistent across every source in `open_data/rest_apis/sql/` and `open_data/parquet_csv/sql/`, so once you've done it once you can repeat it for any source in the catalogs below.

## Documentation map

| Doc | What it's for |
|---|---|
| [`docs/install/`](docs/install/) | Installing and configuring Zetaris (local or AWS), and the record of what's been tested |
| [`docs/cookbooks/`](docs/cookbooks/) | Short, task-focused guides, including [connecting Codex to Zetaris over JDBC](docs/cookbooks/codex-connection.md) |
| [`open_data/rest_apis/`](open_data/rest_apis/) | REST/JSON API sources — catalog, HOWTO, and `sql/*_create.sql` + `*_select.sql` pairs |
| [`open_data/parquet_csv/`](open_data/parquet_csv/) | Parquet/CSV file sources — same catalog/HOWTO/sql pattern |
| [`open_data/usl/`](open_data/usl/) | Unified Semantic Layer contrast build — the same EDGAR+SIC data product, rebuilt with USL instead of REST+VDM |
| [`scripts/`](scripts/) | TypeScript and Python helpers for the Zetaris HTTP API and a PostgreSQL connection check — see [Client scripts](#client-scripts) below |
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
docs/
  cookbooks/       Short connection guides (Codex, with Cursor and Grok Build to follow)
  install/         Installation & configuration guide, plus its test record
  guides/          The Zetaris SQL companion reference guide
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

The check lists visible Lightning databases to confirm authenticated API access. The query command sends the SQL text as one request to `POST /api/proxy/sql-editor/sqls/run-query` and prints its JSON response (`headers`, `data`, `total`, `timeUsed`). For a file with multiple statements, use one statement at a time if the endpoint rejects the batch. Set `ZETARIS_QUERY_LIMIT` to cap returned rows or `ZETARIS_ENGINE_ID` to select a compute engine. SQL runs with your Zetaris account's permissions, so review a file before passing it to the command.

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
| REST / JSON APIs | 🟢 6 of 9 sources live-tested and working | [`rest-api-sources.md`](open_data/rest_apis/rest-api-sources.md) |
| Parquet / CSV | 🟢 7 current CREATE/SELECT pairs; PUDL energy-source table live-tested | [`parquet-csv-data-sources.md`](open_data/parquet_csv/parquet-csv-data-sources.md) |
| SQL scripts | ✅ CREATE/SELECT split done across all sources | see Quickstart above |
| USL | 🟡 Live-tested, fix applied, pending final confirmation | [`open_data/usl/HOWTO.md`](open_data/usl/HOWTO.md) |
| TypeScript/Python scripts | ✅ Zetaris API + PostgreSQL connection helpers available | see Client scripts above |
| SQL RDBMS, logs, PDFs, broader NASA, Singapore, data.gov, EU, UK, Canada/Australia/Mexico/Africa | 📋 Planned, not started | [`docs/plans/FUTURES.md`](docs/plans/FUTURES.md) |
| Kafka / streaming | ⏸ Deferred until a hobby-edition Zetaris instance is confirmed to ingest from a broker | [`docs/plans/recipes/11-kafka-streaming.md`](docs/plans/recipes/11-kafka-streaming.md) |

Each linked doc has the full per-source detail and caveats — this table is a summary, not the source of truth.
