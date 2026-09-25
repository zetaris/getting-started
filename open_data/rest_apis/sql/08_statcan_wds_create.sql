-- =============================================================================
-- Source:   Statistics Canada Web Data Service (WDS) -- getChangedCubeList
-- License:  Statistics Canada Open Licence --
--           https://www.statcan.gc.ca/en/terms-conditions/open-licence --
--           same permissive family as OGL-Canada 2.0 and the UK's OGL,
--           attribution required, plus an added restriction: don't combine
--           StatCan data with other sources to re-identify individuals.
-- Format:   REST/JSON, top-level object wrapping a plain array-of-structs
--           (the simplest, cleanest shape investigated in this package)
-- Docs:     https://www.statcan.gc.ca/en/developers/wds/user-guide
-- Rate limit: no key or registration needed; rate-limited at 50 req/sec
--           system-wide, 25/sec per IP.
-- Before running: sanity-check the endpoint returns something sane --
--   curl -s "https://www150.statcan.gc.ca/t1/wds/rest/getChangedCubeList/2026-09-15" | python3 -m json.tool | head -20
-- (swap the date for a recent one -- this endpoint only has data for dates
-- StatCan actually published changes on)
-- =============================================================================
--
-- Live-tested and confirmed working (2026-09-19): the base REST table and
-- changed_cubes_table view both created and verified successfully in
-- Zetaris. Extended the same day with a 5-day window (a UNION ALL cross-
-- date view, the same pattern as PokéAPI's/Open Food Facts' cross-record
-- views) and 8 analytical queries (see sql/08_statcan_wds_select.sql).
-- Queries 3, 7, and 8 hit the known self-join/MISSING_ATTRIBUTES error
-- live on their first run (see caveat 8) and were rewritten with window
-- functions -- validated against the same live data independently, but
-- the rewritten versions have not yet been re-run against Zetaris to
-- confirm.
--
-- Investigated 2026-09-19:
--   1. Response shape: {status: "SUCCESS", object: [{responseStatusCode,
--      productId, releaseTime}, ...]} -- `object` is a PLAIN ARRAY OF FLAT
--      STRUCTS, no nesting beyond one level. This is the cleanest, simplest
--      shape found across every source investigated in this package so
--      far -- a good "does the basic pattern work at all" smoke test if
--      something more complex (Eurostat, DONKI) is failing and you want to
--      isolate whether the problem is Zetaris's REST connector in general
--      or something specific to a harder source.
--   2. This is a simple GET with no query parameters beyond the date in the
--      URL path itself -- no request body, no headers needed.
--   3. INVESTIGATED AND BLOCKED (2026-09-19): the manifest's other
--      suggested StatCan endpoint, getCubeMetadata, would have been a
--      natural follow-up -- it returns human-readable cube titles
--      (`cubeTitleEn`) instead of opaque `productId` numbers, which would
--      make the queries below far more readable. It's a POST with a JSON
--      ARRAY request body (e.g. `[{"productId":14100004}]`), confirmed
--      via curl to STRICTLY require `Content-Type: application/json` --
--      a form-urlencoded body (the only body format ever confirmed
--      working with Zetaris's `BODY(...)` clause in this package, and
--      what `http_encoding "URLENCODED"` implies) was tested directly
--      against the live endpoint and rejected outright with HTTP 415
--      Unsupported Media Type. There is no confirmed Zetaris syntax in
--      this package for a REQUEST(...) BODY(...) clause that sends a raw
--      JSON body instead of form-encoded key/value pairs -- until one is
--      found (e.g. an `http_encoding "JSON"` option, untested), this
--      endpoint is NOT reachable via this package's established pattern.
--      This is a specific, confirmed blocker, not just "untested" --
--      flagged here rather than attempted blindly. This script sticks
--      to getChangedCubeList and works entirely with productId numbers
--      as a result.
--   4. `productId` is a StatCan "cube" (dataset) identifier -- this table
--      is a discovery/catalog view (what changed recently), not the
--      actual statistical data. Pairs naturally with a follow-up
--      getDataFromCubePidCoord call once a productId of interest is
--      found -- not built here, flagged as a follow-up.
--   5. `productId`, `releaseTime`, and `responseStatusCode` are all
--      mixed-case -- per the confirmed EDGAR/PokéAPI rule (HOWTO.md,
--      "Troubleshooting / FAQ"), all three need backtick-quoting. Fixed
--      below.
--   6. FINDING, confirmed via curl across 5 consecutive days
--      (2026-09-14 through 2026-09-18, 127 total change records): every
--      single release happens at exactly the same time of day, "08:30"
--      -- StatCan publishes changed-cube notifications on a fixed daily
--      schedule, not continuously throughout the day.
--      sql/08_statcan_wds_select.sql query 6 confirms this from inside
--      Zetaris rather than assuming it from the curl investigation.
--   7. FINDING, same 5-day investigation: of 119 unique products that
--      changed at least once in this window, only 2 changed on EVERY
--      single day (productId 33100036 and 10100139) -- genuinely
--      continuously-updated "daily cubes," as opposed to the other 117
--      products which each changed on just one or two of the five days.
--      sql/08_statcan_wds_select.sql query 3 finds these programmatically
--      rather than hardcoding the two IDs found during investigation.
--   8. CONFIRMED FAILING live (2026-09-19), then fixed: queries 3, 7, and
--      8's original forms each referenced `changed_cubes_all_table` (a
--      UNION ALL of 5 exploded REST tables) more than once in the same
--      query -- once directly, once inside a `WHERE ... IN (SELECT ...)`
--      or a scalar `HAVING x = (SELECT ...)` subquery. This is the same
--      self-reference pitfall already confirmed on Open Food Facts
--      (sql/03) and documented in HOWTO.md, "Troubleshooting / FAQ" --
--      `MISSING_ATTRIBUTES.RESOLVED_ATTRIBUTE_APPEAR_IN_OPERATION` on the
--      `explode(object)` operator behind the view. Fixed the same way:
--      rewritten to reference the view exactly once per query, using
--      `COUNT(*) OVER (PARTITION BY product_id)` window functions (or, in
--      query 3, a plain `HAVING COUNT(*) = 5` since a literal is simpler
--      and just as correct for a known, fixed 5-day window) instead of
--      any subquery that reads the same view a second time. This is now
--      the SECOND source in this package to hit this exact error class --
--      treat "does this query reference the same UNION ALL'd exploded
--      view more than once, anywhere in the query, including inside a
--      WHERE/HAVING subquery" as a standard thing to check before running
--      a new query against any multi-record cross-union view in this
--      package.
--
-- ---------------------------------------------------------------------------
-- STEP 0: Lightning database for this source.
-- ---------------------------------------------------------------------------
CREATE LIGHTNING DATABASE STATCAN_REST DESCRIBE BY "Statistics Canada WDS REST source";

