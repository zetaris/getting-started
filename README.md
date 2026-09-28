# getting-started

Real, permissively-licensed data sources you can query within minutes of standing up a small Zetaris deployment — a tested install guide, ready-to-run SQL onboarding scripts, and a reference guide for the SQL gotchas found along the way.

## Quickstart

1. **Install Zetaris.** Follow [`docs/install/updated_zetaris_installation_guide.md`](docs/install/updated_zetaris_installation_guide.md) (local Docker Compose, fully tested) and sign in to the SQL Workspace.
2. **Pick a source and run its `_create.sql`.** Every source ships as a pair of scripts — e.g. [`open_data/rest_apis/sql/02_pokeapi_create.sql`](open_data/rest_apis/sql/02_pokeapi_create.sql) registers PokéAPI and builds the flattened views.
3. **Run the matching `_select.sql`** — e.g. [`02_pokeapi_select.sql`](open_data/rest_apis/sql/02_pokeapi_select.sql) — to verify it worked and see example analytical queries against real data.

That `*_create.sql` / `*_select.sql` split (setup DDL vs. verification/example queries) is consistent across every source in `open_data/rest_apis/sql/` and `open_data/parquet_csv/sql/`, so once you've done it once you can repeat it for any source in the catalogs below.

## Documentation map

| Doc | What it's for |
|---|---|
| [`docs/install/`](docs/install/) | Installing and configuring Zetaris (local or AWS), and the record of what's been tested |
| [`open_data/rest_apis/`](open_data/rest_apis/) | REST/JSON API sources — catalog, HOWTO, and `sql/*_create.sql` + `*_select.sql` pairs |
| [`open_data/parquet_csv/`](open_data/parquet_csv/) | Parquet/CSV file sources — same catalog/HOWTO/sql pattern |
| [`open_data/usl/`](open_data/usl/) | Unified Semantic Layer contrast build — the same EDGAR+SIC data product, rebuilt with USL instead of REST+VDM |
| [`docs/guides/zetaris-sql-companion.md`](docs/guides/zetaris-sql-companion.md) | SQL reference: shapes, quoting, gotchas, and confirmed platform limitations — read alongside the Zetaris Kbase while writing your own SQL |
| [`docs/plans/FUTURES.md`](docs/plans/FUTURES.md) | The full data-source roadmap, priority order, and status per category |
| [`docs/plans/`](docs/plans/) | Active plans for in-progress or upcoming work; [`docs/plans/archive/`](docs/plans/archive/) holds completed or superseded plans and the original source-research manifest, kept as historical record |

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

Folders are added as each category in the roadmap actually ships, rather than scaffolded up front — see [`docs/plans/FUTURES.md`](docs/plans/FUTURES.md) for where this is headed.

## Status

| Category | Status | Detail |
|---|---|---|
| Install | ✅ Local Docker Compose fully tested; AWS checked on paper only | [`docs/install/`](docs/install/) |
| REST / JSON APIs | 🟢 6 of 9 sources live-tested and working | [`rest-api-sources.md`](open_data/rest_apis/rest-api-sources.md) |
| Parquet / CSV | 🟢 9 sources catalogued, most live-tested | [`parquet-csv-data-sources.md`](open_data/parquet_csv/parquet-csv-data-sources.md) |
| SQL scripts | ✅ CREATE/SELECT split done across all sources | see Quickstart above |
| USL | 🟡 Live-tested, fix applied, pending final confirmation | [`open_data/usl/HOWTO.md`](open_data/usl/HOWTO.md) |
| SQL RDBMS, logs, PDFs, broader NASA, Singapore, data.gov, EU, UK, Canada/Australia/Mexico/Africa | 📋 Planned, not started | [`docs/plans/FUTURES.md`](docs/plans/FUTURES.md) |
| Kafka / streaming | ⏸ Deferred until a hobby-edition Zetaris instance is confirmed to ingest from a broker | [`docs/plans/recipes/11-kafka-streaming.md`](docs/plans/recipes/11-kafka-streaming.md) |

Each linked doc has the full per-source detail and caveats — this table is a summary, not the source of truth.
