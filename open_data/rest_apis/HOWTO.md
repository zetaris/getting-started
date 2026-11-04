# HOWTO: onboard these REST API sources into Zetaris

Start with [Start here](../../START-HERE.md) and [your first dataset](../../docs/guides/first-dataset.md). On your own local or AWS instance, use your chosen database and container names consistently.


**File naming:** each source has a numbered `_create.sql` file for DDL and a matching `_select.sql` file for verification and examples. Run the create script first. Verification and optional queries in the select files are commented out by default.

**Source folders:** each source's script pair lives in one of four folders under `sql/`, based on whether the source API enforces a rate limit and whether the script is still current:

- `sql/rate_limited/` — the source API caps how many requests you can make in a given window. Some operators set the limit themselves, so it differs between deployments. For `company_dns` it depends on whether you identify yourself: Callers that identify themselves (a User-Agent of the form `app_name user@domain.tld`) get 6,000 requests a minute (100 a second) with a burst of 600, per address. Callers that do not (no User-Agent, a library default, or a name with no contact) get 600 a minute with a burst of 60, a limit raised for the event; the service default is 5 a minute with a burst of 1. A burst larger than the allowance gets HTTP `429` even when the average is low. Run these deliberately: send an identifying `User-Agent`, run one statement at a time, cache the raw table straight away (`CACHE TABLE`, which these scripts do for you), and if you cannot identify yourself wait 15 seconds or more before each statement that calls the endpoint. Prefer a registered API key over an anonymous one where the source offers it, and expect the `CACHE TABLE` guidance in "Known limitations" below to matter more here than elsewhere. Every `_select.sql` here keeps its queries commented out: run them one at a time after the cache test the file describes.
- `sql/non_rate_limited/` — no documented limit, or an informal one (e.g. a fair-use policy) with no hard cap observed in testing. Still be a reasonable citizen of a shared free resource, but you don't need to plan around exhausting a quota.
- `sql/known_to_fail/` — NASA DONKI, which hit a blocking issue during testing, plus the issue record for Singapore's PM2.5 API (its scripts moved to `sql/rate_limited/` after a later run passed). Kept as documented, reproducible examples rather than deleted; not part of the main sequence below. See `sql/known_to_fail/README.md`.

- `sql/deprecated/` — scripts that a newer script replaced (currently the old V3-only `company_dns` script, replaced by `rate_limited/12_company_dns_*.sql`). Kept for reference, marked DEPRECATED in their own header and in the catalog, and refused by `scripts/onboard.py` unless you pass `--allow-deprecated`. Do not run a deprecated script and its replacement on the same instance: they create the same names.

`rest-api-sources.md`'s quick-reference table lists which folder each source is in.

---

## 0. Fast start: `company_dns` end to end in about 10 minutes

The fastest way to see this package's whole pattern — register, cache, flatten, verify — working on a real, live source, before reading anything else. This uses `company_dns` (`sql/rate_limited/12_company_dns_create.sql` / `_select.sql`), a SIC industry-classification hierarchy, loaded from both of its API versions side by side.

**It is rate limited, and the limit depends on whether you identify yourself.** Callers that identify themselves (a User-Agent of the form `app_name user@domain.tld`) get 6,000 requests a minute (100 a second) with a burst of 600, per address. Callers that do not (no User-Agent, a library default, or a name with no contact) get 600 a minute with a burst of 60, a limit raised for the event; the service default is 5 a minute with a burst of 1. Send an identifying User-Agent and you can work at a normal pace, one statement at a time. Without one, wait **15 seconds or more** before each statement marked "calls the endpoint" in the script. The script caches each raw table right after creating it, which is what keeps every later query from calling the service again. If a statement fails with a `429`, wait 60 seconds and retry that one statement.