-- ---------------------------------------------------------------------------
-- STEP 1: SCHEMASTORE container. RUN ONCE -- see open_data/rest_apis/HOWTO.md,
-- "Known limitations" (no IF NOT EXISTS support). Comment out on a re-run
-- if it already exists in your environment.
-- ---------------------------------------------------------------------------
CREATE SCHEMASTORE CONTAINER statcan;

-- =============================================================================
-- CHANGED CUBES -- a 5-day window (2026-09-14 through 2026-09-18), one REST
-- table per day, the same "one REST table per record group, unioned into a
-- cross-record view" pattern as PokéAPI's per-Pokémon tables (sql/02) and
-- Open Food Facts' per-product tables (sql/03). Swap the dates for a recent
-- window via the Before-running curl check above.
-- =============================================================================
CREATE LIGHTNING REST TABLE changed_cubes_20260914 FROM STATCAN_REST REQUEST(
    endpoint "https://www150.statcan.gc.ca/t1/wds/rest/getChangedCubeList/2026-09-14",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
) BODY ();

CREATE LIGHTNING REST TABLE changed_cubes_20260915 FROM STATCAN_REST REQUEST(
    endpoint "https://www150.statcan.gc.ca/t1/wds/rest/getChangedCubeList/2026-09-15",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
) BODY ();

