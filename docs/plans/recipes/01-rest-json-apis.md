# Recipe: JSON / REST APIs

**Status:** 📋 Planned — next up after Parquet/CSV
**Priority:** 1
**Manifest reference:** `quickstart-data-manifest.md` §4
**Target location:** `json/`

## Sources

- 🟢 **JSONPlaceholder** — `https://jsonplaceholder.typicode.com/`, MIT, no signup. The "get a 200 back in 30 seconds" example.
- 🟢 **PokéAPI** — `https://pokeapi.co/`, BSD-3-Clause, no signup, fair-use rate limiting (cache responses, don't load-test it). Good nested/relational JSON example.
- 🔴 Not included: REST Countries (now key-gated) — `countries.dev` flagged as an unverified candidate if country reference data is ever needed.

**Pulled forward:** Open Food Facts (🟡 ODbL, attribution + share-alike) moved to the Parquet/CSV recipe (`docs/plans/recipes/00-parquet-csv.md`) — its bulk JSONL/CSV export is a filestore-table source, not a REST-table one, so it made more sense there than here. If a live single-record API demo against Open Food Facts is wanted later (as opposed to the bulk export), that would come back to this recipe as a third example, but isn't currently planned.

## Goal

Establish the `REGISTER REST DATASOURCE TABLE` pattern (Zetaris's REST DDL, per `HOWTO.md` §5's pointer) with two sources of increasing JSON complexity — flat, then nested — so every later government-API category (NASA, data.gov, Singapore, EU, UK, ...) can reuse the same recipe instead of re-deriving it.

## Work items

- [ ] Confirm `REGISTER REST DATASOURCE TABLE` syntax against `kbase.zetaris.com`/`data-fabric.readthedocs.io` (same verification standard as the filestore DDL in Parquet/CSV)
- [ ] `jsonplaceholder/` — minimal curl/REST example + one `REGISTER REST DATASOURCE TABLE` script, README
- [ ] `pokeapi/` — nested JSON flattening example (a Pokémon record's stats/moves/abilities), README with fair-use note (cache locally, no load-testing) and Nintendo-trademark caveat
- [ ] Verify both against a live Zetaris instance; capture row counts / sample queries

## Open questions / dependencies

- Needs the REST DDL confirmed against a live instance (same blocker class as Parquet/CSV's two open items) — do this early since every subsequent government-API category depends on the same syntax working
- Decide whether the REST DDL verification happens here or is folded into the Parquet/CSV live-verification pass, to avoid two separate "first contact with a live Zetaris instance" sessions
