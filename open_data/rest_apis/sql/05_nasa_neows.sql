-- =============================================================================
-- Source:   NASA NeoWs (Near Earth Object Web Service) -- /neo/browse endpoint
-- License:  NASA content is a U.S. federal government work, generally not
--           subject to copyright (17 U.S.C. §105) --
--           https://www.nasa.gov/nasa-brand-center/images-and-media/
--           Exceptions: NASA trademarks/insignia, third-party-licensed
--           material NASA occasionally hosts, personnel likeness -- none of
--           those apply to this structured asteroid data.
-- Format:   REST/JSON, top-level object, array-of-structs (deeply nested)
-- Docs:     https://api.nasa.gov/ (NeoWs section) ·
--           https://www.nasa.gov/nasa-api-catalog-neo-feed/
-- Signup:   DEMO_KEY works with no signup (30 req/hour, 50/day per IP); a
--           free api.data.gov key (same one used for the SEC/data.gov keys
--           elsewhere, if you register one) raises this to 1,000 req/hour.
-- Before running: sanity-check the endpoint returns something sane --
--   curl -s "https://api.nasa.gov/neo/rest/v1/neo/browse?api_key=DEMO_KEY" | python3 -m json.tool | head -30
-- =============================================================================
--
-- Investigated (not yet live-tested against Zetaris) 2026-09-19:
--   1. DELIBERATELY using /neo/browse instead of the more commonly-cited
--      /neo/rest/v1/feed endpoint. /feed's `near_earth_objects` field is a
--      JSON OBJECT KEYED BY DATE STRING (e.g. {"2026-09-15": [...],
--      "2026-09-16": [...]}), not an array -- that's a dynamic-key shape
--      SQL's LATERAL VIEW explode() isn't built for (you'd need to
--      backtick-quote a literal date as a field name, and that date
--      changes every query). /neo/browse instead returns
--      `near_earth_objects` as a PLAIN ARRAY -- the same array-of-structs
--      shape used successfully elsewhere in this package. If a date-range
--      feed is specifically wanted later, that's a genuinely harder
--      flattening problem -- don't just swap the endpoint back without
--      solving that first.
--   2. `near_earth_objects` entries have DEEPLY nested structs --
--      `estimated_diameter.kilometers.estimated_diameter_min/max` is three
--      levels of dot-access, and `close_approach_data` is itself a NESTED
--      ARRAY-OF-STRUCTS inside each NEO record (an array inside an
--      exploded array element) -- flattening that fully would need a
--      SECOND LATERAL VIEW explode() on close_approach_data within the
--      same view. This script flattens one level (the NEO record itself)
--      and pulls the FIRST close-approach entry via array indexing
--      (close_approach_data[0]) rather than a double explode, to keep the
--      first attempt simple -- see the optional follow-up at the bottom
--      for the full double-explode version.
--   3. /neo/browse is PAGINATED (`page`/`links.next`) -- this script's
--      table only captures page 0 (the default, 20 objects) unless the
--      endpoint includes a `size` or `page` parameter. Fine for a first
--      test; not a complete dataset.
--
-- ---------------------------------------------------------------------------
-- STEP 0: Lightning database for this source. Shared with sql/06 (DONKI) --
-- both are NASA api.nasa.gov endpoints, same pattern as EDGAR sharing
-- SEC_DATA across 7 companies.
-- ---------------------------------------------------------------------------
CREATE LIGHTNING DATABASE NASA_REST DESCRIBE BY "NASA api.nasa.gov REST sources";

-- ---------------------------------------------------------------------------
-- STEP 1: SCHEMASTORE container. RUN ONCE -- see open_data/rest_apis/HOWTO.md
-- sec 2 (no IF NOT EXISTS support). Shared with sql/06 (DONKI). Comment out
-- on a re-run if it already exists in your environment.
-- ---------------------------------------------------------------------------
CREATE SCHEMASTORE CONTAINER nasa;

-- =============================================================================
-- NEO BROWSE -- first page (20 objects), DEMO_KEY
-- =============================================================================
CREATE LIGHTNING REST TABLE neo_browse_page0 FROM NASA_REST REQUEST(
    endpoint "https://api.nasa.gov/neo/rest/v1/neo/browse?api_key=DEMO_KEY",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
) BODY ();

-- Flattened view -- near_earth_objects is the array-of-structs field (see
-- caveat 1); close_approach_data[0] takes only the FIRST approach record
-- per object rather than a full double-explode (see caveat 2):
CREATE SCHEMASTORE VIEW neo_browse_table WITH CONTAINER nasa AS
SELECT
    neo.id,
    neo.name,
    neo.absolute_magnitude_h,
    neo.estimated_diameter.kilometers.estimated_diameter_min AS diameter_km_min,
    neo.estimated_diameter.kilometers.estimated_diameter_max AS diameter_km_max,
    neo.is_potentially_hazardous_asteroid,
    neo.close_approach_data[0].close_approach_date   AS first_close_approach_date,
    neo.close_approach_data[0].miss_distance.kilometers AS first_miss_distance_km,
    neo.close_approach_data[0].relative_velocity.kilometers_per_hour AS first_relative_velocity_kmh
FROM nasa_rest.neo_browse_page0
LATERAL VIEW explode(near_earth_objects) AS neo;

-- Verify:
SELECT * FROM nasa.neo_browse_table;

-- ---------------------------------------------------------------------------
-- Diagnostic (run if the view above fails or comes back empty):
--   SELECT * FROM nasa_rest.neo_browse_page0;
--   DESCRIBE nasa_rest.neo_browse_page0;
-- If array-indexing syntax (close_approach_data[0]) isn't supported by
-- Zetaris's SQL dialect, that's worth reporting back -- try the full
-- double-explode version below instead.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Optional, full double-explode version (every close approach, not just the
-- first) -- try this if array indexing above doesn't work, or if the demo
-- specifically wants full approach history per object:
-- CREATE SCHEMASTORE VIEW neo_browse_all_approaches_table WITH CONTAINER nasa AS
-- SELECT
--     neo.id,
--     neo.name,
--     approach.close_approach_date,
--     approach.miss_distance.kilometers AS miss_distance_km,
--     approach.relative_velocity.kilometers_per_hour AS relative_velocity_kmh,
--     approach.orbiting_body
-- FROM nasa_rest.neo_browse_page0
-- LATERAL VIEW explode(near_earth_objects) AS neo
-- LATERAL VIEW explode(neo.close_approach_data) AS approach;
-- ---------------------------------------------------------------------------
