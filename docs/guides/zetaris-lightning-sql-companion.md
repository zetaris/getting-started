# Zetaris SQL Companion: Tips, Tricks, and Limitations

**Status:** Live findings are scoped to the version, fixture and SQL form tested. USL notes from the supplied guide are marked separately.

Use this beside the [Zetaris SQL Guide](https://kbase.zetaris.com/knowledge/sql-guide) and [SQL Manual](https://kbase.zetaris.com/knowledge/sql-manual). Those docs define syntax. This page records useful source patterns, confirmed behaviour and limits for this repo.

## Table of contents

0. [Companion map — this guide vs. the Zetaris Kbase](#0-companion-map--this-guide-vs-the-zetaris-kbase)
1. [The two onboarding patterns this repo has proven](#1-the-two-onboarding-patterns-this-repo-has-proven)
2. [REST tables: the shape you must plan for before writing SQL](#2-rest-tables-the-shape-you-must-plan-for-before-writing-sql)
3. [Decoding dynamic-key ("map-shaped") JSON](#3-decoding-dynamic-key-map-shaped-json)
4. [Self-joins against `UNION ALL`-of-`explode()` views](#4-self-joins-against-union-all-of-explode-views-use-window-functions)
5. [Operational limitations (confirmed live)](#5-operational-limitations-confirmed-live-not-documentation-guesses)
6. [Verifying data](#6-verifying-data--the-non-negotiable-discipline)
7. [Virtual Data Marts (VDM): SQL commands and tested limits](#7-virtual-data-marts-vdm--the-sql-free-consumption-layer-and-where-usl-changes-this)
8. [The Unified Semantic Layer (USL)](#8-the-unified-semantic-layer-usl-a-scriptable-alternativesuccessor-to-vdm)
9. [Open questions](#9-open-questions-to-close-before-validating-this-guide)
10. [Related documents](#10-related-documents-in-this-repo)

---

## 0. Companion map — this guide vs. the Zetaris Kbase

Use the Kbase for full syntax and options. This guide adds repo examples and tested behaviour.

| Topic | Kbase reference | Scope here |
|---|---|---|
| Registration and REST/file tables | [SQL Guide](https://kbase.zetaris.com/knowledge/sql-guide), [Data source overview](https://kbase.zetaris.com/knowledge/connect) | The two patterns and source-specific behaviour |
| REST shapes, views and SQL workarounds | [SQL Guide](https://kbase.zetaris.com/knowledge/sql-guide), [SQL Manual](https://kbase.zetaris.com/knowledge/sql-manual) | JSON decoding, quoting and self-join limits |
| Cache and data checks | [SQL Manual](https://kbase.zetaris.com/knowledge/sql-manual), [SQL Editor overview](https://kbase.zetaris.com/knowledge/sql-editor-overview) | Cache behaviour and independent verification |
| Virtual Data Marts | [Virtual Data Mart overview](https://kbase.zetaris.com/knowledge/virtual-data-mart-overview), [Virtual Pipeline guide](https://kbase.zetaris.com/knowledge/virtual-pipeline-guide) | SQL commands and the tested query path |
| USL and data quality | Supplied USL User Guide | Guide-only claims and the live-tested limits below |

The supplied USL guide is the source used here for USL syntax. The SQL Guide and SQL Manual do not document the `REGISTER DQ` commands described in section 8.6.

---

## 1. The two onboarding patterns this repo has proven

| Data shape | SQL entry point | Walkthrough |
|---|---|---|
| Parquet or CSV on S3/S3-compatible storage | `CREATE LIGHTNING FILESTORE TABLE ... FROM <db> FORMAT <fmt> OPTIONS (PATH ..., ...)` | [Parquet/CSV HOWTO](../../open_data/parquet_csv/HOWTO.md) |
| REST/JSON API | `CREATE LIGHTNING REST TABLE ...` then a `CREATE SCHEMASTORE VIEW` to flatten it | [REST API HOWTO](../../open_data/rest_apis/HOWTO.md) |

Create the logical database before its first table. A `FROM <name>` reference fails if `CREATE LIGHTNING DATABASE <name>` has not run.

```sql
CREATE LIGHTNING DATABASE <logical_datasource_name> DESCRIBE BY "<short description>";
```

`DESCRIBE BY` accepts letters, digits, spaces, `_`, `.`, `-` and `,`. Parentheses, slashes and colons fail validation. For example, use `SIC reference data - division, major group` rather than `SIC reference data (division/major group)`. This was confirmed while registering `company_dns`; see the [REST source guide](../../open_data/rest_apis/HOWTO.md).

---

## 2. REST tables: the shape you must plan for before writing SQL

A REST table exposes the API's JSON response. A SchemaStore view flattens it. Inspect a real response before writing the view.

1. **Top-level object, array-of-structs field(s)** (EDGAR, PokéAPI, Open Food Facts, NASA NeoWs, and `company_dns`'s V4, EU NACE and Japan endpoints, whose `data` is a flat array of objects) — `LATERAL VIEW explode(<array_field>) AS fact` then plain dot-access, `fact.val`. This nests arbitrarily deep (PokéAPI's `ability.ability.name`, two levels deep, confirmed working).
2. **Array-of-structs nested under a non-array wrapper key** (Singapore PM2.5, `data.items`) — same `explode()`, just applied one level deeper.
3. **Top-level JSON array, no wrapping object** (NASA DONKI) — whether `CREATE LIGHTNING REST TABLE` accepts this at all is the first thing to check; don't assume.
4. **Flat struct, no array anywhere** (Open Food Facts `product.nutriments`) — plain dot-access all the way down, **no `explode()`**. Don't reach for `explode()` reflexively; check whether the node is actually an array first.
5. **Dynamic-key ("map-shaped") object** (Eurostat/ABS SDMX-JSON, `company_dns`'s V3 SIC lookup) — see section 3 below; this is its own technique, not a variant of #1.

**One service, two shapes (`company_dns` V3 and V4).** The same 1,005 SIC codes come back as a dynamic-key object from V3 (decode it with the section 3 technique) and as a flat array of eight fields from V4 (a plain `explode(data)`). V4 also **renamed the hierarchy levels**: V3 `division` (letter) is V4 `section_id`, V3 `major_group` (2-digit) is V4 `division_id`, V3 `industry_group` (3-digit) is V4 `group_id`, V3 `sic_code` is V4 `class_id`, and the `_desc` columns follow. A column name can therefore mean a different level in each version (`division_desc`: "Manufacturing" in V3, a 2-digit division label in V4). When two versions of one source must coexist, expose the other version's column names through a second view (the `_compat_` views in `open_data/rest_apis/sql/rate_limited/12_company_dns_create.sql`) rather than renaming in downstream SQL.

For parallel arrays that represent paired values, positional expansion such as `posexplode()` may be needed; this pattern has not been confirmed in this repo.

Use `curl` to inspect the source response before writing SQL. A plausible field name is not evidence that the field exists.

### Identifier quoting

Use backticks for mixed-case keys, reserved words and keys containing punctuation. Examples: `` `entityName` ``, `` fact.`start` `` and `` product.nutriments.`energy-kcal_100g` ``.

### Numeric-looking fields that are actually strings

Zetaris infers the JSON type. A quoted number remains a string, so sorting is lexicographic. Cast it in the view, for example `CAST(... AS DOUBLE)`, before downstream queries. NASA NeoWs returns `miss_distance.kilometers` as a string even though nearby diameter fields are numeric.

---

## 3. Decoding dynamic-key ("map-shaped") JSON

JSON-stat/SDMX formats (Eurostat, ABS) and some REST APIs (`company_dns`'s V3 SIC lookup; its V4 endpoint returns a plain array instead) return their payload as an object keyed by a computed offset or code (`{"168": 11.8, "169": 11.5}`), not an array-of-structs. There's nothing to `explode()` directly — Spark's schema inference turns this into a STRUCT with one field per observed key, not a MAP.

- For a known key, use backtick-quoted dot access, such as `` value.`522` ``.
- To turn the full object into rows, convert it to JSON and parse it with a MAP schema, then explode it:

  `from_json(to_json(data.sics), 'map<string, struct<description:string, division:string, ...>>')`

Apply the conversion to every dynamic-key object you explode in the same query. On Eurostat, converting `value` but not `dimension.time.category.index` caused `DATATYPE_MISMATCH` on the second `explode()`.

### A JSON-stat source returning empty isn't necessarily "no data"

Eurostat can return an empty category index for an invalid dimension code without an error. Check each filter code against `dimension.<name>.category.index` before concluding the dataset has no data.

---

## 4. Self-joins against `UNION ALL`-of-`explode()` views: use window functions

**Error:** `MISSING_ATTRIBUTES.RESOLVED_ATTRIBUTE_APPEAR_IN_OPERATION`.

**Trigger:** referencing the same `UNION ALL`/`explode()` view more than once in a query. This failed with a self-join and with `IN` and `HAVING` subqueries against Open Food Facts and StatCan WDS.

Use one pass with a window function for questions such as “top row per group”:

```sql
SELECT key, val
FROM (
    SELECT key, val, ROW_NUMBER() OVER (PARTITION BY key ORDER BY val DESC) AS rn
    FROM some_view
) ranked
WHERE rn = 1;
```

For a count threshold, use `COUNT(*) OVER (PARTITION BY key)`. This avoids the repeated view reference that triggered the error in the tested examples.

The same error can come from a view *definition* that reads one view several times. On 2.4.3.1 (24 October 2026), a `CREATE SCHEMASTORE VIEW` made of five `UNION ALL` branches over the same view failed with it (Singapore PM2.5's long-format view). To unpivot columns into rows, read the base table once and use `stack()`:

```sql
SELECT item.timestamp AS reading_timestamp, r.region, r.pm25
FROM sg_datagovsg_rest.pm25_readings_20260918
LATERAL VIEW explode(data.items) AS item
LATERAL VIEW stack(2,
    'north', item.readings.pm25_one_hourly.north,
    'south', item.readings.pm25_one_hourly.south
) r AS region, pm25;
```

---

## 5. Operational limitations (confirmed live, not documentation guesses)

Live-check scope on 12 October 2026, Zetaris 2.4.3.1: 96 of 144 SQL command entries were exercised. Ninety-five passed; one passed with a limitation; 48 were not attempted. A pass covers only the tested form and fixture. AUTH checks used a dummy token against a public HTTP response; they do not confirm real OAuth or access to a protected service.

- **SchemaStore containers:** `CREATE SCHEMASTORE CONTAINER` has no `IF NOT EXISTS`; an earlier duplicate-name attempt failed. The 2.4.3.1 check deleted an empty test container through the documented API after confirming `viewCount=0`. It did not test a SQL container-drop command.
- **REST request volume:** A REST table may call its source again for each query. On one `company_dns` table, `CACHE TABLE` reduced a count query from 49.7 seconds to about 1.2 seconds. This result is source-specific. `CACHE TABLE` uses a session cache; this repo has not confirmed a TTL or storage-tier option, and `SHOW CACHE TABLES` has not reliably reported active state. The Data Explorer cache action also behaved differently from SQL caching on two AWS Public Blockchain tables; see the [Parquet/CSV catalog](../../open_data/parquet_csv/parquet-csv-data-sources.md).
- **Filestore updates:** On 2.4.3.1, `UPDATE LIGHTNING FILESTORE TABLE` failed without the original `path` in `OPTIONS` and succeeded with that path. See the [SQL command reference](zetaris-lightning-sql-commands.md).
- **View replacement and cache:** On 2.4.3.1, `CREATE OR REPLACE SCHEMASTORE VIEW` invalidated a test cache. `OFFSITE UNCACHE TABLE` then returned `is not cached`; caching the view again made uncaching succeed. Do not assume view replacement preserves its cache.
- **Table removal:** On 12 October 2026, `DROP LIGHTNING DATABASE TABLE` removed `reason` from a public S3 filestore registration and `ability` from a public PokéAPI REST registration on Zetaris 2.4.3.1. A `SELECT id, name` returned data from `ability` before the drop. `DROP LIGHTNING DATABASE` then removed the test database. These fixtures do not prove removal works for every connector or registration; use Data Explorer's **File Source & API** panel for an unconfirmed object.
- **Source failures:** On 2026-10-31, PUDL registration on the dotted bucket `pudl.catalyst.coop` succeeded with path-style access, Overture Places analytical queries on release `2026-10-21.0` succeeded inside a Manhattan bbox, and Foursquare Places queries on release `2024-11-19` succeeded inside a Manhattan lat/lon window ([PUDL](../../open_data/parquet_csv/sql/03_pudl_create.sql), [Overture](../../open_data/parquet_csv/sql/05_overture_maps_create.sql), [Foursquare](../../open_data/parquet_csv/sql/04_foursquare_places_create.sql)). Ookla's earlier registration HTTP 500 did not reproduce: the 2026 quarter=2 fixed and mobile files were already registered, a new table with the same OPTIONS registered, and Manhattan-window queries on both tables returned rows ([Ookla](../../open_data/parquet_csv/sql/07_ookla_speedtest_create.sql), [earlier issue record](../../open_data/parquet_csv/sql/known_to_fail/ISSUE-07-ookla.md)). GBIF's earlier query-time HTTP 500 did not reproduce: a filtered `LIMIT 10` on the registered 2026-09-01 directory returned 10 rows, and the example queries succeeded against one file of snapshot 2026-10-01 (`occurrence.parquet/004990`, 538,620 rows) ([GBIF](../../open_data/parquet_csv/sql/08_gbif_create.sql)). A successful `CREATE` alone does not confirm a usable table.
- **Rate limits:** `company_dns` V4 is rate limited, and the allowance depends on whether you identify yourself, per the service operator. Callers that identify themselves (a User-Agent of the form `app_name user@domain.tld`) get 6,000 requests a minute (100 a second) with a burst of 600, per address. Callers that do not (no User-Agent, a library default, or a name with no contact) get 600 a minute with a burst of 60, a limit raised for the event; the service default is 5 a minute with a burst of 1. Send a User-Agent of the form `app_name user@domain.tld` on every request (in the create scripts, the `user-agent` header), cache the raw table, and wait 60 seconds after a 429 before retrying that statement; without an identifying User-Agent also space endpoint-calling statements by at least 15 seconds. One statement can trigger several pooled retries. Scripts 12–14 include the cache steps; these limits are operator guidance, not measurements from the SQL command check.
- **HTTP errors:** Singapore PM2.5 returned 502 in the cloud SQL Workspace under source rate limiting. On 2.4.3.1 through the SQL API (24 October 2026), rapid uncached queries against it surfaced the source's own 429 (`REST API call failed: Server returned HTTP response code: 429`), and after `CACHE TABLE` 20 back-to-back queries all succeeded; the original 502 is not yet reconciled ([issue record](../../open_data/rest_apis/sql/known_to_fail/ISSUE.md)). `company_dns` previously returned a cold-start 502 and worked on retry; the incoming recipe record says its new host no longer scales to zero and the warm-up helper has been removed. Check the source and wait before retrying; do not treat all 502s as the same failure.
- **JSON request bodies:** Repo scripts use an empty body with `http_encoding "URLENCODED"`. StatCan's JSON endpoint returned 415 with that form. A working JSON-body form has not been confirmed.
- **Row counts:** Earlier repo runs recorded grid/footer count differences. Compare query results with the source before assuming Zetaris lost rows. Joins can also exclude records: the SIC/EDGAR inner join omitted IBM because its SIC code `3570` was missing from the reference. This is separate from the UI-count observation; see the [USL model checks](../../open_data/usl/usl-sources.md).

---

## 6. Verifying data — the non-negotiable discipline

For each REST or filestore table:

1. Run `SELECT COUNT(*) FROM <container_or_db>.<table>`.
2. Check the same source directly: `curl`/`jq` for REST or a bucket listing for files.
3. Investigate any mismatch before relying on the result. A low count may come from the source, a path or query, or Zetaris.

For versioned files, rerun the listing command in the SQL header before use. A valid `PATH` can stop matching when a source replaces a release.

---

<a id="7-virtual-data-marts-vdm--the-sql-free-consumption-layer-and-where-usl-changes-this"></a>
## 7. Virtual Data Marts (VDM): SQL commands and tested limits

*Kbase: [Virtual Data Mart overview](https://kbase.zetaris.com/knowledge/virtual-data-mart-overview), [Virtual Pipeline guide](https://kbase.zetaris.com/knowledge/virtual-pipeline-guide).*

The SQL command reference documents a native Virtual Data Mart lifecycle. On 12 October 2026, a fixture on Zetaris 2.4.3.1 passed the tested create, add, show, describe, update, rename and drop forms. This corrects the blanket claim that VDMs have no SQL controls. The run does not prove every canvas operation, option or permission has an equivalent SQL command. See [Virtual Data Marts in the SQL command reference](zetaris-lightning-sql-commands.md#17-virtual-data-marts).

The query path for a table added to a mart is a flat two-part name. This was confirmed on 21 September 2026; the mart exposes the virtual table alias without its original container prefix:

```sql
SELECT * FROM companies_mart.all_companies_profile_table;   -- correct
-- NOT companies_mart.edgar.all_companies_profile_table
```

The [USL](#8-the-unified-semantic-layer-usl-a-scriptable-alternativesuccessor-to-vdm) also defines tables and relationships in SQL. The supplied guide describes additional schema, data-quality and materialization features; see sections 8.3–8.6 for what this repo did and did not confirm.

---

## 8. The Unified Semantic Layer (USL): a scriptable alternative/successor to VDM

The examples below use the supplied USL User Guide and the [`open_data/usl/`](../../open_data/usl/) package. See [USL source status](../../open_data/usl/usl-sources.md) and the [archived build record](../plans/archive/usl-build-plan.md). Claims based only on the guide are identified below.

### 8.1 Why this matters for this repo specifically

A SchemaStore view and a USL table can use the same flattening `SELECT`. USL adds a declared table schema and a lifecycle around that query. This example shows the shape; see the package scripts for complete SQL:

```text
Design (DDL)  →  Compile & Deploy  →  Activate (blue)  →  Query
                                            │
                                            ├─→  Data Quality rules → valid / invalid records → export
                                            └─→  Materialize (purple) → fast queries on large tables
```

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

The JSON conversion and `LATERAL VIEW explode()` still do the flattening. USL changes the destination and adds the declared schema; it does not remove that work.

### 8.2 What USL adds beyond a SchemaStore view

The supplied USL guide describes these capabilities. The table is a guide summary, not confirmation of every option.

| Capability | SchemaStore view | USL table |
|---|---|---|
| Types and constraints | Inferred output columns | Declared types, keys and checks |
| Relationships | Written as joins | Foreign keys shown in the ERD |
| Data quality | Separate queries | Constraint-generated and custom rules |
| Materialization | Separate pipeline | Export to configured storage |
| Descriptions and access | SQL comments and source permissions | Model/table/column descriptions and access controls |

### 8.3 Practical implications for this repo's REST sources

- `CACHE TABLE` is a session cache. `MATERIALIZE USL TABLE` is described as a persistent export. The repo has not live-tested materialization or its interaction with a cache.
- A foreign key checks that a referenced value exists. In the EDGAR/SIC fixture, the `sic` rule found IBM's code `3570` missing from the reference list; it does not check whether two description strings match. See [USL source status](../../open_data/usl/usl-sources.md) and the [archived build record](../plans/archive/usl-build-plan.md).
- The current USL example uses zero-padded string `cik` values from submissions. It does not join to revenue tables where `cik` is numeric; normalize that difference before adding such a join.
- Activation queries are ordinary `SELECT` statements. The self-join workaround in section 4 may apply, but the USL-specific case has not been tested.

<a id="84-usl-quirks-worth-flagging-per-the-guide-not-yet-live-tested"></a>
### 8.4 USL quirks and validation limits

Some items below come from the supplied guide; others were checked live on 12 October 2026, Zetaris 2.4.3.1.

- **Model replacement clears activation.** `UPDATE USL ... AS <JSON>` accepted a model containing `activateQuery`, but its next `SELECT` failed with `table(...) is not activated`. Running `ACTIVATE USL TABLE` restored access. The update result alone does not confirm the table remains queryable. See [UPDATE USL](zetaris-lightning-sql-commands.md).
- **Namespace and compile:** `lightning.metastore` must exist before `CREATE NAMESPACE IF NOT EXISTS lightning.metastore.<name>`. The `open_data/usl` create scripts create the parent first (`CREATE NAMESPACE IF NOT EXISTS lightning.metastore;`), then the package namespace. A multi-table `COMPILE USL` worked when sent as one statement over JDBC. These checks were confirmed on 1 October 2026; the SQL Workspace editor and a semicolon-splitting runner did not handle that multi-table form.
- **`IF NOT EXISTS` idempotency:** the supplied guide shows this option for `CREATE NAMESPACE` and `COMPILE USL`. The 2.4.3.1 check did not confirm repeat-run behaviour.
- **Canvas edits:** the supplied guide says card positions and FK edits made on the ERD canvas are session-only; define persistent relationships in DDL.
- **Valid-record materialization:** the guide says `Valid Records Only` requires a DQ rule. The repo has not confirmed that option live.
- **USL removal:** `REMOVE USL` removed the deployed test model on 2.4.3.1; `DROP NAMESPACE` then removed its empty namespace. Non-empty namespace removal and `DROP NAMESPACE ... CASCADE` were not tested.

### 8.5 Known open items in this repo's USL package specifically

The [archived USL build record](../plans/archive/usl-build-plan.md) tracks the full checklist. Remaining limits include:

- Cross-USL foreign keys have not been tested.
- The SQL form of `MATERIALIZE USL TABLE` has not been confirmed to support `Records: Valid Records Only`.
- The current USL model avoids the numeric-versus-string `cik` join rather than resolving it.
- Whether materialization changes cache behaviour and whether preview counts share the SQL Workspace row-display issue remain open.

### 8.6 REGISTER DQ: confirmed limitations (live-tested)

These findings come from the live-tested [`open_data/usl/`](../../open_data/usl/) examples. The supplied USL guide is the only SQL syntax source found for these commands.

- **No row alias:** use `REGISTER DQ <rule> TABLE <table> AS <expr>`. Adding an alias before `AS` failed.
- **No window functions:** rule expressions run as a filter, where Spark rejects window functions.
- **Same-table checks can be blocked by name collisions:** in `sic_usl.sic_code`, the table and column share a name. Three tested correlated-subquery/alias/window forms failed, so the consistency check remains a plain query in [`01_sic_usl_select.sql`](../../open_data/usl/sql/01_sic_usl_select.sql).
- **Cross-table correlation is unconfirmed:** the tested EDGAR/SIC check remains a plain join query in [`02_sic_edgar_usl_select.sql`](../../open_data/usl/sql/02_sic_edgar_usl_select.sql).
- **Constraint rule names use the column name:** check `LIST DQ USL` output rather than guessing a generated name.
- **DQ output shape:** `SHOW DQ ALL INVALID TABLE` returns rows in a JSON `records` column. In the 2.4.3.1 test, individual `SHOW DQ VALID/INVALID RECORD` queries returned ordinary columns. Check the output for your rule and table rather than assuming one shape for every form.

---

## 9. Open questions to close before validating this guide

Use the [archived USL build record](../plans/archive/usl-build-plan.md) for the live-verification checklist. The outstanding items are materialization behaviour, valid-only SQL options, `COMPILE USL` repeat behaviour, cross-USL foreign keys and preview row counts. Treat the guide-only claims above as unverified until a test or product document confirms them.

---

## 10. Related documents in this repo

| Document | Use it for |
|---|---|
| [EDGAR/SIC archived record](../plans/archive/edgar-sic-enrichment-plan.md) | REST/SchemaStore/VDM example and its source-data caveats |
| [USL archived build record](../plans/archive/usl-build-plan.md) | USL verification checklist and outcomes |
| [`open_data/usl/`](../../open_data/usl/) | USL SQL and per-model status |
| [REST API HOWTO](../../open_data/rest_apis/HOWTO.md), [Parquet/CSV HOWTO](../../open_data/parquet_csv/HOWTO.md) | Source setup and verification steps |
| [SQL command reference](zetaris-lightning-sql-commands.md) | Command syntax and examples |
