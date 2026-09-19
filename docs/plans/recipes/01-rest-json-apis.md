# Recipe: JSON / REST APIs

**Status:** 🟢 Active — 2 of 9 sources live-tested and verified against a real Zetaris instance
**Priority:** 1 (proceeding alongside Parquet/CSV rather than strictly after it — both are being driven by whatever's testable against the live instance at any given moment)
**Manifest reference:** `quickstart-data-manifest.md` §4 (original scope); EDGAR below is a new addition found via direct Zetaris testing, not in the original manifest
**Target location:** `open_data/rest_apis/` (matches the `open_data/parquet_csv/` convention already established, rather than the manifest's originally-suggested `json/`)

## Correction: the actual DDL is not what HOWTO.md's original pointer guessed

The Parquet/CSV package's `HOWTO.md` §6 speculated the REST pattern would be `REGISTER REST DATASOURCE TABLE`. **Live-tested and confirmed otherwise (2026-09-18):** it's actually two statements together — `CREATE LIGHTNING REST TABLE ... REQUEST(...) HEADER(...) BODY()` to register the raw JSON response, then `CREATE SCHEMASTORE VIEW ... WITH CONTAINER <name> AS SELECT ... LATERAL VIEW explode(...)` to flatten it into a queryable view. Full syntax reference now in `open_data/rest_apis/HOWTO.md`.

## Sources

Status legend: ✅ live-tested and working · 📋 scripted, not yet tested against Zetaris · ⚠️ scripted, high risk of not working at all (flagged reason) · 🔴 not included

1. ✅ **SEC EDGAR XBRL Company Facts API** — live-tested and working, `open_data/rest_apis/sql/01_edgar_company_facts.sql`, 7 companies (Apple, IBM, Oracle, Walmart, Target, Ford, Tesla). 🟡 Ambiguous license (filer-authored content, same posture as the manifest §6 SEC EDGAR PDF entry — point at the live API, don't bulk-redistribute). No signup, but requires a declared `User-Agent` (SEC blocks default ones) and respects a 10 req/sec rate limit. New addition, not in the original manifest.
2. ✅ **PokéAPI** — `sql/02_pokeapi.sql`. 🟢 BSD-3-Clause, no signup, fair-use rate limiting. Live-tested and working (2026-09-19) — confirmed two-level nested dot-access through `explode()` works, extended to two Pokémon (Pikachu, Charizard) with abilities/types/stats views, cross-Pokémon `UNION ALL` views, and 6 example analytical queries.
3. 📋 **Open Food Facts — live single-product API** — `sql/03_open_food_facts_live.sql`. 🟡 ODbL. Distinct from the bulk CSV/JSONL export already pulled forward into the Parquet/CSV recipe — this is the live per-product REST lookup instead. Array-of-structs with sparse/optional fields per entry.
4. 📋 **Singapore data.gov.sg — PM2.5 real-time API** — `sql/04_singapore_pm25.sql`. 🟢 SODL v1.0, no key needed for testing. Different shape class: array nested under a non-top-level wrapper key, fixed (non-array) struct per item.
5. 📋 **NASA NeoWs** (`/neo/browse`) — `sql/05_nasa_neows.sql`. 🟢 Public domain, `DEMO_KEY` works with no signup. Deeply nested array-of-structs plus a nested array-within-array, needing either indexing or a second `explode()`.
6. ⚠️ **NASA DONKI (CME)** — `sql/06_nasa_donki.sql`. 🟢 Public domain, same key system as NeoWs. **High risk:** the response is a top-level JSON array, not an object — every other source in this package returns a top-level object, and whether `CREATE LIGHTNING REST TABLE` accepts a bare array response at all is unverified.
7. ⚠️ **Eurostat REST API** — `sql/07_eurostat.sql`. 🟢/🟡 (copyright policy page worth reading directly). **High risk, likely drop candidate:** returns JSON-stat 2.0, a sparse multi-dimensional array format with no array-of-structs to flatten — fundamentally different from every other source's shape.
8. 📋 **Statistics Canada WDS** (`getChangedCubeList`) — `sql/08_statcan_wds.sql`. 🟢 StatCan Open Licence, no key. Simplest shape investigated across this whole batch — flat array-of-structs, one level, plain GET.
9. ⚠️ **Australian ABS Data API** (CPI) — `sql/09_abs_data_api.sql`. 🟢 CC-BY 3.0 AU (older version, not 4.0). **High risk, likely drop candidate:** SDMX-JSON 2.0.0, same risk class as Eurostat but with an extra layer of compound dynamic keys.
10. 🔴 Not included: REST Countries (now key-gated) — `countries.dev` flagged as an unverified candidate if country reference data is ever needed.
11. 📋 **JSONPlaceholder** — still not scripted (wasn't part of the 2026-09-19 investigation batch above). `https://jsonplaceholder.typicode.com/`, MIT, no signup — the flattest/simplest possible REST source, worth adding if a "get a 200 back in 30 seconds" example is still wanted after the batch above is worked through.

**Pulled forward, not here:** Open Food Facts's *bulk* export (🟡 ODbL) is in the Parquet/CSV recipe (`docs/plans/recipes/00-parquet-csv.md`) — its bulk JSONL/CSV export is a filestore-table source. Source 3 above is the separate live-API path.

## Goal

Establish the confirmed `CREATE LIGHTNING REST TABLE` + `CREATE SCHEMASTORE VIEW` pattern across a wide enough range of real-world JSON shapes that every later government-API category (NASA, data.gov, EU, UK, Canada, Australia, ...) can reuse it with confidence instead of re-deriving it per category. EDGAR proved the baseline works; the 2026-09-19 investigation batch (sources 2–9) was a deliberate breadth pass — testing as many *different* shape classes as possible in one go (see `open_data/rest_apis/HOWTO.md` §2's taxonomy) — so shape-specific problems get found and fixed (or a source gets dropped) before every remaining manifest category independently rediscovers the same issues one at a time.

## Work items

- [x] Confirm the actual REST DDL syntax against a live Zetaris instance — done, see correction above and `open_data/rest_apis/HOWTO.md` §1
- [x] `open_data/rest_apis/sql/01_edgar_company_facts.sql` — live-tested against 7 companies
- [x] Investigate and script 8 more candidate REST sources (2026-09-19) — real JSON responses pulled and inspected for each (not guessed from docs alone), scripted following the package's conventions, catalogued in `rest-api-sources.md` with a risk/status rating per source
- [x] `open_data/rest_apis/sql/02_pokeapi.sql` — live-tested and working (2026-09-19); confirmed two-level nested dot-access through `explode()` works (derisks NeoWs, sql/05, and any other deeply-nested source); extended to a second Pokémon, cross-Pokémon `UNION ALL` views, and 6 example analytical queries
- [ ] **Test sources 3–9 one by one against Zetaris**, in the order suggested in `HOWTO.md` §3 (lowest-risk/simplest shape first) — fix what can be fixed, drop what can't, same "test until it works or drop it" approach as the Parquet/CSV package's live-testing pass
- [ ] Verify EDGAR row counts aren't truncated (see `HOWTO.md` §2's "possible response-truncation bug" and §4's verification method) — flagged, not yet confirmed as a real bug or ruled out
- [ ] Determine whether `CREATE SCHEMASTORE CONTAINER`'s confirmed one-time-only limitation (no `IF NOT EXISTS`, `LightningDdlParseException` on a second run) has a workaround — research what query/API surface Zetaris exposes outside the SQL Editor for an external precheck script to use, if any
- [ ] Determine whether `CREATE LIGHTNING DATABASE` has the same one-time-only limitation — untested so far, would affect every script in both this package and `open_data/parquet_csv/` if so
- [ ] `jsonplaceholder/` — minimal flat-JSON example, only if still wanted after sources 2–9 are worked through

## Open questions / dependencies

- The `CREATE SCHEMASTORE CONTAINER` idempotency gap is a real usability problem for this whole package, not just EDGAR — every script that creates a container needs the "comment this out on a re-run" workaround until (if) a precheck mechanism is found
- If `CREATE LIGHTNING DATABASE` turns out to share the same one-time-only limitation, that's a cross-cutting fix needed in `open_data/parquet_csv/` too, not just here
- Sources 6, 7, and 9 (DONKI, Eurostat, ABS) are the real open questions of this batch — whether Zetaris can ingest a top-level-array response, and whether SDMX-family formats are usable at all through this pattern, are answers that will shape how ambitious later categories (EU §11, Australia §12) can be
- If DONKI's top-level-array problem turns out to be a real Zetaris limitation (not just this source), that's worth checking against any *other* manifest source that returns a bare array before assuming REST tables always need object-wrapped responses
