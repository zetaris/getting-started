# getting-started

Real, permissively-licensed data sources you can query within minutes of standing up a small Zetaris deployment — a tested install guide, ready-to-run SQL onboarding scripts, TypeScript and Python helper scripts for the Zetaris API, and a reference guide for the SQL gotchas found along the way.

## Quickstart

1. **Install Zetaris.** Follow [`docs/install/updated_zetaris_installation_guide.md`](docs/install/updated_zetaris_installation_guide.md) (local Docker Compose, fully tested) and sign in to the SQL Workspace.
2. **Pick a source and run its `_create.sql`.** Every source ships as a pair of scripts — e.g. [`open_data/rest_apis/sql/non_rate_limited/02_pokeapi_create.sql`](open_data/rest_apis/sql/non_rate_limited/02_pokeapi_create.sql) registers PokéAPI and builds the flattened views.
3. **Run the matching `_select.sql`** — e.g. [`02_pokeapi_select.sql`](open_data/rest_apis/sql/non_rate_limited/02_pokeapi_select.sql) — to verify it worked and see example analytical queries against real data.

That `*_create.sql` / `*_select.sql` split (setup DDL vs. verification/example queries) is consistent across every source in `open_data/rest_apis/sql/` and `open_data/parquet_csv/sql/`, so once you've done it once you can repeat it for any source in the catalogs below.

## Key getting started material

| Doc | What it's for |
|---|---|
| [Installation Guide](docs/install/updated_zetaris_installation_guide.md) | Installing and configuring Zetaris (local or AWS); the [installation test record](docs/install/zetaris-installation-test-record.md) has what's been tested |
| [Connecting to Coding Harnesses](docs/connections/codex-connection.md) | Connecting a coding harness (Codex today; Cursor and Grok Build to follow) to Zetaris over JDBC |
| [REST API Howto](open_data/rest_apis/HOWTO.md) | Onboarding REST/JSON API sources — see also the [source catalog](open_data/rest_apis/rest-api-sources.md) |
| [Parquet/CSV Howto](open_data/parquet_csv/HOWTO.md) | Onboarding Parquet/CSV file sources — see also the [source catalog](open_data/parquet_csv/parquet-csv-data-sources.md) |
| [USL Howto](open_data/usl/HOWTO.md) | Unified Semantic Layer contrast builds — data products already built elsewhere in this repo, rebuilt with USL instead |
| [Scripts Howto](scripts/HOWTO.md) | TypeScript and Python helpers for the Zetaris HTTP API, a PostgreSQL connection check, and local data fetchers |
| [Zetaris SQL Companion](docs/guides/zetaris-sql-companion.md) | SQL reference: shapes, quoting, gotchas, and confirmed platform limitations — read alongside the Zetaris Kbase while writing your own SQL |
| [Roadmap](docs/plans/FUTURES.md) | The full data-source roadmap, priority order, and status per category |

## Repo layout

```
open_data/   Data source packages — REST/JSON APIs, Parquet/CSV, USL (see Key getting started material above)
scripts/     TypeScript and Python helper scripts (see scripts/HOWTO.md)
docs/        Install guide, connection guides, SQL companion, and the roadmap/plans
```

Folders are added as each category in the roadmap actually ships, rather than scaffolded up front — see [`docs/plans/FUTURES.md`](docs/plans/FUTURES.md) for where this is headed.

## Client scripts

[`scripts/`](scripts/) has TypeScript (Deno) and Python helpers for connecting to the Zetaris HTTP API and checking a PostgreSQL connection, plus two standalone Python downloaders for the Parquet/CSV package's not-yet-registered sources. See [`scripts/HOWTO.md`](scripts/HOWTO.md) for setup, environment variables, and usage for both languages.

## Contributing

Adding a new data source, documenting one that doesn't work, archiving a finished plan, or touching anything else in this repo? See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the conventions this repo relies on — the `_create.sql`/`_select.sql` pattern, the `known_to_fail/` writeup format, license verification, and more.
