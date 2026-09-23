# Zetaris SQL Companion: Tips, Tricks, and Limitations

**Status:** 🟡 Draft — first pass assembled from confirmed, live-tested findings in this repo's `open_data/rest_apis/` and `open_data/parquet_csv/` packages, plus the USL User Guide. section 1-7 (REST/Parquet/SchemaStore/VDM) reflect things that have actually been run against a live Zetaris instance. section 8 (USL) is written from the USL User Guide alone and has **not yet been live-tested against this repo's sources** — live verification of section 8 is tracked separately in [`docs/plans/usl-simple-advanced-build-plan.md`](../plans/usl-simple-advanced-build-plan.md), not in this document; section 10 below explains why the split.

This is a working reference, not a tutorial, and it is a **companion to the Zetaris SQL Guide and SQL Manual**, not a replacement for either — it exists to record the gap between what those documents say and what a live instance actually does, indexed by the same topics they cover. Each item names the source script/doc it came from so a claim can be re-verified rather than taken on faith. Where a Kbase page is silent or disagrees with live behavior, live behavior (as recorded in `open_data/*/HOWTO.md` and the `sql/*.sql` headers) wins — that disagreement is exactly what's worth writing down here.

**Why this lives in `docs/guides/`, not `docs/plans/`:** `docs/plans/` is for plans to build or improve something in this repo (see `docs/plans/FUTURES.md` and its `recipes/`). This document isn't a plan — it's a reference someone consults *while writing SQL*, the way they'd consult the Kbase itself. The plan for *validating* the USL section below lives in `docs/plans/usl-simple-advanced-build-plan.md`, exactly where a plan belongs; its findings feed back into section 8 here once confirmed.

---

## Table of contents

