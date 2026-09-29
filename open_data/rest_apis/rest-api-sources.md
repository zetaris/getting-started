# REST API Data Sources for Zetaris Quick-Starts

A catalog of REST API sources you can point a small Zetaris deployment at directly via `CREATE LIGHTNING REST TABLE` — no file download, the JSON response becomes a queryable table (raw) plus a flattened `SCHEMASTORE` view (tabular). Each entry lists the license, the access requirements, and a docs link. For the SQL syntax pattern, the JSON-shape taxonomy, and troubleshooting, see `HOWTO.md` — it isn't repeated here.

**License key:** Open — use it freely (read the note for any attribution requirement) · Open, with a condition — worth reading before you build on it · Not included — see the note for why

**Script location:** onboarding scripts live in three folders under `sql/`, grouped by whether the source API enforces a rate limit — `sql/rate_limited/`, `sql/non_rate_limited/`, and `sql/known_to_fail/` for the one source that didn't work out. See `HOWTO.md`'s "Source folders" section for what that grouping means for how you run a script.

---

## Quick-reference table

| # | Source | Domain | License | Rate limit | Verification | Script |
|---|---|---|---|---|---|---|
| 1 | SEC EDGAR XBRL Company Facts | Financial/regulatory | Ambiguous | Rate limited | Verified | `sql/rate_limited/01_edgar_company_facts_create.sql` |
| 2 | PokéAPI | Structured game data | Open (BSD-3-Clause) | Not rate limited | Verified | `sql/non_rate_limited/02_pokeapi_create.sql` |
| 3 | Open Food Facts (live API) | Product/nutrition | Open, with a condition (ODbL) | Rate limited | Verified | `sql/rate_limited/03_open_food_facts_live_create.sql` |
| 4 | Singapore data.gov.sg — PM2.5 real-time | Environment | Open (SODL v1.0) | Rate limited | Known to fail | `sql/known_to_fail/04_singapore_pm25_create.sql` |
| 5 | NASA NeoWs (`/neo/browse`) | Astronomy | Open (public domain) | Rate limited | Verified | `sql/rate_limited/05_nasa_neows_create.sql` |
| 6 | NASA DONKI (CME) | Space weather | Open (public domain) | Rate limited | Unverified | `sql/rate_limited/06_nasa_donki_create.sql` |
| 7 | Eurostat REST API | Statistics | Open, with a condition | Not rate limited | Verified | `sql/non_rate_limited/07_eurostat_create.sql` |
| 8 | Statistics Canada WDS | Statistics | Open (StatCan Open Licence) | Rate limited | Verified | `sql/rate_limited/08_statcan_wds_create.sql` |
| 9 | Australian ABS Data API | Statistics | Open (CC-BY 3.0 AU) | Not rate limited | Verified | `sql/non_rate_limited/09_abs_data_api_create.sql` |
| 10 | company_dns — SIC hierarchy reference | Industry classification | Apache 2.0 (traces to SEC's public SIC list) | Not rate limited | Verified | `sql/non_rate_limited/10_company_dns_sic_create.sql` |
| 11 | EDGAR company profiles (SIC-enriched) | Financial/regulatory | Ambiguous (see source 1) | Rate limited | Verified | `sql/rate_limited/11_edgar_company_profiles_create.sql` |

"Verified" means the create script's `CREATE`/`CACHE` statements and its matching select script's example queries have been run successfully against a live Zetaris instance. "Unverified" means the script is written and believed correct but hasn't been run live yet. "Known to fail" means it was run and hit a blocking issue — kept as a documented example, not a live source to build on.

---

## 1. SEC EDGAR XBRL Company Facts API — license: ambiguous

- **What it is:** structured financial facts (revenue, and other US-GAAP tags) extracted from public companies' own XBRL-tagged filings, served as JSON per company/concept via `data.sec.gov/api/xbrl/companyconcept/CIK{10-digit-cik}/us-gaap/{tag}.json`.
- **License:** filings are filer-authored, not government-authored — free API access doesn't automatically mean a copyright/license grant over the extracted facts. Query the live API for a demo; don't bulk-redistribute a copy of the extracted data.
- **Access:** free, no authentication, but SEC requires a declared `User-Agent` (blocks default/missing ones) and caps requests at 10/sec — see [SEC's developer FAQ](https://www.sec.gov/os/webmaster-faq#developers).
- **Docs:** [Accessing EDGAR data](https://www.sec.gov/search-filings/edgar-search-assistance/accessing-edgar-data) · [EDGAR company search](https://www.sec.gov/cgi-bin/browse-edgar) (for confirming a company's current CIK)

## 2. PokéAPI — license: open (BSD-3-Clause)

- **What it is:** structured game data (Pokémon stats, abilities, moves, types) — a large, well-modeled REST API good for showing nested JSON.
- **License:** BSD-3-Clause for the code/API — [LICENSE.md](https://github.com/PokeAPI/pokeapi/blob/master/LICENSE.md). Fair Use Policy: cache responses, don't load-test it. Pokémon names/characters are Nintendo trademarks — fine for a technical demo, not for anything Zetaris-branded.
- **Access:** no signup, no formal rate limit (removed 2018) but the Fair Use Policy still applies.
- **Docs:** [pokeapi.co/docs/v2](https://pokeapi.co/docs/v2)

## 3. Open Food Facts — live single-product API — license: open, with a condition (ODbL)

- **What it is:** the live per-product lookup API, distinct from the bulk CSV/JSONL export onboarded as a filestore source in `../parquet_csv/` — this demonstrates the single-record REST pattern specifically.
- **License:** ODbL — same as the bulk-export entry in `../parquet_csv/parquet-csv-data-sources.md`. Attribution required, share-alike if redistributing a combined database.
- **Access:** no signup, but requires a custom `User-Agent`; per-endpoint rate limits apply.
- **Docs:** [openfoodfacts.github.io/openfoodfacts-server/api](https://openfoodfacts.github.io/openfoodfacts-server/api/)

## 4. Singapore data.gov.sg — PM2.5 real-time API — license: open (SODL v1.0) — known to fail

- **What it is:** national air-quality readings (PM2.5), updated hourly, part of data.gov.sg's real-time API family (same family as weather forecasts, rainfall, tide/temperature readings).
- **License:** Singapore Open Data Licence (SODL) v1.0 — same umbrella license as the pulled-forward data.gov.sg CSV source in `../parquet_csv/`.
- **Access:** no key or headers needed for testing. Documented as 5 requests/minute, but the real burst limit is tighter in practice.
- **Docs:** [guide.data.gov.sg/developer-guide/real-time-apis](https://guide.data.gov.sg/developer-guide/real-time-apis)
- **Why it's here rather than in the main script set:** `CREATE LIGHTNING REST TABLE` returned an HTTP 502 on the first statement run against it. Kept as a documented, reproducible example rather than dropped — see `sql/known_to_fail/ISSUE.md` for the full investigation.

## 5. NASA NeoWs (Near Earth Object Web Service) — license: open (public domain)

- **What it is:** structured asteroid/near-Earth-object data — this script uses `/neo/browse` (a flat, paginated catalog) rather than `/neo/rest/v1/feed` (whose response is keyed by date string, a shape `explode()` isn't built for).
- **License:** NASA content is a U.S. federal government work, public domain (17 U.S.C. §105).
- **Access:** `DEMO_KEY` works with no signup (30 req/hour, 50/day per IP); a free `api.data.gov` key raises this to 1,000 req/hour. Shares its quota with NASA DONKI (source 6) if both are used against `DEMO_KEY` in the same session.
- **Docs:** [api.nasa.gov](https://api.nasa.gov/)

## 6. NASA DONKI (Space Weather) — license: open (public domain) — unverified

- **What it is:** Coronal Mass Ejection (CME) space-weather events, queryable by date range.
- **License:** same NASA public-domain basis as NeoWs.
- **Access:** same `api.data.gov` key system as NeoWs, same shared quota.
- **Docs:** [api.nasa.gov](https://api.nasa.gov/) (DONKI section)
- **Open question:** the response is a top-level JSON array rather than an object, unlike every other source in this catalog — whether `CREATE LIGHTNING REST TABLE` accepts that shape at all hasn't been confirmed against a live instance yet. See the create script's own caveats.

## 7. Eurostat REST API — license: open, with a condition

- **What it is:** EU statistical data (e.g. unemployment rate, HICP inflation) via a fully public SDMX/REST API.
- **License:** Eurostat's copyright policy is generally understood to align with CC-BY 4.0 — the policy page itself is worth reading directly, not independently confirmed as a hard match.
- **Access:** no key, no registration, CORS-enabled.
- **Docs:** [Eurostat API Statistics guide](https://wikis.ec.europa.eu/display/EUROSTATHELP/API+Statistics+-+data+query)

## 8. Statistics Canada Web Data Service (WDS) — license: open (StatCan Open Licence)

- **What it is:** `getChangedCubeList` — a discovery endpoint listing which StatCan datasets ("cubes") recently published new data.
- **License:** Statistics Canada Open Licence — same permissive family as OGL-Canada 2.0; don't combine with other sources to re-identify individuals.
- **Access:** no key or registration, rate-limited at 50 req/sec system-wide / 25/sec per IP.
- **Docs:** [statcan.gc.ca/en/developers/wds/user-guide](https://www.statcan.gc.ca/en/developers/wds/user-guide)

## 9. Australian Bureau of Statistics (ABS) Data API — license: open (CC-BY 3.0 AU)

- **What it is:** Australian economic/statistical data (this example: CPI) via ABS's SDMX-based Data API.
- **License:** CC-BY 3.0 Australia by default — the older 3.0 port, not 4.0. Still genuinely permissive; some individual datasets may specify 4.0 instead.
- **Access:** no API key required.
- **Docs:** [ABS Data API user guide](https://www.abs.gov.au/statistics/application-programming-interfaces-apis/data-api-user-guide/using-api)

## 10. company_dns — SIC hierarchy reference — license: Apache 2.0

- **What it is:** a company-firmographics/industry-classification service (`github.com/miha42-github/company_dns`) that, among other things, serves the full US Standard Industrial Classification (SIC, 1987 revision) hierarchy — 4-digit code, description, and its division/major-group/industry-group rollup — as REST/JSON.
- **License:** the service itself is Apache 2.0. Its SIC data traces back to SEC's own public SIC list — query live, don't bulk-redistribute the extracted data.
- **Access:** hosted instance at `https://company-dns.mediumroast.io`, no key or signup; also self-hostable via Docker at `http://localhost:8000`. No documented rate limit.
- **Docs:** interactive API reference at `/docs` on the hosted instance; OpenAPI spec at `/openapi.json`.

## 11. EDGAR company profiles — SIC-enriched — license: ambiguous (see source 1)

- **What it is:** a company profile that joins SEC EDGAR's Submissions API (name, SIC code) against `company_dns`'s SIC hierarchy (source 10) to produce a readable industry profile per company — division, major group, and industry group, not just a bare 4-digit code. This is the "advanced data product" built on top of sources 1 and 10; see `sql/rate_limited/11_edgar_company_profiles_create.sql` for the hard dependency on both.
- **License:** same posture as source 1 (filer-authored EDGAR content) and source 10 (SIC data traces to SEC's public list) — query live, don't bulk-redistribute.
- **Access:** same as source 1 — 10 req/sec, declared `User-Agent` required.
- **Docs:** [Submissions API](https://data.sec.gov/submissions/CIK{10-digit-cik}.json)

---

**See also:** `HOWTO.md` for the Zetaris REST onboarding walkthrough, `sql/known_to_fail/` for sources that hit a blocking issue during testing along with their debugging writeups, `../parquet_csv/` for the filestore-table pattern, and [`docs/plans/FUTURES.md`](../../docs/plans/FUTURES.md) plus its `recipes/*.md` files for every other category.