CREATE LIGHTNING REST TABLE changed_cubes_20260916 FROM STATCAN_REST REQUEST(
    endpoint "https://www150.statcan.gc.ca/t1/wds/rest/getChangedCubeList/2026-09-16",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
) BODY ();

CREATE LIGHTNING REST TABLE changed_cubes_20260917 FROM STATCAN_REST REQUEST(
    endpoint "https://www150.statcan.gc.ca/t1/wds/rest/getChangedCubeList/2026-09-17",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
) BODY ();

CREATE LIGHTNING REST TABLE changed_cubes_20260918 FROM STATCAN_REST REQUEST(
    endpoint "https://www150.statcan.gc.ca/t1/wds/rest/getChangedCubeList/2026-09-18",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
) BODY ();

-- Flattened view -- object is the array-of-structs field (see caveat 1) --
-- kept exactly as originally confirmed working, still just 2026-09-17:
CREATE SCHEMASTORE VIEW changed_cubes_table WITH CONTAINER statcan AS
SELECT
    status                        AS request_status,
    cube.`productId`             AS product_id,
    cube.`releaseTime`           AS release_time,
    cube.`responseStatusCode`    AS response_status_code
FROM statcan_rest.changed_cubes_20260917
LATERAL VIEW explode(object) AS cube;

-- Cross-date view -- one row per (date, changed product) pair across the
-- full 5-day window, the long-format analog to changed_cubes_table:
CREATE SCHEMASTORE VIEW changed_cubes_all_table WITH CONTAINER statcan AS
SELECT '2026-09-14' AS snapshot_date, cube.`productId` AS product_id, cube.`releaseTime` AS release_time
FROM statcan_rest.changed_cubes_20260914
LATERAL VIEW explode(object) AS cube
UNION ALL
SELECT '2026-09-15' AS snapshot_date, cube.`productId` AS product_id, cube.`releaseTime` AS release_time
FROM statcan_rest.changed_cubes_20260915
LATERAL VIEW explode(object) AS cube
UNION ALL
SELECT '2026-09-16' AS snapshot_date, cube.`productId` AS product_id, cube.`releaseTime` AS release_time
FROM statcan_rest.changed_cubes_20260916
LATERAL VIEW explode(object) AS cube
UNION ALL
SELECT '2026-09-17' AS snapshot_date, cube.`productId` AS product_id, cube.`releaseTime` AS release_time
FROM statcan_rest.changed_cubes_20260917
LATERAL VIEW explode(object) AS cube
UNION ALL
SELECT '2026-09-18' AS snapshot_date, cube.`productId` AS product_id, cube.`releaseTime` AS release_time
FROM statcan_rest.changed_cubes_20260918
LATERAL VIEW explode(object) AS cube;

-- =============================================================================
-- TEARDOWN -- removes the flattened views this script created. Commented
-- out by default so a re-run of the file above doesn't accidentally wipe
-- a live environment; uncomment and run standalone when you want to tear
-- these views down.
--
-- DROP VIEW is the only teardown statement confirmed to work reliably in
-- this package. There is no SQL statement confirmed to remove the raw
-- REST tables or the STATCAN_REST Lightning database registration itself
-- -- see HOWTO.md, "Removing a source" and "Troubleshooting / FAQ", for
-- the full explanation.
-- =============================================================================

-- DROP VIEW statcan.changed_cubes_table;
-- DROP VIEW statcan.changed_cubes_all_table;

-- To remove the STATCAN_REST REST tables and Lightning database
-- registration, use the Zetaris Data Explorer's "File Source & API"
-- panel (see HOWTO.md, "Removing a source").

-- Next: verify with sql/08_statcan_wds_select.sql
