# REST API Data Sources for Zetaris Quick-Starts

A catalog of REST sources registered with `CREATE LIGHTNING REST TABLE`. Each entry records its licence, access needs, verification status, and documentation. See [`HOWTO.md`](HOWTO.md) for SQL patterns and JSON shapes.

**Licence key:** Open · Open with conditions · Not included or unresolved. Read each source's note before reuse.

**Script location:** onboarding scripts live in four folders under `sql/`, grouped by whether the source API enforces a rate limit — `sql/rate_limited/`, `sql/non_rate_limited/` — plus `sql/known_to_fail/` for the one source that didn't work out and `sql/deprecated/` for a script a newer one replaced. See `HOWTO.md`'s "Source folders" section for what that grouping means for how you run a script.

---

## Quick-reference table

| # | Source | Domain | Licence | Rate limit | Verification | Script |
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
| 10 | company_dns — SIC hierarchy reference (V3 only) | Industry classification | Apache 2.0 (traces to SEC's public SIC list) | — | **Deprecated**, replaced by 12 | `sql/deprecated/10_company_dns_sic_create.sql` |
| 11 | EDGAR company profiles (SIC-enriched) | Financial/regulatory | Ambiguous (see source 1) | Rate limited | Verified | `sql/rate_limited/11_edgar_company_profiles_create.sql` |
| 12 | company_dns — US SIC hierarchy, V3 and V4 | Industry classification | Apache 2.0 (traces to SEC's public SIC list) | Rate limited | Verified | `sql/rate_limited/12_company_dns_create.sql` |
| 13 | company_dns — EU NACE hierarchy | Industry classification | Open (CC BY 4.0, Eurostat) | Rate limited | Verified | `sql/rate_limited/13_company_dns_eu_nace_create.sql` |
| 14 | company_dns — Japan industry classification | Industry classification | Open (CC BY 4.0, e-Stat) | Rate limited | Verified | `sql/rate_limited/14_company_dns_japan_create.sql` |

"Verified" means the create script's `CREATE`/`CACHE` statements and its matching select script's example queries have been run successfully against a live Zetaris instance. "Unverified" means the script is written and believed correct but hasn't been run live yet. "Deprecated" means a newer script replaced it: it is kept for reference only and must not be run on the same instance as its replacement. "Known to fail" means it was run and hit a blocking issue — kept as a documented example, not a live source to build on.

---

## 1. SEC EDGAR XBRL Company Facts API — license: ambiguous

- **What it is:** company XBRL facts, served per company and US-GAAP tag.
- **Licence:** filings are company-authored; free API access does not grant a data licence. Query live, but do not bulk-redistribute extracted data.
- **Access:** free, no authentication. Send a declared `User-Agent`; limit requests to 10/second. See the [SEC developer FAQ](https://www.sec.gov/os/webmaster-faq#developers).
- **Docs:** [Accessing EDGAR data](https://www.sec.gov/search-filings/edgar-search-assistance/accessing-edgar-data) · [EDGAR company search](https://www.sec.gov/cgi-bin/browse-edgar) (for confirming a company's current CIK)

## 2. PokéAPI — license: open (BSD-3-Clause)

- **What it is:** Pokémon stats, abilities, moves, and types, including nested JSON.
- **Licence:** BSD-3-Clause for the API code. Follow its Fair Use Policy and cache responses. Pokémon names and characters are Nintendo trademarks; this source is for technical demos, not Zetaris-branded material.
- **Access:** no signup or formal rate limit; fair use still applies.
- **Docs:** [pokeapi.co/docs/v2](https://pokeapi.co/docs/v2)

## 3. Open Food Facts — live single-product API — license: open, with a condition (ODbL)

- **What it is:** a live, single-product lookup. The bulk export is a separate filestore source in [`../parquet_csv/parquet-csv-data-sources.md`](../parquet_csv/parquet-csv-data-sources.md).
- **Licence:** ODbL. Attribute the data and share alike when redistributing a combined database.
- **Access:** no signup; send a custom `User-Agent` and observe endpoint rate limits.
- **Docs:** [openfoodfacts.github.io/openfoodfacts-server/api](https://openfoodfacts.github.io/openfoodfacts-server/api/)

## 4. Singapore data.gov.sg — PM2.5 real-time API — license: open (SODL v1.0) — known to fail

- **What it is:** hourly national PM2.5 readings.
- **Licence:** Singapore Open Data Licence (SODL) v1.0, also used by the data.gov.sg CSV source in [`../parquet_csv/`](../parquet_csv/parquet-csv-data-sources.md).
- **Access:** no key or headers. The documented limit is 5 requests/minute; testing hit a tighter burst limit.
- **Docs:** [guide.data.gov.sg/developer-guide/real-time-apis](https://guide.data.gov.sg/developer-guide/real-time-apis)
- **Status:** the first `CREATE LIGHTNING REST TABLE` returned HTTP 502. See the [issue write-up](sql/known_to_fail/ISSUE.md); this source is excluded from the main sequence.

## 5. NASA NeoWs (Near Earth Object Web Service) — license: open (public domain)

- **What it is:** a flat, paginated asteroid catalog from `/neo/browse`; the date-keyed `/neo/rest/v1/feed` uses a different, unsupported shape.
- **Licence:** NASA content is a U.S. federal government work, public domain (17 U.S.C. §105).
- **Access:** `DEMO_KEY` needs no signup (30 requests/hour, 50/day per IP). A free `api.data.gov` key raises this to 1,000/hour. NeoWs and DONKI share the `DEMO_KEY` quota.
- **Docs:** [api.nasa.gov](https://api.nasa.gov/)

## 6. NASA DONKI (Space Weather) — license: open (public domain) — unverified

- **What it is:** Coronal Mass Ejection (CME) space-weather events, queryable by date range.
- **Licence:** same NASA public-domain basis as NeoWs.
- **Access:** the same `api.data.gov` key and shared `DEMO_KEY` quota as NeoWs.
- **Docs:** [api.nasa.gov](https://api.nasa.gov/) (DONKI section)
- **Unverified:** the response is a top-level JSON array. Live registration of that shape has not been confirmed; see the create script's caveats.

## 7. Eurostat REST API — license: open, with a condition

- **What it is:** EU statistics, including unemployment and HICP inflation, through a public SDMX/REST API.
- **Licence:** commonly understood to align with CC-BY 4.0, but this has not been independently confirmed. Read Eurostat's policy before reuse.
- **Access:** no key, no registration, CORS-enabled.
- **Docs:** [Eurostat API Statistics guide](https://wikis.ec.europa.eu/display/EUROSTATHELP/API+Statistics+-+data+query)

## 8. Statistics Canada Web Data Service (WDS) — license: open (StatCan Open Licence)

- **What it is:** `getChangedCubeList`, which lists recently updated Statistics Canada datasets ("cubes").
- **Licence:** Statistics Canada Open Licence. Do not combine the data to re-identify people.
- **Access:** no key; limit requests to 50/second system-wide and 25/second per IP.
- **Docs:** [statcan.gc.ca/en/developers/wds/user-guide](https://www.statcan.gc.ca/en/developers/wds/user-guide)

## 9. Australian Bureau of Statistics (ABS) Data API — license: open (CC-BY 3.0 AU)

- **What it is:** Australian statistics, using CPI as the example, through the ABS SDMX Data API.
- **Licence:** CC-BY 3.0 Australia by default. Individual datasets may use 4.0; check the dataset terms.
- **Access:** no API key required.
- **Docs:** [ABS Data API user guide](https://www.abs.gov.au/statistics/application-programming-interfaces-apis/data-api-user-guide/using-api)

## 10. company_dns — SIC hierarchy reference (V3 only) — license: Apache 2.0 — deprecated

- **Deprecated:** replaced by source 12 (`sql/rate_limited/12_company_dns_create.sql`), which loads the same V3 data under the same names and adds V4. The old scripts are in `sql/deprecated/`. The "no documented rate limit" note below describes the service as it was; it is rate limited now (see source 12).

- **What it is:** REST/JSON for the 1987 U.S. SIC hierarchy: code, description, division, major group, and industry group.
- **Licence:** the service is Apache 2.0. The SIC data traces to the SEC's public list; query live, but do not bulk-redistribute extracted data.
- **Access:** hosted at `https://company-dns.mediumroast.io`, with no key or documented rate limit. It can also be self-hosted at `http://localhost:8000`.
- **Docs:** interactive API reference at `/docs` on the hosted instance; OpenAPI spec at `/openapi.json`.

## 11. EDGAR company profiles — SIC-enriched — license: ambiguous (see source 1)

- **What it is:** a company profile that joins SEC EDGAR's Submissions API (name, SIC code) against `company_dns`'s SIC hierarchy (source 12, formerly source 10) to produce a readable industry profile per company — division, major group, and industry group, not just a bare 4-digit code. This is the "advanced data product" built on top of sources 1 and 12; see `sql/rate_limited/11_edgar_company_profiles_create.sql` for the hard dependency on both.
- **License:** same posture as source 1 (filer-authored EDGAR content) and source 12 (SIC data traces to SEC's public list) — query live, don't bulk-redistribute.
- **Access:** same as source 1 — 10 req/sec, declared `User-Agent` required.
- **Docs:** [Submissions API](https://data.sec.gov/submissions/CIK{10-digit-cik}.json)

## 12. company_dns — US SIC hierarchy, V3 and V4 — license: Apache 2.0 — rate limited

- **What it is:** the same US SIC (1987 revision) hierarchy as source 10, loaded from both versions of the `company_dns` API side by side, as four schemastore views: V3 data and V4 data, each under V3 and V4 column names. V3 returns a dynamic-key object; V4 returns a flat array and renamed the hierarchy levels (V4 `division_desc` is the 2-digit level that V3 calls the major group).
- **License:** the service itself is Apache 2.0. Its SIC data traces back to SEC's own public SIC list — query live, don't bulk-redistribute the extracted data.
- **Access:** V3 at `https://company-dns.mediumroast.io` and V4 at `https://company-dns-staging.mediumroast.io`; no key or signup. Also self-hostable via Docker at `http://localhost:8000`. **Rate limited:** the operator sets the limits, so they differ between deployments; the built-in defaults are 200 requests a minute with a burst of 20 (standard) and 5 a minute with a burst of 1 (strictest). A burst larger than the allowance gets `429` even when the average is low, so spread requests out and cache. The script caches both raw tables for you; see its header and `HOWTO.md` section 0 for the pacing.
- **Docs:** interactive API reference at `/docs` on the hosted instance; OpenAPI spec at `/openapi.json`.

## 13. company_dns — EU NACE hierarchy — license: open (CC BY 4.0) — rate limited

- **What it is:** the EU's NACE industry classification (615 classes under 21 sections, 88 divisions and 272 groups), served by the `company_dns` V4 API at `/V4.0/eu/sic/class/%25`. Same flat-array shape as source 12's V4 endpoint, one view (`company_dns_eu.nace_table`). The counts match NACE Rev. 2, but the response does not state its revision.
- **License:** CC BY 4.0 — [Eurostat copyright notice](https://ec.europa.eu/eurostat/help/copyright-notice). Attribution required: credit Eurostat when you reuse it. The `company_dns` service itself is Apache 2.0.
- **Access:** `https://company-dns-staging.mediumroast.io`; no key or signup. Rate limited, same operator-set tiers as source 12 (and the same service, so leave a few minutes between running scripts 12, 13 and 14).
- **Docs:** as source 12.

## 14. company_dns — Japan industry classification — license: open (CC BY 4.0) — rate limited

- **What it is:** Japan's industry classification (1,460 classes under 20 sections, 99 divisions and 530 groups), served by the `company_dns` V4 API at `/V4.0/japan/sic/industry_group/%25` (the response is class level). Same flat-array shape, one view (`company_dns_japan.japan_table`). Ids are consistent, but some descriptions are shared by more than one id, so group by id, not description. The counts match the 2013 (13th) revision, but the response does not state its revision.
- **License:** CC BY 4.0 — [e-Stat terms of use](https://www.e-stat.go.jp/en/terms-of-use). Attribution required: credit the source when you reuse it. The `company_dns` service itself is Apache 2.0.
- **Access:** `https://company-dns-staging.mediumroast.io`; no key or signup. Rate limited, same operator-set tiers as source 12. The response is about 420 KB, the largest of the three.
- **Docs:** as source 12.

---

**See also:** `HOWTO.md` for the Zetaris REST onboarding walkthrough, `sql/known_to_fail/` for sources that hit a blocking issue during testing along with their debugging writeups, `../parquet_csv/` for the filestore-table pattern, and [`docs/plans/FUTURES.md`](../../docs/plans/FUTURES.md) plus its `recipes/*.md` files for every other category.
