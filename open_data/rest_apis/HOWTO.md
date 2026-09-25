# HOWTO: onboard these REST API sources into Zetaris

The general walkthrough for the `sql/` scripts in this package — read this once before running any of them.

**File naming:** each numbered source is split into two files sharing a prefix: `sql/NN_<name>_create.sql` (every `CREATE`/`DROP`/`CACHE` DDL statement) and `sql/NN_<name>_select.sql` (verification and, where present, example queries). Run the create script first, then verify with its matching select script — the verification queries there are commented out by default so a bulk run of the file doesn't silently fire read queries. A bare shorthand like `sql/05` below refers to that source's pair of files generically, not to a single combined file.

---

## 1. The SQL syntax these scripts use

Every script uses two Zetaris DDL statements together: `CREATE LIGHTNING REST TABLE`, which registers a REST endpoint's raw JSON response as a queryable table, and `CREATE SCHEMASTORE VIEW`, which flattens that raw JSON into a proper tabular view. This is a different pattern from the Parquet/CSV package's `CREATE LIGHTNING FILESTORE TABLE` (`../parquet_csv/HOWTO.md`) — REST sources don't have a file `PATH`, they have an `endpoint`, `HEADER`, and `BODY`.

The general shape:

```sql
-- Step 0: register the logical database (same prerequisite as filestore
-- tables -- see ../parquet_csv/HOWTO.md, "Registering a datasource").
CREATE LIGHTNING DATABASE <logical_datasource_name> DESCRIBE BY "<short description>";

-- Step 1: register the raw REST response as a table.
CREATE LIGHTNING REST TABLE <raw_table_name> FROM <logical_datasource_name> REQUEST(
    endpoint "https://api.example.com/path",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"   -- required by some APIs, e.g. SEC EDGAR
) BODY ();

-- Step 2: a SCHEMASTORE container to hold flattened views (see
-- "Known limitations" below -- this can only be created ONCE per name).
CREATE SCHEMASTORE CONTAINER <container_name>;

-- Step 3: flatten the raw JSON into a queryable view.
CREATE SCHEMASTORE VIEW <view_name> WITH CONTAINER <container_name> AS
SELECT
    <top_level_field>,
    `<mixedCaseField>` AS <alias>,          -- backtick-quote mixed-case JSON keys
    fact.<nested_field> AS <alias>
FROM <logical_datasource_name>.<raw_table_name>
LATERAL VIEW explode(<array_field>) AS fact;
```

`<logical_datasource_name>` works exactly like the Parquet/CSV package's filestore datasource names — it must be registered with `CREATE LIGHTNING DATABASE` before anything can reference it in `FROM`.

---

## 2. Known limitations

Read this before running any script — these are hard limits observed in the current Zetaris version, not suggestions.

