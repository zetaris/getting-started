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

### JSON response shapes — a taxonomy from investigating 8 more sources (2026-09-19)

`LATERAL VIEW explode(<array_field>) AS fact` followed by dot-access (`fact.val`, `fact.accn`, ...) works when a JSON field is an **array of objects** (array-of-structs) — confirmed for EDGAR's `units.USD`. Investigating candidates for `sql/02`–`sql/09` surfaced four distinct response shapes, with very different risk levels for this pattern:

1. **Top-level object, array-of-structs field(s)** — the confirmed-working shape (EDGAR `sql/01`, PokéAPI `sql/02`, Open Food Facts live API `sql/03`, NASA NeoWs `sql/05` via `/neo/browse`). `explode()` + dot-access works directly. Some of these nest a struct *inside* the array's struct (PokéAPI's `ability.ability.name`, two levels deep) — untested whether Zetaris supports that depth, flagged per-script.
2. **Top-level object, array-of-structs nested under a non-array wrapper key** — Singapore's PM2.5 API (`sql/04`): the array lives at `data.items`, not the top level, and each item's per-region breakdown (`readings.pm25_one_hourly`) is itself a **fixed struct, not an array** — no inner `explode()` needed there, just deeper dot-access.
3. **Top-level JSON array (no wrapping object at all)** — NASA DONKI's CME endpoint (`sql/06`). Every confirmed-working source so far returns a top-level *object*; whether `CREATE LIGHTNING REST TABLE` can register a table from a bare top-level array is **unknown and untested** — this is flagged as the first thing to check for that script, before worrying about flattening.
4. **SDMX-family formats (JSON-stat 2.0 / SDMX-JSON 2.0.0)** — Eurostat (`sql/07`) and the Australian ABS Data API (`sql/09`). These are **not row-oriented at all** — they're sparse, multi-dimensional arrays addressed by computed offset keys (Eurostat) or compound colon-separated dimension-index tuples with a further nested time-index (ABS), decoded against separate `dimension`/`structure` metadata. There's no array-of-structs to explode. **High risk of being a dead end** for this package's pattern — both scripts fall back to exposing only the dimension *metadata* as a view and flag the actual value data as possibly requiring a transform outside SQL entirely, or being dropped.

A **parallel-arrays** shape (separate `times: [...]` and `values: [...]` meant to be read pairwise) hasn't been hit yet in this package but would need `posexplode()` + positional indexing instead of a plain `explode()` — don't assume array-of-structs is universal for a future source; confirm the actual JSON shape (`curl` or the browser) before writing a new script's `SELECT`.

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

Suggested order — lowest-risk / simplest shape first, so a failure on a harder source doesn't block confirming the basic pattern works at all (see sec 2's shape taxonomy):

| Order | Script | Why here |
|---|---|---|
| 1 | `01_edgar_company_facts.sql` | Already live-tested and working — confirms the baseline pattern end to end. |
| 2 | `08_statcan_wds.sql` | Simplest shape investigated (flat array-of-structs, one level, GET-only) — good smoke test if something else is failing. |
| 3 | `02_pokeapi.sql` | Array-of-structs with one extra level of nested struct — tests whether two-level dot-access through an exploded field works. |
| 4 | `03_open_food_facts_live.sql` | Array-of-structs with sparse/optional fields across entries — tests schema-inference tolerance for inconsistent struct shapes. |
| 5 | `04_singapore_pm25.sql` | Array nested under a non-top-level wrapper key, with a fixed (non-array) struct per item — a different shape class from 1–4. |
| 6 | `05_nasa_neows.sql` | Array-of-structs with deep nesting (3 levels) and a nested array-within-array (`close_approach_data`) — tests indexing (`[0]`) vs. a second `explode()`. |
| 7 | `06_nasa_donki.sql` | ⚠️ Top-level JSON array, not object — untested whether `CREATE LIGHTNING REST TABLE` even accepts this at all. |
| 8 | `07_eurostat.sql` | ⚠️ JSON-stat format, no array-of-structs anywhere — likely drop candidate. |
| 9 | `09_abs_data_api.sql` | ⚠️ SDMX-JSON with doubly-compound dynamic keys — same risk class as Eurostat, likely drop candidate. |

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
