# Recipe: JSON / REST APIs

**Status:** 🟢 Active — first source live-tested and verified against a real Zetaris instance
**Priority:** 1 (proceeding alongside Parquet/CSV rather than strictly after it — both are being driven by whatever's testable against the live instance at any given moment)
**Manifest reference:** `quickstart-data-manifest.md` §4 (original scope); EDGAR below is a new addition found via direct Zetaris testing, not in the original manifest
**Target location:** `open_data/rest_apis/` (matches the `open_data/parquet_csv/` convention already established, rather than the manifest's originally-suggested `json/`)

## Correction: the actual DDL is not what HOWTO.md's original pointer guessed

The Parquet/CSV package's `HOWTO.md` §6 speculated the REST pattern would be `REGISTER REST DATASOURCE TABLE`. **Live-tested and confirmed otherwise (2026-09-18):** it's actually two statements together — `CREATE LIGHTNING REST TABLE ... REQUEST(...) HEADER(...) BODY()` to register the raw JSON response, then `CREATE SCHEMASTORE VIEW ... WITH CONTAINER <name> AS SELECT ... LATERAL VIEW explode(...)` to flatten it into a queryable view. Full syntax reference now in `open_data/rest_apis/HOWTO.md`.

## Sources

1. ✅ **SEC EDGAR XBRL Company Facts API** — live-tested and working, `open_data/rest_apis/sql/01_edgar_company_facts.sql`, 7 companies (Apple, IBM, Oracle, Walmart, Target, Ford, Tesla). 🟡 Ambiguous license (filer-authored content, same posture as the manifest §6 SEC EDGAR PDF entry — point at the live API, don't bulk-redistribute). No signup, but requires a declared `User-Agent` (SEC blocks default ones) and respects a 10 req/sec rate limit. Good real-world array-of-structs JSON flattening example. New addition, not in the original manifest.
2. 📋 **JSONPlaceholder** — `https://jsonplaceholder.typicode.com/`, MIT, no signup. Still planned as the "flat JSON, get a 200 back in 30 seconds" example — a simpler complement to EDGAR's nested structure.
3. 📋 **PokéAPI** — `https://pokeapi.co/`, BSD-3-Clause, no signup, fair-use rate limiting (cache responses, don't load-test it). Still planned.
4. 🔴 Not included: REST Countries (now key-gated) — `countries.dev` flagged as an unverified candidate if country reference data is ever needed.

**Pulled forward, not here:** Open Food Facts (🟡 ODbL) moved to the Parquet/CSV recipe (`docs/plans/recipes/00-parquet-csv.md`) — its bulk JSONL/CSV export is a filestore-table source, not a REST-table one.

## Goal

Establish the confirmed `CREATE LIGHTNING REST TABLE` + `CREATE SCHEMASTORE VIEW` pattern with sources of increasing/varying JSON complexity, so every later government-API category (NASA, data.gov, Singapore, EU, UK, ...) can reuse it instead of re-deriving it. EDGAR (array-of-structs) is the first proof point; JSONPlaceholder (flat) and PokéAPI (nested, possibly parallel-arrays-shaped) would round out the pattern coverage.

## Work items

- [x] Confirm the actual REST DDL syntax against a live Zetaris instance — done, see correction above and `open_data/rest_apis/HOWTO.md` §1
- [x] `open_data/rest_apis/sql/01_edgar_company_facts.sql` — live-tested against 7 companies; `HOWTO.md`, `rest-api-sources.md` written following the Parquet/CSV package's conventions
- [ ] Verify EDGAR row counts aren't truncated (see `HOWTO.md` §2's "possible response-truncation bug" and §4's verification method) — flagged, not yet confirmed as a real bug or ruled out
- [ ] Determine whether `CREATE SCHEMASTORE CONTAINER`'s confirmed one-time-only limitation (no `IF NOT EXISTS`, `LightningDdlParseException` on a second run) has a workaround — research what query/API surface Zetaris exposes outside the SQL Editor for an external precheck script to use, if any
- [ ] Determine whether `CREATE LIGHTNING DATABASE` has the same one-time-only limitation — untested so far, would affect every script in both this package and `open_data/parquet_csv/` if so
- [ ] `jsonplaceholder/` — minimal flat-JSON example, README
- [ ] `pokeapi/` — nested JSON flattening example (a Pokémon record's stats/moves/abilities) — confirm its actual JSON shape (array-of-structs vs. parallel arrays) before assuming EDGAR's `explode()` pattern applies unchanged; README with fair-use note (cache locally, no load-testing) and Nintendo-trademark caveat

## Open questions / dependencies

- The `CREATE SCHEMASTORE CONTAINER` idempotency gap is a real usability problem for this whole package, not just EDGAR — every script that creates a container needs the "comment this out on a re-run" workaround until (if) a precheck mechanism is found
- If `CREATE LIGHTNING DATABASE` turns out to share the same one-time-only limitation, that's a cross-cutting fix needed in `open_data/parquet_csv/` too, not just here