- **`CREATE SCHEMASTORE CONTAINER` can only be run once per name.** It does not support `IF NOT EXISTS`. Running it a second time against a name that already exists fails with a parse exception. Every script in `sql/` creates its container in a clearly-marked, standalone statement near the top — comment that line out if the container already exists in your environment.
- **`DROP VIEW` is the only teardown statement confirmed to work reliably.** `DROP TABLE` and `DROP DATASOURCE` do not reliably remove a `CREATE LIGHTNING DATABASE`-registered REST source. See "Removing a source" below for the full picture and the GUI-based path that is currently the only confirmed way to remove a source's underlying registration.
- **`SCHEMASTORE CONTAINER` has no removal path at all**, SQL or otherwise, that we have found. Treat a container as permanent once created.
- Whether `CREATE LIGHTNING DATABASE` tolerates being re-run (the same way `CREATE SCHEMASTORE CONTAINER` does not) has not been tested.
- **A Lightning REST table is not materialized once at `CREATE` time.** Confirmed live (NASA NeoWs, `sql/05`, 2026-09-19): Zetaris appears to re-issue the underlying HTTP request to the source API on every subsequent query that touches the table, directly or through a view built on it — not just the first one. Running a full script's `CREATE` + views + several example queries in one sitting can exhaust a strict source API's rate limit partway through, surfacing as a failed query on an ordinary `SELECT`, not on the `CREATE TABLE` statement itself. **`CACHE TABLE` is now a confirmed fix** (`company_dns`, `sql/10`, 2026-09-21 — ~49.7s down to a stable ~1.2s on a repeated `SELECT COUNT(*)`) — see "Troubleshooting / FAQ" below for the details, and for why this is related to, but does not fully explain, the Singapore PM2.5 failure case (different error signature — see `failure_cases/singapore_pm25/ISSUE.md`).
- **One source in this package is currently blocked and excluded from the main sequence:** Singapore's data.gov.sg PM2.5 API returned an HTTP 502 on its first `CREATE LIGHTNING REST TABLE` statement. See `failure_cases/singapore_pm25/ISSUE.md` for the full investigation and `failure_cases/README.md` for how this package tracks blocked sources generally.
- **No confirmed way to send a raw JSON request body.** Every script in this package that uses `BODY(...)` uses it empty — `http_encoding "URLENCODED"` implies a form-encoded body, and there's no confirmed Zetaris syntax for sending a raw JSON array/object body instead. Confirmed blocking: Statistics Canada's `getCubeMetadata` endpoint (a natural follow-up for `sql/08`) strictly requires `Content-Type: application/json` and rejects a form-urlencoded body outright with `415 Unsupported Media Type` — tested directly via `curl`, not assumed. If a future source needs a POST with an actual JSON body, this is the first thing to research (e.g. an untested `http_encoding "JSON"` option) before assuming the pattern this package uses will work.
- **`DESCRIBE BY "<text>"` (on `CREATE LIGHTNING DATABASE` and elsewhere) only accepts a restricted character set.** Confirmed live (`sql/10_company_dns_sic_create.sql`, 2026-09-21): a description containing parentheses and a slash (`"company_dns SIC reference data (division/major group/industry group/SIC code)"`) was rejected outright with `Description is invalid, it must be alphanumeric including the _ (underscore), . (dot), - (hyphen) and , (comma) character` — before the statement ever reached the REST endpoint. Plain spaces are fine (every other script in this package, e.g. `sql/01`'s `"SEC EDGAR XBRL company facts REST source"`, uses them and is live-tested working) despite not being named in the error text — it's specifically punctuation like `()`, `/`, `:`, `;` that trips this. Keep every `DESCRIBE BY` string to letters, digits, spaces, and `_ . - ,` only.
- **SQL Workspace results grid can under-render a page's row count, and rows can go missing from query results more broadly.** Observed (2026-09-21, `sql/01`'s `apple_revenue_table`): the grid displayed 10 data rows on page 1 while the footer correctly reported `Total Count: 11` and `1/2` pagination — the underlying data and count were confirmed correct independently (matches the live SEC API exactly, see the row-count entry above). Separately (`sql/11_edgar_company_profiles_create.sql`'s `all_companies_profile_table`, a 7-way `UNION ALL`): the footer itself reported `Total Count: 6`, one company (IBM) apparently missing — not yet root-caused as of this writing (could be the join finding no match for IBM's `sic` code, or the same underlying row-dropping behavior as the grid case, just surfacing in the footer count this time rather than only the display). **The user has filed a formal issue with Zetaris engineering covering rows being dropped/truncated** (2026-09-22) — treat this as a known, tracked platform issue rather than something to keep independently investigating here. If you hit a suspiciously low row count anywhere in this package, still do the independent `curl`/`jq` cross-check per "Verifying data" above, but don't assume every discrepancy has a source-data explanation the way the Apple/EDGAR case turned out to — some may be this filed bug instead.

---

## 3. Understanding JSON response shapes

`LATERAL VIEW explode(<array_field>) AS fact` followed by dot-access (`fact.val`, `fact.accn`, ...) works when a JSON field is an **array of objects** (array-of-structs) — confirmed for EDGAR's `units.USD`. The sources in this package cover several distinct response shapes, with different levels of risk for this pattern:

1. **Top-level object, array-of-structs field(s)** — the confirmed-working shape (EDGAR `sql/01`, PokéAPI `sql/02`, Open Food Facts live API `sql/03`, NASA NeoWs `sql/05` via `/neo/browse`). `explode()` + dot-access works directly. Some of these nest a struct *inside* the array's struct (PokéAPI's `ability.ability.name`, two levels deep) — this depth is confirmed to work. Open Food Facts' `ingredients` array goes further still: some entries are compound ingredients that carry their own nested `ingredients` sub-array (e.g. a biscuit's "Céréale" entry breaking down into wheat flour and whole wheat flour) — a single `explode()` only reaches the top-level entries; going deeper would need a second `explode()`, not built in `sql/03`.
2. **Top-level object, array-of-structs nested under a non-array wrapper key** — Singapore's PM2.5 API (`failure_cases/singapore_pm25/`, blocked — see "Known limitations" above): the array lives at `data.items`, not the top level, and each item's per-region breakdown (`readings.pm25_one_hourly`) is itself a fixed struct, not an array — no inner `explode()` needed there, just deeper dot-access.
3. **Top-level JSON array (no wrapping object at all)** — NASA DONKI's CME endpoint (`sql/06`). Every confirmed-working source so far returns a top-level object; whether `CREATE LIGHTNING REST TABLE` can register a table from a bare top-level array is untested — this is the first thing to check for that script, before worrying about flattening.
4. **SDMX-family formats (JSON-stat 2.0 / SDMX-JSON 2.0.0)** — Eurostat (`sql/07`) and the Australian ABS Data API (`sql/09`). These are not row-oriented at all — they're sparse, multi-dimensional arrays addressed by computed offset keys (Eurostat) or compound colon-separated dimension-index tuples with a further nested time-index (ABS), decoded against separate `dimension`/`structure` metadata. There's no array-of-structs to explode. Both scripts expose the dimension metadata as a view, confirmed working for Eurostat. **Update (2026-09-19):** for Eurostat specifically, the sparse `value` object turns out to be addressable two ways — a low-risk option (direct backtick-quoted dot-access to specific known-present numeric keys, e.g. `` value.`522` ``, confirmed working) and a higher-risk option decoding the entire object into rows via `from_json(to_json(...), 'map<string,TYPE>')` coercion — **the coercion technique itself is confirmed working** (2026-09-19), but the first attempt only applied it to `value` and not to the second dynamic-key object being exploded (`dimension.time.category.index`), which has the identical struct-inference problem and needs the identical fix. See `sql/07_eurostat_create.sql`'s caveat 6c for the exact error this produced and the general lesson: apply the coercion to *every* dynamic-key JSON object you explode in a query, not just the first one you notice. With that fix applied, the full decode view and all 8 example queries built on it are confirmed working end to end. Whether the same technique helps ABS's doubly-compound-key structure (`sql/09`) is untested and likely harder, since ABS needs two levels of key decoding, not one.

