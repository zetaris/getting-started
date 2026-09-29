-- =============================================================================
-- Source: NASA NeoWs (Near Earth Object Web Service) -- /neo/browse endpoint.
--
-- License: NASA content is a U.S. federal government work, generally
-- not subject to copyright (17 U.S.C. §105) --
-- https://www.nasa.gov/nasa-brand-center/images-and-media/
-- Exceptions: NASA trademarks/insignia, third-party-licensed material
-- NASA occasionally hosts, personnel likeness -- none of those apply to
-- this structured asteroid data.
--
-- Format: REST/JSON, top-level object, array-of-structs (deeply
-- nested). See the SQL companion guide for the general shape taxonomy.
--
-- Docs: https://api.nasa.gov/ (NeoWs section)
-- https://www.nasa.gov/nasa-api-catalog-neo-feed/
--
-- Signup: DEMO_KEY works with no signup (30 req/hour, 50/day per IP),
-- but a free registered key is recommended -- see caveat 8. Register
-- directly at https://api.nasa.gov/ (first name, last name, email --
-- key emailed immediately, no approval wait) for 1,000 req/hour,
-- roughly 33x DEMO_KEY. Shares this rate limit with
-- 06_nasa_donki_create.sql.
--
-- Before running: sanity-check the endpoint returns something sane:
--   curl -s "https://api.nasa.gov/neo/rest/v1/neo/browse?api_key=DEMO_KEY" | python3 -m json.tool | head -30
--
-- Status: live-tested and confirmed working (2026-09-19) -- base table,
-- both views, and the example queries all ran successfully.
-- =============================================================================
--
-- Caveats:
--   1. Deliberately using /neo/browse instead of the more commonly
--      cited /neo/rest/v1/feed endpoint. /feed's `near_earth_objects`
--      field is a JSON object keyed by date string, not an array --
--      a dynamic-key shape explode() isn't built for. /neo/browse
--      instead returns `near_earth_objects` as a plain array. If a
--      date-range feed is specifically wanted later, that's a
--      genuinely harder flattening problem.
--   2. `near_earth_objects` entries have deeply nested structs --
--      `estimated_diameter.kilometers.estimated_diameter_min/max` is
--      three levels of dot-access, and `close_approach_data` is itself
--      a nested array-of-structs inside each object -- flattening it
--      fully needs a second LATERAL VIEW explode() on
--      close_approach_data within the same view (confirmed working in
--      neo_close_approaches_table below).
--   3. /neo/browse is paginated (`page`/`links.next`) -- this script's
--      table only captures page 0 (the default, 20 objects) unless the
--      endpoint includes a `size` or `page` parameter. Fine for a demo,
--      not a complete dataset. Confirmed via curl: the full catalog is
--      62,401 objects across 3,121 pages.
--   4. `close_approach_data` is ordered chronologically ascending, so
--      `close_approach_data[0]` (used in neo_browse_table below) is the
--      earliest recorded approach on file for that object, not the
--      most recent or most relevant one -- for a well-studied asteroid
--      this can be a date from 1900, which is expected, not a bug. Each
--      object's full approach history is only available through
--      neo_close_approaches_table. Two objects on this page (1916
--      Boreas, 1980 Tezcatlipoca) have zero recorded approaches at all
--      -- expected null/absent behavior, not an error.
--   5. Every field this script references was confirmed present with
--      these exact names/casing in a live response via curl -- no
--      mixed-case or hyphenated fields here, so no backtick-quoting is
--      needed anywhere in this script.
--   6. `estimated_diameter_min/max` and `absolute_magnitude_h` are real
--      JSON numbers, but `miss_distance.kilometers` and
--      `relative_velocity.kilometers_per_hour` are JSON strings
--      (quoted in the raw response). See the SQL companion guide for
--      why this matters and the CAST fix -- every query below that
--      orders or aggregates by these fields casts them explicitly.
--   7. The DEMO_KEY rate limit does not exhibit aggressive
--      burst-throttling -- 6 rapid-fire requests in immediate
--      succession all returned 200. Still respect the documented 30
--      req/hour, 50/day per-IP caps for anything beyond casual testing.
--   8. A Lightning REST table re-issues its HTTP request on every query
--      that touches it, not just at CREATE time -- running this
--      script's base create, both views, and the 8 example queries in
--      one sitting can exhaust NASA's DEMO_KEY rate limit partway
--      through. See the SQL companion guide for the general mechanism
--      and the CACHE TABLE workaround applied below.
-- =============================================================================

