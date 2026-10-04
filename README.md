# getting-started

Data recipes, connection helpers, and guides for making external data queryable in Zetaris and building a project from it. Source licenses and verification limits are recorded in the catalogs.

## Start here

Read [START-HERE.md](START-HERE.md) first. It supports both a locally installed platform and an existing instance. The event instance is shared; use assigned team names and permissions.

1. **Confirm access.** This repo does not supply the platform distribution, an account, or a JDBC driver. Follow the prerequisite checklist and the appropriate access path.
2. **Connect and execute one query.** Choose SQL Editor, agent JDBC, or the HTTP helpers in the [connection guide](docs/connections/README.md).
3. **Verify a small dataset.** Follow [your first dataset](docs/guides/first-dataset.md): a minimal PokéAPI JSON subset; PUDL is now known to fail. Execute complete statements separately and inspect actual rows.
4. **Choose your project.** Follow an [analysis, data-product, or application path](docs/guides/project-paths.md), then use the [demo template](docs/guides/demo-template.md).

CREATE/SELECT pairs are available for the active REST and file sources. Read their headers and select the statements you need. The single-query helper's `--file` option sends the whole file as one request. For multi-command files use the new `run_sql.py` runner; source/model dependencies are declared in `open_data/manifest.json` and planned by `onboard.py`. REST verification queries are generally commented out. Do not treat a whole recipe as an automatically executed migration.

Use [recipe readiness](docs/guides/recipe-readiness.md) to choose later sources and [troubleshooting](docs/guides/troubleshooting.md) for partial setup or errors. Support and submission details remain unresolved in the [organizer checklist](docs/guides/hackathon-organizer-checklist.md).

## Documentation map

| Doc | What it's for |
|---|---|
| [`docs/install/`](docs/install/) | Installing and configuring Zetaris (local or AWS), and the record of what's been tested |
| [`docs/connections/README.md`](docs/connections/README.md) | SQL Editor, Cursor/Codex/Claude Code JDBC and REST choices; included recipe and full command references |
| [Full Lightning command reference](docs/guides/zetaris-lightning-sql-commands.md) | Platform command syntax; use the smaller recipe reference for the starter |
| [`open_data/rest_apis/`](open_data/rest_apis/) | REST/JSON API sources — catalog, HOWTO, and `sql/*_create.sql` + `*_select.sql` pairs |
| [`open_data/parquet_csv/`](open_data/parquet_csv/) | Parquet/CSV file sources — same catalog/HOWTO/sql pattern |
| [`open_data/usl/`](open_data/usl/) | Unified Semantic Layer contrast build — the same EDGAR+SIC data product, rebuilt with USL instead of REST+VDM |
| [`scripts/`](scripts/) | Preflight, dependency-aware onboarding, multi-command execution, API helpers, and local fetchers |
| [`open_data/manifest.json`](open_data/manifest.json) | Source/model IDs, status, and dependencies for `onboard.py` |
| [`docs/guides/project-paths.md`](docs/guides/project-paths.md) | Optional project directions, including the [PUDL chart](examples/pudl-chart/README.md) and [EDGAR/PUDL/NOAA guide](docs/guides/create-edgar-pudl-noaa-usl.md) |
| [`docs/guides/zetaris-lightning-sql-companion.md`](docs/guides/zetaris-lightning-sql-companion.md) | SQL reference: shapes, quoting, gotchas, and confirmed platform limitations — read alongside the Zetaris Kbase while writing your own SQL |
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
  connections/     Route choices, Cursor/Codex/Claude Code prompts, and recipe command reference
  install/         Installation & configuration guide, plus its test record
  guides/          First dataset, project paths, readiness, recovery, and demo guidance
  plans/           Active roadmap and category plans (FUTURES.md, recipes/); archive/ for completed plans
```

Folders are added as each category in the roadmap actually ships, rather than scaffolded up front — see [`docs/plans/FUTURES.md`](docs/plans/FUTURES.md) for where this is headed.

## Client scripts

[`scripts/`](scripts/) now includes `preflight.py`, `run_sql.py`, and dependency-aware `onboard.py`, alongside TypeScript (Deno) and Python helpers for connecting to the Zetaris HTTP API and checking a PostgreSQL connection, plus two standalone Python downloaders for the Parquet/CSV package's not-yet-registered sources. See [`scripts/HOWTO.md`](scripts/HOWTO.md) for setup, environment variables, and usage for both languages.

## Contributing

Adding a new data source, documenting one that doesn't work, archiving a finished plan, or touching anything else in this repo? See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the conventions this repo relies on — the `_create.sql`/`_select.sql` pattern, the `known_to_fail/` writeup format, license verification, and more.
