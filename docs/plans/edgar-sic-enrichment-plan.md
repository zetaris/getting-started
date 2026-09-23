# Plan: EDGAR SIC Enrichment — Advanced Data Product

**Status:** 🟢 `company_dns` SIC reference source live-tested and confirmed working end to end against Zetaris (§8) — `CREATE LIGHTNING REST TABLE`, `CACHE TABLE` (confirmed ~40x speedup), the `SCHEMASTORE VIEW`, and all 8 analytical queries. Still open: the EDGAR-join "company profile" piece (§6 steps 4-9) and the Virtual Pipeline/VDM follow-up (§5.3-5.4, §6 steps 6-7) — neither has been built or run yet.
**Follow-on (2026-09-23):** this plan's own scope stops at the REST+SchemaStore+manual-VDM version of the data product (section 5.3 found VDM has no SQL surface at all — a real, accepted limitation at the time this plan was written). A *second*, separate mechanism — the Unified Semantic Layer (USL) — has since become available and appears to close that exact gap with scriptable DDL. Rather than rewriting this plan around a primitive that didn't exist when it was written, the USL rebuild of this same data product (same 7 companies, same SIC join) is tracked as its own plan: [`docs/plans/usl-simple-advanced-build-plan.md`](usl-simple-advanced-build-plan.md), building on [`open_data/usl/`](../../open_data/usl/). It is explicitly a **contrast** artifact, kept alongside `sql/10`/`sql/11` and their manual VDM below, not a replacement for either — see that plan's section 1 for why it's separate, and [`docs/guides/zetaris-sql-companion.md`](../guides/zetaris-sql-companion.md) sections 7-8 for the reference material behind the comparison.
**Depends on:** `open_data/rest_apis/sql/01_edgar_company_facts.sql` (live-tested baseline, 7 companies) and the confirmed `CREATE LIGHTNING REST TABLE` + `CREATE SCHEMASTORE VIEW` pattern in `open_data/rest_apis/HOWTO.md`
**Companion docs:** `docs/plans/recipes/01-rest-json-apis.md` (tracked REST recipe this extends, source 10 now marked done), `open_data/rest_apis/rest-api-sources.md` (source 10 catalog entry), `open_data/rest_apis/scripts/warmup_company_dns.ts` (§8), `open_data/rest_apis/sql/10_company_dns_sic.sql` (§8, live-tested)

**Scope note:** this document was originally planning-only research; §8 below records that the SQL script and its warmup companion have since been written, run, and confirmed working end to end against a live Zetaris instance. §1-§7 are the original research; §8 is the follow-up build and its live-test results.

---

## 1. Goal

Turn the existing single-concept EDGAR REST source (`sql/01_edgar_company_facts.sql`, revenue facts only, 7 hardcoded companies) into an **advanced data product**: a company profile that joins EDGAR's own filer data with a real SIC (Standard Industrial Classification) hierarchy — code, description, industry group, major group, and division — so a downstream consumer sees more than a bare 4-digit code next to a revenue number. The mechanism for assembling and serving that joined result should use Zetaris's own composition primitives (Virtual Pipeline, Virtual Data Mart) rather than just stacking more `SCHEMASTORE VIEW`s, per the user's ask to understand those specifically.

## 2. What else EDGAR's REST surface offers (beyond `companyconcept`)

`sql/01` only touches one endpoint family. `data.sec.gov` (JSON, no key, 10 req/sec, requires a declared `User-Agent`) exposes several more, all REST/JSON and all compatible with the already-confirmed `CREATE LIGHTNING REST TABLE` pattern:

