-- =============================================================================
-- Source: Statistics Canada Web Data Service (WDS) -- getChangedCubeList.
-- Registers one REST table per day across a 5-day window (2026-09-14
-- through 2026-09-18), then a per-day view and a cross-date union view.
--
-- License: Statistics Canada Open Licence --
-- https://www.statcan.gc.ca/en/terms-conditions/open-licence -- attribution
-- required, plus an added restriction: don't combine StatCan data with
-- other sources to re-identify individuals.
--
-- Format: REST/JSON, top-level object wrapping a plain array-of-structs
-- -- the simplest, cleanest shape in this package.
--
-- Docs: https://www.statcan.gc.ca/en/developers/wds/user-guide
--
-- Rate limit: no key or registration needed; rate-limited at 50
-- req/sec system-wide, 25/sec per IP.
--
-- Before running: sanity-check the endpoint returns something sane
-- (swap the date for a recent one -- this endpoint only has data for
-- dates StatCan actually published changes on):
--   curl -s "https://www150.statcan.gc.ca/t1/wds/rest/getChangedCubeList/2026-09-15" | python3 -m json.tool | head -20
--
-- Status: live-tested and confirmed working (2026-09-19) -- the base
-- REST tables, both views, and the example queries all ran
-- successfully. Queries 3, 7, and 8 hit a self-join error on their
-- first run (see caveat 5) and were rewritten with window functions.
-- =============================================================================
--
-- Caveats:
--   1. Response shape: {status: "SUCCESS", object: [{responseStatusCode,
--      productId, releaseTime}, ...]} -- `object` is a plain array of
--      flat structs, no nesting beyond one level.
--   2. This is a simple GET with no query parameters beyond the date in
--      the URL path itself -- no request body, no headers needed.
--   3. `getCubeMetadata`, a natural follow-up that returns
--      human-readable cube titles instead of opaque productId numbers,
--      is confirmed blocked. It's a POST with a JSON array request
--      body, confirmed via curl to strictly require
--      `Content-Type: application/json` -- a form-urlencoded body (the
--      only body format confirmed working with Zetaris's `BODY(...)`
--      clause) was tested directly against the live endpoint and
--      rejected outright with HTTP 415 Unsupported Media Type. This
--      script sticks to getChangedCubeList and works entirely with
--      productId numbers as a result.
--   4. Confirmed via curl across 5 consecutive days (2026-09-14 through
--      2026-09-18, 127 total change records): every single release
--      happens at exactly the same time of day, "08:30" -- StatCan
--      publishes changed-cube notifications on a fixed daily schedule,
--      not continuously throughout the day. Of 119 unique products
--      that changed at least once in this window, only 2 changed on
--      every single day (productId 33100036 and 10100139).
--   5. Queries 3, 7, and 8's original forms each referenced
--      `changed_cubes_all_table` (a union of 5 exploded REST tables)
--      more than once in the same query -- once directly, once inside
--      a subquery -- and failed with
--      MISSING_ATTRIBUTES.RESOLVED_ATTRIBUTE_APPEAR_IN_OPERATION. See
--      the SQL companion guide for why. Fixed by rewriting to reference
--      the view exactly once per query, using window functions (or, in
--      query 3, a plain `HAVING COUNT(*) = 5` since a literal is
--      simpler and just as correct for a known, fixed 5-day window).
-- =============================================================================

-- Step 0: Lightning database for this source.
CREATE LIGHTNING DATABASE STATCAN_REST DESCRIBE BY "Statistics Canada WDS REST source";

-- Step 1: schemastore container. Run once -- comment out on a re-run
-- if it already exists in your environment.
CREATE SCHEMASTORE CONTAINER statcan;

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

-- Flattened view -- object is the array-of-structs field (see caveat
-- 1) -- just 2026-09-17.
CREATE SCHEMASTORE VIEW changed_cubes_table WITH CONTAINER statcan AS
SELECT
    status AS request_status,
    cube.`productId` AS product_id,
    cube.`releaseTime` AS release_time,
    cube.`responseStatusCode` AS response_status_code
FROM statcan_rest.changed_cubes_20260917
LATERAL VIEW explode(object) AS cube;

-- Cross-date view -- one row per (date, changed product) pair across
-- the full 5-day window, the long-format analog to
-- changed_cubes_table.
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
-- Teardown -- removes the flattened views this script created.
-- Commented out by default. See the SQL companion guide for why
-- DROP VIEW is the only reliable teardown statement, and how to remove
-- the underlying REST tables and database registration (Zetaris Data
-- Explorer -- no SQL path exists).
-- =============================================================================

-- DROP VIEW statcan.changed_cubes_table;
-- DROP VIEW statcan.changed_cubes_all_table;
