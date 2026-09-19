# REST API Data Sources for Zetaris Quick-Starts

A catalog of REST API sources you can point a small Zetaris deployment at directly via `CREATE LIGHTNING REST TABLE` — no file download, the JSON response becomes a queryable table (raw) plus a flattened `SCHEMASTORE` view (tabular). Each entry lists the license, the exact endpoint pattern, a docs link, and the matching onboarding script in `sql/`.

**License key:** 🟢 open, use it freely (read the note for any attribution requirement) · 🟡 open with a condition worth reading before you build on it · 🔴 not included — see the note for why

**About the SQL:** every `CREATE LIGHTNING REST TABLE` statement registers the raw JSON response as a table; every `CREATE SCHEMASTORE VIEW` flattens it into something query-shaped via `LATERAL VIEW explode(...)`. See `HOWTO.md` for the full syntax reference and confirmed gotchas — most importantly that `CREATE SCHEMASTORE CONTAINER` can only be run once per name (no `IF NOT EXISTS` support).

---

## Quick-reference table

| # | Source | Domain | License | Status | Onboarding script |
|---|---|---|---|---|---|
| 1 | SEC EDGAR XBRL Company Facts | Financial/regulatory | 🟡 Ambiguous | ✅ Live-tested, working | `sql/01_edgar_company_facts.sql` |
| 2 | PokéAPI | Structured game data | 🟢 BSD-3-Clause | 📋 Scripted, not yet tested | `sql/02_pokeapi.sql` |
| 3 | Open Food Facts (live API) | Product/nutrition | 🟡 ODbL | 📋 Scripted, not yet tested | `sql/03_open_food_facts_live.sql` |
| 4 | Singapore data.gov.sg — PM2.5 real-time | Environment | 🟢 SODL v1.0 | 📋 Scripted, not yet tested | `sql/04_singapore_pm25.sql` |
| 5 | NASA NeoWs (`/neo/browse`) | Astronomy | 🟢 Public domain | 📋 Scripted, not yet tested | `sql/05_nasa_neows.sql` |
| 6 | NASA DONKI (CME) | Space weather | 🟢 Public domain | ⚠️ Scripted, high risk (top-level array, unverified) | `sql/06_nasa_donki.sql` |
| 7 | Eurostat REST API | Statistics | 🟢/🟡 (see below) | ⚠️ Scripted, high risk (JSON-stat format) | `sql/07_eurostat.sql` |
| 8 | Statistics Canada WDS | Statistics | 🟢 StatCan Open Licence | 📋 Scripted, not yet tested | `sql/08_statcan_wds.sql` |
| 9 | Australian ABS Data API | Statistics | 🟢 CC-BY 3.0 AU | ⚠️ Scripted, high risk (SDMX-JSON format) | `sql/09_abs_data_api.sql` |

Sources 2–9 were investigated and scripted on 2026-09-19 (real JSON responses pulled and inspected, not guessed from docs alone) but **not yet run against Zetaris** — the plan is to test each one by one, per `docs/plans/recipes/01-rest-json-apis.md`, and either fix or drop based on what actually happens. Full per-source detail below; JSON shape classification in `HOWTO.md` §2.

---

## 1. 🟡 SEC EDGAR XBRL Company Facts API

