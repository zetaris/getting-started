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
9. [RAG on Zetaris: chunking, embeddings, search and answers](#9-rag-on-zetaris-chunking-embeddings-search-and-answers)
10. [Open questions](#10-open-questions-to-close-before-validating-this-guide)
11. [Related documents](#11-related-documents-in-this-repo)

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
| RAG pipelines: nodes, chunking, embeddings | Not covered by the Kbase pages used here; worked example in `examples/help-app` (planned, not yet in this repo) | Pilot findings on the RAG nodes, section 9 (draft) |

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
- **Writing through a JDBC datasource (pilot pattern, not run here):** in the pilot (2026-11-05, Zetaris 2.4.3.1, local Docker), `INSERT INTO <datasource>.<table> SELECT ...` through Zetaris SQL appended to a registered Postgres datasource. Base64-decode text values (`decode(unbase64('...'),'UTF-8')`) so quotes and newlines cannot break the statement. [C]
- **Omitted columns and `GENERATED` columns (pilot):** columns left out of such an `INSERT` arrive as NULL, not the database default, so write timestamps explicitly. A Postgres `GENERATED` column breaks the insert because Spark writes every column. [C] **Re-run 2026-11-09 (local Postgres):** a base64-decoded value containing quotes, a semicolon and a newline read back identical; a column-list `INSERT` worked; an omitted column with a default arrived as NULL; and an insert into a table with a `GENERATED` column failed both without the column (arity mismatch) and with a value for it (Postgres rejected the batch).
- **Postgres arrays (pilot, not re-checked):** Zetaris read a Postgres `float8[]` column as a string like `{0.1,0.2}`. **Re-run 2026-11-09** on the real vector table (27,514 rows): the `float8[]` column came back with Zetaris type `string`. [S]
- **Pipeline JDBC sink (pilot, not re-checked):** the sink takes `url`, `driver`, `username`, `password`, `dbtable` and `overwrite`, and appends. It ran at about 4 rows a second for embedded chunks, not re-run. [S, D]

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

A table can also be added to a mart from a saved pipeline relation or from a USL table. In the RAG pilot (2026-11-05, Zetaris 2.4.3.1), `ADD DATAMART TABLE ... FROM <container>.<relation>` and `... FROM <usl table>` both worked (re-run 2026-11-09, with a `VSCHEMA` clause listing every column), and the mart description accepted only letters, digits, `_`, `.`, `-` and `,`. See [section 9.9](#99-rag-in-the-semantic-layer-usl-and-vdm). [C]

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

In the RAG pilot (2026-11-05, Zetaris 2.4.3.1, local Docker), a USL table was also activated over a saved pipeline relation and over a REST table, not only over SchemaStore views. See [section 9.9](#99-rag-in-the-semantic-layer-usl-and-vdm). [C]

An activated USL table can also be added to a Virtual Data Mart with `ADD DATAMART TABLE <table> INTO <mart> FROM <usl table> VSCHEMA (...)`, which needs every column named; see [section 7](#7-virtual-data-marts-vdm--the-sql-free-consumption-layer-and-where-usl-changes-this). [C]

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
- **`IF NOT EXISTS` idempotency:** the supplied guide shows this option for `CREATE NAMESPACE` and `COMPILE USL`. On 2026-11-09 (Zetaris 2.4.3.1), running `COMPILE USL IF NOT EXISTS <name> DEPLOY` again on an existing USL with different DDL did not skip: it replaced the model (only the new table remained) and activating the earlier table then failed with "Catn't find tables for files". One run; do not use it to add a table. [S]
- **Canvas edits:** the supplied guide says card positions and FK edits made on the ERD canvas are session-only; define persistent relationships in DDL.
- **Valid-record materialization:** the guide says `Valid Records Only` requires a DQ rule. The repo has not confirmed that option live.
- **USL removal:** `REMOVE USL` removed the deployed test model on 2.4.3.1; `DROP NAMESPACE` then removed its empty namespace. Non-empty namespace removal and `DROP NAMESPACE ... CASCADE` were not tested.
- **Scalar columns only (RAG pilot, 2026-11-09, Zetaris 2.4.3.1):** `timestamp`, `date`, `decimal`, `boolean`, `bigint`, `double` and `varchar` compiled, activated and read back with their types. An `array<double>` column was rejected at compile time ("Invalid DDL statement"), as the guide says. [C]
- **Reserved word `source`:** a column named `source` broke the USL DDL ("Invalid DDL statement"); use another name such as `origin`. [C]
- **Nullability on activation:** a nullable source column under a `NOT NULL` USL column failed with "Schema mismatch ... nullable -> NOT NULL". Wrapping the column in `coalesce` fixed it. [C]
- **USL tables are read-only:** `INSERT` ("does not support append in batch mode"), `UPDATE` and `DELETE` all failed. Change the source table instead. [C]
- **No add-table command:** to add a table, `REMOVE USL` and compile again with every table, then re-activate each. [C] **Re-run 2026-11-09:** the scalar types, the reserved word, the nullability error (with `coalesce` activating cleanly), read-only behaviour and the add-table limit were all re-run in this repo.
- **`USING spark` in an `ACTIVATE USL TABLE` query (tested 2026-11-10, Zetaris 2.4.3.1; REST and JDBC differ):** over **REST** the statement succeeds and the table reads back all 309 rows, but the echoed query has no `USING` clause, and a nonexistent engine name (`no_such_engine_zz`) is accepted too: the REST layer reads the clause as an engine hint and cuts the statement at it, so the USL stores the shorter query. Over **JDBC** the same `USING spark` and `USING spark mspark` activations fail with `SQL parse error: mismatched input 'coalesce' expecting 'METADATA'`. `USING presto` fails on both channels with `Not presto engine is available` (no Presto engine here). So the clause does not choose an engine for a USL table on this build. [C]

### 8.5 Known open items in this repo's USL package specifically

The [archived USL build record](../plans/archive/usl-build-plan.md) tracks the full checklist. Remaining limits include:

- Cross-USL foreign keys have not been tested.
- **Foreign keys inside one USL work and generate a Foreign Key data-quality rule (RAG pilot, 2026-11-09, Zetaris 2.4.3.1).** Declare them as `col type FOREIGN KEY REFERENCES t(col)`, with the referenced table first in the DDL. On real data the generated rule reported 8 of 8 valid. With one orphan row inserted, it reported 9 records, 8 valid, 1 invalid. [C] **Re-run 2026-11-09:** on a two-table USL (`search.file` referencing `files.file`, with one source file deliberately left out of `files`), `RUN DQ file TABLE <namespace>.<usl>.search` returned `file, search, Foreign Key Constraint, 100, 77, 23` (total, valid, invalid). `LIST DQ USL <namespace>.<usl>` named the rules after their columns, `SHOW DQ ALL INVALID TABLE` returned the 23 invalid rows, and `SHOW DQ INVALID RECORD file TABLE …` and `SHOW DQ VALID RECORD file TABLE …` returned 23 and 77 rows. The form is `RUN DQ <rule> TABLE <namespace>.<usl>.<table>` as in the [command reference](zetaris-lightning-sql-commands.md#146-run-dq).
- The pilot's one failed attempt at `SHOW DQ INVALID RECORD` used a table name without a rule name; with the rule name it worked (above).
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

## 9. RAG on Zetaris: chunking, embeddings, search and answers

> **Draft: written from a pilot on Zetaris Lightning 2.4.3.1; items not marked confirmed have not been re-run in this repository.**

**Scope.** Findings come from a single-machine local Docker deployment of Zetaris Lightning 2.4.3.1 (Spark 3.5.3), first measured in a pilot on 2026-11-04 to 2026-11-09, mostly one run each. Items marked **Re-run 2026-11-09** were run again in this repo against the same kind of deployment (Milvus v3.0.5, Ollama running locally, this repo's own `docs/` as the corpus), one run each. Other builds, topologies (AWS, clusters) and other Milvus or Ollama versions may differ; none was tested. Answer-model quality and timings came from hosts that were unreachable when this draft was written, so no timing for them is given.

**Evidence tags.** Without a "Re-run" note, an item has not been re-run in this repo. **[C]** repeated in the pilot. **[S]** one run or a small sample. **[M]** mixed, or did not reproduce. **[U]** untested. **[D]** not re-checked: it needed hosts that were unreachable when this draft was written.

**SQL in this section** is "pilot pattern" unless stated: it was adapted from the pilot's scripts with placeholders. Statements that a "Re-run" note covers were run in this repo in the form shown, apart from placeholders.

### 9.1 The chain and what you need first

For an end-to-end example, see `examples/help-app` (planned, not yet in this repo). It will be a worked example that you run yourself on your own infrastructure against your own Zetaris; it is not hosted. This guide states the rules and the example will show them in context.

- The RAG pipeline is two chains. Ingest is `SQLTable → Chunking → Embedding → VectorStoreSink`. Answering is `VectorStoreSearch → LLM`. [C]
- Build and run them as `SPEC` JSON, with `RUN PIPELINE ON '<node>' LIMIT n SPEC {…}` for one-off runs and `REGISTER PIPELINE RELATION CONTAINER <c> SPEC {…}` to save. Syntax is in [section 16 of the command reference](zetaris-lightning-sql-commands.md#16-data-pipelines); that section has no node reference. [C]
- Create the Milvus collection first; the sink does not create it (see 9.5). Embeddings come from an in-engine `Local` model or an Ollama server. Answers need an Ollama server reachable from the driver and API containers, using `host.docker.internal` for the local machine, not `localhost`. [C]
- Node settings use the nested form: `strategy` or `provider` plus a `config` object. Flat fields are not stored. **Re-run 2026-11-09:** registering a Chunking node with `maxSegmentSizeInChars` at the node level and no `config` object failed with "No usable value for config". [C]
- **Re-run 2026-11-09:** `VERIFY PIPELINE SPEC` accepted the ingest spec, and the Milvus sink reached Milvus at `http://host.docker.internal:19530` from the Zetaris containers.
- One run of 5 repositories (2,221 chunks, MiniLM, machine not specified) took about 78 s, with the Zetaris driver at 2.2 GiB and Milvus at 320 MiB afterwards. Treat it as indicative only. [S] **Re-run 2026-11-09:** this repo's 49 Markdown files (about 556,000 characters, 641 parts) ingested with MiniLM in about 29 s of wall time on a local Docker setup, one run.

```sql
-- Pilot pattern, not run here. Check a spec, then run the chain up to the sink.
VERIFY PIPELINE SPEC {…}
RUN PIPELINE ON 'sink' LIMIT 100000 SPEC {…}   -- see 9.5 for why the LIMIT matters
```

*Worked example: `ingest` and `core/specs` in `examples/help-app` (planned).*

### 9.2 Reading the documents (source tables)

- Markdown and text files read through `FORMAT MARKDOWN`. The Markdown type reads PDFs as raw bytes; use a `FORMAT PDF` table with a `*.pdf` glob instead. [C]
- `recursiveFileLookup "true"` makes a directory path recursive; a plain directory path reads the top level only. Set `preview_len` large, or the text is cut. [C]
- Hidden files and folders starting with `.` or `_` are not read. In one run, 538 files were copied and 510 distinct files were in the source. [C]
- A SQLTable node accepts `explode()` in its select list but not `LATERAL VIEW` over a subquery. A SQLTable or Aggregation node placed after Embedding failed to resolve. [S]
- A file path is the path as the Zetaris containers see it (a mounted folder), not the host path. [C] **Re-run 2026-11-09:** a `FORMAT MARKDOWN` table with `recursiveFileLookup "true"` and `preview_len "100000"` over a read-only mounted copy of `docs/` returned 49 files. Hidden-file handling was not re-run.

*Worked example: `core/corpus` in `examples/help-app` (planned).*

### 9.3 Chunking

- The designer offers GenericText, MarkdownText, HtmlText, TokenBasedChunking, SemanticChunking and AgentChunking. The character strategies take `maxSegmentSizeInChars` and `maxOverlapSizeInChars`. [C]
- **The Chunking node adds its `REPO/FILE/…` header only to a document's first chunk.** In one run, 264 of 2,861 chunks (9%) carried it, so about 91% lost provenance. [C] **Re-run 2026-11-09:** on this repo's `docs/` (49 files, GenericText 1,000/100) the node alone produced 819 chunks and exactly 49 carried the header, one per file.
- **The Milvus sink uses the chunk text as its primary key**, so a batch containing identical chunks fails ("duplicate primary keys"). Repeated boilerplate gave 49 duplicates with GenericText and 43 with MarkdownText; TokenBased gave none. [C] **Re-run 2026-11-09:** the same GenericText run into the sink failed with "duplicate primary keys are not allowed in the same batch" after 722 rows were already written, so a failed batch leaves a partial index. The 819 chunks held one extra exact duplicate.
- Pattern used in the pilot: cut the text in SQL into 1,000-character parts every 900 characters, carry `REPO`, `FILE` and `PART` as columns, and set the Chunking node to a 1,500-character guard so nothing is re-split. It gave the same 2,221 chunks as the unguarded run. [C] **Re-run 2026-11-09:** the pre-split gave 641 parts, the guarded chain wrote 641 rows to Milvus, and no duplicate failure occurred.
- Dedupe in SQL if a batch is rejected for duplicates (the pilot's header made each part unique). [S]
- On one document, a heading-aware SQL split gave no retrieval gain and 24% more chunks. SemanticChunking produced chunks up to 15,406 characters, too long for MiniLM's reading window of roughly 1,000 characters (a model property, not measured here). AgentChunking called `http://localhost:11434` from inside the container and failed. [S]
- Chunk hygiene on 20,782 parts: 1.7% were under 100 characters and 3.8% were mostly symbols. Whether dropping them helps retrieval was not tested. [U]

```sql
-- Pilot pattern, not run here. Goes in the SQLTable node's sqlExpression.
-- {{MOUNT_NAME}} is the mounted folder name as the containers see it.
select repo, file, cast(i as string) as part, substring(text, i*900+1, 1000) as text from (
  select repo, file, text, explode(sequence(0, cast(ceil(length(text)/900.0) as int) - 1)) as i from (
    select 'my_repo' as repo,
           regexp_extract(path, '{{MOUNT_NAME}}/(.*)$', 1) as file,
           preview as text
    from <logical_db>.<file_table>
    where path not like '%.pdf'
  ) d where length(text) > 0
) x
```

*Worked example: the SQL pre-split in `examples/help-app` (planned).*

### 9.4 Embedding

- Local models `all-minilm-l6-v2`, `bge-small-en-v1.5` and `e5-small-v2` are all 384 dimensions. `nomic-embed-text` through the Ollama provider is 768 dimensions and needs a 768-dimension collection. [C] **Re-run 2026-11-09:** a one-off Embedding node returned 384 values for each local model and 768 for `nomic-embed-text` through a local Ollama server.
- The node outputs `llm_chunk` and `llm_embedding` (a string of floats, not an array). It needs the Chunking node in front, because it reads `llm_chunk`. [C] **Re-run 2026-11-09:** an Embedding node fed directly from a SQLTable failed with an unresolved-column error.
- The node adds no `query:`/`passage:` (E5) or `search_*` (nomic) prefixes. Whether they help or hurt is open. [C]
- On one set of 14 questions with 5 repositories indexed, repository hit@5 was 12/14 for MiniLM, 13/14 for BGE and 14/14 for E5. At 30 repositories MiniLM and E5 tied at 9/14, and E5's ingest took about 4.5 times as long. With n = 14, one question is 7 points. This is not a basis for recommending a model. [S]

### 9.5 Sink and search

- Create the Milvus collection beforehand through the Milvus REST API: a `VarChar` primary key `id` (max length 65,535, it receives the chunk text) and a `FloatVector` `vector` whose dimension matches the model, with COSINE. [C]
- The sink needs `uri`, `token`, `collectionName`, and `milvusBatchSize` (100) for the designer's validation to pass. The token is stored encrypted and read back as ciphertext. Use the local default token only in examples; never commit a real one. [C]
- **`RUN PIPELINE ON 'sink'` needs a large `LIMIT` (100000).** `LIMIT 1` silently wrote 4,792 of 20,782 rows. [C] **Re-run 2026-11-09:** `LIMIT 1` wrote 100 of 641 rows (one batch of 100) and `LIMIT 100000` wrote all 641.
- **VectorStoreSearch returns at most 100 rows**, whatever the `LIMIT`; the `LIMIT` is the hit count (3, 20 and 100 returned 3, 20 and 100; 500 and 3,000 returned 100). Search took about 0.1 to 0.6 s. [C] **Re-run 2026-11-09:** `LIMIT` 3, 20, 100, 500 and 3,000 returned 3, 20, 100, 100 and 100 rows.
- The question is the node's own `prompt`, embedded with the node's model, which must match the ingest model. A table in `sources` is accepted but ignored, an empty `prompt` fails ("text cannot be null or blank"), and `${…}`, `{{…}}` and `@…` placeholders are embedded literally. A different question therefore needs a new `SPEC` per call. [C] **Re-run 2026-11-09:** with a source row of "billing invoice payment" and the node's own prompt "weather api terms", the scores matched the prompt-only search exactly, and an empty prompt failed with "text cannot be null or blank". A `${prompt}` placeholder was accepted without error; whether it was embedded literally was not checked.
- **A question containing a USL or DQ command phrase fails to parse.** **Re-run 2026-11-09:** `RUN PIPELINE` failed with "no viable alternative at input 'RUN PIPELINE'" when the spec text contained `compile usl`, `activate usl`, `run dq`, `show dq` or `register dq` (any case, any spacing, and also in the `description` field), but not `compile the usl`, `registerdq`, `register pipeline` or `create pipeline relation`. Rewording avoids it. Writing one letter as a JSON escape (`\u0063ompile usl`) passed parsing in one test; the engine's scoring of that decoded question was not compared. This matters for questions about this guide's own commands. [S]
- `minScore` must match the model's similarity scale. With MiniLM, 0.6 and 0.9 returned zero contexts. [C] **Re-run 2026-11-09:** `minScore` 0.9 returned an empty `contexts` and the model replied that it needed the contexts.

```sh
# Pilot pattern, not run here. Local default token only.
curl -s -X POST "$MILVUS/v2/vectordb/collections/create" \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{
  "collectionName": "'"$COLL"'",
  "schema": {"autoID": false, "enableDynamicField": true, "fields": [
    {"fieldName": "id", "dataType": "VarChar", "isPrimary": true, "elementTypeParams": {"max_length": "65535"}},
    {"fieldName": "vector", "dataType": "FloatVector", "elementTypeParams": {"dim": "384"}}]},
  "indexParams": [{"fieldName": "vector", "metricType": "COSINE", "indexName": "vec_idx", "indexType": "AUTOINDEX"}]}'
```

*Worked example: `milvus/` setup, `ingest` and `core/specs` in `examples/help-app` (planned).*

### 9.6 The LLM node

- The node outputs three columns, `prompt`, `answer` and `contexts` (**re-run 2026-11-09** against a local Ollama model). `contexts` is not always valid JSON (unescaped quotes), so read the `REPO:` headers with a regular expression instead of a JSON parser. [C]
- Check `contexts` before trusting an answer. With no contexts the model still replied fluently, asking for the contexts. [C]
- The node accepts **any** table with columns `prompt`, `content` and `similarity` as its source, so you can re-rank passages yourself and pass the best N. Pass text base64-decoded in SQL so quotes cannot break the statement. [C] **Re-run 2026-11-09:** a one-row SQLTable source with quotes and apostrophes in `content` fed the LLM node and the local model's answer named the right file.
- Ollama models load cold, and the pilot retried and pre-warmed them. Answer-model timings and the models used were on hosts that were unreachable when this draft was written. [D]
- In the pilot's tests, wrong answers came from retrieval, not from the answer model. One question each, so this is an indication only. [S]

*Worked example: `core/prompt` and `core/rank` in `examples/help-app` (planned).*

### 9.7 Ranking and how to evaluate

- Re-rank the (at most) 100 hits: similarity plus 0.15 times the share of the question's words found in the passage text or path. On one 14-question set with E5, repository hit@1, hit@5 and expected-file hit@5 went from 8/11/1 to 11/12/3. [S]
- Caveats: the weight was tuned on those 14 questions. A held-out set of 30 easier questions agreed in direction, but its wording overlapped the documents, which flatters keyword matching. Grouping hits by entry made results worse. Do not read these as a benchmark. [S]
- Evaluate with a fixed question set and report hit@1, hit@5 and the sample size. An early retrieval run on the 14 questions did not reproduce in three later runs, so re-run before quoting a number. [M]

### 9.8 Saved pipelines and the designer

- A relation registered with SQL alone has no layout or connections, and the designer drew no links. Post the layout and connections separately (`targetType` 0, except 1 for JDBC and file sinks). [C]
- In this build's designer, stored RAG node settings opened blank and Save failed with a mapping error, because the designer reads flat fields while the server stores the nested form. The pilot saw it in two browsers. Treat it as a probable defect to report upstream. Without a fix, do not press Save on a loaded relation; recreate it from SQL. [C]
- **`SELECT * FROM <container>.<relation>` runs the pipeline again.** A search-only relation took about 2 s and returned 100 rows. A relation with an LLM node took 23 to 45 s and gave a different answer each time. Never `SELECT` from an ingest relation: it runs the ingest. [C]
- `DROP PIPELINE RELATION` runs immediately with no confirmation. [C] **Re-run 2026-11-09** for both this and the `SELECT` behaviour above: a `SELECT` on a search-only relation took about 2.5 s and returned 100 rows.
- A Chunking guard of 2,000 characters on 1,000-character parts did nothing; set the guard above the part size plus its header (1,500 here). [C]
- **`USING spark` or `USING presto` in a SQL Table node is rejected (tested 2026-11-10, Zetaris 2.4.3.1, REST and JDBC):** a SQLTable `sqlExpression` of `SELECT path, title FROM help_pg.docs` passed `VERIFY PIPELINE` and `RUN PIPELINE` on both channels. With ` USING spark`, ` USING spark mspark` or ` USING presto` added, every `VERIFY PIPELINE` and `RUN PIPELINE` failed (`REGISTER` was not tried). **JDBC** returns the cause directly: `mismatched input 'path' expecting 'METADATA'`, because a SQLTable expression holding a `USING` clause is sent to the Lightning DDL parser, not the query parser. **REST** first cuts the whole statement at the word `USING` (so the spec JSON arrives truncated, `JsonEOFException`, at the offset of `USING` in four variants); hiding the word with a JSON escape (`\u0055SING spark`) got past that and gave the same parse error. Not tested: the Data Pipeline designer and a real Presto engine. [C]

```sql
-- Pilot pattern, not run here.
CREATE PIPELINE CONTAINER help_app DESCRIPTION 'Help app RAG pipelines'
REGISTER PIPELINE RELATION CONTAINER help_app SPEC {…}
```

*Worked example: the `help_search` and `help_answer` relations in `examples/help-app` (planned).*

### 9.9 RAG in the semantic layer (USL and VDM)

- A saved search relation backed a USL table (`ACTIVATE USL TABLE … AS SELECT … FROM <container>.<relation>`). So did a relation with an LLM node, but each query took 25 to 45 s and returned a new answer, and joining a search-only table to an LLM table re-ran the LLM. [C] **Re-run 2026-11-09** for the search-only case: a USL table activated over a saved search relation returned the same ranked hits as the relation.
- Parse the `REPO/FILE/PART/TEXT` header with `regexp_extract`. In Zetaris SQL strings write `[0-9]`, not `\d`. [C]
- `ADD DATAMART TABLE … FROM <container>.<relation>` worked, and so did adding a USL table. See [section 7](#7-virtual-data-marts-vdm--the-sql-free-consumption-layer-and-where-usl-changes-this). [C] **Re-run 2026-11-09:** both worked only with a `VSCHEMA (...)` clause listing every source column. Omitting it was a parse error for the relation, and a partial list for the USL table gave "Data mart table schemas do not match source table's". The mart then returned 100 and 48 rows as `<mart>.<table>`.
- **Milvus is not a data source** in this build; it appears only as a pipeline sink and a search node (PineCone is the other option in the designer, not tested here). [C]
- Rows can be read through a `CREATE LIGHTNING REST TABLE` on `/v2/vectordb/entities/query`, but every `BODY` value is sent as a JSON string, so `limit` and `outputFields` fail. You get Milvus's default 100 rows and a fixed filter, and vector search through a REST table is not possible. [C]
- A vector cannot live in a USL table, because USL columns must be scalar; see [section 8.4](#84-usl-quirks-worth-flagging-per-the-guide-not-yet-live-tested). [C]
- Label each passage with its source corpus so results stay attributable; the pilot attributed reference docs, project documents and code separately. Indexing the Zetaris Kbase alongside repo docs was not tested. [U]

*Worked example: `build_usl`, `help_usl` and `help_mart` in `examples/help-app` (planned).*

### 9.10 Experimental: vector search as Spark SQL

*Experimental; one setup, one question, re-check before relying on it.* In the pilot, the vectors of an index were copied into a Postgres on another machine on the LAN and searched with plain Spark SQL, as a way past the 100-row cap.

- Spark 3.5.3 has no vector index, but a dot product over normalized vectors runs in plain SQL (`aggregate(zip_with(…))`). E5 vectors have norm 1, so the dot product is the cosine. The query vector comes from a one-off Embedding pipeline (Chunking, then Embedding). [S]
- Zetaris read a Postgres `float8[]` column as a string like `{0.1,0.2}`, so the SQL parses it with `transform(split(regexp_replace(llm_embedding,'[{}]',''),','), x -> cast(x as double))`. **Re-run 2026-11-09.** [S]
- **Re-run 2026-11-09 over 27,514 rows (E5, 384 dimensions) on that remote Postgres:** the top score was 0.875914 against 0.875904 from Milvus for the same question (the query vector was rounded to six places). The Spark statement took 9.5 to 10.4 s over three runs, against about 0.5 s for the Milvus search. The pilot measured 5.5 to 6.0 s on its own setup, so treat the timing as setup-specific. [S]
- Not tested: concurrent queries, larger tables, Zetaris driver memory at scale, or pushing similarity down to Postgres (pgvector was not installed). Loading vectors through the pipeline JDBC sink ran at about 4 rows a second in the pilot and was not re-run. [S, D]

---

## 10. Open questions to close before validating this guide

Use the [archived USL build record](../plans/archive/usl-build-plan.md) for the live-verification checklist. The outstanding items are materialization behaviour, valid-only SQL options, `COMPILE USL` repeat behaviour, cross-USL foreign keys and preview row counts. Treat the guide-only claims above as unverified until a test or product document confirms them.

RAG items from the pilot (section 9) still open:

- Do the Join node and the SimpleDQ node return rows in any spec form, or is that a defect in this build? The Join node passed `VERIFY PIPELINE`, but both nodes returned no rows.
- Why do `compile usl`, `activate usl`, `run dq`, `show dq` and `register dq` inside a `RUN PIPELINE` spec break parsing, and is there a supported way to quote them? (Section 9.5.)
- Is there an AgentChunking URL setting? The node called `localhost:11434` from inside the container and failed.
- Do E5 `query:`/`passage:` prefixes or nomic `search_*` prefixes change retrieval? The node adds none.
- Is there a size cap for SemanticChunking? The pilot saw chunks up to 15,406 characters.
- `MATERIALIZE USL TABLE` with real storage configured (it returned an error row with none).
- Can Zetaris push a vector operator down to pgvector, and can a REST table page past 100 Milvus rows?
- Spark SQL vector search (section 9.10) was re-run once on a Postgres on another LAN machine; concurrency and larger tables are open.
- Stale catalog entries: after dropping a Postgres table, `SHOW TABLES IN <datasource>` still listed it, and no SQL form to unregister it was found (`DROP DATASOURCE TABLE` did not parse).
- `USING spark <engine>` and `USING presto` have no working place in a USL table query or a pipeline SQL Table node over REST or JDBC on this build (sections 8.4 and 9.8). Over REST the clause on an ad hoc query is accepted and any engine name is taken; over JDBC the same ad hoc `USING spark` fails to parse, so the Kbase examples may rely on the GUI's query path. Open: whether the Data Pipeline designer, or a build with a Presto engine, treats the clause differently.
- Concurrent users, other Zetaris builds, other Milvus or Ollama versions, and non-local topologies were not tested.

---

## 11. Related documents in this repo

| Document | Use it for |
|---|---|
| [EDGAR/SIC archived record](../plans/archive/edgar-sic-enrichment-plan.md) | REST/SchemaStore/VDM example and its source-data caveats |
| [USL archived build record](../plans/archive/usl-build-plan.md) | USL verification checklist and outcomes |
| [`open_data/usl/`](../../open_data/usl/) | USL SQL and per-model status |
| [REST API HOWTO](../../open_data/rest_apis/HOWTO.md), [Parquet/CSV HOWTO](../../open_data/parquet_csv/HOWTO.md) | Source setup and verification steps |
| [SQL command reference](zetaris-lightning-sql-commands.md) | Command syntax and examples |
| `examples/help-app` (planned, not yet in this repo) | End-to-end RAG worked example that you run on your own infrastructure; it is not hosted |