| Endpoint | Shape | What it adds |
|---|---|---|
| `data.sec.gov/submissions/CIK{10-digit-cik}.json` | Top-level object, mixed scalar + array-of-structs (`filings.recent`, parallel-arrays-in-a-struct — a shape **not yet seen** in this package, see §2.1) | Full entity metadata: **`sic` and `sicDescription` directly** (confirmed live, see §3), legal name, former names, addresses, tickers/exchanges, fiscal year end, filer category, and the full recent-filings list (accession numbers, forms, dates) |
| `data.sec.gov/api/xbrl/companyconcept/CIK{cik}/us-gaap/{tag}.json` | Array-of-structs (`units.USD`) — the shape `sql/01` already uses | One US-GAAP concept (e.g. `Revenues`) for one company — what's already scripted |
| `data.sec.gov/api/xbrl/companyfacts/CIK{cik}.json` | Nested object-of-objects (`facts.us-gaap.{tag}.units.USD[]`) — every concept for one company in a single call, not one call per tag | All available concepts (Revenues, Assets, NetIncomeLoss, EPS, etc.) in one request — reduces N tag-specific calls to 1, at the cost of a much larger payload (worth checking against the truncation caveat already flagged in `sql/01`, line 32-40) |
| `data.sec.gov/api/xbrl/frames/us-gaap/{tag}/{unit}/CY{year}Q{n}I.json` | Array-of-structs, one row per **company** for a single concept/period | Cross-sectional: "every filer's Revenues for Q2 2026" in one call — a genuinely different axis (company-major, not concept-major) worth its own future recipe entry, not needed for this plan |
| `www.sec.gov/cgi-bin/browse-edgar` (CIK lookup, HTML) | Not REST/JSON | Already used manually (per `sql/01`'s header comment) to confirm a CIK is current; not a REST source itself |

### 2.1 The submissions endpoint's shape is new for this package

`filings.recent` in the submissions payload is **parallel arrays**, not array-of-structs — e.g. `accessionNumber: [...]`, `form: [...]`, `filingDate: [...]` are separate same-length top-level arrays under `filings.recent`, meant to be read pairwise by index. `HOWTO.md` §3 flags this shape ("parallel arrays... hasn't been hit yet in this package") as needing `posexplode()` + positional indexing instead of the `explode()` + dot-access pattern used everywhere else so far. That's real, new risk to account for if the filings list itself is ever flattened — but **out of scope for this plan**, since the only fields needed from `submissions` here are the top-level scalars (`sic`, `sicDescription`, `name`, ...), which need no explode at all.

## 3. How to get SIC codes for each company (confirmed, live-tested during this research pass)

**EDGAR already returns the SIC code and its plain-English description for free**, no join needed — confirmed live against Apple (CIK `0000320193`) on 2026-09-21:

```
GET https://data.sec.gov/submissions/CIK0000320193.json
```
```json
{
  "cik": "0000320193",
  "sic": "3571",
  "sicDescription": "Electronic Computers",
  "name": "Apple Inc.",
  ...
}
```

So per-company SIC lookup is just one more `CREATE LIGHTNING REST TABLE` against an endpoint EDGAR already serves — no new source needed for the code + a one-line description. What EDGAR does **not** provide is the SIC **hierarchy**: which division and major group `3571` rolls up into, or a searchable code list. That's what triggered the search in §4.

## 4. SIC hierarchy source: `company_dns` (found via user pointer, live-tested)

No general-purpose open REST API for the *full* US SIC hierarchy (division → major group → industry group → 4-digit code, with descriptions at every level) turned up in open web/GitHub search — see the rejected candidates in §4.3. The working source came from the user directly: **`https://company-dns.mediumroast.io`**, a "DNS for company information" service (their own — `github.com/miha42-github/company_dns`, Apache 2.0, self-hostable via Docker at `localhost:8000` or usable at the hosted URL above). It responds slowly on a cold request (confirmed during this session — first GET returned empty, a retry ~10s later returned the full page) but is healthy and versioned once warm (`GET /health` → `{"status":"healthy","version":"3.2.0",...}`).

### 4.1 Relevant endpoints (confirmed live, 2026-09-21)

All under `/V3.0/na/sic/...` (a `/V2.0/...` legacy form also exists, no regional prefix):

| Endpoint | Purpose |
|---|---|
| `GET /V3.0/na/sic/code/{sic_code}` | Full hierarchy for one 4-digit code |
| `GET /V3.0/na/sic/description/{sic_desc}` | Search codes by description text |
| `GET /V3.0/na/sic/division/{division_code}` | Division-level lookup (e.g. `D`) |
| `GET /V3.0/na/sic/major/{major_code}` | Major-group-level lookup (2-digit, e.g. `35`) |
| `GET /V3.0/na/sic/industry/{industry_code}` | Industry-group-level lookup (3-digit, e.g. `357`) |

Confirmed response, `GET /V3.0/na/sic/code/3571`:
```json
{
  "code": 200,
  "data": {
    "sics": {
      "3571": {
        "description": "Electronic Computers",
        "division": "D",
        "division_desc": "Manufacturing",
        "major_group": "35",
        "major_group_desc": "Industrial And Commercial Machinery And Computer Equipment",
        "industry_group": "357",
        "industry_group_desc": "Computer And Office Equipment"
      }
    },
    "total": 1
  },
  "dependencies": {"data": {"sicData": "https://github.com/miha42-github/sic4-list", "oshaSICQuery": "https://www.osha.gov/data/sic-search"}}
}
```
That's the full division/major-group/industry-group/code hierarchy with a description at every level — the piece EDGAR itself doesn't provide.

### 4.2 `company_dns` also joins EDGAR + SIC hierarchy in one call, per company

Two endpoints go further and remove the need to join EDGAR and SIC data ourselves at all, for a *specific* company:

- `GET /V3.0/na/company/edgar/firmographics/{cik_no}` — EDGAR submissions data **plus** the full SIC hierarchy (`division`, `divisionDescription`, `majorGroup`, `majorGroupDescription`, `industryGroup`, `industryGroupDescription`) already merged into one response. Confirmed live against Apple's CIK.
- `GET /V3.0/global/company/merged/firmographics/{company_name}` — goes further still: EDGAR + SIC hierarchy + Wikipedia (when available) + geocoding (lat/long, Google Maps/News/Patents/Finance links). Confirmed live for "Apple Inc" (Wikipedia lookup didn't resolve for this exact query string, but EDGAR + SIC + geocoding all populated; ~3.1s total, itemized per-source timing in the response).
- `GET /V3.0/na/companies/edgar/ciks/{company_name}` — fuzzy name → CIK lookup (confirmed: querying `Apple` returns 8 candidates, including Apple Inc.'s `320193`), useful for resolving CIKs programmatically instead of the hardcoded list `sql/01` currently uses.

These are useful, but they're a per-company call each — fine for a handful of companies, less fine as a general reference dataset. §4.4 below found something better for that purpose.

### 4.3 Rejected / weaker candidates (for the record)

- **SEC's own SIC list** (`sec.gov/info/edgar/siccodes.htm`) — exact match to the codes EDGAR filings use, but HTML-only (no REST/JSON), and flat (no division/major-group hierarchy, just a code, an "Office" grouping, and a title).
- **A GitHub JSON mirror of that same SEC list** (`adamfowleruk/mlperf`) — confirmed via fetch to be flat, same ~470 entries, no hierarchy; also a third-party mirror with no freshness guarantee.
- **OSHA's SIC Manual** (`osha.gov/data/sic-manual`) — has the genuine 1987 SIC hierarchy (division → major group → industry group), but is HTML-only, paginated across ~10 division pages and ~83 major-group pages, with no JSON export or API found. (Notably, `company_dns`'s own dependency metadata cites `oshaSICQuery` as a reference alongside its own `sic4-list` GitHub data — so OSHA's structure likely informed `company_dns`'s hierarchy, without requiring us to scrape OSHA directly.)
- **Commercial APIs** (NAICS Association, Dun & Bradstreet, Context.dev, InfobelPRO) — real REST APIs with SIC data, but paid/key-gated, not open.
- **UK `sic-code-api` (Companies House)** — open and REST, but UK SIC 2007 is a different code system from the US SIC 1987 codes EDGAR uses (code `3571` means something else, or nothing, in UK SIC) — not usable as-is.

### 4.4 Better still: `company_dns` can return the *entire* SIC reference set from a single call

Investigated further (2026-09-21) after being asked whether a full bulk pull is possible, rather than one REST call per company. Two things made this discoverable:

1. **The GitHub source for `company_dns` is public** (`github.com/miha42-github/company_dns`, Apache 2.0) and was read directly (`lib/sic.py`) rather than inferred from the API surface alone.
2. Reading `lib/sic.py` shows the `/sic/code/{sic_code}` endpoint's underlying SQL is:
   ```sql
   SELECT sic.division, sic.major_group, sic.industry_group, sic.sic, sic.description, major_groups.description
   FROM sic INNER JOIN major_groups ON major_groups.major_group = sic.major_group
   WHERE sic.sic LIKE ?
   ```
   with the path parameter substituted as `'%' + query_str + '%'` — i.e. every SIC lookup in this API is a SQL `LIKE` **substring** match, not an exact match, and the `sic_code` path parameter has no `minLength` constraint in the OpenAPI schema (unlike `sic_desc`, which requires ≥2 characters). That means the SQL wildcard character itself, `%`, is a valid path parameter — URL-encoded as `%25` — and produces the pattern `LIKE '%%%%'`, which matches every row.

**Confirmed live (2026-09-21):**

| Endpoint (with `%25` wildcard) | Returns | Row count |
|---|---|---|
| `GET /V3.0/na/sic/code/%25` | Every 4-digit SIC code, each with its full division/major-group/industry-group rollup and descriptions at every level (the same shape as §4.1's single-code example, just all of them) | **1,005** (~278 KB JSON) |
| `GET /V3.0/na/sic/division/%25` | All 10 divisions, each with a short `description` and a long `full_description` (multi-paragraph SIC Manual prose) | **10** |
| `GET /V3.0/na/sic/major/%25` | All major groups, each with `description` and parent `division` | **83** |
| `GET /V3.0/na/sic/industry/%25` | All industry groups, each with `description`, parent `division`, and parent `major_group` | **416** |

**Follow-up finding (2026-09-21, same session): only the first of these 4 calls is actually needed.** Asked directly whether the `/sic/code/%25` response alone already contains everything, so the other 3 could be skipped. Checked programmatically, live: every one of the 1,005 `/sic/code/%25` entries was confirmed to have all 7 fields (`description`, `division`, `division_desc`, `major_group`, `major_group_desc`, `industry_group`, `industry_group_desc`) — zero missing across the full set. The distinct division/major-group/industry-group codes and descriptions *derivable* from that one response were then diffed field-by-field against the 3 dedicated endpoints: **same 10/83/416 codes, zero description mismatches.** The only content present on the dedicated endpoints and absent from the single call is `full_description` (the long SIC-Manual paragraph per division) — everything else is fully redundant.

**Conclusion: one call — `GET /V3.0/na/sic/code/%25` — is sufficient** for the EDGAR enrichment use case. `sql/10_company_dns_sic.sql` (§8.2) fetches only this endpoint, and derives division/major-group/industry-group dimension views from it via `SELECT DISTINCT` rather than 3 more REST calls, when a normalized shape is wanted for query convenience. The 3 dedicated endpoints remain useful only if the division's long-form `full_description` text is ever needed — that's a 2nd, optional REST table, not a requirement.

This is a materially better design than either §4.2 (a per-company merged call) or the original plan's proposal to call `company_dns` once per company: **pull the complete SIC reference dataset once, via a single REST call, independent of which or how many companies are being profiled**, and treat it as a small, slow-changing dimension table joined locally against whatever `sic` code each company's own EDGAR `submissions` record already carries (§3) — no per-company dependency on `company_dns` at all, if the join happens against EDGAR's own `sic`/`sicDescription` fields. This also directly serves the caching angle below: a ~278 KB reference table that changes essentially never (SIC 1987 hasn't been revised) is close to the ideal case for finally testing whether `CACHE TABLE` (§17 of the legacy SQL Manual, general-purpose, not REST-specific) actually stops Zetaris re-issuing the underlying HTTP request on every query — the deferred task flagged in `docs/plans/recipes/01-rest-json-apis.md`'s work-item list and `HOWTO.md`'s Troubleshooting/FAQ, previously blocked on NASA's rate limit before the test could even run. `company_dns` has no documented rate limit at all (see §7), so nothing should block actually running this test this time.

Whether the wildcard `%` substring-match behavior is an intentional bulk-export feature or an incidental side effect of how the endpoint is implemented is unknown — it isn't documented anywhere in the site's own explorer or OpenAPI spec, it was found by reading the service's own source. Worth flagging to the user (this is their own service) rather than depending on undocumented behavior silently; see §7.

## 5. Zetaris Kbase research: Virtual Data Pipeline and Virtual Data Mart

Read from `kbase.zetaris.com` (`Using Zetaris` → `Virtual Data Pipeline` and `Virtual Data Mart` sections) to understand the composition layer above `CREATE LIGHTNING REST TABLE` / `CREATE SCHEMASTORE VIEW`, which is all this package has used so far.

### 5.1 Virtual Data Pipeline

A GUI pipeline builder (Zetaris SQL Editor is a separate, text-based path — the two aren't mutually exclusive, see §6.3) for transforming data either for real-time downstream access or as a source→target migration tool. Structure:

- **Pipeline Containers** hold one or more named **Pipelines** (two-level hierarchy, same shape as datasource `database.table`).
- A pipeline is built by dragging **nodes** onto a canvas and connecting them; **Validate** (requires ≥2 nodes) must pass before **Save** is enabled.
- Seven node types (6 usable in the version documented — Notebook wasn't available in 2.1.0):
  - **DataSource Node** — the starting point; a physical/logical/streaming datasource table
  - **Join Node** — join two or more nodes on predicates (join-predicate order matters), with optional filter/orderBy
  - **Projection Node** — column selection/rename, computed ("virtual") columns, optional filter/orderBy — the pipeline-GUI equivalent of a `SELECT ... AS ...`
  - **SQL Table Node** — an alternative entry point: write one raw `SELECT` (not multiple statements) and click "Infer" to derive columns, instead of dragging a datasource table
  - **Simple DQ Node** — data-quality assertions via an integrated Amazon Deequ
  - **DB / File Sink Node** — writes pipeline output out (JDBC target, S3/Azure Blob, NDP File System, or local) — pipeline results otherwise only live in the Lightning backend's `meta_store`
  - **Aggregation Node** — group-by + aggregate functions, with an optional `HAVING`-equivalent and an explicit output-column selection step (a bare aggregation node with no selected output columns returns nothing on preview)

### 5.2 Virtual Data Mart (VDM)

"Virtual (not physical) collections of your data objects, including raw data, pipelines and views, from any combination of differing data sources (file, database, stream)." Built by:
1. Create a VDM (name + optional description).
2. Drag tables from physical/logical data sources onto the VDM's grid.
3. Optionally define relationships between the dragged tables and rename columns/tables.
4. Save.

The stated intent is **dynamic provisioning** — as underlying source data changes shape or location, the VDM absorbs that with minimal disruption to whatever's built on top, and a single VDM can be reused across multiple users/roles. In other words: a VDM is the *consumption-facing* layer, sitting above whatever raw tables, `SCHEMASTORE VIEW`s, or pipeline outputs feed it — closer to a semantic/presentation layer than a transformation step.

### 5.3 SQL surface for Pipelines and VDMs (confirmed, 2026-09-21)

Investigated specifically: can either Virtual Pipelines or Virtual Data Marts be created via SQL script, the same way `sql/01` scripts `CREATE LIGHTNING REST TABLE`/`CREATE SCHEMASTORE VIEW`, or are they GUI-only? Checked three sources: the current **Zetaris SQL Guide** (`kbase.zetaris.com/knowledge/sql-guide`, marked "CURRENTLY IN REVISION" — the authoritative statement list), the legacy **Zetaris SQL Manual** (`kbase.zetaris.com/knowledge/sql-manual`, the older, fuller-prose reference already used to confirm `CACHE TABLE` syntax in §4.4), and the **Virtual Pipeline Guide**'s worked walkthrough (`kbase.zetaris.com/knowledge/virtual-pipeline-guide`, a full illustrated example — customer summary by country, aggregated and sunk to Snowflake).

**Pipelines: partial SQL surface, container-level only.** The SQL Guide's "Pipeline and View Statements" section lists these statement names side by side:
```
ALTER VIEW
CREATE CONTAINER
CREATE PIPELINE CONTAINER
CREATE SCHEMASTORE CONTAINER
CREATE SCHEMASTORE VIEW
DROP VIEW
DROP CONTAINER
DROP PIPELINE CONTAINER
DROP SCHEMASTORE CONTAINER
```
So `CREATE PIPELINE CONTAINER` / `DROP PIPELINE CONTAINER` are real, documented SQL statements — the container-level lifecycle (the same "Pipeline Containers" concept from §5.1's GUI walkthrough) can be scripted, mirroring how `sql/01` already scripts `CREATE SCHEMASTORE CONTAINER`. **But there is no `CREATE PIPELINE` statement, or any SQL equivalent, for defining a pipeline's actual contents** (which nodes, which join predicates, which aggregations). Only worked examples are given for `CREATE SCHEMASTORE CONTAINER`/`CREATE SCHEMASTORE VIEW` — the other statements in the list, including both pipeline-container ones, are named but not demonstrated. This is corroborated by the Virtual Pipeline Guide's entire worked example (Join → Aggregation → Db/File Sink) being described exclusively in click/drag terms ("Drag the Join operator into the work area", "Click the Aggregation object... drag the dimensions... into the Group By dialog box") — no SQL statement appears anywhere in that walkthrough. **Conclusion: a pipeline's container can be scripted, but the pipeline itself (the nodes and their logic) is GUI-only** in the currently-documented product.

**Virtual Data Marts: no SQL surface at all.** `CREATE`/`DROP`/anything **VIRTUAL DATA MART** does not appear anywhere in the SQL Guide's statement list (checked the full "Pipeline and View Statements", "DDL", and "DCL" sections — VDM isn't mentioned in any of them) or in the legacy SQL Manual's 21 sections. The dedicated Kbase page for this — confusingly titled **"Processes for Automation: Virtual Data Mart creation / deletion"** (`kbase.zetaris.com/knowledge/processes-for-automation-virtual-data-mart-creation-/-deletion`) — turns out to mean "the click-through process," not scripted automation: every step (create, update, delete) is described as "Click the plus button," "drag and drop tables... into the middle pane," "Click on 'Save changes'." The sibling page for the older Query Builder-based permanent-view mechanism (`processes-for-automation-table-view-schema-creation-/-deletion`) uses the identical "Processes for Automation" title format for an equally GUI-only click sequence, confirming this is the Kbase's naming convention for "here's how to do X in the UI," not a signal that an API/SQL path exists. **Conclusion: VDMs are GUI-only, full stop, in the currently-documented product** — no automation path was found.

### 5.4 How this maps onto what `sql/01` already does, and onto this plan

`sql/01`'s `CREATE LIGHTNING REST TABLE` + `CREATE SCHEMASTORE VIEW` pattern is the **SQL-editor path** to roughly the same place a `DataSource Node` → `Projection Node` pipeline would get via the GUI: raw ingestion, then a flattened/shaped view. Whether a `SCHEMASTORE VIEW` can itself be dragged in as a Virtual Pipeline `DataSource Node` input hasn't been confirmed live (§7) — Zetaris's own Physical/Logical/Streaming datasource taxonomy makes it plausible, but §5.3 didn't turn up a definitive answer either way, and it needs testing directly rather than being assumed.

Given §5.3's findings, the practical build path for this plan is:
- **The join** of EDGAR facts + the SIC reference tables from §4.4 is a plain SQL `JOIN` between `SCHEMASTORE VIEW`s — the pattern already proven working elsewhere in this package (e.g. Eurostat's dimension-metadata join) — since there is no SQL equivalent for defining pipeline internals. A Virtual Pipeline **Join Node** doing the equivalent join is a GUI-only comparison exercise, not a scriptable alternative; §6 keeps it as an optional, manually-driven step rather than something a future session can script and rerun unattended.
- **The pipeline *container*** (if a Virtual Pipeline is built at all, for the GUI comparison above) can be pre-created via `CREATE PIPELINE CONTAINER` in the same script that sets up the REST tables and schemastore container — one more scriptable prerequisite, same spirit as `sql/01`'s `CREATE SCHEMASTORE CONTAINER` line.
- **The VDM** cannot be scripted at all. It's the natural final step for making the joined "company profile" reusable across users/roles, but building it is necessarily a manual, one-time GUI action for whoever runs this plan against a live instance — not something `sql/01`-style automation can drive. This is worth stating plainly to the user rather than implying a script could someday cover it.

## 6. Proposed build sequence (not executed — for a future session)

1. **New REST source: `company_dns` SIC reference table (§4.4).** Following `sql/01`'s pattern (`CREATE LIGHTNING DATABASE COMPANY_DNS DESCRIBE BY "..."`), register **one REST table**, `sic_codes` (`/V3.0/na/sic/code/%25`) — confirmed sufficient on its own (§4.4's follow-up finding); the 3 sibling endpoints (division/major/industry) aren't called. No `User-Agent` requirement confirmed yet for `company_dns` (unlike SEC's own endpoints) — check during live testing. **Watch for the cold-start latency observed during this research session** (first request empty or a real HTTP 502, resolved on retry within a few seconds) — may need a longer timeout or a warm-up call before the first `CREATE LIGHTNING REST TABLE` attempt.
2. **Cache the reference tables and test whether it works.** Immediately after step 1, run `CACHE TABLE company_dns.sic_codes;` (and the other 3), per the legacy SQL Manual §17 syntax — this is the deferred task from `docs/plans/recipes/01-rest-json-apis.md`, previously blocked by NASA's rate limit before it could be tested at all. These 4 tables are close to an ideal test case: small (largest is ~278 KB/1,005 rows), effectively static, and (per §7) not confirmed to be rate-limited at all. Confirm whether a subsequent `SELECT` against the cached table still re-issues a live HTTP call (checked via `company-dns.mediumroast.io` access logs if available, or indirectly via response latency) — this directly answers the open question flagged in `HOWTO.md`'s Troubleshooting/FAQ.
3. **Flatten each into a `SCHEMASTORE VIEW`**, matching `sql/01`'s style — all 4 responses are flat objects-of-objects (no array-of-structs to `explode()`), so this needs whatever construct turns a dynamic-key JSON object's keys into rows. This is the same "dynamic-key object, not an array" problem already solved for Eurostat/ABS (`sql/07`/`sql/09`) via `from_json(to_json(...), 'map<string,TYPE>')` coercion — worth trying that proven technique here first, rather than assuming a new pattern is needed.
4. **Get each of the 7 existing companies' own `sic` code from EDGAR directly**, not from `company_dns` — either add a `submissions` REST table per company (§3) alongside `sql/01`'s existing `companyconcept` tables, or (simpler, one fewer REST table per company) extend `sql/01`'s existing per-company tables with a `submissions`-sourced `SCHEMASTORE VIEW` carrying just `cik`, `sic`, `name`, and the other top-level scalars called out in §2.1 — no `explode()` needed for those fields.
5. **Join**: EDGAR facts view (`sql/01`) → EDGAR submissions view (step 4, `sic` code) → the `sic_codes` reference view (step 3, full hierarchy), all on `cik`/`sic` as appropriate. This is a plain SQL `JOIN` across `SCHEMASTORE VIEW`s (the pattern already proven elsewhere in this package) — per §5.3, there is no SQL alternative for the join logic itself, only for the pipeline container it could optionally live in.
6. **Optional comparison exercise**: pre-create a pipeline container via `CREATE PIPELINE CONTAINER` (confirmed real SQL, §5.3), then manually (GUI-only, no script) rebuild step 5's join as a Virtual Pipeline **Join Node** dragging the same `SCHEMASTORE VIEW`s in as `DataSource Node`s — this is the one remaining way to test the open question in §5.4/§7 about whether a `SCHEMASTORE VIEW` is a valid pipeline input, since no amount of SQL-only work in this plan can otherwise touch that question.
7. **Build a Virtual Data Mart** ("EDGAR Company Profiles" or similar) over the resulting joined view, giving downstream users/roles one reusable, named entry point. Per §5.3, this step is unavoidably manual GUI work — there's no script to write for it, just a documented click sequence to follow and record.
8. **Verify** using the same discipline as every other source in this package (`HOWTO.md` §5): compare row counts against direct `curl` calls to `data.sec.gov` and `company-dns.mediumroast.io` before trusting the Zetaris-side result (1,005/10/83/416 are the expected reference-table counts per §4.4), and re-confirm the already-flagged EDGAR truncation caveat (`sql/01`, lines 32-40) isn't also present here.
9. **Document findings** the same way `rest-api-sources.md` and `REST-API-HANDOFF.md` already do for every other source — add `company_dns` as source #10 in the catalog, record whatever new gotchas the caching/join/pipeline/VDM steps surface (especially the `CACHE TABLE` result — that answer is worth its own line in `HOWTO.md`'s Troubleshooting/FAQ regardless of which way it comes out), and update `docs/plans/recipes/01-rest-json-apis.md`'s work-item list.

## 7. Open questions / risks for the execution session

- **Whether `CACHE TABLE` actually prevents re-fetching** — the core deferred question this plan's step 2 is finally positioned to test cleanly, given a small, effectively-static, apparently-unthrottled source. Answer this before assuming caching solves the "every query re-hits the source API" behavior documented in `HOWTO.md` for every REST source in this package so far.
- **Whether the `%` wildcard bulk-retrieval behavior (§4.4) is intentional or incidental** — found by reading `company_dns`'s own source (`lib/sic.py`), not from any documented API contract. Worth confirming directly with the user (it's their service) before building a production data product around undocumented behavior — it could change without notice if it's not actually a supported feature.
- **Cold-start behavior of `company_dns`** — is the ~10s initial delay observed in this session a one-off (server sleeping between requests, e.g. a scale-to-zero host) or does it recur per-session? Affects whether `CREATE LIGHTNING REST TABLE`'s own request needs retry logic or a pre-warming step.
- **Whether a `SCHEMASTORE VIEW` can be used as a Virtual Pipeline `DataSource Node` input** — inferred plausible from Zetaris's own Physical/Logical/Streaming datasource taxonomy, but §5.3's research didn't turn up a definitive answer either way; needs to be tested directly rather than assumed, per this package's established practice of proving syntax against reality before trusting it (see `HOWTO.md`'s own framing).
- **Whether `company_dns`'s hosted instance has its own rate limit** — nothing in the site, OpenAPI spec, or the `lib/sic.py`/`lib/edgar.py` source read during this session states one; worth checking response headers during live testing before assuming EDGAR's 10 req/sec is the only constraint in play.
- **License/attribution posture for `company_dns`-sourced SIC data** — Apache 2.0 per the site footer and repo `LICENSE` file, which is permissive, but the underlying `sic4-list` data itself traces back to SEC's own public list (see §4.1's `dependencies.data.sicData` field) — same "don't bulk-redistribute the extracted data" posture already applied to the raw EDGAR entries in `sql/01`'s header and `quickstart-data-manifest.md` §6 likely applies here too, worth confirming explicitly before this becomes a redistributed data product rather than a live-queried one.
- **Self-hosted fallback** — `company_dns` is Dockerizable (`localhost:8000` per the site and its `Dockerfile`), worth keeping as a documented fallback if the hosted instance's cold-start or availability becomes a blocker during live testing.

## 8. Build: warmup script + SQL script (written 2026-09-21, not yet run against Zetaris)

Following on from §7's cold-start and caching open questions, two artifacts were built:

### 8.1 `open_data/rest_apis/scripts/warmup_company_dns.ts`

A small Deno script (no `package.json`/npm install needed — this repo has no existing JS tooling, so a single-file, zero-dependency script matches its established no-build-step convention better than a Node + npm setup would). It:
1. Polls `GET /health` (2s interval, 30s deadline) until the service reports `{"status": "healthy"}`.
2. Once warm, hits §4.4's `sic_codes` bulk `%25` endpoint once, logging latency and comparing the response's row count against the expected minimum found during research (1000). (An earlier version of this script warmed all 4 bulk endpoints — trimmed after §4.4's follow-up finding that only one is actually needed.)
3. Exits 0 if the service became healthy and all 4 endpoints responded (row-count mismatches are logged as warnings, not failures — the SIC list could legitimately grow); exits 1 if the service never became healthy or an endpoint request failed outright.

**Actually run (2026-09-21)**, not just written — real output:
```
[warmup] target: https://company-dns.mediumroast.io
[warmup] attempt 1: /health responded HTTP 502
[warmup] /health OK after 2 attempt(s): {"status":"healthy","version":"3.2.0",...}
[warmup] sic_codes: 1049ms, total=1005 (ok)
[warmup] sic_divisions: 166ms, total=10 (ok)
[warmup] sic_major_groups: 161ms, total=83 (ok)
[warmup] sic_industry_groups: 165ms, total=416 (ok)
[warmup] done -- company_dns should now be warm for sql/10_company_dns_sic.sql.
```
This is a real, reproduced confirmation of the cold-start behavior flagged in §4/§7 (a genuine HTTP 502 on the first attempt, not just the empty-response symptom seen during initial research) — the warmup script's retry loop handled it and the second attempt succeeded cleanly. Usage: `deno run --allow-net --allow-env scripts/warmup_company_dns.ts` from `open_data/rest_apis/`; point at a self-hosted instance with `COMPANY_DNS_BASE_URL=http://localhost:8000` prefixed.

### 8.2 `open_data/rest_apis/sql/10_company_dns_sic.sql`

Covers build-sequence steps 1-5 from §6 (reference table, caching, per-company SIC lookup, and the SQL join) — steps 6-7 (pipeline/VDM) stay out of this file since §5.3 confirmed they have no SQL equivalent. Structure:
- **Step 0-1**: `CREATE LIGHTNING DATABASE COMPANY_DNS`, then **one** bulk reference REST table from §4.4 (`sic_codes_raw`, the `/sic/code/%25` endpoint — confirmed sufficient on its own, the 3 sibling endpoints aren't called), immediately followed by `CACHE TABLE` — the deferred caching test, finally on a source without a confirmed rate limit.
- **Step 3-4**: `CREATE SCHEMASTORE CONTAINER company_dns`, then `sic_codes_table` decoding the one dynamic-key object via the `from_json(to_json(...), 'map<string, struct<...>>')` coercion already proven on Eurostat/ABS (`sql/07`/`sql/09`) — simpler here than Eurostat's case, since it only needs one coercion (no second nested dynamic-key object in the same query) — plus 3 *optional* dimension views (`sic_divisions_table`, `sic_major_groups_table`, `sic_industry_groups_table`) derived from `sic_codes_table` via `SELECT DISTINCT`, at no extra REST-call cost, for anyone who wants a normalized shape.
- **Step 5**: for each of the same 7 companies as `sql/01` (Apple, IBM, Oracle, Walmart, Target, Ford, Tesla), a `submissions`-endpoint REST table (reusing `sql/01`'s `SEC_DATA` database) plus a `SCHEMASTORE VIEW` (reusing its `edgar` container) joining that company's `sic` code against `sic_codes_table` — a per-company "profile" view carrying both EDGAR's own `sicDescription` and the fuller hierarchy from `company_dns`, for a direct sanity-check that the two agree.
- Verification queries (expected row counts per §4.4: 1005/10/83/416), a commented-out cross-company `UNION ALL` view (same "verify each piece first" discipline as `sql/01`), a worked example joining a profile view to `sql/01`'s revenue-facts views, an explicit trailing note pointing at the GUI-only pipeline/VDM follow-up (§5.3), and a `TEARDOWN` block matching `sql/01`'s conventions (`DROP VIEW` + `UNCACHE TABLE`, with a pointer to the Data Explorer for the rest, per `HOWTO.md`).

**Not yet run against Zetaris** — the header is explicit about this (mirroring how `sql/01` originally read before its first live run). The HTTP-level shape of every endpoint it depends on was independently verified live during research (§3, §4.4), but Zetaris-side behavior (whether `CREATE LIGHTNING REST TABLE` accepts these responses, whether the map-coercion technique carries over cleanly, whether `CACHE TABLE` actually stops re-fetching) remains to be confirmed the next time this is run against a real instance — that's the natural next session's work, following the same "run it, see what breaks, fix or document it" loop as every other source in this package.

### 8.3 First live-Zetaris result (2026-09-21): `DESCRIBE BY` character-set bug, fixed

The user began executing this script against their own live Zetaris instance (paste-and-report, since this session has no direct connection to it — see §7's access constraints). The very first statement, `CREATE LIGHTNING DATABASE COMPANY_DNS DESCRIBE BY "..."`, failed:
```
Description is invalid, it must be alphanumeric including the _ (underscore), . (dot), - (hyphen) and , (comma) character
```
The description string used parentheses and a slash (`"company_dns SIC reference data (division/major group/industry group/SIC code)"`) — comparing against every other script in this package already confirmed live-tested (`sql/01`-`sql/09`), none of their `DESCRIBE BY` strings use anything beyond plain words and spaces. **Fixed** in `sql/10_company_dns_sic.sql` by rewriting to `"company_dns SIC reference data - division, major group, industry group, SIC code"` (hyphen and commas, both in the allowed set, instead of parens and a slash). Documented as a new "Known limitations" bullet and Troubleshooting/FAQ entry in `HOWTO.md`, per explicit request — this is a real constraint on every script in this package that uses `DESCRIBE BY`, not something specific to `company_dns`, and nothing before this session had actually hit it (every prior script's description happened to already avoid punctuation). The REST endpoint itself was never contacted — this check runs before Zetaris does anything with the statement, so it says nothing yet about whether the endpoint, the REST table registration, or `CACHE TABLE` actually work; that's still pending the corrected statement being re-run.

### 8.4 Second live-Zetaris result (2026-09-21): `CREATE LIGHTNING REST TABLE` and `SELECT *`/`DESCRIBE` succeeded; `SELECT COUNT(*)` initially hit a cold-start 502, resolved on retry

With the fixed `DESCRIBE BY` string, `CREATE LIGHTNING DATABASE` and `CREATE LIGHTNING REST TABLE sic_codes_raw` both succeeded. `DESCRIBE company_dns.sic_codes_raw` also succeeded, correctly showing the full inferred nested schema (`data: struct<sics:struct<0111:struct<description:string,...>,...>>`) — confirming Spark's schema inference handles this response's width (1,005 dynamically-keyed struct fields) without issue, ruling out the ABS-style "payload too large/complex for transport" theory floated earlier in this session as the cause of anything seen so far.

`SELECT COUNT(*) FROM company_dns.sic_codes_raw` then failed with:
```
Multiple exceptions were thrown (3), first java.sql.SQLException: org.apache.thrift.transport.TTransportException
```
Investigated by isolating variables: the user's own `curl` against the identical URL succeeded cleanly (full 278 KB response, all 1,005 codes) — ruling out a genuine API-side problem — and Zetaris's own error detail, fetched next, turned out to be a plain `HTTP 502` from `company-dns.mediumroast.io` itself, encountered live during the `SELECT`'s own HTTP fetch (not at `CREATE` time — consistent with "a REST table re-fetches on every query," already documented in `HOWTO.md`). This is the exact cold-start signature the warmup script (§8.1) was built to catch — re-running `scripts/warmup_company_dns.ts` immediately before retrying **confirmed the fix**: `SELECT COUNT(*)` then succeeded, returning `1` (correct — the raw REST table is one row, the whole JSON response as a single nested object; 1,005 only appears after `sic_codes_table`'s `LATERAL VIEW explode()`, not yet built at this point).

**Conclusion: the `TTransportException` was cold-start timing, not a structural/size problem** — the "(3)" in the error reflects a connection pool retrying the same failing request across a few pooled connections, all hitting the same momentarily-cold backend. Documented as a new Troubleshooting/FAQ entry in `HOWTO.md`, distinguishing this cause from Singapore PM2.5's rate-limit-driven 502 (already documented) and noting the specific `TTransportException` wrapping as a new nuance.

**One open performance observation, not yet explained:** Zetaris's own UI reported `Query Time: 49.685s` for the successful `SELECT COUNT(*)`, alongside `Transport Time: 43ms` — the HTTP leg itself was fast once the backend was warm, but total query time was very high for a count on a single row. Resolved by §8.5 below.

### 8.5 Third live-Zetaris result (2026-09-21): `CACHE TABLE` confirmed working — ~40x speedup

Also resolves §8.4's open performance observation. Ran `CACHE TABLE company_dns.sic_codes_raw;` immediately after the successful (warm) `SELECT COUNT(*)` in §8.4, then re-ran the identical query. Result: `Query Time` dropped from `49.685s` (uncached, live HTTP round-trip to `company_dns` dominating) to a **stable ~1.2s**, confirmed across repeated runs by the user.

**This is the first confirmed case in this entire package of `CACHE TABLE` actually stopping the "a Lightning REST table re-fetches on every query" behavior** documented in `HOWTO.md`'s "Known limitations" since `sql/05_nasa_neows.sql` (2026-09-19) — every earlier attempt to test this was blocked by a source-side rate limit (NASA's shared `DEMO_KEY`) before the test itself could run. `company_dns` had no such constraint (§7), which is exactly what made this test possible here. Documented in `HOWTO.md`'s Troubleshooting/FAQ (upgrading the existing "suggested workaround, not yet confirmed" language to confirmed) and in `docs/plans/recipes/01-rest-json-apis.md`'s work-item list (marked done).

**Also checked and documented (in response to a direct question about `CACHE TABLE`'s syntax options):** the Zetaris SQL Manual (§17) documents only the bare form — `CACHE TABLE <name>;` / `UNCACHE TABLE <name>;` — no `LAZY` keyword, no storage-level `OPTIONS(...)`, no `AS <query>` form, unlike standard Spark SQL's fuller `CACHE TABLE` grammar. So the statement already used is the complete, unconfigurable form, not a shorthand for something more tunable. Also found: the kbase's "Product Feature Videos" section names a second, distinct feature, **"Adaptive Cache"** (alongside "Explicit Caching," which is what `CACHE TABLE`/`UNCACHE TABLE` are called there) — both pages are video-only with no written spec, so Adaptive Cache's mechanics, trigger conditions, and whether it's SQL-invoked at all remain unconfirmed and out of scope for this plan; flagged as a genuine open question rather than investigated further.

**Still open, not yet measured:** whether caching the raw table (`sic_codes_raw`) also speeds up a `SCHEMASTORE VIEW` built on top of it (`sic_codes_table`, not yet created at this point in the session) — the ~40x improvement above was measured on the raw table only. Test this the same way once the view exists: time a `SELECT` against `company_dns.sic_codes_table` before and after `CACHE TABLE company_dns.sic_codes_raw;`, rather than assuming the speedup propagates through the `LATERAL VIEW explode(...)` layer.

### 8.6 Fourth live-Zetaris result (2026-09-21): full script confirmed — view, and all 8 analytical queries, working post-cache

Asked to produce a complete, focused SQL script for `company_dns` "just like the other examples" — reviewed `sql/08_statcan_wds.sql` as the house-style reference (header/caveat block structure, `STEP N` comment banners, numbered example-query section with rationale comments, `TEARDOWN` block) and rewrote `sql/10_company_dns_sic.sql` to match it exactly, scoped to the `company_dns` SIC reference source on its own — the speculative per-company EDGAR-join content from the original draft (§6 steps 4-5) was removed from this file to keep it single-source, consistent with how `sql/02`-`sql/09` are each scoped to one source; that join is still planned (§6, §7) but deferred to a future script rather than left half-built here.

The script's `STEP 2` (SCHEMASTORE CONTAINER + the `sic_codes_table` view, decoding `data.sics` via the same `from_json(to_json(...), 'map<string, STRUCT<...>>')` coercion already proven on Eurostat/ABS) and all 8 analytical queries — overview counts (query 1, expect 1005/10/83/416), per-division and per-major-group breakdowns (queries 2-3), industry-group diversity per division (query 4), two description-search examples ("Computer", "software" — queries 5-6), a `ROW_NUMBER()` "one representative SIC code per division" window function (query 7), and a data-quality self-consistency check expecting zero rows back (query 8) — **were all run and confirmed working**, post-cache. `sql/10_company_dns_sic.sql`'s header, `rest-api-sources.md`'s source 10 entry, and `docs/plans/recipes/01-rest-json-apis.md`'s work-item list have all been updated to reflect this as fully live-tested, matching the confirmation level of `sql/01`-`sql/09`.

**What this plan has now fully delivered, end to end against a live Zetaris instance:** a working, cached, queryable SIC hierarchy reference table — build-sequence steps 1-3 from §6, in full. **What's still open** (§6 steps 4-9, unchanged from earlier in this document): joining this table against each EDGAR company's own `sic` field to build per-company "profile" views, the optional Virtual Pipeline Join Node comparison, and the Virtual Data Mart — all deferred to a follow-up session, not started.

### 8.7 Row-count caveat resolved, and `sql/11_edgar_company_profiles.sql` written (2026-09-21)

**EDGAR truncation caveat resolved.** Before building the new script, the user independently verified `sql/01`'s long-standing "possible truncation bug" (Apple's `us-gaap:Revenues` table returning only 11 rows) with the `curl` command from `HOWTO.md`'s "Verifying data" section — the live SEC API itself also returned exactly 11, and Zetaris's own `SELECT COUNT(*)` matched it. **Confirmed: not a Zetaris defect** — the upstream tag genuinely has that little data for Apple (likely a tag switch around the 2018 revenue-recognition standard change). `sql/01`'s header, `HOWTO.md`'s Troubleshooting/FAQ, and the recipe's work-item list were all updated to close this out. Separately, the user also found and reported a Zetaris results-grid rendering issue (a page showing 10 rows while the footer correctly reported `Total Count: 11`/`1 of 2` pages) to Zetaris engineering directly — noted in `HOWTO.md` as a known UI quirk, not investigated further per the user's own call.

**`sql/11_edgar_company_profiles.sql` written** — build-sequence steps 4-5 from §6 (per-company EDGAR `submissions` data joined against `company_dns.sic_codes_table`), plus query 4 additionally joining back to `sql/01`'s revenue-fact tables for a combined profile+financials view (the actual payoff the plan set out to demonstrate). Structure, matching house style: 7 `submissions` REST tables + 7 per-company profile views (reusing the existing `SEC_DATA` database and `edgar` container — both already stood up by `sql/01`'s Steps 0-1, confirmed present on this instance) + one cross-company `UNION ALL` view + 8 analytical queries + a manual Virtual Data Mart walkthrough (§6 step 7, requested explicitly — see below) + teardown.

Two syntax choices worth flagging for whoever runs this next:
- **Query 4 uses comma-joins** (`FROM a, (SELECT ...) f`), not `CROSS JOIN` or `JOIN ... ON TRUE` — neither appears in Zetaris's documented `join_type` grammar (`INNER | (LEFT|RIGHT) SEMI | (LEFT|RIGHT|FULL) [OUTER] | [LEFT] ANTI`), while the comma-join form is explicitly documented ("Joining multiple data sources," SQL Manual §3). Safe here because both sides of every pair are guaranteed exactly one row.
- **Queries 3 and 6 use `COLLECT_LIST`/`CONCAT_WS`** to aggregate company names into a readable string per group — standard Spark SQL, but not used anywhere else in this package yet, so it's flagged inline as unconfirmed against this specific Zetaris instance rather than assumed to work.

**Virtual Data Mart walkthrough included, per explicit request** — a full manual GUI walkthrough (create the VDM, drag in `all_companies_profile_table` plus optionally the raw revenue tables and `sic_codes_table`, a caveat against auto-relating tables on `cik` given the format mismatch in caveat 1 below, save) is written into the script's trailing comments, matching the kbase's own documented steps from "Processes for Automation: Virtual Data Mart creation / deletion" (§5.3). No SQL exists for this step — confirmed earlier in this plan — so it stays a documented walkthrough, not executable SQL.

**Not yet run against Zetaris** — same honesty convention as every other script before its first live test. Two known risks to watch for specifically: **(1)** the `cik` format mismatch flagged in the script's own caveat 1 — `submissions` returns a zero-padded string, `sql/01`'s revenue tables carry a bare integer (confirmed via the Apple screenshot in this session) — sidestepped by construction (every view is scoped to one hardcoded company, never joined dynamically on `cik`), but worth knowing if extending this pattern; **(2)** the "latest revenue" caveat inherited from `sql/01`'s now-resolved truncation finding — a company's most recent value under the `us-gaap:Revenues` tag specifically may be stale by several years, so query 4's numbers demonstrate the join mechanic, not necessarily current financials.

### 8.8 `sql/11` run successfully; Virtual Data Mart built (§6 step 7 — done); VDM query syntax confirmed (2026-09-21)

**`sql/11_edgar_company_profiles.sql` ran successfully** — all 7 `submissions` REST tables, all 7 profile views, and `all_companies_profile_table` were created without incident (no repeat of the `DESCRIBE BY` or cold-start issues hit earlier, since this script doesn't touch `company_dns` or use a fresh `DESCRIBE BY` string). One open item from this run: `all_companies_profile_table`'s preview showed `Total Count: 6`, not 7 — IBM appears to be missing from the union. Not yet root-caused; flagged to check `SELECT * FROM edgar.ibm_profile_table;` directly (does IBM's own profile view return a row at all — i.e. did its `sic` code fail to match anything in `sic_codes_table`?) and `SELECT COUNT(*) FROM edgar.all_companies_profile_table;` (confirm the 6-vs-7 discrepancy isn't itself a preview-pane artifact, given the unrelated grid-rendering bug already found and reported to Zetaris engineering, sec 8's HOWTO.md note). **Still open — not resolved as of this writing.**

**Virtual Data Mart built by hand, per the plan's §6 step 7 and the walkthrough written into `sql/11`'s trailing comments.** Named `companies_mart`, containing exactly the 8 tables recommended (not more): `edgar.all_companies_profile_table` (the core deliverable), all 7 `edgar.*_revenue_table`s, and `company_dns.sic_codes_table` — matching the "primary + optional, nothing redundant" recommendation (skipping the 7 individual per-company profile views, the raw REST tables, and the 3 derived SIC dimension views, all deliberately left out per that same recommendation). **This is the first confirmed completion of the plan's Virtual Data Mart step, closing out the last fully-manual item from §6.**

**VDM query syntax discovered and confirmed — genuinely new finding, not documented anywhere in the Zetaris Kbase.** Checked the VDM Overview page, "Processes for Automation: Virtual Data Mart creation / deletion," and Query Director's own page (a Spark/Presto engine-routing feature, unrelated despite the similar name) — none of them document how to actually query a table once it's inside a mart. Inferred from the VDM canvas UI (each dragged-in table's card shows a "Virtual Table:" field with just the bare table name, no source container prefix) that the mart likely exposes a flat 2-part reference rather than a 3-part one preserving the original container — **confirmed live**: `SELECT * FROM companies_mart.all_companies_profile_table;` works; the original container prefix (`edgar.`) is dropped entirely once a table is inside a mart. Documented as a new Troubleshooting/FAQ entry in `HOWTO.md`.

### 8.9 Three issues filed with Zetaris engineering (2026-09-22) — noted, not further investigated here

The user has filed formal issues with Zetaris engineering covering three findings from this session, closing them out as tracked platform issues rather than open investigation items on our side:

1. **Rows being dropped/truncated** — covers both the Apple `apple_revenue_table` grid-vs-footer mismatch (§8's HOWTO.md note) and the `all_companies_profile_table` 6-vs-7 (missing IBM) discrepancy from §8.8 — the IBM root cause remains unconfirmed (join failure vs. this same platform-level row-dropping behavior), and is not being pursued further pending the filed issue.
2. **`CACHE TABLE` doesn't accept options for duration or storage location** — confirms and extends this plan's own finding (§8.5/§8.6: only the bare `CACHE TABLE <name>;` form exists, no `LAZY`/`OPTIONS`/`AS` clause) with a concrete symptom: a cache observed to have silently expired back to uncached after some elapsed time, consistent with an unconfigurable default TTL.
3. **`SHOW CACHE TABLES` reports nothing, even for a table independently proven to be cached** (the confirmed ~40x speedup from §8.6 was measured on the same table this was checked against). The statement exists by name in the current SQL Guide but has no worked example anywhere in the docs — now confirmed broken/non-functional in practice, not just under-documented.

All three are documented in `HOWTO.md`'s Troubleshooting/FAQ with this same framing — known, externally tracked issues, not something to keep independently debugging in this repo.
