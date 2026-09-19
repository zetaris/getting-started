# Roadmap: data source recipes

`quickstart-data-manifest.md` (14 sections of researched-but-mostly-unscripted sources) is being implemented one category at a time rather than all at once. Each category below has its own implementation plan in `docs/plans/recipes/`, with its own checklist. This file is the index and the priority order — update the status column as work lands, don't duplicate the detail here.

**Guiding rule (per current direction):** don't scaffold or build against a category until we're reasonably confident it'll actually work end-to-end against a real Zetaris instance. Parquet/CSV and JSON/REST APIs are both active now — live testing against the real instance is what's actually driving which category gets attention at any given moment, not a strict one-at-a-time queue. Everything below priority 1 still waits its turn, and Kafka specifically is held back pending explicit verification (see its recipe for why).

**Selective harvesting:** rather than treating each category as strictly sequential, every later category was scanned for CSV/Parquet-shaped assets that fit the filestore-table pattern already proven in Parquet/CSV — those get pulled forward into priority 0 instead of waiting, even though the rest of their category (REST APIs, signups, etc.) stays at its original position. Three were found and pulled forward: a data.gov.sg CSV dataset (from Singapore, priority 5), the Open Food Facts bulk CSV/JSONL export (from REST/JSON, priority 1), and a Sentinel-2 GeoParquet STAC index (from EU, priority 7). Detail and status in [recipes/00-parquet-csv.md](recipes/00-parquet-csv.md)'s "Pulled-forward candidates" section. NASA, data.gov, UK, and the regional bundle were checked too — nothing pull-forward-worthy turned up in what the manifest researched for those, noted in each recipe so it isn't re-checked without reason.

## Status legend

🟢 Active · 📋 Planned (not started) · ⏸ Deferred (blocked on verification) · ✅ Done

## Prerequisite

| | |
|---|---|
| [Zetaris installation & configuration guide](zetaris-installation-guide.md) | 📋 Planned — AWS free-tier mini install + local docker-compose install. Every recipe below needs a running instance to verify against; this is what provides one. |

## Recipes, in priority order

| # | Category | Status | Plan | Why this position |
|---|---|---|---|---|
| 0 | Parquet / CSV | 🟢 Active | [recipes/00-parquet-csv.md](recipes/00-parquet-csv.md) | Already scripted (9 sources) + 3 pulled-forward candidates from later categories (Singapore CSV, Open Food Facts bulk export, Sentinel-2 GeoParquet); finishing this first gives a fully verified reference for the filestore-table pattern everything file-based reuses. |
| 1 | JSON / REST APIs | 🟢 Active | [recipes/01-rest-json-apis.md](recipes/01-rest-json-apis.md) | SEC EDGAR live-tested and working — establishes the confirmed `CREATE LIGHTNING REST TABLE` + `CREATE SCHEMASTORE VIEW` pattern. 8 more sources investigated and scripted 2026-09-19 (PokéAPI, Open Food Facts live API, Singapore PM2.5, NASA NeoWs/DONKI, Eurostat, StatCan WDS, ABS) covering a deliberately wide range of JSON shapes, several flagged high-risk (DONKI's top-level array, Eurostat/ABS's SDMX formats) — testing one by one is next. Open Food Facts's bulk export is at priority 0 instead (it's a file source, not a REST one). |
| 2 | SQL RDBMS | 📋 Planned | [recipes/02-sql-rdbms.md](recipes/02-sql-rdbms.md) | Self-hosted via docker compose, no external account needed — establishes the JDBC `CREATE DATASOURCE` pattern independent of any API-key story. |
| 3 | Logs | 📋 Planned | [recipes/03-logs.md](recipes/03-logs.md) | Reuses the filestore-table pattern from Parquet/CSV directly; low complexity once that pattern is confirmed. |
| 4 | NASA open APIs | 📋 Planned | [recipes/04-nasa-open-data.md](recipes/04-nasa-open-data.md) | Richest, best-documented API family with a genuine no-key entry point (Image/Video Library) before any signup — high demo value, low friction. |
| 5 | Singapore open data | 📋 Planned | [recipes/05-singapore-open-data.md](recipes/05-singapore-open-data.md) | One clean umbrella license (SODL), mostly REST/JSON — direct REST-recipe consumer with an honestly-documented Kafka/SQL gap (the Parquet/CSV gap was closed early — a data.gov.sg CSV source moved to priority 0). |
| 6 | data.gov | 📋 Planned | [recipes/06-datagov.md](recipes/06-datagov.md) | Shares its API key mechanism with NASA (§9) — natural to sequence right after. |
| 7 | EU open data | 📋 Planned | [recipes/07-eu-open-data.md](recipes/07-eu-open-data.md) | Eurostat is a zero-friction REST example. A Sentinel-2 GeoParquet STAC index (via a Source Cooperative mirror, not Azure/`wasb://`) moved to priority 0 — a real, confirmed Parquet source, not just documentation. |
| 8 | UK open data | 📋 Planned | [recipes/08-uk-open-data.md](recipes/08-uk-open-data.md) | Companies House is a strong SQL-recipe-adjacent relational dataset; TfL is a future Kafka-replay candidate. |
| 9 | Canada / Australia / Mexico / Africa | 📋 Planned | [recipes/09-regional-open-data.md](recipes/09-regional-open-data.md) | Four smaller, mostly no-key categories bundled into one unit of work; each still gets its own top-level repo folder. |
| 10 | PDFs | 📋 Planned | [recipes/10-pdf-sources.md](recipes/10-pdf-sources.md) | Lower priority — valuable for a RAG/ingestion demo, but not central to "get data queryable in Zetaris." |
| 11 | Kafka streaming | ⏸ Deferred | [recipes/11-kafka-streaming.md](recipes/11-kafka-streaming.md) | Held back until it's confirmed a hobby-edition Zetaris instance (AWS free-tier or docker-compose) can actually ingest from a broker — heavier footprint, higher risk of wasted scaffolding if built before that's known. |

## Not a recipe on its own

- **Kaggle / data.world sourcing rule** (manifest §8) — a cross-cutting verification rule ("independently trace the license, don't trust a badge"), not a category with its own folder. Gets folded into `LICENSE-NOTES.md` and the top-level conventions section of the README rather than its own plan.
- **Known limitations** (manifest §14) — each item there is already attached to the recipe it affects; check a recipe's "Open questions" section rather than re-reading §14 separately.

## When picking up the next recipe

1. Confirm the previous recipe's live-Zetaris verification actually passed — don't start priority *N* on the assumption priority *N-1*'s DDL pattern works, confirm it did.
2. Update this table's status column and the individual recipe's status line together, so they don't drift.
3. If a recipe surfaces a blocking discovery (a source going away, a license turning out to be unusable, a syntax that doesn't work as documented), note it in that recipe file's "Open questions" section rather than silently reordering this table — reorder here only after a deliberate decision.
