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
-- Investigated (not yet live-tested against Zetaris) 2026-09-19:
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
--   3. NOTE: the manifest's other suggested StatCan endpoint,
--      getCubeMetadata, is a POST with a JSON request body and returns a
--      TWO-LEVEL nested array (dimension[].member[]) -- meaningfully more
--      complex than this one. Deliberately started with
--      getChangedCubeList instead since it's simpler and GET-based; a
--      getCubeMetadata script can be added later once the REST POST-with-
--      body pattern (needed for BODY(...) with actual content, unlike
--      every other script in this package so far which uses empty
--      BODY()) is confirmed to work.
--   4. `productId` is a StatCan "cube" (dataset) identifier -- this table
--      alone is a discovery/catalog view (what changed recently), not the
--      actual statistical data. Pairs naturally with a follow-up
--      getDataFromCubePidCoord call once a productId of interest is found
--      -- not built here, flagged as a follow-up.
--
-- ---------------------------------------------------------------------------
-- STEP 0: Lightning database for this source.
-- ---------------------------------------------------------------------------
CREATE LIGHTNING DATABASE STATCAN_REST DESCRIBE BY "Statistics Canada WDS REST source";

-- ---------------------------------------------------------------------------
-- STEP 1: SCHEMASTORE container. RUN ONCE -- see open_data/rest_apis/HOWTO.md
-- sec 2 (no IF NOT EXISTS support). Comment out on a re-run if it already
-- exists in your environment.
-- ---------------------------------------------------------------------------
CREATE SCHEMASTORE CONTAINER statcan;

-- =============================================================================
-- CHANGED CUBES -- a recent date; swap for whatever date you confirmed has
-- data via the Before-running curl check above.
-- =============================================================================
CREATE LIGHTNING REST TABLE changed_cubes_20260915 FROM STATCAN_REST REQUEST(
    endpoint "https://www150.statcan.gc.ca/t1/wds/rest/getChangedCubeList/2026-09-15",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
) BODY ();

-- Flattened view -- object is the array-of-structs field (see caveat 1):
CREATE SCHEMASTORE VIEW changed_cubes_table WITH CONTAINER statcan AS
SELECT
    status          AS request_status,
    cube.productId  AS product_id,
    cube.releaseTime AS release_time,
    cube.responseStatusCode
FROM statcan_rest.changed_cubes_20260915
LATERAL VIEW explode(object) AS cube;

-- Verify:
SELECT * FROM statcan.changed_cubes_table;

-- ---------------------------------------------------------------------------
-- Diagnostic (run if the view above fails or comes back empty -- likely
-- means the date in the URL had no published changes, not a Zetaris
-- problem, given how simple this shape is):
--   SELECT * FROM statcan_rest.changed_cubes_20260915;
--   DESCRIBE statcan_rest.changed_cubes_20260915;
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Attribution reminder (Statistics Canada Open Licence, per the license
-- note above) -- carry this into any README or demo:
--   "Adapted from Statistics Canada, [dataset/cube name], [access date].
--   This does not constitute an endorsement by Statistics Canada of this
--   product."
-- ---------------------------------------------------------------------------
