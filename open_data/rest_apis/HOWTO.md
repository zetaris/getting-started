# HOWTO: onboard these REST API sources into Zetaris

The general walkthrough for the `sql/` scripts in this package — read this once before running any of them.

---

## 1. The SQL syntax these scripts use

Every script uses two Zetaris DDL statements together: `CREATE LIGHTNING REST TABLE`, which registers a REST endpoint's raw JSON response as a queryable table, and `CREATE SCHEMASTORE VIEW`, which flattens that raw JSON into a proper tabular view. This is a different pattern from the Parquet/CSV package's `CREATE LIGHTNING FILESTORE TABLE` (`../parquet_csv/HOWTO.md`) — REST sources don't have a file `PATH`, they have an `endpoint`, `HEADER`, and `BODY`.

The general shape:

```sql
-- Step 0: register the logical database (same prerequisite as filestore
-- tables -- see ../parquet_csv/HOWTO.md sec 1, confirmed 2026-09).
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

-- Step 2: a SCHEMASTORE container to hold flattened views (see sec 2 --
-- this can only be created ONCE per name).
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

## 2. Confirmed gotchas — read before you spend time debugging

### `CREATE SCHEMASTORE CONTAINER` can only be run once per name

**Confirmed via `LightningDdlParseException`** (2026-09-18): unlike most `CREATE` statements, `CREATE SCHEMASTORE CONTAINER` does not support `IF NOT EXISTS` — it's simply not in that statement's grammar. Running it a second time against a name that already exists fails outright, not silently.

**Practical handling for now:** every script in `sql/` creates its container in a clearly-marked, standalone statement near the top. If you're re-running a script against an environment where the container already exists (e.g. from an earlier interactive session), comment that one line out before running the rest.

**Open item, not yet built:** a small external precheck (a script using whatever query interface Zetaris exposes outside the SQL Editor — not yet researched) could check for the container's existence before attempting to create it, so these scripts could become safely re-runnable. This needs Zetaris's external query/API surface investigated first; see `docs/plans/recipes/01-rest-json-apis.md` for tracking. Until then, treat every `CREATE SCHEMASTORE CONTAINER` statement in this package as run-once-manually.

**Untested so far:** whether `CREATE LIGHTNING DATABASE` has the same one-time-only limitation, or tolerates being re-run. Worth confirming — if it also fails on a second run, every script in both this package and `../parquet_csv/` needs the same "comment this out on a re-run" treatment for that statement too, not just `CREATE SCHEMASTORE CONTAINER`.

### Mixed-case and reserved-word JSON field names need backtick-quoting

A REST API's JSON response often has camelCase or mixed-case field names (e.g. `entityName`), which Zetaris's SQL layer doesn't accept unquoted or double-quoted — they need backticks: `` `entityName` ``, not `"entityname"` or bare `entityname`. Separately, JSON field names that collide with SQL reserved words (e.g. `start`, `end`) need backtick-quoting too, even if they're not mixed-case, e.g. `` fact.`start` ``.

### Array-of-structs vs. other nested shapes

`LATERAL VIEW explode(<array_field>) AS fact` followed by dot-access (`fact.val`, `fact.accn`, ...) works when a JSON field is an **array of objects** (array-of-structs) — confirmed for EDGAR's `units.USD`. A REST API that instead returns **parallel arrays** (e.g. separate `times: [...]` and `values: [...]` arrays meant to be read pairwise) needs a different flattening approach (typically `posexplode()` on one array, then indexing into the other by position) — don't assume the array-of-structs pattern is universal across every future REST source added here. Confirm the actual JSON shape (via `curl` or the browser) before writing a new script's `SELECT`.

### Possible response-truncation bug — verify row counts, don't trust them

Live-tested against EDGAR: a table's row count came back suspiciously low (11 rows, capping out years before the company's real filing history ends) in a way that looks like the REST connector truncating the response mid-array rather than the API actually having that little data. **Not yet confirmed as a Zetaris bug vs. some other explanation** (pagination the connector doesn't follow, a caching layer, etc.) — see sec 4 below for the verification query to run before trusting any REST-sourced row count in this package.

---

## 3. Running the scripts

1. Open the Zetaris **SQL Editor**.
2. For each script in `sql/`, in order:
   - Read the header comment and every numbered caveat.
   - Run the `CREATE LIGHTNING DATABASE` statement (Step 0).
   - Run the `CREATE SCHEMASTORE CONTAINER` statement **once** (Step 1) — skip it if the container already exists in your environment (see sec 2).
   - Fill in any required `HEADER` values (e.g. a real `user-agent` string — some APIs, like SEC EDGAR, reject default/missing ones).
   - Run each `CREATE LIGHTNING REST TABLE` + `CREATE SCHEMASTORE VIEW` pair.
   - Run the verification query (sec 4) before trusting the result.

---

## 4. Verifying a table/view actually has correct (non-truncated) data

For every REST source in this package:

1. `SELECT COUNT(*) FROM <container>.<view_name>;` — get the row count Zetaris thinks it has.
2. Independently query the same endpoint with `curl` + `jq` (or equivalent) and count the array length directly, e.g.:
   ```bash
   curl -s -A "YOUR_APP_NAME YOUR_CONTACT_EMAIL" \
     https://data.sec.gov/api/xbrl/companyconcept/CIK0000320193/us-gaap/Revenues.json \
     | jq '.units.USD | length'
   ```
3. If the Zetaris count is lower than the direct API count, the connector is truncating — don't trust that table for real analysis until that's resolved.

---

## 5. Going further

- **Adding another REST source:** confirm the license, confirm the actual JSON shape (array-of-structs vs. parallel arrays vs. something else — see sec 2), write the `CREATE LIGHTNING REST TABLE` + `CREATE SCHEMASTORE VIEW` pair using this document's syntax reference, and add a verification query per sec 4.
- **Filestore sources instead of REST:** that's `CREATE LIGHTNING FILESTORE TABLE` — see `../parquet_csv/HOWTO.md`.
- **JDBC/relational sources instead of REST:** that's `CREATE DATASOURCE` — see `../parquet_csv/HOWTO.md` sec 6 for the pointer.

---

## 6. Everything else

For license details and per-source docs links, see `rest-api-sources.md` in this package. For every other category (Kafka, filestore Parquet/CSV, logs, SQL RDBMS, PDFs, and the government open-data sections), see the main `../../quickstart-data-manifest.md` and the roadmap in `../../docs/plans/FUTURES.md`.
