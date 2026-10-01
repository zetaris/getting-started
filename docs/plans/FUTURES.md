# Roadmap: data source recipes

The original source research (14 sections of researched-but-mostly-unscripted sources, now archived at [`docs/plans/archive/quickstart-data-manifest.md`](archive/quickstart-data-manifest.md) — its content has been dispersed into the recipes below) is being implemented one category at a time rather than all at once. Each category below has its own implementation plan in `docs/plans/recipes/`, with its own checklist and full sourcing detail — that's now the primary reference, not the archived manifest. This file is the index and the priority order — update the status column as work lands, don't duplicate the detail here.

**Guiding rule (per current direction):** don't scaffold or build against a category until we're reasonably confident it'll actually work end-to-end against a real Zetaris instance. Parquet/CSV and JSON/REST APIs are both active now — live testing against the real instance is what's actually driving which category gets attention at any given moment, not a strict one-at-a-time queue. Everything below priority 1 still waits its turn, and Kafka specifically is held back pending explicit verification (see its recipe for why).

**Selective harvesting:** later categories have three file-data candidates tracked under priority 0: data.gov.sg and Open Food Facts have local fetch scripts but no Zetaris SQL registrations; the Sentinel-2 STAC index has no script yet. See [recipes/00-parquet-csv.md](archive/00-parquet-csv.md) for their current blockers. They are not part of the seven current SQL pairs.

## Status legend

🟢 Active · 📋 Planned (not started) · ⏸ Deferred (blocked on verification) · ✅ Done

## Prerequisite

| | |
|---|---|
| [Zetaris installation & configuration guide](../install/updated_zetaris_installation_guide.md) | ✅ Done — local docker-compose install fully tested; AWS free-tier path checked on paper, not yet run on AWS. See the [test record](../install/zetaris-installation-test-record.md). |

## Recipes, in priority order

| # | Category | Status | Plan | Why this position |
|---|---|---|---|---|
| 0 | Parquet / CSV | ✅ Done | [archive/00-parquet-csv.md](archive/00-parquet-csv.md) | Seven current CREATE/SELECT pairs (IDs 02, 03, 04, 05, 07, 08, 09) live in `open_data/parquet_csv/`. NOAA GHCN-Daily and AWS Public Blockchain Data are live-tested and confirmed (the latter with a confirmed-but-asymmetric caching story between its BTC/ETH tables and the SQL/GUI caching mechanisms — see the catalog); PUDL, Ookla, Foursquare, Overture, and GBIF are known to fail, each at a different step (PUDL and Ookla at table-registration time, for different unrelated reasons; Foursquare at every query including the plain SELECT; Overture beyond a bounded SELECT; GBIF at every query despite the table creating and caching successfully). Current status lives in `open_data/parquet_csv/parquet-csv-data-sources.md`; the recipe plan is archived. |
| 1 | JSON / REST APIs | ✅ Done | [archive/01-rest-json-apis.md](archive/01-rest-json-apis.md) | 9 of 11 sources verified (SEC EDGAR, PokéAPI, Open Food Facts, NASA NeoWs, Eurostat, StatCan WDS, ABS Data API, company_dns, EDGAR company profiles); NASA DONKI unverified (top-level-array question open); Singapore PM2.5 known to fail, kept in `sql/known_to_fail/`. Scripts are organized into `sql/rate_limited/`, `sql/non_rate_limited/`, and `sql/known_to_fail/` — see `open_data/rest_apis/HOWTO.md`. Current status lives in `open_data/rest_apis/rest-api-sources.md`; the recipe plan is archived. |
| 2 | SQL RDBMS | 📋 Planned | [recipes/02-sql-rdbms.md](recipes/02-sql-rdbms.md) | Self-hosted via docker compose, no external account needed — establishes the JDBC `CREATE DATASOURCE` pattern independent of any API-key story. |
| 3 | Logs | 📋 Planned | [recipes/03-logs.md](recipes/03-logs.md) | Reuses the filestore-table pattern from Parquet/CSV directly; low complexity once that pattern is confirmed. |
| 4 | NASA open APIs | 📋 Planned, recipe archived | [archive/04-nasa-open-data.md](archive/04-nasa-open-data.md) | This recipe's own standout sources, NeoWs and DONKI, already shipped under priority 1 (REST). The rest (APOD, Mars Rover Photos, EONET, Images API, DONKI-to-Kafka) remains unbuilt; the plan doc moved to `archive/` as unstarted research, not as done work — pick it back up here if this category gets prioritized again. |
| 5 | Singapore open data | 📋 Planned | [recipes/05-singapore-open-data.md](recipes/05-singapore-open-data.md) | One clean umbrella license (SODL), mostly REST/JSON. A data.gov.sg CSV fetcher is tracked under priority 0, but it has no Zetaris SQL registration yet; Kafka and remote SQL examples also remain open. |
| 6 | data.gov | 📋 Planned | [recipes/06-datagov.md](recipes/06-datagov.md) | Shares its API key mechanism with NASA (§9) — natural to sequence right after. |
| 7 | EU open data | 📋 Planned | [recipes/07-eu-open-data.md](recipes/07-eu-open-data.md) | Eurostat is a zero-friction REST example. A Sentinel-2 GeoParquet index on Source Cooperative is a candidate under priority 0; its path is unconfirmed and it has no SQL script yet. |
| 8 | UK open data | 📋 Planned | [recipes/08-uk-open-data.md](recipes/08-uk-open-data.md) | Companies House is a strong SQL-recipe-adjacent relational dataset; TfL is a future Kafka-replay candidate. |
| 9 | Canada / Australia / Mexico / Africa | 📋 Planned | [recipes/09-regional-open-data.md](recipes/09-regional-open-data.md) | Four smaller, mostly no-key categories bundled into one unit of work; each still gets its own top-level repo folder. |
| 10 | PDFs | 📋 Planned | [recipes/10-pdf-sources.md](recipes/10-pdf-sources.md) | Lower priority — valuable for a RAG/ingestion demo, but not central to "get data queryable in Zetaris." |
| 11 | Kafka streaming | ⏸ Deferred | [recipes/11-kafka-streaming.md](recipes/11-kafka-streaming.md) | Held back until it's confirmed a hobby-edition Zetaris instance (AWS free-tier or docker-compose) can actually ingest from a broker — heavier footprint, higher risk of wasted scaffolding if built before that's known. |