A **parallel-arrays** shape (separate `times: [...]` and `values: [...]` meant to be read pairwise) hasn't been hit yet in this package but would need `posexplode()` + positional indexing instead of a plain `explode()`. Don't assume array-of-structs is universal for a future source; confirm the actual JSON shape (`curl` or the browser) before writing a new script's `SELECT`.

Open Food Facts' `product.nutriments` (`sql/03`) is a **flat struct**, not an array-of-structs — reading it is plain dot-access all the way down (`product.nutriments.sugars_100g`) with no `LATERAL VIEW explode()` involved. Don't reach for `explode()` reflexively on every nested field; check whether the JSON node is actually an array first.

---

## 4. Running the scripts

1. Open the Zetaris **SQL Editor**.
2. For each source in `sql/`, in order:
   - Read the `_create.sql` header comment and every numbered caveat.
   - Run the `CREATE LIGHTNING DATABASE` statement (Step 0).
   - Run the `CREATE SCHEMASTORE CONTAINER` statement **once** (Step 1) — skip it if the container already exists in your environment (see "Known limitations").
   - Fill in any required `HEADER` values (e.g. a real `user-agent` string — some APIs, like SEC EDGAR, reject default/missing ones).
   - Run each `CREATE LIGHTNING REST TABLE` + `CREATE SCHEMASTORE VIEW` pair in `_create.sql`.
   - Open the matching `_select.sql`, uncomment its verification query (see "Verifying data" below), and run it before trusting the result.

Suggested order — lowest-risk / simplest shape first, so a failure on a harder source doesn't block confirming the basic pattern works at all (see "Understanding JSON response shapes" above):

| Order | Script | Why here |
|---|---|---|
| 1 | `01_edgar_company_facts_create.sql` | Already live-tested and working — confirms the baseline pattern end to end. |
| 2 | `08_statcan_wds_create.sql` | Simplest shape investigated (flat array-of-structs, one level, GET-only) — good smoke test if something else is failing. |
| 3 | `02_pokeapi_create.sql` | Array-of-structs with one extra level of nested struct — tests whether two-level dot-access through an exploded field works. |
| 4 | `03_open_food_facts_live_create.sql` | Array-of-structs with sparse/optional fields across entries — tests schema-inference tolerance for inconsistent struct shapes. |
| 5 | `05_nasa_neows_create.sql` | Array-of-structs with deep nesting (3 levels) and a nested array-within-array (`close_approach_data`) — tests indexing (`[0]`) vs. a second `explode()`. |
| 6 | `06_nasa_donki_create.sql` | Higher risk: top-level JSON array, not object — untested whether `CREATE LIGHTNING REST TABLE` even accepts this at all. |
| 7 | `07_eurostat_create.sql` | Metadata path confirmed working; JSON-stat format still needs an experimental `to_json`/`from_json` coercion (not yet tested) to decode actual values — see "Understanding JSON response shapes" below. |
| 8 | `09_abs_data_api_create.sql` | Higher risk: SDMX-JSON with doubly-compound dynamic keys — same risk class as Eurostat, likely drop candidate. |

**Not in this sequence:** `04_singapore_pm25_create.sql` is excluded — it hit a blocking connector-or-API issue during testing (an HTTP 502 on its first statement) and has been moved to `failure_cases/singapore_pm25/` along with a full writeup for engineering. See "Known limitations" below and `failure_cases/README.md`.

---

## 5. Verifying data