0. [Companion map — this guide vs. the Zetaris Kbase](#0-companion-map--this-guide-vs-the-zetaris-kbase)
1. [The two onboarding patterns this repo has proven](#1-the-two-onboarding-patterns-this-repo-has-proven)
2. [REST tables: the shape you must plan for before writing SQL](#2-rest-tables-the-shape-you-must-plan-for-before-writing-sql)
3. [Decoding dynamic-key ("map-shaped") JSON](#3-decoding-dynamic-key-map-shaped-json)
4. [Self-joins against `UNION ALL`-of-`explode()` views](#4-self-joins-against-union-all-of-explode-views-use-window-functions)
5. [Operational limitations (confirmed live)](#5-operational-limitations-confirmed-live-not-documentation-guesses)
6. [Verifying data — the non-negotiable discipline](#6-verifying-data--the-non-negotiable-discipline)
7. [Virtual Data Marts (VDM) — the SQL-free consumption layer](#7-virtual-data-marts-vdm--the-sql-free-consumption-layer-and-where-usl-changes-this)
8. [The Unified Semantic Layer (USL)](#8-the-unified-semantic-layer-usl-a-scriptable-alternativesuccessor-to-vdm)
9. [Open questions to close before validating this guide](#9-open-questions-to-close-before-validating-this-guide)
10. [Related documents in this repo](#10-related-documents-in-this-repo)

---

## 0. Companion map — this guide vs. the Zetaris Kbase

Read this guide's sections *alongside* the linked Kbase page, not instead of it — the Kbase has the authoritative syntax and options list; this guide has the parts that only showed up under live testing (quirks, undocumented behavior, confirmed workarounds). Kbase page titles below are exactly as they appear in the "Using Zetaris" nav (checked 2026-09-23).

| This guide | Zetaris Kbase page(s) | What the Kbase covers that this guide doesn't |
|---|---|---|
| section 1 (onboarding, `CREATE LIGHTNING DATABASE`) | [Zetaris SQL Guide](https://kbase.zetaris.com/knowledge/sql-guide) → "Connection and Registration Statements"; [Data source overview](https://kbase.zetaris.com/knowledge/connect) | Full statement grammar, the complete list of supported file formats/connection types |
| section 2-4 (REST/JSON shapes, quoting, window functions) | [Zetaris SQL Guide](https://kbase.zetaris.com/knowledge/sql-guide) → "Pipeline and View Statements"; [Zetaris SQL Manual](https://kbase.zetaris.com/knowledge/sql-manual) | `CREATE LIGHTNING REST TABLE`/`CREATE SCHEMASTORE VIEW` grammar reference; the Manual's own worked examples (source for the confirmed `CACHE TABLE` syntax used in section 5) |
| section 5 (`CACHE TABLE`, `DROP`/`SHOW`, rate limits) | [Zetaris SQL Guide](https://kbase.zetaris.com/knowledge/sql-guide) → "Auxiliary Statements" (`SHOW CACHE TABLES` is listed here with no worked example — see section 5's own note on why that matters) | The statement list itself; this guide adds what actually happens when you run them |
| section 6 (verifying data) | [SQL Editor](https://kbase.zetaris.com/knowledge/sql-editor-overview), [How to Save and Re-use SQL](https://kbase.zetaris.com/knowledge/how-to-save-and-re-use-sql), [Data Catalog Overview](https://kbase.zetaris.com/knowledge/data-catalog-overview) | The SQL Editor's UI mechanics, result-grid/pagination basics |
| section 7 (Virtual Data Mart) | [Virtual Data Mart Overview](https://kbase.zetaris.com/knowledge/virtual-data-mart-overview), [Processes for Automation: Virtual Data Mart creation / deletion](https://kbase.zetaris.com/knowledge/processes-for-automation-virtual-data-mart-creation-/-deletion), [Virtual Pipeline Guide](https://kbase.zetaris.com/knowledge/virtual-pipeline-guide) | The click-through build/delete steps in full, with screenshots |
| section 8 (USL) | **No dedicated page found in the Kbase's "Using Zetaris" index as of 2026-09-23** — checked the full nav (Data Catalog, Data Lineage, Data Quality, File System, Query Builder, SQL Editor, User Management, Virtual Data Pipeline, Virtual Data Mart, Query Director; no "Unified Semantic Layer" or "Data Product" entry) and the SQL Guide's statement list (no `ACTIVATE`/`COMPILE USL`/`MATERIALIZE USL` anywhere in it). The supplied "Unified Semantic Layer (USL) — User Guide" is, as far as this repo has found, the only documentation for this feature right now. | — (this is the gap; see section 8's own header note) |
| Adjacent: Data Quality outside USL | [Data Quality & Exception Management - Technical implementation](https://kbase.zetaris.com/knowledge/data-quality-exception-management-technical-implementation) | The platform's general DQ mechanism — worth comparing against USL's own DQ rules (section 8.2) to see whether USL's DQ is the same subsystem exposed through the USL model, or a separate one; not yet checked |

**If a future pass finds the real USL Kbase page** (a product update, a search-engine hit, a support ticket response), replace the "No dedicated page found" row above with the real link and re-check every USL claim in section 8 against it — right now section 8 is single-sourced from one PDF/markdown guide, which is thinner evidence than everything else in this document.

---

## 1. The two onboarding patterns this repo has proven

*Kbase: [SQL Guide → Connection and Registration Statements](https://kbase.zetaris.com/knowledge/sql-guide), [Data source overview](https://kbase.zetaris.com/knowledge/connect).*

| Data shape | DDL entry point | Where |
|---|---|---|
| File-based (Parquet/CSV, S3 or S3-compatible) | `CREATE LIGHTNING FILESTORE TABLE ... FROM <db> FORMAT <fmt> OPTIONS (PATH ..., ...)` | [`open_data/parquet_csv/HOWTO.md`](../../open_data/parquet_csv/HOWTO.md) |
| REST/JSON API | `CREATE LIGHTNING REST TABLE ... FROM <db> REQUEST(endpoint ..., method ..., response_type "json", ...) HEADER (...) BODY (...)` + `CREATE SCHEMASTORE VIEW` to flatten it | [`open_data/rest_apis/HOWTO.md`](../../open_data/rest_apis/HOWTO.md) |

Both patterns share one prerequisite that earlier drafts of this repo got wrong and had to correct after live testing: **`CREATE LIGHTNING DATABASE <name> DESCRIBE BY "<text>"` must be run once, before the first table that references `<name>` in its `FROM` clause.** It is not just a label — a `FROM` referencing an unregistered name fails outright.

```sql
CREATE LIGHTNING DATABASE <logical_datasource_name> DESCRIBE BY "<short description>";
```

**`DESCRIBE BY` only accepts a restricted character set** — letters, digits, spaces, and `_ . - ,`. Parentheses, slashes, and colons are rejected before the statement even reaches the endpoint (`"Description is invalid, it must be alphanumeric including the _ (underscore), . (dot), - (hyphen) and , (comma) character"`). Confirmed live 2026-09-21 on `company_dns`'s registration. Write `"SIC reference data - division, major group"`, not `"SIC reference data (division/major group)"`.

---

## 2. REST tables: the shape you must plan for before writing SQL

`CREATE LIGHTNING REST TABLE` registers a raw JSON response as a table; `CREATE SCHEMASTORE VIEW` flattens it. What you write for the flattening step depends entirely on the JSON shape, confirmed across 8+ live sources:

1. **Top-level object, array-of-structs field(s)** (EDGAR, PokéAPI, Open Food Facts, NASA NeoWs) — `LATERAL VIEW explode(<array_field>) AS fact` then plain dot-access, `fact.val`. This nests arbitrarily deep (PokéAPI's `ability.ability.name`, two levels deep, confirmed working).
2. **Array-of-structs nested under a non-array wrapper key** (Singapore PM2.5, `data.items`) — same `explode()`, just applied one level deeper.
3. **Top-level JSON array, no wrapping object** (NASA DONKI) — whether `CREATE LIGHTNING REST TABLE` accepts this at all is the first thing to check; don't assume.
4. **Flat struct, no array anywhere** (Open Food Facts `product.nutriments`) — plain dot-access all the way down, **no `explode()`**. Don't reach for `explode()` reflexively; check whether the node is actually an array first.
5. **Dynamic-key ("map-shaped") object** (Eurostat/ABS SDMX-JSON, `company_dns`'s SIC lookup) — see section 3 below; this is its own technique, not a variant of #1.

A **parallel-arrays** shape (`times: [...]` / `values: [...]` meant to be read pairwise) hasn't been hit yet but would need `posexplode()` + positional indexing, not a plain `explode()`.

**Confirm the actual shape with `curl` before writing the `SELECT`.** Every failure case in this repo where a field "should" exist but didn't (Singapore's PM2.5 `national` field) traces back to assuming a plausible-sounding field existed instead of checking a real response.

### Identifier quoting

- **Mixed-case/camelCase JSON keys** need backticks: `` `entityName` ``, not bare or lowercased.
- **Reserved words** as field names need backticks even if not mixed-case: `` fact.`start` ``.
- **Hyphens in a key** need backticks for a different reason — unquoted, a hyphen parses as subtraction: `` product.nutriments.`energy-kcal_100g` ``.

General rule: any JSON key with a character a bare SQL identifier can't use (mixed case, reserved word, hyphen, space) needs backticks.

### Numeric-looking fields that are actually strings

Zetaris's schema inference follows the JSON type as written. A quoted numeric value in the source JSON (`"kilometers": "47112732.928149391"`) infers as STRING, and sorting/comparing it does **lexicographic string comparison** — `"9000000.1"` sorts before `"47112732.9"` because `'9' > '4'`. This fails silently, no error, just a wrong answer. Confirmed on NASA NeoWs (`miss_distance.kilometers` is a quoted string; sibling fields like `estimated_diameter_min` are real numbers in the same response). **Fix: `CAST(... AS DOUBLE)` in the view's own `SELECT`**, once, rather than remembering to cast at every downstream query.

---

## 3. Decoding dynamic-key ("map-shaped") JSON

JSON-stat/SDMX formats (Eurostat, ABS) and some REST APIs (`company_dns`'s SIC lookup) return their payload as an object keyed by a computed offset or code (`{"168": 11.8, "169": 11.5}`), not an array-of-structs. There's nothing to `explode()` directly — Spark's schema inference turns this into a STRUCT with one field per observed key, not a MAP.

- **Low risk — a handful of known keys:** backtick-quoted dot-access on the specific key, e.g. `` value.`522` ``. No `explode()` needed.
- **Higher risk, confirmed working — decode the whole object into rows:** round-trip it through JSON text with an explicit target schema to force the STRUCT into a MAP, then explode that:
  ```sql
  from_json(to_json(data.sics), 'map<string, struct<description:string, division:string, ...>>')
  ```
  then `LATERAL VIEW explode(...) AS sic_code, sic_val`.

**Critical gotcha, confirmed on Eurostat:** apply this coercion to **every** dynamic-key object you explode in the same query, not just the first one you notice. The first attempt at Eurostat's decode applied it to `value` but exploded `dimension.time.category.index` (also dynamic-key) without it — result: `DATATYPE_MISMATCH` on the second `explode()`. The `value` coercion itself raised no error, proving the technique works once applied consistently everywhere it's needed.

`to_json`/`from_json` are standard Spark SQL, not Zetaris-specific.

### A JSON-stat source returning empty isn't necessarily "no data"

Eurostat doesn't error on an invalid dimension code — it silently returns an empty category index for that dimension, and therefore an empty top-level `value`. This looks identical to "genuinely no data for this combination." Before concluding there's no data, check `dimension.<name>.category.index` for each filter dimension — an empty list means the code is invalid for that dataset, not that data doesn't exist.

---

## 4. Self-joins against `UNION ALL`-of-`explode()` views: use window functions

**Error:** `MISSING_ATTRIBUTES.RESOLVED_ATTRIBUTE_APPEAR_IN_OPERATION`

**Trigger:** referencing the same view — when that view is a `UNION ALL` of `explode()`-based views — more than once in one query: an explicit self-join, a `WHERE x IN (SELECT ... FROM same_view)`, or a scalar `HAVING x = (SELECT ... FROM same_view)`. Confirmed on both Open Food Facts (explicit self-join) and StatCan WDS (`IN` and `HAVING` subquery forms) — this is a class of failure, not a one-off.

**Fix — rewrite as a single-pass window function:**
```sql
SELECT key, val
FROM (
    SELECT key, val, ROW_NUMBER() OVER (PARTITION BY key ORDER BY val DESC) AS rn
    FROM some_view
) ranked
WHERE rn = 1;
```
A plain `COUNT(*) OVER (PARTITION BY key)` covers "does this group meet a count threshold" the same way. Standard ANSI/Spark SQL — reach for this pattern by default any time a "top row per group" question comes up against a `UNION ALL`/`explode()` view, rather than discovering the error first.

---

## 5. Operational limitations (confirmed live, not documentation guesses)

*Kbase: [SQL Guide → Auxiliary Statements](https://kbase.zetaris.com/knowledge/sql-guide) (lists `SHOW CACHE TABLES`; `CACHE TABLE`/`UNCACHE TABLE` themselves are documented in the [Zetaris SQL Manual](https://kbase.zetaris.com/knowledge/sql-manual), not the newer SQL Guide — cross-check both when a statement seems to be missing from one).*

- **`CREATE SCHEMASTORE CONTAINER` has no `IF NOT EXISTS`.** Runs exactly once per name; a second run against an existing name is a parse exception. Comment the line out on re-runs.
- **`SCHEMASTORE CONTAINER` has no removal path at all**, SQL or GUI. Treat it as permanent.
- **A `CREATE LIGHTNING REST TABLE` re-issues its HTTP request on every query that touches it** — directly, or through a view built on it — not just once at `CREATE` time. Confirmed on NASA NeoWs: an early `SELECT` worked, a later ordinary `SELECT` failed with the source API's own `429`, because it re-fetched. Running a full script's create + views + example queries can burn through a strict rate limit partway through.
  - **Fix, confirmed ~40x speedup (company_dns, 2026-09-21):** `CACHE TABLE <db>.<raw_table>;` right after creating the raw table. 49.7s uncached `SELECT COUNT(*)` → stable ~1.2s cached. Release with `UNCACHE TABLE <same_name>;` when done.
  - **Known gaps in `CACHE TABLE`, filed with Zetaris engineering, not solvable from this side:** no configurable TTL or storage tier (a cache has been observed to silently expire); `SHOW CACHE TABLES` reports nothing even when a cache is independently proven active — don't rely on it, time a query before/after instead.
- **No confirmed way to send a raw JSON POST body.** Every script here uses an empty `BODY()` with `http_encoding "URLENCODED"`. Confirmed blocking: StatCan's `getCubeMetadata` needs `Content-Type: application/json` and 415s on form-encoded. If a source needs a real JSON body, check for an untested `http_encoding "JSON"` before assuming the pattern here works.
- **Removing a REST or filestore source's underlying registration has no reliable SQL path.** `DROP VIEW` is the only teardown statement confirmed to work reliably. `DROP TABLE` against a Lightning-registered table is inconsistent (works for some sources, fails with an internal catalog error for others, same statement). `DROP DATASOURCE` doesn't reliably remove a `CREATE LIGHTNING DATABASE` registration either — it's meant for JDBC `CREATE DATASOURCE` sources. **The only confirmed removal path is the Data Explorer GUI's "File Source & API" panel.**
- **Row counts can be under-reported**, independent of source-API behavior. Observed: a results grid showing 10 rows on page 1 while the footer correctly said `Total Count: 11`; separately, a 7-way `UNION ALL` view where the footer itself reported 6, dropping one company. **Filed as a tracked platform issue with Zetaris engineering (2026-09-22).** Always independently verify row counts against the source (`curl`/`jq`, see section 6) before trusting a Zetaris-reported count — but don't assume every discrepancy is this bug either; one "low count" case (Apple's `us-gaap:Revenues`, 11 rows) turned out to be a true reflection of the upstream data, matched exactly by direct `curl`.
- **HTTP 502 has (at least) two distinct, confirmed causes** — don't treat every 502 the same:
  - **Rate limiting** (Singapore PM2.5): the connector likely issues more than one HTTP request per visible SQL statement (schema introspection, a Data Explorer preview fetch, a retry), tripping a source's real burst limit even though only one statement was run. Fix: wait ~30s and retry; don't add headers the API doesn't need.
  - **Cold-start** (`company_dns`, reproduced 5x): a serverless/scale-to-zero backend 502s on the first request after idle, succeeds on immediate retry. If the cold instance is hit on a later `SELECT` rather than `CREATE TABLE` (remember: re-fetches every query), it surfaces instead as a client-side `java.sql.SQLException: ... TTransportException`, sometimes `"Multiple exceptions were thrown (3), ..."` — don't assume this wrapped exception means a structural/schema problem; check whether an immediate retry (after a warm-up ping) succeeds first.

---

## 6. Verifying data — the non-negotiable discipline

*Kbase: [SQL Editor overview](https://kbase.zetaris.com/knowledge/sql-editor-overview), [How to Save and Re-use SQL](https://kbase.zetaris.com/knowledge/how-to-save-and-re-use-sql), [Data Catalog Overview](https://kbase.zetaris.com/knowledge/data-catalog-overview).*

For every REST or filestore table:

1. `SELECT COUNT(*) FROM <container_or_db>.<table>;`
2. Independently hit the same source directly (`curl` + `jq` for REST; an S3 bucket listing for filestore) and compare.
3. If Zetaris's count is lower, don't assume it's a source-data quirk — but don't assume it's a Zetaris bug either. Check both before trusting the table (section 5's row-count entry has a confirmed example of each direction).

For filestore/date-partitioned sources specifically, re-run the bucket-listing command from the script's header comment shortly before you need the source — a `PATH` can silently stop matching anything when a new release replaces an old one.

---

## 7. Virtual Data Marts (VDM) — the SQL-free consumption layer, and where USL changes this

*Kbase: [Virtual Data Mart Overview](https://kbase.zetaris.com/knowledge/virtual-data-mart-overview), [Processes for Automation: Virtual Data Mart creation / deletion](https://kbase.zetaris.com/knowledge/processes-for-automation-virtual-data-mart-creation-/-deletion), [Virtual Pipeline Guide](https://kbase.zetaris.com/knowledge/virtual-pipeline-guide).*

A **Virtual Data Mart** sits above raw tables/views as a consumption-facing, drag-and-drop layer (`docs/plans/edgar-sic-enrichment-plan.md` section 5.2). Confirmed by checking the SQL Guide's full statement list, the legacy SQL Manual, and the Virtual Pipeline Guide: **VDMs have no SQL surface at all** — create/update/delete is 100% GUI (drag tables onto a canvas, click Save). This is a real gap: unlike everything else in this document, a VDM cannot be scripted, version-controlled, or reproduced from a `.sql` file.

**Querying a table once it's inside a VDM** is undocumented in the Zetaris Kbase (checked the VDM Overview, the "Processes for Automation" page, and Query Director's page — none say). Confirmed live (2026-09-21): the reference is a **flat 2-part path, `<mart_name>.<table_name>`** — the mart drops the original `SCHEMASTORE CONTAINER` prefix entirely, using whichever "Virtual Table" alias the canvas shows for that node:
```sql
SELECT * FROM companies_mart.all_companies_profile_table;   -- correct
-- NOT companies_mart.edgar.all_companies_profile_table
```
If a table was renamed on the way into the mart, query it by the renamed alias.

**This is exactly the gap the Unified Semantic Layer (USL) closes** — see section 8. Where a VDM's model, relationships, and materialization state exist only as GUI clicks, a USL's equivalent concepts (table definitions, FK relationships, activation queries, DQ rules, and materialization) are all expressible as `CREATE TABLE` DDL and companion SQL statements, runnable from a script and re-creatable from source.

---

## 8. The Unified Semantic Layer (USL): a scriptable alternative/successor to VDM

*Source: the "Unified Semantic Layer (USL) — User Guide" (supplied separately, not yet checked into this repo). Kbase: **no dedicated page found as of 2026-09-23** — see section 0's companion-map table for exactly what was checked. This section has not yet been live-tested against this repo's REST/Parquet sources. Treat every claim below as "per the guide," not "confirmed live," until someone runs it — that live run is tracked in [`docs/plans/usl-simple-advanced-build-plan.md`](../plans/usl-simple-advanced-build-plan.md), and its worked example is [`open_data/usl/`](../../open_data/usl/), built specifically to test the claims in this section against the EDGAR+SIC data already onboarded via REST (`open_data/rest_apis/sql/10_company_dns_sic.sql`, `sql/11_edgar_company_profiles.sql`).*

### 8.1 Why this matters for this repo specifically

Every REST/Parquet source in this repo ends the same way: raw table → `SCHEMASTORE VIEW` → (optionally) dragged into a GUI-only VDM with no SQL trail. USL's lifecycle covers the same ground but keeps the whole thing — including the final consumption layer — in DDL:

```text
Design (DDL)  →  Compile & Deploy  →  Activate (blue)  →  Query
                                            │
                                            ├─→  Data Quality rules → valid / invalid records → export
                                            └─→  Materialize (purple) → fast queries on large tables
```

Concretely, a USL table's `ACTIVATE ... AS SELECT` clause can be exactly the `CREATE SCHEMASTORE VIEW ... AS SELECT` query this repo already writes for every REST source — pointed at a raw Lightning REST/Filestore table instead of a bare data source:

```sql
-- What this repo does today (SchemaStore):
CREATE SCHEMASTORE VIEW sic_codes_table WITH CONTAINER company_dns AS
SELECT sic_code, sic_val.description AS description, ...
FROM company_dns.sic_codes_raw
LATERAL VIEW explode(from_json(to_json(data.sics), 'map<string, struct<...>>')) AS sic_code, sic_val;

-- The USL equivalent shape:
CREATE TABLE sic_code (
  sic_code           varchar(4) NOT NULL PRIMARY KEY,
  description        varchar(200),
  division           varchar(1),
  division_desc      varchar(200),
  major_group        varchar(2),
  major_group_desc   varchar(200),
  industry_group     varchar(3),
  industry_group_desc varchar(200)
);
-- then, after COMPILE USL DEPLOY:
ACTIVATE USL TABLE lightning.metastore.company_dns.sic_usl.sic_code AS
SELECT sic_code, sic_val.description AS description, ...
FROM company_dns.sic_codes_raw
LATERAL VIEW explode(from_json(to_json(data.sics), 'map<string, struct<...>>')) AS sic_code, sic_val;
```

The `LATERAL VIEW explode()` + dynamic-key coercion technique from section 3 is unaffected — a USL activation query is still an ordinary `SELECT`, so every JSON-shape lesson in section 2-section 4 applies unchanged. **USL doesn't replace the flattening work; it replaces the destination the flattened result lands in** — a schema-validated, describable, relatable, DQ-checkable, materializable table instead of a bare view.

### 8.2 What USL adds beyond a SchemaStore view

| Capability | SchemaStore view (today) | USL table |
|---|---|---|
| Column-level types/constraints | Not modeled — a view just has inferred output columns | `PRIMARY KEY`, `UNIQUE`, `FOREIGN KEY ... REFERENCES` (with `ON DELETE`/`ON UPDATE`), `NOT NULL`, `CHECK` — all in the `CREATE TABLE` DDL |
| Schema validation on activation | None — a view's `SELECT` just runs | `ACTIVATE` checks the query's result schema against the table definition and reports a mismatch inline |
| Relationships between tables | Implicit (a manual `JOIN` in a downstream query, e.g. `edgar.*_profile_table` joining `company_dns.sic_codes_table`) | Explicit FK, drawn on the ERD canvas, generates a DQ rule automatically |
| Data quality | None built in — this repo's own "self-consistency check" queries (e.g. `sql/10`'s query 8, `sql/11`'s query 8) are hand-written ad hoc `SELECT`s | First-class: PK/unique/FK constraints auto-generate DQ rules; custom rules are arbitrary boolean SQL, run via `RUN DQ`, with valid/invalid record sets you can inspect and export |
| Consumption layer with no SQL trail (VDM's problem, section 7) | N/A — a view already has a SQL definition | The USL table **is** the consumption layer, and it's still `CREATE TABLE` DDL — no separate GUI-only object needed |
| Fast queries over a live REST/file source | Would need to build a separate materialization pipeline by hand | `MATERIALIZE USL TABLE ... TO STORAGE (format='parquet'|'delta'|'iceberg', path=...)`, with a LIVE/MATERIALIZED toggle per table (and a global toggle) |
| Documentation | A comment in the `.sql` file | Markdown descriptions at USL/table/column level, stored on the model itself (`UPDATE USL ... SET DESCRIPTION`) |
| Access control | Whatever the underlying data source or container grants | Namespace, USL-instance, and column-level (GRANT/DENY/HIDE/MASKED/ENCRYPTED) — admin-only |

### 8.3 Practical implications for this repo's REST sources

- **`CACHE TABLE` (section 5) and USL `MATERIALIZE` solve overlapping but different problems.** `CACHE TABLE` is an in-session performance workaround for the "every query re-fetches" REST behavior — no format choice, no TTL, undocumented expiry. `MATERIALIZE USL TABLE` is a first-class, persistent export to Parquet/Delta/Iceberg in configured cloud storage, with a `Records: All | Valid Records Only` option gated on having at least one DQ rule. For a rate-limited or cold-start-prone REST source (Singapore PM2.5, `company_dns`), materializing the activated table is very plausibly a more durable fix than `CACHE TABLE` — this is worth live-testing directly, since `CACHE TABLE`'s known gaps (section 5) are exactly the kind of thing a persistent materialized snapshot sidesteps.
- **The `MISSING_ATTRIBUTES` self-join failure (section 4)** is about referencing the same `UNION ALL`/`explode()`-based view twice in one query. A USL activation query has the same shape risk if it's built the same way — the window-function rewrite in section 4 should carry over unchanged, since the underlying query engine (Spark SQL) hasn't changed, just the destination the query's result lands in.
- **This repo's `all_companies_profile_table` pattern (`sql/11`, a 7-way `UNION ALL` across per-company REST tables)** maps naturally onto USL's FK-based model instead of a flat union: a `company` table with one row per company, activated from each company's own `SELECT`, related to a `sic_code` table via `FOREIGN KEY (sic) REFERENCES sic_code(sic_code)`. That relationship then auto-generates a DQ rule for free — replacing `sql/11`'s hand-written query 8 (checking that `sic_description_edgar` and `sic_description_reference` agree) with something closer to the platform's own constraint mechanism, though note a custom DQ rule (not a bare FK) is still what's needed for that specific "do two description strings agree" check, since FK just checks referential existence, not value equality across columns.
- **The `cik` format mismatch called out in `sql/11` caveat 1** (bare integer in the revenue tables vs. zero-padded string in the submissions data) is exactly the kind of thing a USL `FOREIGN KEY` relationship should be defined *after* resolving, not before — the ERD canvas will happily draw a relationship line on a column pair that never actually matches at query time, the same silent-mismatch risk noted for VDM relationships in `sql/11`'s own trailing comment.
- **VDM's dead end (section 7 — no SQL surface, no version control) doesn't need to be solved by working around it any more.** Where the `edgar-sic-enrichment-plan.md` had to accept "the VDM step is unavoidably manual GUI work, not something `sql/01`-style automation can drive," the USL lifecycle is scripted DDL end to end, per the Appendix B command reference — `COMPILE USL`, `ACTIVATE USL TABLE`, `REGISTER DQ`, `MATERIALIZE USL TABLE`, `UPDATE USL ... SET DESCRIPTION` are all real SQL statements, not GUI-only click sequences. **For any future "advanced data product" like the EDGAR+SIC join, USL is very likely the tool to reach for first, not VDM** — but this needs to be confirmed with an actual live run before treating it as settled, the same discipline this whole document otherwise applies everywhere else.

### 8.4 USL quirks worth flagging (per the guide, not yet live-tested)

- **`CREATE NAMESPACE`/`COMPILE USL` both use `IF NOT EXISTS`**, unlike `CREATE SCHEMASTORE CONTAINER` (section 5), which conspicuously does not. Worth confirming this actually behaves idempotently live — this repo has been burned before by a doc claiming an option that didn't hold up live (the `CREATE LIGHTNING DATABASE` prerequisite, section 1).
- **Canvas card positions and FK edits made directly on the ERD canvas are session-only** — per the guide's own note, "relationships that must persist should be defined in the DDL." Treat the canvas as a viewer/scratchpad for relationships, not the source of truth; the DDL is.
- **`Valid Records Only` materialization requires at least one DQ rule already on the table** — if a table has none, the option is unavailable with a warning. Don't assume materialization alone gives you a clean/valid dataset; a DQ rule has to exist first.
- **The example DQ rule syntax includes a self-referencing subquery form** (`cid IN (SELECT id FROM lightning.metastore.crm.ordermart.customer)`) — worth checking this doesn't hit the same `MISSING_ATTRIBUTES` class of error as section 4 if the referenced table is itself a `UNION ALL`/`explode()`-based activation.
- **`REMOVE USL`/`DROP NAMESPACE ... CASCADE` exist as real SQL**, unlike VDM's complete absence of a teardown path and unlike this repo's own REST/filestore sources (section 5, where only `DROP VIEW` is reliable and the underlying Lightning database registration needs the GUI). If confirmed live, USL teardown may be strictly better than what this repo has had to document as a workaround everywhere else.

---

## 9. Open questions to close before validating this guide

These need an actual Zetaris instance, not more reading, to resolve — consistent with how every other "confirmed" claim in this repo was closed out. **This list is now tracked as an executable checklist in [`docs/plans/usl-simple-advanced-build-plan.md`](../plans/usl-simple-advanced-build-plan.md)** rather than duplicated here; treat the items below as the "why," and that plan as the "how/status."

1. **Activate a USL table from one of this repo's existing REST raw tables** (candidate: `company_dns.sic_codes_raw`, its flattening query already confirmed working as a SchemaStore view — see [`open_data/usl/sql/01_simple_sic_usl.sql`](../../open_data/usl/sql/01_simple_sic_usl.sql)) and confirm `ACTIVATE ... AS SELECT` schema-validation actually works against a `LATERAL VIEW explode()` + `from_json`/`to_json` coercion query.
2. **Test whether `CACHE TABLE` and USL `MATERIALIZE` compose or conflict** — does materializing an activated table that wraps an already-cached raw REST table behave any differently than materializing one that doesn't?
3. **Confirm `COMPILE USL IF NOT EXISTS` is actually idempotent live**, the way `CREATE SCHEMASTORE CONTAINER`'s missing `IF NOT EXISTS` was NOT assumed and had to be caught by testing.
4. **Rebuild the EDGAR+SIC "company profile" advanced data product as a USL model** — done as a document in [`open_data/usl/sql/02_advanced_company_profile_usl.sql`](../../open_data/usl/sql/02_advanced_company_profile_usl.sql), kept **alongside**, not instead of, the existing flat `UNION ALL` + manual VDM version (`open_data/rest_apis/sql/11_edgar_company_profiles.sql`) so the two can be run side by side and contrasted. Still needs a live run to record whether the FK-based DQ rules genuinely replace the hand-written self-consistency queries (`sql/10` query 8, `sql/11` query 8) or only partially cover them — see section 8.3's own note on why a bare FK likely isn't sufficient for that specific check.
5. **Confirm the row-count under-reporting bug (section 5) does or doesn't also affect USL table previews/`Preview` panel results** — it was observed in the plain SQL Workspace grid; unclear whether USL's own preview path shares the same rendering code.

---

## 10. Related documents in this repo

| Document | Relationship to this guide |
|---|---|
| [`docs/plans/edgar-sic-enrichment-plan.md`](../plans/edgar-sic-enrichment-plan.md) | The plan that produced `sql/10`/`sql/11` (the REST+SchemaStore+manual-VDM version of the EDGAR+SIC data product). section 9 item 4 above extends this plan's scope; see that plan's own updated status line for the USL follow-on. |
| [`docs/plans/usl-simple-advanced-build-plan.md`](../plans/usl-simple-advanced-build-plan.md) | The plan for building and live-verifying the USL package below — tracks section 9's checklist as actionable, checkable steps. |
| [`open_data/usl/`](../../open_data/usl/) | The actual USL rebuild: a "simple" single-table USL and an "advanced" FK/DQ/materialization USL model of the same EDGAR+SIC data product `sql/10`/`sql/11` already built with REST+SchemaStore+VDM. Kept side by side with those scripts specifically to contrast the two approaches, per explicit request — not a replacement. |
| [`open_data/rest_apis/HOWTO.md`](../../open_data/rest_apis/HOWTO.md), [`open_data/parquet_csv/HOWTO.md`](../../open_data/parquet_csv/HOWTO.md) | The per-package onboarding walkthroughs this guide's section 1-section 6 summarize and cross-link back to; read those for the full, source-by-source detail this guide compresses. |