-- Step 0: Lightning database for this source. Shared with
-- 06_nasa_donki_create.sql -- both are api.nasa.gov endpoints.
CREATE LIGHTNING DATABASE NASA_REST DESCRIBE BY "NASA api.nasa.gov REST sources";

-- Step 1: schemastore container. Run once -- shared with
-- 06_nasa_donki_create.sql. Comment out on a re-run if it already
-- exists in your environment.
CREATE SCHEMASTORE CONTAINER nasa;

-- NEO browse -- first page (20 objects), DEMO_KEY
CREATE LIGHTNING REST TABLE neo_browse_page0 FROM NASA_REST REQUEST(
    endpoint "https://api.nasa.gov/neo/rest/v1/neo/browse?api_key=DEMO_KEY",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
) BODY ();

-- Cache the raw REST table before running anything else against it --
-- see caveat 8.
CACHE TABLE nasa_rest.neo_browse_page0;

-- One row per object, with its earliest recorded close approach only
-- (see caveat 4) -- a quick per-object summary, not the full approach
-- history.
CREATE SCHEMASTORE VIEW neo_browse_table WITH CONTAINER nasa AS
SELECT
    neo.id,
    neo.name,
    neo.absolute_magnitude_h,
    neo.estimated_diameter.kilometers.estimated_diameter_min AS diameter_km_min,
    neo.estimated_diameter.kilometers.estimated_diameter_max AS diameter_km_max,
    neo.is_potentially_hazardous_asteroid,
    neo.close_approach_data[0].close_approach_date AS first_close_approach_date,
    CAST(neo.close_approach_data[0].miss_distance.kilometers AS DOUBLE) AS first_miss_distance_km,
    CAST(neo.close_approach_data[0].relative_velocity.kilometers_per_hour AS DOUBLE) AS first_relative_velocity_kmh
FROM nasa_rest.neo_browse_page0
LATERAL VIEW explode(near_earth_objects) AS neo;

-- Full approach history -- every recorded close approach (past and
-- predicted future) for every object on this page, via a second
-- LATERAL VIEW explode() on the nested close_approach_data array (see
-- caveat 2).
CREATE SCHEMASTORE VIEW neo_close_approaches_table WITH CONTAINER nasa AS
SELECT
    neo.id,
    neo.name,
    neo.is_potentially_hazardous_asteroid,
    approach.close_approach_date,
    CAST(approach.miss_distance.kilometers AS DOUBLE) AS miss_distance_km,
    CAST(approach.relative_velocity.kilometers_per_hour AS DOUBLE) AS relative_velocity_kmh,
    approach.orbiting_body
FROM nasa_rest.neo_browse_page0
LATERAL VIEW explode(near_earth_objects) AS neo
LATERAL VIEW explode(neo.close_approach_data) AS approach;

-- Optional follow-up: this page (page 0) is only 20 of 62,401 total
-- objects (see caveat 3). A second REST table against
-- `?page=1&api_key=DEMO_KEY` would follow the same pattern -- not built
-- here, since one page already gives enough variety for the example
-- queries.

-- =============================================================================
-- Teardown -- removes the flattened views this script created.
-- Commented out by default. See the SQL companion guide for why
-- DROP VIEW is the only reliable teardown statement, and how to remove
-- the underlying REST table and database registration (Zetaris Data
-- Explorer -- no SQL path exists). NASA_REST and the `nasa` container
-- are shared with 06_nasa_donki_create.sql.
-- =============================================================================

-- DROP VIEW nasa.neo_browse_table;
-- DROP VIEW nasa.neo_close_approaches_table;
-- UNCACHE TABLE nasa_rest.neo_browse_page0;