1. Set your user-agent, in the form `app_name user@domain.tld` (for example `zetaris dev@zetaris.com`). `company_dns` V4 requires it: a bare app name, a library default or no User-Agent at all gets the strict limit. The create scripts carry a `YOUR_APP_NAME YOUR_CONTACT_EMAIL` placeholder: replace it by hand, or put `ZETARIS_USER_AGENT="app_name user@domain.tld"` in `.env.local` and let `scripts/run_sql.py` fill it in (it refuses a value that doesn't name a contact e-mail).
2. Open `12_company_dns_create.sql` and run its steps in the Zetaris **SQL Editor**, one statement at a time:

   | Step | Statement | Calls the endpoint? |
   |---|---|---|
   | 0 | `CREATE LIGHTNING DATABASE COMPANY_DNS` | no |
   | 1 | `CREATE LIGHTNING REST TABLE sic_codes_raw` (V3, production) | yes |
   | 2 | `CACHE TABLE company_dns.sic_codes_raw` | yes |
   | 3 | `CREATE LIGHTNING REST TABLE sic_codes_v4_raw` (V4, production) | yes |
   | 4 | `CACHE TABLE company_dns.sic_codes_v4_raw` | yes |
   | 5 | `CREATE SCHEMASTORE CONTAINER company_dns` | no |
   | 6-9 | four `CREATE SCHEMASTORE VIEW` statements | no (they read the cached tables) |

   Without an identifying User-Agent, wait 15 seconds or more before each step that calls the endpoint. **Hosts:** `company_dns` V4 is now served by `https://company-dns.mediumroast.io` and V3 is deprecated. The staging host (`company-dns-staging.mediumroast.io`) is retired: do not use it. The `/V3.0` path still answered on the production host when checked (2026-10-19), which is why step 1 still works, but expect it to go away.

   Steps 1-2 and 3-4 are two copies of one pattern — register the raw response, cache it, flatten it with `LATERAL VIEW explode(...)` — for two response shapes: V3 returns a dynamic-key object that needs the `from_json(to_json(...))` coercion (section 7), V4 returns a plain array.
3. Verify it worked, timing the first query. About a second means the view reads the cached copy; much longer means it called the service again, so stop and check the cache step:
   ```sql
   SELECT COUNT(*) FROM company_dns.sic_codes_table;   -- expect 1005
   ```
4. Try a real query — every SIC code in the "Manufacturing" division, for example:
   ```sql
   SELECT sic_code, description, major_group_desc
   FROM company_dns.sic_codes_table
   WHERE division_desc LIKE '%Manufacturing%'
   ORDER BY sic_code;
   ```

The script builds four views so the two versions can be compared and so existing SQL keeps working: `sic_codes_table` (V3 data, V3 column names, the name everything else in this repo uses), `sic_codes_v4_table` (V4 data, V4 names), and two `_compat_` views that carry one version's data under the other's column names. **V4 renamed the hierarchy levels**, so `division_desc` means a different level in each version (V3: the letter level, "Manufacturing"; V4: the 2-digit level). The script's header has the full mapping table. `12_company_dns_select.sql` has the verification queries (commented out; run them one at a time) and the example queries in both naming schemes.

Two more classification systems from the same service follow the same pattern with a single view each: `13_company_dns_eu_nace_*` (EU NACE, 615 classes) and `14_company_dns_japan_*` (Japan, 1,460 classes). Everything below explains this pattern in more depth — how to run it against any of the other sources in this package (`1. Running the scripts`), how to check your results are trustworthy (`2. Verifying data`), what to do when something doesn't go as smoothly as it did here, and the full syntax/shape/limitations reference.

---

## 1. Running the scripts

1. Open the Zetaris **SQL Editor**.
2. For each source in `sql/`, in order:
   - Read the `_create.sql` header and its caveats.
   - Run the `CREATE LIGHTNING DATABASE` statement (Step 0).
   - Create the SchemaStore container once; skip this statement if it already exists.
   - Fill required `HEADER` values. SEC EDGAR requires a real `User-Agent`.
   - Run each `CREATE LIGHTNING REST TABLE` and `CREATE SCHEMASTORE VIEW` statement.
   - Run the matching verification query in `_select.sql` before trusting the result.

Suggested order, from simpler verified patterns to higher-risk shapes:

| Order | Script | Why here |
|---|---|---|
| 1 | `rate_limited/12_company_dns_create.sql` | Already walked through above (Fast Start) — confirms your environment works before trying anything new. Rate limited: send an identifying User-Agent. |
| 2 | `rate_limited/01_edgar_company_facts_create.sql` | Live-tested and working — confirms the baseline array-of-structs pattern end to end. |
| 3 | `rate_limited/08_statcan_wds_create.sql` | Simplest shape investigated (flat array-of-structs, one level, GET-only) — good smoke test if something else is failing. |
| 4 | `non_rate_limited/02_pokeapi_create.sql` | Array-of-structs with one extra level of nested struct — tests whether two-level dot-access through an exploded field works. |
| 5 | `rate_limited/03_open_food_facts_live_create.sql` | Array-of-structs with sparse/optional fields across entries — tests schema-inference tolerance for inconsistent struct shapes. |
| 6 | `rate_limited/05_nasa_neows_create.sql` | Array-of-structs with deep nesting (3 levels) and a nested array-within-array (`close_approach_data`) — tests indexing (`[0]`) vs. a second `explode()`. |
| 7 | `non_rate_limited/07_eurostat_create.sql` | Metadata path confirmed working; JSON-stat format needs the dynamic-key coercion technique (see "Understanding JSON response shapes" below) to decode actual values. |
| 8 | `non_rate_limited/09_abs_data_api_create.sql` | Higher risk: SDMX-JSON with doubly-compound dynamic keys — same risk class as Eurostat, likely drop candidate. |
| 9 | `rate_limited/13_company_dns_eu_nace_create.sql` | Same flat-array shape as `company_dns` V4, one view; a different classification system (EU NACE). Rate limited. |
| 10 | `rate_limited/14_company_dns_japan_create.sql` | Same shape again (Japan, 1,460 classes). Rate limited, same service as 12 and 13. |
| 11 | `rate_limited/04_singapore_pm25_create.sql` | Array-of-structs under a non-array wrapper key (`data.items`), plus a one-pass `stack()` unpivot. Tight burst limit: run one statement at a time; the script caches the raw table straight after creating it. |

---

## 2. Verifying data

For every source, run the verification query in its `_select.sql` (commented out by default):

1. Count rows in the Zetaris view.
2. Count the matching array directly from the API with `curl` and `jq`, for example:
   ```bash
   curl -s -A "YOUR_APP_NAME YOUR_CONTACT_EMAIL" \
     https://data.sec.gov/api/xbrl/companyconcept/CIK0000320193/us-gaap/Revenues.json \
     | jq '.units.USD | length'
   ```
3. Compare counts before analysis. A lower Zetaris count may mean truncation; check the source response first. On EDGAR, the direct API and Zetaris both returned 11 rows for Apple's `us-gaap:Revenues` tag.

---

## 3. Removing a source

On 12 October 2026, Zetaris 2.4.3.1 accepted these commands against disposable public-S3 file tables and a PokeAPI REST table:

- `DROP LIGHTNING DATABASE TABLE sqltest_20261012_files.reason` (file table)
- `DROP LIGHTNING DATABASE TABLE sqltest_20261012_files.ability` (PokeAPI REST table)
- `DROP LIGHTNING DATABASE sqltest_20261012_files`

The database drop succeeded after its test tables were removed. This does not establish behavior for every connector. Use the exact `DROP LIGHTNING DATABASE TABLE` form; the check does not establish that generic `DROP TABLE` works. `DROP DATASOURCE` was not validated for these Lightning registrations.

`DROP VIEW <container>.<view>` removes a SchemaStore view. Container removal was performed through the documented API after confirming `viewCount` was zero; this validation did not establish a SQL command for dropping a container. Script `TEARDOWN` blocks therefore keep their `DROP VIEW` statements and direct readers here for source cleanup.

---

## 4. Troubleshooting / FAQ

### My query failed with an unresolved-column error mentioning a mixed-case, reserved-word, or hyphenated field name

A JSON field may need backticks when it uses mixed case, a reserved word, spaces, or punctuation such as a hyphen. For example, use `` `entityName` ``, `` fact.`start` ``, or `` product.nutriments.`energy-kcal_100g` ``. Check the source keys before writing a view.

The unquoted forms may fail or parse incorrectly because Zetaris treats the name as a different identifier or as an operator.

### My query failed with `UNRESOLVED_COLUMN`, referencing a column that "doesn't exist" on a view I expected to have it

Check the view's own `CREATE SCHEMASTORE VIEW ... AS SELECT` list. A comment or a similar view may name columns this view does not expose.

Check the raw response too. Singapore PM2.5's documented `national` field was absent from the JSON; see caveat 2 in [`rate_limited/04_singapore_pm25_create.sql`](sql/rate_limited/04_singapore_pm25_create.sql).

### My query failed with `MISSING_ATTRIBUTES.RESOLVED_ATTRIBUTE_APPEAR_IN_OPERATION`

This can occur when one query reads the same `UNION ALL` view built with `LATERAL VIEW explode(...)` more than once, including through a self-join or subquery. For example:

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

The analyzer can see conflicting internal attributes from the repeated exploded view. This was reproduced with StatCan `IN` and scalar subqueries and an Open Food Facts self-join. Joins between distinct views did not show the issue.

**Fix:** use a window function so the query reads the view once:

```sql
SELECT key, val
FROM (
    SELECT key, val, ROW_NUMBER() OVER (PARTITION BY key ORDER BY val DESC) AS rn
    FROM some_view
) ranked
WHERE rn = 1;
```

Use `COUNT(*) OVER (PARTITION BY key)` for group counts or `ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)` to select a top row. See the StatCan and Open Food Facts select scripts for examples.

The same error can come from a view *definition*. Singapore PM2.5's long-format view, written as five `UNION ALL` branches over one view, failed at `CREATE SCHEMASTORE VIEW`. One pass with `LATERAL VIEW stack(n, 'label', value, ...)` over the base table builds the same rows; see caveat 5 in [`rate_limited/04_singapore_pm25_create.sql`](sql/rate_limited/04_singapore_pm25_create.sql).

### A numeric-looking field sorts or compares wrong (e.g. "closest" or "smallest" picks the wrong row)

JSON may encode numeric-looking values as strings. NeoWs distance and velocity fields are quoted strings, so Zetaris can sort them lexicographically. Cast them to `DOUBLE`, `INT`, or `BIGINT` in the view before numeric comparisons or aggregation.

### A JSON-stat / SDMX source returns an empty result even though the dataset should have data

Eurostat silently returns an empty result for an invalid dimension code such as `age=Y15-74`. Check `dimension.<name>.category.index` for valid codes before concluding the dataset has no matching rows.

### A table's row count looks lower than I expect

Compare the Zetaris count with a direct API count first. Apple's EDGAR `us-gaap:Revenues` endpoint returned 11 rows in both checks; a low count can reflect the source's selected tag, not connector truncation.

### `CREATE LIGHTNING REST TABLE` (or the Data Explorer previewing a new source) returned an HTTP 502

Check the endpoint directly with `curl` before changing headers or authentication. The Singapore PM2.5 endpoint returned HTTP 200 to a plain GET, but rapid testing hit 429 after about 5–6 requests in 5–8 seconds and recovered after about 30 seconds. Its first Zetaris registration (cloud SQL Workspace) returned 502, not the upstream 429. A later run on Zetaris 2.4.3.1 through the SQL API did not reproduce the 502: rapid uncached queries surfaced the source's own 429, and `CACHE TABLE` stopped the re-fetching. The original 502 is not yet reconciled; see the [issue write-up](sql/known_to_fail/ISSUE.md).

Wait about 30 seconds before retrying a rate-limited endpoint. Avoid probing it with repeated `curl` calls immediately beforehand. If 502s persist, check the source API again at a slower interval.

### A REST source's HTTP 502 is a cold-start problem, not rate limiting — and can surface as a client-side `TTransportException`

A second, distinct cause of the "HTTP 502" symptom above: not every 502 is rate-limiting (Singapore's cause, previous entry). Some source APIs appear to run on infrastructure that scales to zero between requests (a serverless/cold-start host) — the *first* request after a period of no traffic gets a 502 from whatever's in front of the actual service, and a near-immediate retry succeeds cleanly. `company_dns` showed this pattern reliably while it ran on Azure Container Apps; it has since moved to a host that does not scale to zero and is no longer affected, so it no longer needs a warm-up script (the old one was removed). The fix for a source that does behave this way is to make one cheap request first (a `/health` endpoint, if it has one) until it answers, before running the `CREATE LIGHTNING REST TABLE` or `SELECT` that touches the real endpoint. Do not do this against a rate-limited source — see the next entries.

This can surface two different ways depending on *which* statement hits the cold instance:
- If it happens on `CREATE LIGHTNING REST TABLE` itself, Zetaris reports it as a plain HTTP 502, same as the Singapore case.
- If it happens on a later `SELECT` (remember: a Lightning REST table re-fetches on every query, not just at `CREATE` time — see `docs/guides/zetaris-lightning-sql-companion.md` section 5 and the next entry below), Zetaris can instead report it as a client-side `java.sql.SQLException: org.apache.thrift.transport.TTransportException`, sometimes bundled as `Multiple exceptions were thrown (3), first java.sql.SQLException: ...` — the "(3)" reflects a connection pool retrying the same failing request across a few pooled connections. Don't assume this wrapped exception means a structural problem (oversized payload, too-wide inferred schema, etc.) just because the message looks like a low-level transport failure — check whether the *next* attempt, made immediately, succeeds before investigating anything else. A `DESCRIBE` on the same table succeeding (schema-only, no live re-fetch) alongside a manual `curl` against the exact same URL succeeding points at cold-start timing, not payload size or schema width.

**Fix:** make one cheap request immediately before the statement that's about to touch the real data, and retry immediately if a 502-flavored error appears — don't wait, and don't assume a redesign (chunking the request, changing the schema) is needed before ruling out cold start first. On a rate-limited source, retry once, then wait: see the `429` entry below.

### A rate-limited source returns `429`, even though I am sending very few queries

The operator of a service like `company_dns` sets its limits, so they differ between deployments. For `company_dns` the allowance depends on whether you identify yourself: Callers that identify themselves (a User-Agent of the form `app_name user@domain.tld`) get 6,000 requests a minute (100 a second) with a burst of 600, per address. Callers that do not (no User-Agent, a library default, or a name with no contact) get 600 a minute with a burst of 60, a limit raised for the event; the service default is 5 a minute with a burst of 1. A burst larger than the allowance gets `429` even when the average rate is low, so a handful of requests close together can trip the strict tier. Two things multiply the request count behind one statement: a Lightning REST table re-fetches on every query (next entry), and Zetaris can retry a failing fetch on a few pooled connections.

**Fix:** send an identifying User-Agent (`app_name user@domain.tld`), which alone lifts the allowance from 600 to 6,000 a minute; run the create script one statement at a time; if you cannot identify yourself, wait 15 seconds or more before each statement it marks "calls the endpoint"; cache the raw table straight away (`CACHE TABLE`) so later queries read the cached copy; after a `429`, wait 60 seconds and retry that one statement rather than re-running the script. Time the first query after the cache step: about a second means it read the cache. If you are unsure which tier you are on, check which User-Agent your script actually sent: a vague one puts you on the strict tier.

### `WHERE division_desc LIKE '%Manufacturing%'` returns nothing against the V4 `company_dns` data

V4 renamed the four hierarchy levels, so a column name can mean a different level than it did in V3. V3's `division` (letter) is V4's `section_id`, V3's `major_group` (2-digit) is V4's `division_id`, V3's `industry_group` (3-digit) is V4's `group_id`, and V3's `sic_code` is V4's `class_id`. "Manufacturing" is a `division_desc` in V3 but a `section_desc` in V4. Use `sic_codes_v4_compat_table` to run V3-era SQL unchanged against V4 data, or the V4 names against `sic_codes_v4_table`. `12_company_dns_create.sql` has the full mapping table.

### A query fails with a rate-limit error well after `CREATE LIGHTNING REST TABLE` already succeeded

On NASA NeoWs, registration and an early SELECT succeeded; a later SELECT returned:

```
REST API call failed: Server returned HTTP response code: 429 for URL: https://api.nasa.gov/neo/rest/v1/neo/browse?api_key=DEMO_KEY
...
Response body: <html><body><h1>OVER_RATE_LIMIT</h1><p>You have exceeded your rate limit...
```

The error URL was the source endpoint. A REST table is registered at CREATE time, but an uncached query fetches the endpoint again. Repeated SELECTs can therefore exhaust rate limits. This does not explain the distinct PM2.5 502; its cause remains unresolved in the [issue write-up](sql/known_to_fail/ISSUE.md).

**Workaround:** cache the raw REST table right after creating it, before running further queries, using the `CACHE TABLE` statement:
```sql
CACHE TABLE <logical_datasource_name>.<raw_table_name>;
```
Caching `company_dns.sic_codes_raw` reduced the UI-reported count query from 49.685 seconds to about 1.2 seconds. Whether that cache also speeds up dependent SchemaStore views has not been tested. Use `UNCACHE TABLE <same_name>;` to release it.

`CACHE TABLE` is explicit in-memory caching. It is distinct from Adaptive Cache; its persistence and status reporting are limited. `SHOW CACHE TABLES` does not prove explicit-cache membership. See the [SQL companion](../../docs/guides/zetaris-lightning-sql-companion.md#5-operational-limitations-confirmed-live-not-documentation-guesses) for details and materialization options.

If caching does not help, reduce or space out queries and use a registered key where available. NASA's `DEMO_KEY` allows 30 requests/hour and 50/day per IP; a free key allows 1,000/hour. The shared quota resets on a rolling basis.

### Can I `DROP` a REST table or its Lightning database?

On 12 October 2026, `DROP LIGHTNING DATABASE TABLE` removed one PokeAPI REST table on Zetaris 2.4.3.1. See "Removing a source" above for the exact command and limits. This does not establish that generic `DROP TABLE` works for every connector.

### `CREATE SCHEMASTORE CONTAINER` failed with "A container named ... already exists"

`CREATE SCHEMASTORE CONTAINER` has no `IF NOT EXISTS` form. If it already exists, skip that statement or use `python3 scripts/run_sql.py --skip-exists FILE`; see the [SQL companion](../../docs/guides/zetaris-lightning-sql-companion.md#5-operational-limitations-confirmed-live-not-documentation-guesses).

### `CREATE LIGHTNING DATABASE ... DESCRIBE BY "..."` failed with "Description is invalid"

`DESCRIBE BY` accepts letters, digits, spaces, `_`, `.`, `-`, and `,`. Parentheses, slashes, and colons fail. For example, replace `"... (division/major group)"` with `"... - division, major group"`. This validation runs before Zetaris contacts the endpoint.

### How do I query a table once it's inside a Virtual Data Mart?

Use `<mart_name>.<table_name>`. The mart omits the original `SCHEMASTORE CONTAINER` prefix and uses the VDM node's "Virtual Table" alias. For example, a mart named `companies_mart` containing `edgar.all_companies_profile_table`:
```sql
SELECT * FROM companies_mart.all_companies_profile_table;
```
If the VDM renamed the table, use its alias instead of the source name.

---

## 5. Basic syntax

`CREATE LIGHTNING REST TABLE` registers the endpoint response; `CREATE SCHEMASTORE VIEW` flattens it into columns. REST requests use `endpoint`, `HEADER`, and `BODY`, not a file `PATH`. See the [Parquet/CSV guide](../parquet_csv/HOWTO.md) for file tables.

The general shape (the Fast Start above is a filled-in, real version of this):

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
-- companion guide sec 5 (docs/guides/zetaris-lightning-sql-companion.md) -- this can only be created ONCE per name).
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

Register `<logical_datasource_name>` with `CREATE LIGHTNING DATABASE` before referencing it in `FROM`.

---

## 6. Known limitations

See the [SQL companion](../../docs/guides/zetaris-lightning-sql-companion.md#5-operational-limitations-confirmed-live-not-documentation-guesses) for platform limits on containers, teardown, request re-fetching, cache behavior, JSON bodies, `DESCRIBE BY`, and row counts.

Two issues are specific to these sources:

- Singapore PM2.5 has a burst limit far tighter than documented (about 5–6 requests in 5–8 seconds). Cache the raw table straight after creating it, as the script does; see its caveat 4.
- StatCan's `getCubeMetadata` requires `Content-Type: application/json`; the form-encoded request returned 415 in direct `curl` testing. This is the package's example of the JSON-body limitation.

---

## 7. Understanding JSON response shapes

See the [SQL companion's REST-shape sections](../../docs/guides/zetaris-lightning-sql-companion.md#2-rest-tables-the-shape-you-must-plan-for-before-writing-sql) for `explode()`, dot-access, dynamic keys, and field types.

Source shapes in this package:

1. **Top-level object, array-of-structs field(s)** (companion guide §2, case 1) — EDGAR, PokéAPI, Open Food Facts live API, NASA NeoWs, and the `company_dns` V4, EU NACE and Japan endpoints (a flat array of objects directly under `data`, so a plain `explode(data)` is enough). PokéAPI nests a struct *inside* the array's struct (`ability.ability.name`, two levels deep, confirmed working). Open Food Facts' `ingredients` array goes further still — some entries are compound ingredients carrying their own nested `ingredients` sub-array (e.g. a biscuit's "Céréale" entry breaking down into wheat flour and whole wheat flour) — a single `explode()` only reaches the top-level entries; going deeper would need a second `explode()`, not built in that script.
2. **Array-of-structs nested under a non-array wrapper key** (companion guide §2, case 2) — Singapore's PM2.5 API (`sql/rate_limited/04_singapore_pm25_create.sql`): the array lives at `data.items`, each item's per-region breakdown (`readings.pm25_one_hourly`) is itself a fixed struct, not an array.
3. **Top-level JSON array, no wrapping object** (companion guide §2, case 3) — NASA DONKI's CME endpoint (known to fail: NASA's gateway returns HTTP 503 for it, see `sql/known_to_fail/ISSUE-06-nasa-donki.md`). Every confirmed-working source so far returns a top-level object; whether `CREATE LIGHTNING REST TABLE` can register a table from a bare top-level array is untested, and may be related.
4. **Dynamic-key ("map-shaped") object** (companion guide §3) — Eurostat, the Australian ABS Data API, and `company_dns`'s V3 SIC lookup (see the Fast Start above; its V4 endpoint dropped the dynamic keys) all use the `from_json(to_json(...), 'map<...>')` coercion technique. For Eurostat specifically, the sparse `value` object is addressable two ways — a low-risk option (direct backtick-quoted dot-access to specific known-present numeric keys, e.g. `` value.`522` ``) and the higher-risk full-decode coercion, which needs to be applied to *every* dynamic-key object exploded in the same query — see `sql/non_rate_limited/07_eurostat_create.sql`'s caveats for the exact error a partial application produces. Whether the same technique helps ABS's doubly-compound-key structure is untested and likely harder, since ABS needs two levels of key decoding, not one.
5. **Flat struct, no array anywhere** — Open Food Facts' `product.nutriments`, plain dot-access all the way down (`product.nutriments.sugars_100g`), no `LATERAL VIEW explode()` involved. Don't reach for `explode()` reflexively on every nested field; check whether the JSON node is actually an array first.

No source here uses parallel arrays such as `times: [...]` and `values: [...]`. That shape needs `posexplode()` and positional indexing; inspect the response before writing a query.

---

## 8. Everything else

For licenses and source links, see [`rest-api-sources.md`](rest-api-sources.md). The [SQL companion](../../docs/guides/zetaris-lightning-sql-companion.md#1-the-two-onboarding-patterns-this-repo-has-proven) compares REST, file, and JDBC onboarding. Other categories are tracked in [`docs/plans/FUTURES.md`](../../docs/plans/FUTURES.md).

### PLACES: Census Tract Data (GIS Friendly Format), 2025 release

The 15_cdc_places_tracts pair registers the Socrata endpoint for one county's 71 tracts (a bare JSON array, so columns read directly), caches the raw table, and creates a records view. Verified live on 2026-10-26. Licence and source details are in the catalog.

### Census TIGERweb census tracts

The 16_census_tigerweb pair registers an ArcGIS MapServer query for the same county's 71 tracts, explodes the `features` array (2,000 records per page, one page here), caches the raw table, and creates a records view. Verified live on 2026-10-26. Licence and source details are in the catalog.