For every REST source in this package (the query below is commented out by default in each source's `_select.sql` — uncomment it or run it directly in the SQL Editor):

1. `SELECT COUNT(*) FROM <container>.<view_name>;` — get the row count Zetaris thinks it has.
2. Independently query the same endpoint with `curl` + `jq` (or equivalent) and count the array length directly, e.g.:
   ```bash
   curl -s -A "YOUR_APP_NAME YOUR_CONTACT_EMAIL" \
     https://data.sec.gov/api/xbrl/companyconcept/CIK0000320193/us-gaap/Revenues.json \
     | jq '.units.USD | length'
   ```
3. If the Zetaris count is lower than the direct API count, the connector is truncating — don't trust that table for real analysis until that's resolved. See the Troubleshooting / FAQ entry below for the specific case observed against EDGAR.

---

## 6. Going further

- **Adding another REST source:** confirm the license, confirm the actual JSON shape (array-of-structs vs. parallel arrays vs. something else — see "Understanding JSON response shapes"), write the `CREATE LIGHTNING REST TABLE` + `CREATE SCHEMASTORE VIEW` pair using this document's syntax reference, add a verification query per "Verifying data", and add a commented-out `TEARDOWN` block for its views per "Removing a source" below.
- **Filestore sources instead of REST:** that's `CREATE LIGHTNING FILESTORE TABLE` — see `../parquet_csv/HOWTO.md`.
- **JDBC/relational sources instead of REST:** that's `CREATE DATASOURCE` — see `../parquet_csv/HOWTO.md` for the pointer.

---

## 7. Removing a source

This section reflects what is actually confirmed to work, not what the SQL manual suggests should work.

**What works:**
- `DROP VIEW <container>.<view>` removes a schemastore view. This is confirmed and reliable — use it to clean up the flattened views each script creates. Every script's `TEARDOWN` block contains the `DROP VIEW` statements for its own views.

**What does not work:**
- `DROP TABLE <database>.<table>` against a `CREATE LIGHTNING REST TABLE`-registered table is inconsistent — it has worked for some sources and failed for others with an internal catalog error (`NoSuchElementException: key not found: <database>`), even when the statement is written identically. Do not rely on it.
- `DROP DATASOURCE <database_name>` does not reliably remove a `CREATE LIGHTNING DATABASE`-registered source. In practice it has either reported that the data source does not exist, or completed without error while the source remained visible in the Data Explorer afterward. `DROP DATASOURCE` appears to be intended for JDBC-style `CREATE DATASOURCE` registrations (documented with a `DROP DATASOURCE ORCL` example matching a JDBC connection), not for the Lightning-registered REST and file sources this package uses.
- **No SQL statement exists to remove a `SCHEMASTORE CONTAINER`** once created.

**How to actually remove a source's REST table(s) and Lightning database registration:**

Use the Zetaris SQL Workspace's **Data Explorer**. The source appears under **File Source & API** with the name given to it at creation (e.g. `POKEAPI_REST`, `OFF_LIVE_REST`). Locate the entry there and use the removal action available on that row (for example, a right-click menu or an overflow/options menu icon on the row). This is currently the only confirmed way to remove the underlying registration — there is no SQL equivalent.

If no removal action is available in your version of the Data Explorer either, this is a product gap rather than something this package's scripts can work around; raise it with your Zetaris contact.

Every script's `TEARDOWN` block therefore contains only `DROP VIEW` statements, followed by a comment pointing back to this section for removing the REST table(s) and database registration via the Data Explorer.

---

## 8. Troubleshooting / FAQ

### My query failed with an unresolved-column error mentioning a mixed-case, reserved-word, or hyphenated field name

A REST API's JSON response often has field names that Zetaris's SQL layer will not accept unquoted:

- **Mixed-case / camelCase names** (e.g. `entityName`, `updatedTimestamp`) — need backticks: `` `entityName` ``, not `"entityname"` or a bare `entityname`.
- **Names that collide with SQL reserved words** (e.g. `start`, `end`) — need backticks even though they are not mixed-case, e.g. `` fact.`start` ``.
- **Names containing a hyphen** (e.g. `energy-kcal_100g`) — need backticks for a different reason: an unquoted hyphen inside an identifier parses as subtraction, e.g. `` product.nutriments.`energy-kcal_100g` ``.

The general rule: if a JSON key contains any character a SQL identifier cannot use unquoted (mixed case, a reserved word, a hyphen, a space, ...), quote it with backticks. Before writing a new script's `SELECT`, check every field name you intend to reference against this rule rather than finding out from the error.

### My query failed with `UNRESOLVED_COLUMN`, referencing a column that "doesn't exist" on a view I expected to have it

This happens when a downstream query assumes a view carries a column it was never actually given. For example, a view built to expose only `(pokemon_name, ability_name, is_hidden)` will not have `base_experience`, even if a comment elsewhere describes the view as "carrying" that field — the comment can drift out of sync with the view's actual `SELECT` list.

Before writing a query that joins or reads from a view, check the view's own `CREATE SCHEMASTORE VIEW ... AS SELECT` statement for the exact column list, rather than relying on a comment or on what a similar-looking view elsewhere in the package exposes. If you need a column from a different view, either select it from that view directly or extend the view's own `SELECT` list.

A related version of this problem happens one level lower, in the raw JSON itself: a `CREATE SCHEMASTORE VIEW` can reference a struct field (e.g. `item.readings.pm25_one_hourly.national`) that looks plausible but was never actually present in the API's response, because it was assumed rather than checked. Singapore's PM2.5 API (`failure_cases/singapore_pm25/`) had exactly this — a `national` field that doesn't exist anywhere in the response, confirmed by inspecting every key across a full day of readings. Before writing a new script's `SELECT`, pull a real response with `curl` and check every field name you intend to reference actually appears in it, rather than assuming a field exists because it would make sense for the API to provide it.

### My query failed with `MISSING_ATTRIBUTES.RESOLVED_ATTRIBUTE_APPEAR_IN_OPERATION`

This occurs when a query joins a view against an aggregate **subquery of that same view** — a self-join — where the view is itself a `UNION ALL` of other views built with `LATERAL VIEW explode(...)`. For example:

```sql
-- Avoid this pattern:
SELECT a.*
FROM some_view a
JOIN (
    SELECT key, MAX(val) AS max_val
    FROM some_view
    GROUP BY key
) top ON top.key = a.key AND top.max_val = a.val;
```

The `explode()` operator behind `some_view` leaves behind an internal struct attribute that was never selected. Referencing the same union'd, exploded view twice in one query — once directly, once inside the aggregate subquery — causes the query analyzer to see that internal attribute with conflicting identifiers across the two references.

Joining two genuinely **different** views together does not hit this. The problem is specific to referencing a view against a derivative of itself — and this isn't limited to an explicit `JOIN`. **Confirmed on Statistics Canada WDS (`sql/08`, 2026-09-19):** the same error occurs with a `WHERE product_id IN (SELECT ... FROM same_view ...)` subquery and with a scalar `HAVING count = (SELECT ... FROM same_view)` subquery — any form that reads the same UNION ALL'd exploded view more than once in one query, not just an explicit self-join, is at risk. This is now the **second** source in this package to hit this exact error class (after Open Food Facts, `sql/03`, which hit it via an explicit self-join) — treat "does this query reference the same UNION ALL'd exploded view more than once, anywhere in the query, including inside any subquery" as a standard thing to check before running a new query against a cross-record union view in this package.

**Fix:** rewrite the query as a window function instead of any form of self-reference. A single pass over the view avoids the conflict entirely, whether the original was a self-join, an `IN` subquery, or a scalar `HAVING` subquery:

```sql
SELECT key, val
FROM (
    SELECT key, val, ROW_NUMBER() OVER (PARTITION BY key ORDER BY val DESC) AS rn
    FROM some_view
) ranked
WHERE rn = 1;
```

A plain `COUNT(*) OVER (PARTITION BY key)` (no ranking needed) works the same way for "does this group meet some count threshold" questions — see `sql/08_statcan_wds_select.sql` queries 3, 7, and 8 for worked examples of both the failing subquery forms and their window-function fixes.

`ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)` is standard ANSI/Spark SQL. Prefer this pattern any time a "top row per group" question comes up, especially when the view involved is a `UNION ALL` of `explode()`-based views. See `sql/03_open_food_facts_live_select.sql` query 7 for a worked example of both the failing self-join and the working window-function rewrite.

### A numeric-looking field sorts or compares wrong (e.g. "closest" or "smallest" picks the wrong row)

A JSON field that looks numeric in a raw response can still be a JSON **string** rather than a number — check by looking at whether the value is quoted in the raw JSON, e.g. `"kilometers": "47112732.928149391"` (a string) versus `"estimated_diameter_min": 22.1082810359` (a real number). Confirmed on NASA NeoWs (`sql/05`): `miss_distance.kilometers` and `relative_velocity.kilometers_per_hour` are both quoted strings, while sibling fields in the same response (`estimated_diameter_min/max`, `absolute_magnitude_h`) are real numbers.

Zetaris's schema inference follows the JSON type, so a quoted numeric field is very likely typed as STRING. Sorting or comparing it without casting does **lexicographic string comparison**, not numeric comparison — a value like `"9000000.1"` sorts *before* `"47112732.9"`, because `'9' > '4'` as the first character, even though 9,000,000 is smaller than 47,000,000 numerically. This fails silently: no error, just a wrong "closest"/"smallest"/"highest" answer.

**Fix:** wrap the field in `CAST(... AS DOUBLE)` (or `INT`/`BIGINT` as appropriate) anywhere it's sorted, compared, or aggregated numerically — ideally once, in the view's own `SELECT`, so every downstream query inherits the correct type instead of needing to remember to cast every time. Before writing a new script's numeric queries, check each field's raw JSON representation for quotes, don't assume "looks like a number" means "is a number."

### A JSON-stat / SDMX source returns an empty result even though the dataset should have data

Confirmed on Eurostat (`sql/07`, 2026-09-19): the original query used `age=Y15-74`, which isn't a valid category code for that particular dataset. Eurostat doesn't return an error for an invalid dimension code — it silently returns zero valid categories for that dimension (`dimension.age.category.index: {}`) and therefore an empty top-level `value: {}`, which looks identical to "this combination genuinely has no published data."

Before concluding a JSON-stat source has no data for your combination of filters, check `dimension.<name>.category.index` for each dimension you're filtering on (via `curl`, or `SELECT * FROM <container>.<metadata_view>` once you have one) — an empty or missing category list for a dimension means the code you used isn't valid for that dataset, not that the data doesn't exist. Re-querying the same dataset without that filter will show you the actual valid codes.

### Decoding a JSON-stat sparse `value` object into real rows

JSON-stat 2.0 (used by Eurostat, `sql/07`) and similar sparse formats store their actual data as an object keyed by a computed integer offset (e.g. `{"168": 11.8, "169": 11.5, ...}`), not as an array-of-structs — there's nothing to `LATERAL VIEW explode()` directly, unlike every other source in this package. Two techniques, in increasing order of risk:

- **Low risk:** if you only need a handful of specific, known data points, address them directly via backtick-quoted dot-access on the numeric key, e.g. `` value.`522` ``. This works because Spark's default JSON schema inference turns a dynamic-key object like this into a STRUCT with one field per observed key — the same struct/backtick-quoting mechanism already used throughout this package for mixed-case field names, just applied to purely numeric ones. No `explode()` involved, so this doesn't depend on solving the harder map-vs-struct problem below.
- **Higher risk, technique confirmed working:** to decode the *entire* sparse object into proper rows, coerce the inferred STRUCT into a MAP by round-tripping it through JSON text with an explicit target schema: `from_json(to_json(value), 'map<string,double>')`. This can then be exploded like any other map, and joined against the relevant dimension's `category.index` (also exploded) to translate the raw numeric offset back into a real, human-readable label.

  **Important, confirmed 2026-09-19:** this coercion needs to be applied to *every* dynamic-key JSON object you explode in the same query, not just the first one you notice. A first attempt against Eurostat applied it to `value` but plainly exploded `dimension.time.category.index` without the same coercion — the resulting error (`DATATYPE_MISMATCH` on the second `explode()`, with the STRUCT's individual dynamic fields spelled out in the message) confirmed two things at once: the struct-inference behavior applies uniformly to any dynamic-key object, not just the one you're focused on, and — more usefully — the `value` coercion itself raised no error at all in the same query plan, meaning the technique genuinely works once applied consistently. `to_json`/`from_json` are standard Spark SQL functions, not something specific to this package. See `sql/07_eurostat_create.sql`'s caveat 6c for the exact error and the fix (wrapping the time-index explode in the identical coercion pattern).

### A table's row count looks lower than I expect

Verify it independently before trusting it — see "Verifying data" above. **Resolved case (EDGAR, `sql/01`, 2026-09-21):** Apple's `us-gaap:Revenues` table returned a suspiciously low row count (11 rows, capping out years before the company's real filing history ends), originally suspected as the REST connector truncating the response mid-array. Confirmed NOT a Zetaris bug: a direct `curl` against the live SEC endpoint also returned exactly 11 rows, and Zetaris's `SELECT COUNT(*)` matched it exactly. The live SEC API itself only has 11 data points under that specific tag for Apple — likely because Apple, like many filers, stopped using the older `Revenues` tag for total revenue at some point (e.g. around the 2018 ASC 606 revenue-recognition standard change), consistent with all 11 rows tracing to one 2018 filing. **General lesson, still applies:** don't assume a low row count is a Zetaris defect — run the independent `curl`/`jq` check first (see "Verifying data" above); it may just mean the source API itself has less data under that specific query than expected.

### `CREATE LIGHTNING REST TABLE` (or the Data Explorer previewing a new source) returned an HTTP 502

Before assuming this is a missing header or authentication problem, check the endpoint directly with `curl` (see the "Before running" check at the top of each script). If a plain `curl` GET with no special headers returns `200`, the API itself doesn't require a `User-Agent`, `Accept` header, or authentication, and the 502 is not a header problem.

The more likely cause is rate limiting on the source API. Confirmed against Singapore's data.gov.sg PM2.5 endpoint: its documented limit ("5 requests/minute") is optimistic — repeated `curl` testing tripped a `429` after roughly 5-6 requests within 5-8 seconds, recovering to `200` again after about 30 seconds. This was observed to trip on that source's *first* `CREATE LIGHTNING REST TABLE` run, with no other query run first — one visible SQL statement does not necessarily mean only one HTTP request reached the endpoint (see the next entry below for direct proof of that general mechanism on a different source). That said, this specific case surfaced as a 502 rather than a passed-through 429 — a distinction worth not glossing over; see `failure_cases/singapore_pm25/ISSUE.md` for why that matters and what's still unresolved about it.

**Fix:** wait roughly 30 seconds and re-run the `CREATE LIGHTNING REST TABLE` statement, rather than retrying immediately or adding headers that the API doesn't actually require. Avoid `curl`-testing the same endpoint again right before retrying. If a 502 persists after waiting, check the API's own status directly (repeated `curl` calls a minute or so apart) before assuming it's a Zetaris-side problem.

**This is exactly what happened with the Singapore PM2.5 source.** It hasn't been re-tested after the wait-and-retry fix above — the other 8 sources in this package already cover the JSON-shape range needed, so it was set aside rather than spending further time on one source, and moved out of `sql/` into `failure_cases/singapore_pm25/` with a full reproduction and a root-cause hypothesis for engineering in `failure_cases/singapore_pm25/ISSUE.md`. If you hit this same failure mode on a different source, that document is a useful template for writing it up.

### A REST source's HTTP 502 is a cold-start problem, not rate limiting — and can surface as a client-side `TTransportException`

A second, distinct cause of the "HTTP 502" symptom above: confirmed live against `company_dns` (`sql/10_company_dns_sic_create.sql`, 2026-09-21), not every 502 is rate-limiting (Singapore's cause, previous entry). Some source APIs appear to run on infrastructure that scales to zero between requests (a serverless/cold-start host) — the *first* request after a period of no traffic gets a 502 from whatever's in front of the actual service, and a near-immediate retry succeeds cleanly. This was reproduced reliably (5 separate times in one session) with a small warm-up script that polls a lightweight endpoint (e.g. `/health`) on a short interval until it returns healthy, before running any `CREATE LIGHTNING REST TABLE` or `SELECT` against the real endpoint — see `scripts/warmup_company_dns.ts`.

**Important nuance not covered by the entry above:** this can surface two different ways depending on *which* statement hits the cold instance:
- If it happens on `CREATE LIGHTNING REST TABLE` itself, Zetaris reports it as a plain HTTP 502, same as the Singapore case.
- If it happens on a later `SELECT` (remember: a Lightning REST table re-fetches on every query, not just at `CREATE` time — see "Known limitations" above and the next entry below), Zetaris can instead report it as a **client-side `java.sql.SQLException: org.apache.thrift.transport.TTransportException`**, sometimes bundled as `Multiple exceptions were thrown (3), first java.sql.SQLException: ...` — the "(3)" reflects a connection pool retrying the same failing request across a few pooled connections. **Don't assume this wrapped exception means a structural problem** (oversized payload, too-wide inferred schema, etc.) just because the message looks like a low-level transport failure — check whether the *next* attempt, made immediately, succeeds before investigating anything else. In the confirmed case here, `DESCRIBE` on the same table succeeded (schema-only, no live re-fetch), a manual `curl` against the exact same URL succeeded, and the identical `SELECT COUNT(*)` succeeded immediately after re-running the warm-up script — conclusively pointing at cold-start timing, not payload size or schema width.

**Fix:** run (or re-run) a warm-up request immediately before the statement that's about to touch the real data, and retry immediately if a 502-flavored error appears — don't wait, and don't assume a redesign (chunking the request, changing the schema) is needed before ruling out cold start first.

### A query fails with a rate-limit error well after `CREATE LIGHTNING REST TABLE` already succeeded

Confirmed live against NASA NeoWs (`sql/05`, 2026-09-19): the `CREATE LIGHTNING REST TABLE` and `CREATE SCHEMASTORE VIEW` statements succeeded, and an early `SELECT` against the view worked fine — but a later, ordinary `SELECT` further down the same script failed with:

```
REST API call failed: Server returned HTTP response code: 429 for URL: https://api.nasa.gov/neo/rest/v1/neo/browse?api_key=DEMO_KEY
...
Response body: <html><body><h1>OVER_RATE_LIMIT</h1><p>You have exceeded your rate limit...
```

The URL in the error is the *original REST endpoint*, not anything Zetaris-internal — meaning that plain `SELECT` re-issued a live HTTP request to the source API, exactly like the `CREATE TABLE` statement did. **A Lightning REST table does not appear to be materialized once and reused; each query that touches it (directly, or through a view built on it) triggers a fresh call to the underlying endpoint.** Running a script's full set of verification and example queries against the same table can add up to many more requests than it looks like from reading the SQL, and will exhaust a strict rate limit partway through a session that started working fine.

**This confirms the general "one query, multiple HTTP calls" mechanism exists, but it does not fully explain the Singapore PM2.5 failure case** (`failure_cases/singapore_pm25/`) — that source returned an HTTP 502, not a 429, and Zetaris demonstrably *can* relay a clean 429 with the upstream error body intact (as shown above), so a 502 instead is a different failure signature, not just the same mechanism playing out on a stricter limit. The repeated-requests mechanism is still probably part of why that source fails at all, but the specific reason it surfaces as a 502 there and a 429 here remains unresolved. See `failure_cases/singapore_pm25/ISSUE.md` for the full, updated reasoning rather than assuming this entry settles it.

**Workaround, CONFIRMED WORKING (2026-09-21, `sql/10_company_dns_sic_create.sql`):** cache the raw REST table right after creating it, before running further queries, using the Lightning SQL Manual's documented `CACHE TABLE` statement:
```sql
CACHE TABLE <logical_datasource_name>.<raw_table_name>;
```
This loads the table into memory once so later queries read the cached copy instead of re-fetching. **Confirmed live against `company_dns.sic_codes_raw`:** an uncached `SELECT COUNT(*)` took `Query Time: 49.685s` (Zetaris's own UI-reported figure — the HTTP round-trip to the live endpoint dominates this); after `CACHE TABLE company_dns.sic_codes_raw;`, the identical query dropped to a **stable ~1.2s** across repeated runs — roughly a 40x improvement, and no longer showing the timing variance a live re-fetch would produce. This is the first confirmed case in this package of `CACHE TABLE` actually stopping the "every query re-fetches" behavior described above — every earlier attempt (`sql/05_nasa_neows_create.sql`) was blocked by a rate limit before the test could run at all. Not yet tested: whether caching the raw table also speeds up a `SCHEMASTORE VIEW` built on top of it (only the raw table itself was measured here) — test that the same way (time a `SELECT` against the view before and after caching the underlying raw table) before assuming it propagates. Release a cached table with `UNCACHE TABLE <same_name>;` when done.

**Known gaps, both now filed with Zetaris engineering (2026-09-22), not investigated further here:**
- **No configurable duration or storage location.** As documented above, `CACHE TABLE <name>;` takes no options at all — no TTL/duration, no storage-tier selection (memory vs. disk, etc.). A cache observed to have silently expired/reverted to uncached after some elapsed time (exact interval not established) is consistent with an undocumented, non-configurable default TTL — the user has filed this as an issue with Zetaris engineering rather than something to reverse-engineer here.
- **`SHOW CACHE TABLES` reports nothing, even right after a `CACHE TABLE` that's independently proven to be working** (the ~40x speedup above was measured *after* running it). The statement is named in the current SQL Guide's Auxiliary Statements list (see "Known limitations" above) but has no worked example anywhere in the docs; live behavior now confirmed to return empty regardless of actual cache state. Also filed with Zetaris engineering. Until/unless this is fixed, don't rely on `SHOW CACHE TABLES` to check whether a table is currently cached — the only confirmed way is the indirect one used above: time a query before and after `CACHE TABLE`, and compare.

If `CACHE TABLE` doesn't help, the practical fallback is to space out or reduce the number of queries run against a rate-limited source in one sitting, and to prefer a source's free registered API key over its anonymous/demo access when iterating on queries. **For NASA sources specifically** (`sql/05`, `sql/06` — they share one `DEMO_KEY` quota): register a free key directly at [api.nasa.gov](https://api.nasa.gov/) (First Name, Last Name, Email — key emailed back immediately, no approval wait), which raises the limit from DEMO_KEY's 30 req/hour (50/day) to 1,000 req/hour, confirmed 2026-09-19. Note the limit resets on a **rolling** basis per key, not a fixed clock hour — if `DEMO_KEY` is exhausted, the wait is up to an hour from your first request in the current window, not a short pause. This isn't just a convenience: testing `CACHE TABLE` as a fix for the behavior above needs enough request budget to actually exercise it, and running out of requests before confirming whether caching helps just reproduces the same failure rather than testing the fix.

### Can I `DROP` a REST table or its Lightning database?

Not reliably — see "Removing a source" above. `DROP VIEW` works; `DROP TABLE` and `DROP DATASOURCE` do not. Use the Zetaris Data Explorer to remove the underlying registration.

### `CREATE SCHEMASTORE CONTAINER` failed with a parse exception

This means the container name already exists — `CREATE SCHEMASTORE CONTAINER` has no `IF NOT EXISTS` form. Comment out that statement in the script and continue; see "Known limitations" above.

### `CREATE LIGHTNING DATABASE ... DESCRIBE BY "..."` failed with "Description is invalid"

The `DESCRIBE BY` string only accepts letters, digits, spaces, and `_ . - ,` — nothing else, confirmed live (2026-09-21, see "Known limitations" above). The error text names `_`, `.`, `-`, and `,` explicitly but doesn't mention that plain spaces are fine (they are — every live-tested script's own `DESCRIBE BY` uses them). It's punctuation like parentheses, slashes, or colons that fails, e.g. `"... (division/major group)"` — rewrite as `"... - division, major group"` (hyphen and comma instead of parens and slash) and it passes. This check runs before Zetaris does anything else with the statement — the REST endpoint isn't even contacted, so don't waste time debugging the `endpoint`/`HEADER`/`BODY` clauses on this error, it's purely the description text.

### How do I query a table once it's inside a Virtual Data Mart?

Not documented anywhere in the Zetaris Kbase — the VDM Overview page, "Processes for Automation: Virtual Data Mart creation / deletion," and Query Director's own page (which is about Spark/Presto engine routing, not VDMs, despite the similar name) all describe *building* a mart but never how to query through one. **Confirmed live (2026-09-21):** the syntax is a flat **2-part reference, `<mart_name>.<table_name>`** — not `<mart_name>.<original_container>.<table_name>`. The mart drops the original `SCHEMASTORE CONTAINER` prefix (e.g. `edgar.`, `company_dns.`) entirely and exposes each dragged-in table under the mart's own name, using whichever alias the VDM canvas shows as that node's "Virtual Table" name (visible in the mart-builder UI under each table card). Confirmed example, mart named `companies_mart` containing `edgar.all_companies_profile_table`:
```sql
SELECT * FROM companies_mart.all_companies_profile_table;
```
not `companies_mart.edgar.all_companies_profile_table`. If a table was renamed on the way into the mart (optional per the VDM Overview's own build steps), query it by that renamed "Virtual Table" alias, not its original source-side name.

---

## 9. Everything else

For license details and per-source docs links, see `rest-api-sources.md` in this package. For every other category (Kafka, filestore Parquet/CSV, logs, SQL RDBMS, PDFs, and the government open-data sections), see the roadmap in `../../docs/plans/FUTURES.md` and its per-category `docs/plans/recipes/*.md` files — the original research behind them is archived at `../../docs/plans/archive/quickstart-data-manifest.md`.