## Not a recipe on its own

- **Kaggle / data.world sourcing rule** — a cross-cutting verification rule, not a category with its own folder:
  - **Kaggle** is usable, but a license badge on a listing is the uploader's own claim, not something Kaggle vouches for. Only trust it when either (a) the uploader is the original, authoritative source (an official agency's own Kaggle "Organization" account, or a company publishing its own data), or (b) the underlying upstream source can be independently traced and its license confirmed directly — the same way every other source in this repo's research was checked. A random re-upload with a confident-looking badge doesn't meet that bar. Free account required to download; no card needed. Good as a discovery index and for datasets traceable to a verifiable primary source.
  - **data.world** is not usable — it was acquired by ServiceNow in 2025, and its Open Data Community was formally retired 2026-07-13 (community datasets no longer downloadable, no replacement or archive provided). What remains is ServiceNow's enterprise data-catalog product, not a source of open datasets.
  - Apply this rule to any Kaggle-hosted (or similarly crowd-hosted) dataset added to any recipe later — it needs its own license trace before it goes in, this rule doesn't pre-clear it.
- **Known limitations** — each item is already attached to the recipe it affects; check a recipe's "Open questions" section rather than a separate limitations list.
- **Unified Semantic Layer (USL)** ([`open_data/usl/`](../../open_data/usl/), build plan archived at [`docs/plans/archive/usl-build-plan.md`](archive/usl-build-plan.md)) — a contrast track, not a numbered recipe. It rebuilds the priority-10 EDGAR+SIC data product (see `archive/edgar-sic-enrichment-plan.md`) as two models, `sic_usl` and `sic_edgar_usl`, using USL instead of REST+SchemaStore+VDM, specifically to compare the two mechanisms. Each model's lifecycle is live-tested and confirmed working (after a null-handling fix, `8f18f4f`); each model's own custom data-quality check runs as a plain query rather than a `REGISTER DQ` rule (confirmed platform limitations — see `docs/guides/zetaris-sql-companion.md` section 8.6). A handful of verify steps (materialization, teardown, namespace-layout experiment) remain genuinely open and aren't being actively pursued — see [`open_data/usl/usl-sources.md`](../../open_data/usl/usl-sources.md) for current per-model status.

## When picking up the next recipe

1. Confirm the previous recipe's live-Zetaris verification actually passed — don't start priority *N* on the assumption priority *N-1*'s DDL pattern works, confirm it did.
2. Update this table's status column and the individual recipe's status line together, so they don't drift.
3. If a recipe surfaces a blocking discovery (a source going away, a license turning out to be unusable, a syntax that doesn't work as documented), note it in that recipe file's "Open questions" section rather than silently reordering this table — reorder here only after a deliberate decision.