- **What it is:** structured financial facts (revenue, and other US-GAAP tags) extracted from public companies' own XBRL-tagged filings, served as JSON per company/concept via `data.sec.gov/api/xbrl/companyconcept/CIK{10-digit-cik}/us-gaap/{tag}.json`.
- **License:** filings are filer-authored, not government-authored — free API access doesn't automatically mean a copyright/license grant over the extracted facts. Same posture as the SEC EDGAR entry in the main manifest (`quickstart-data-manifest.md` §6, which covers raw filing PDFs — this is the same underlying agency/data family, a different access method: structured XBRL facts instead of PDF documents). Practical guidance: query the live API for a demo, don't bulk-redistribute a copy of the extracted data.
- **Access:** free, no authentication, but SEC requires a declared `User-Agent` (blocks default/missing ones) and caps requests at 10/sec — see [SEC's developer FAQ](https://www.sec.gov/os/webmaster-faq#developers).
- **Docs:** [Accessing EDGAR data](https://www.sec.gov/search-filings/edgar-search-assistance/accessing-edgar-data) · [EDGAR company search](https://www.sec.gov/cgi-bin/browse-edgar) (for confirming a company's current CIK)
- **Shape:** a single JSON object per company/concept; the `units.USD` field is an array of structs (`accn`, `end`, `filed`, `form`, `fp`, `frame`, `fy`, `start`, `val`), not parallel arrays — flattens with `LATERAL VIEW explode(units.USD) AS fact` + dot-access, not `posexplode()`.
- **Live-tested (2026-09-18)** against 7 companies (Apple, IBM, Oracle, Walmart, Target, Ford, Tesla) — see `sql/01_edgar_company_facts.sql` for confirmed gotchas (mixed-case field quoting, a possible response-truncation issue worth verifying per source, and the `CREATE SCHEMASTORE CONTAINER` one-time-only limitation).

---

## 2. 🟢 PokéAPI

- **What it is:** structured game data (Pokémon stats, abilities, moves, types) — a large, well-modeled REST API good for showing nested JSON.
- **License:** BSD-3-Clause for the code/API — [LICENSE.md](https://github.com/PokeAPI/pokeapi/blob/master/LICENSE.md). Fair Use Policy: cache responses, don't load-test it. Pokémon names/characters are Nintendo trademarks — fine for a technical demo, not for anything Zetaris-branded.
- **Access:** no signup, no formal rate limit (removed 2018) but the Fair Use Policy still applies.
- **Docs:** [pokeapi.co/docs/v2](https://pokeapi.co/docs/v2)
- **Shape:** top-level object per Pokémon; `abilities` is `array<struct<is_hidden,slot,ability:struct<name,url>>>` — array-of-structs with one extra level of nesting inside the struct (untested whether Zetaris's dot-access reaches that deep).
- **Not yet live-tested** — see `sql/02_pokeapi.sql`.

## 3. 🟡 Open Food Facts — live single-product API

- **What it is:** the live per-product lookup API, distinct from the bulk CSV/JSONL export already onboarded as a filestore source in `../parquet_csv/` — this demonstrates the single-record REST pattern specifically.
- **License:** ODbL — same as the bulk-export entry in `../parquet_csv/parquet-csv-data-sources.md`. Attribution required, share-alike if redistributing a combined database.
- **Access:** no signup, but requires a custom `User-Agent`; per-endpoint rate limits apply.
- **Docs:** [openfoodfacts.github.io/openfoodfacts-server/api](https://openfoodfacts.github.io/openfoodfacts-server/api/)
- **Shape:** top-level object wrapping a `product` struct; `product.ingredients` is array-of-structs with sparse/optional fields (not every ingredient has the same fields present) — tests Zetaris's tolerance for inconsistent struct shapes across array elements.
- **Not yet live-tested** — see `sql/03_open_food_facts_live.sql`.

## 4. 🟢 Singapore data.gov.sg — PM2.5 real-time API

- **What it is:** national air-quality readings (PM2.5), updated hourly, part of data.gov.sg's real-time API family (same family as weather forecasts, rainfall, tide/temperature readings — this script covers PM2.5 as the first example; others follow the same pattern).
- **License:** Singapore Open Data Licence (SODL) v1.0 — same umbrella license as the pulled-forward data.gov.sg CSV source in `../parquet_csv/`.
- **Access:** no key needed for testing (5 requests/minute unauthenticated, same platform-wide limit as the initiate/poll-download API).
- **Docs:** [guide.data.gov.sg/developer-guide/real-time-apis](https://guide.data.gov.sg/developer-guide/real-time-apis)
- **Shape:** top-level object; the array-of-structs field (`data.items`) is nested one level under a non-array `data` wrapper (not at the top level like EDGAR/PokéAPI), and each item's per-region breakdown is a *fixed* struct, not an array — a genuinely different shape class from every other source in this package.
- **Not yet live-tested** — see `sql/04_singapore_pm25.sql`.

## 5. 🟢 NASA NeoWs (Near Earth Object Web Service)

- **What it is:** structured asteroid/near-Earth-object data — this script uses `/neo/browse` (a flat, paginated catalog) rather than `/neo/rest/v1/feed` (whose response is keyed by date string, a shape LATERAL VIEW explode() isn't built for).
- **License:** NASA content is a U.S. federal government work, public domain (17 U.S.C. §105).
- **Access:** `DEMO_KEY` works with no signup (30 req/hour, 50/day/IP); a free `api.data.gov` key raises this to 1,000 req/hour.
- **Docs:** [api.nasa.gov](https://api.nasa.gov/)
- **Shape:** top-level object; `near_earth_objects` is array-of-structs, deeply nested (3 levels for `estimated_diameter.kilometers.estimated_diameter_min`), plus a *nested array-within-array* (`close_approach_data`) requiring either array-indexing or a second `explode()`.
- **Not yet live-tested** — see `sql/05_nasa_neows.sql`.

## 6. 🟢 NASA DONKI (Space Weather) — ⚠️ high risk

- **What it is:** Coronal Mass Ejection (CME) space-weather events, queryable by date range.
- **License:** same NASA public-domain basis as NeoWs.
- **Access:** same `api.data.gov` key system as NeoWs.
- **Docs:** [api.nasa.gov](https://api.nasa.gov/) (DONKI section)
- **Shape:** ⚠️ **top-level JSON array**, not an object — every other confirmed or scripted source in this package returns a top-level object. Whether `CREATE LIGHTNING REST TABLE` can register a table from a bare array response at all is unverified — this is the first thing to test, before the flattening logic.
- **Not yet live-tested** — see `sql/06_nasa_donki.sql`.

## 7. 🟢/🟡 Eurostat REST API — ⚠️ high risk, likely drop candidate

- **What it is:** EU statistical data (e.g. unemployment rate, HICP inflation) via a fully public SDMX/REST API.
- **License:** Eurostat's copyright policy is generally understood to align with CC-BY 4.0 — the policy page itself is worth reading directly, not independently confirmed as a hard match.
- **Access:** no key, no registration, CORS-enabled.
- **Docs:** [Eurostat API Statistics guide](https://wikis.ec.europa.eu/display/EUROSTATHELP/API+Statistics+-+data+query)
- **Shape:** ⚠️ **JSON-stat 2.0** — a sparse, multi-dimensional array format (not row-oriented JSON at all). Values are addressed by a computed flat offset key across every dimension, decoded against separate `dimension` metadata. No array-of-structs anywhere to `explode()`. The script only exposes dimension metadata as a view; decoding actual data values into rows is unsolved and may not be feasible via plain SQL.
- **Not yet live-tested; investigation also didn't find a dimension-code combination that returned populated values** (one dataset tried turned out to be discontinued) — see `sql/07_eurostat.sql`.

## 8. 🟢 Statistics Canada Web Data Service (WDS)

- **What it is:** `getChangedCubeList` — a discovery endpoint listing which StatCan datasets ("cubes") recently published new data.
- **License:** Statistics Canada Open Licence — same permissive family as OGL-Canada 2.0; don't combine with other sources to re-identify individuals.
- **Access:** no key or registration, 50 req/sec system-wide / 25/sec per IP.
- **Docs:** [statcan.gc.ca/en/developers/wds/user-guide](https://www.statcan.gc.ca/en/developers/wds/user-guide)
- **Shape:** top-level object wrapping a **plain, flat array-of-structs** (`object: [{productId, releaseTime, responseStatusCode}, ...]`) — the simplest shape found across every source investigated in this pass. Good smoke test if a more complex source is failing.
- **Not yet live-tested** — see `sql/08_statcan_wds.sql`.

## 9. 🟢 Australian Bureau of Statistics (ABS) Data API — ⚠️ high risk, likely drop candidate

- **What it is:** Australian economic/statistical data (this example: CPI) via ABS's SDMX-based Data API.
- **License:** CC-BY 3.0 Australia by default (the older 3.0 port, not 4.0 — same caveat already known from the main manifest).
- **Access:** no API key required.
- **Docs:** [ABS Data API user guide](https://www.abs.gov.au/statistics/application-programming-interfaces-apis/data-api-user-guide/using-api)
- **Shape:** ⚠️ **SDMX-JSON 2.0.0** (data-message format) — same risk class as Eurostat but with an extra layer: `dataSets[0].series` is keyed by a colon-separated dimension-index tuple, and each series' `observations` is *itself* keyed by a further time-index. Confirmed via a real (not guessed) query during investigation — a naive dimension-key guess 404'd, but the broad `all` query returned real, correctly-shaped SDMX-JSON (~2.4 MB for the whole CPI dataflow). No array-of-structs to `explode()`; same "metadata-only view, data decoding unsolved" treatment as Eurostat.
- **Not yet live-tested** — see `sql/09_abs_data_api.sql`.

---

**See also:** `HOWTO.md` for the Zetaris REST onboarding walkthrough (including the full JSON-shape taxonomy from this investigation pass), `../parquet_csv/` for the filestore-table pattern, and the main [Zetaris Quick-Start Data Sources](../../quickstart-data-manifest.md) guide for everything else.
