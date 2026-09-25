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
-- Signup:   DEMO_KEY works with no signup (30 req/hour, 50/day per IP) but
--           RECOMMENDED to register a free key instead -- see caveat 9
--           below, this script's own testing hit the DEMO_KEY limit.
--           Register directly at https://api.nasa.gov/ (First Name, Last
--           Name, Email -- key emailed immediately, no approval wait,
--           confirmed 2026-09-19) for 1,000 req/hour, roughly 33x DEMO_KEY.
-- Before running: sanity-check the endpoint returns something sane --
--   curl -s "https://api.nasa.gov/neo/rest/v1/neo/browse?api_key=DEMO_KEY" | python3 -m json.tool | head -30
-- =============================================================================
--
-- Live-tested and confirmed working (2026-09-19): base table and the
-- neo_browse_table view both created and verified successfully. Extended
-- the same day with a second, full-history view and 8 example queries (see
-- sql/05_nasa_neows_select.sql).
--
-- Investigated 2026-09-19:
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
--      exploded array element) -- flattening that fully needs a SECOND
--      LATERAL VIEW explode() on close_approach_data within the same
--      view. Confirmed working below (neo_close_approaches_table) -- the
--      double-explode pattern is fine, same as any other LATERAL VIEW.
--   3. /neo/browse is PAGINATED (`page`/`links.next`) -- this script's
--      table only captures page 0 (the default, 20 objects) unless the
--      endpoint includes a `size` or `page` parameter. Fine for a demo;
--      not a complete dataset. Confirmed via curl: the full catalog is
--      62,401 objects across 3,121 pages.
--   4. `close_approach_data` is ordered CHRONOLOGICALLY ASCENDING, so
--      `close_approach_data[0]` (used in neo_browse_table below) is the
--      EARLIEST recorded approach on file for that object, not the most
--      recent or most relevant one. For a well-studied asteroid like 433
--      Eros this can be a date from 1900 -- expected, not a bug. Each
--      object's full approach history -- past AND predicted future
--      approaches, out to the year 2187 for some objects -- is only
--      available through neo_close_approaches_table below; example queries
--      6-8 in sql/05_nasa_neows_select.sql use it for exactly this reason.
--      Two objects on this page (1916 Boreas, 1980 Tezcatlipoca) have ZERO
--      recorded approaches at all -- expected null/absent behavior, not an
--      error, if they don't show up in an INNER JOIN against the
--      approaches view.
--   5. Every field this script references (id, name,
--      absolute_magnitude_h, estimated_diameter.kilometers.*,
--      is_potentially_hazardous_asteroid, close_approach_date,
--      miss_distance.kilometers, relative_velocity.kilometers_per_hour,
--      orbiting_body) was confirmed present with these exact
--      names/casing in a live response via curl -- no mixed-case or
--      hyphenated fields here, so no backtick-quoting is needed anywhere
--      in this script (unlike sql/04, sql/06, and sql/08's fields).
--   6. IMPORTANT TYPE GOTCHA, confirmed via curl (2026-09-19):
--      `estimated_diameter_min/max` and `absolute_magnitude_h` are real
--      JSON NUMBERS, but `miss_distance.kilometers` and
--      `relative_velocity.kilometers_per_hour` are JSON STRINGS (quoted
--      in the raw response, e.g. `"kilometers": "47112732.928149391"`).
--      Zetaris's schema inference is expected to type those two columns
--      as STRING, not DOUBLE -- sorting or comparing them without an
--      explicit `CAST(... AS DOUBLE)` would do LEXICOGRAPHIC string
--      comparison (e.g. "9000000.1" would sort before "47112732.9",
--      because '9' > '4' as characters, even though 9000000 < 47112732
--      numerically). Every query below that orders or aggregates by
--      these fields casts them explicitly -- don't drop the CAST when
--      copying this pattern elsewhere.
--   7. CONFIRMED (2026-09-19): the DEMO_KEY rate limit does NOT exhibit
--      the aggressive burst-throttling behavior found on Singapore's
--      PM2.5 endpoint (failure_cases/singapore_pm25/) -- 6 rapid-fire
--      requests in immediate succession all returned 200. Still respect
--      the documented 30 req/hour, 50/day per-IP caps for anything
--      beyond casual testing.
--   8. IMPORTANT, CONFIRMED LIVE (2026-09-19): a Lightning REST table is
--      NOT materialized once at CREATE time -- Zetaris appears to
--      re-issue the underlying HTTP request to the source API on every
--      subsequent query that touches the table (directly or through a
--      view built on it), not just the first one. Running this script's
--      base CREATE + both views + the 8 example queries in one sitting hit
--      NASA's DEMO_KEY rate limit partway through (a 429 "OVER_RATE_LIMIT"
--      from api.nasa.gov, surfaced by Zetaris as a failed query, not at
--      CREATE TABLE time but on a later plain SELECT against an
--      already-successfully-created view). This is the same failure class
--      as the Singapore PM2.5 case (failure_cases/singapore_pm25/) and
--      likely explains it much better than the schema-introspection/
--      preview-fetch guesses recorded there -- Singapore's endpoint has a
--      far tighter rate limit, so the same "one HTTP call per query"
--      behavior would exhaust it almost immediately.
--      WORKAROUND: cache the raw REST table right after creating it,
--      before running multiple queries against it or its views, using
--      the Lightning SQL Manual's documented CACHE TABLE statement:
--        CACHE TABLE nasa_rest.neo_browse_page0;
--      This should load the response into memory once, so later queries
--      read the cached copy instead of re-fetching from NASA every time
--      -- NOT YET CONFIRMED whether this actually prevents the repeat
--      HTTP calls for a Lightning REST table specifically (the manual's
--      CACHE TABLE examples are for JDBC-style datasources), or whether
--      caching the raw table propagates through a SCHEMASTORE VIEW built
--      on top of it. Try it, and report back whether it resolves the
--      rate-limit-on-every-query behavior -- this affects every REST
--      source in this package, not just this one.
--   9. RECOMMENDATION, prompted directly by hitting caveat 8's rate limit
--      mid-testing (2026-09-19): switch from DEMO_KEY to a free
--      registered key before doing further testing on this script,
--      especially the CACHE TABLE experiment in caveat 8, which needs
--      request budget to actually test (running out of requests before
--      confirming whether caching helps just reproduces the same
--      failure, not a real test of the fix). Register at
--      https://api.nasa.gov/ -- a simple form (First Name, Last Name,
--      Email, optional use-case description), key emailed back
--      immediately, no signup approval delay. This raises the limit from
--      30 req/hour (50/day) to 1,000 req/hour -- roughly 33x more
--      headroom, comfortably enough to run this script's full set of
--      verification and example queries repeatedly while iterating.
--      Note the limit resets on a ROLLING basis per key, not a fixed
--      clock hour (e.g. requests made at 10:15 free up again at 11:15,
--      independent of requests made at 10:25, which free up at 11:25) --
--      if you're stuck on DEMO_KEY and hit the limit, the wait is up to
--      an hour from your FIRST request in the current window, not just a
--      short pause like Singapore's endpoint (failure_cases/
--      singapore_pm25/). To use a registered key, replace `DEMO_KEY` in
--      the endpoint below (and in sql/06_nasa_donki_create.sql, which
--      shares this rate limit) with the key emailed to you.
--
-- ---------------------------------------------------------------------------
-- STEP 0: Lightning database for this source. Shared with sql/06 (DONKI) --
-- both are NASA api.nasa.gov endpoints, same pattern as EDGAR sharing
-- SEC_DATA across 7 companies.
-- ---------------------------------------------------------------------------
CREATE LIGHTNING DATABASE NASA_REST DESCRIBE BY "NASA api.nasa.gov REST sources";

-- ---------------------------------------------------------------------------
-- STEP 1: SCHEMASTORE container. RUN ONCE -- see open_data/rest_apis/HOWTO.md,
-- "Known limitations" (no IF NOT EXISTS support). Shared with sql/06
-- (DONKI). Comment out on a re-run if it already exists in your environment.
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

-- CACHE the raw REST table before running anything else against it -- see
-- caveat 8 above. This is an attempted fix for "every query re-hits the
-- API," not yet confirmed to work for a Lightning REST table specifically.
-- If queries in sql/05_nasa_neows_select.sql still trigger new HTTP calls
-- (visible as a fresh rate-limit error after this point, or simply by
-- watching whether results change between two identical SELECTs), this
-- didn't help -- report back either way:
CACHE TABLE nasa_rest.neo_browse_page0;

-- One row per object, with its EARLIEST recorded close approach only (see
-- caveat 4) -- a quick per-object summary, not the full approach history:
CREATE SCHEMASTORE VIEW neo_browse_table WITH CONTAINER nasa AS
SELECT
    neo.id,
    neo.name,
    neo.absolute_magnitude_h,
    neo.estimated_diameter.kilometers.estimated_diameter_min AS diameter_km_min,
    neo.estimated_diameter.kilometers.estimated_diameter_max AS diameter_km_max,
    neo.is_potentially_hazardous_asteroid,
    neo.close_approach_data[0].close_approach_date   AS first_close_approach_date,
    CAST(neo.close_approach_data[0].miss_distance.kilometers AS DOUBLE)             AS first_miss_distance_km,
    CAST(neo.close_approach_data[0].relative_velocity.kilometers_per_hour AS DOUBLE) AS first_relative_velocity_kmh
FROM nasa_rest.neo_browse_page0
LATERAL VIEW explode(near_earth_objects) AS neo;

-- Full approach history -- every recorded close approach (past and
-- predicted future) for every object on this page, via a second
-- LATERAL VIEW explode() on the nested close_approach_data array (see
-- caveat 2). This is the view example queries 4-8 in
-- sql/05_nasa_neows_select.sql use for anything needing more than just the
-- earliest approach on file:
CREATE SCHEMASTORE VIEW neo_close_approaches_table WITH CONTAINER nasa AS
SELECT
    neo.id,
    neo.name,
    neo.is_potentially_hazardous_asteroid,
    approach.close_approach_date,
    CAST(approach.miss_distance.kilometers AS DOUBLE)             AS miss_distance_km,
    CAST(approach.relative_velocity.kilometers_per_hour AS DOUBLE) AS relative_velocity_kmh,
    approach.orbiting_body
FROM nasa_rest.neo_browse_page0
LATERAL VIEW explode(near_earth_objects) AS neo
LATERAL VIEW explode(neo.close_approach_data) AS approach;

-- ---------------------------------------------------------------------------
-- Optional, further follow-up: this page (page 0) is only 20 of 62,401
-- total objects (see caveat 3). A second REST table against
-- `?page=1&api_key=DEMO_KEY` would follow the exact same pattern as
-- PokéAPI's second-Pokémon extension (sql/02) -- not built here, since
-- one page already gives enough variety for the queries in
-- sql/05_nasa_neows_select.sql.
-- ---------------------------------------------------------------------------

-- =============================================================================
-- TEARDOWN -- removes the flattened view(s) this script created. Commented
-- out by default so a re-run of the file above doesn't accidentally wipe
-- a live environment; uncomment and run standalone when you want to tear
-- these views down.
--
-- DROP VIEW is the only teardown statement confirmed to work reliably in
-- this package. There is no SQL statement confirmed to remove the raw
-- REST table or the NASA_REST Lightning database registration itself --
-- see HOWTO.md, "Removing a source" and "Troubleshooting / FAQ", for the
-- full explanation. NASA_REST and the `nasa` container are shared with
-- sql/06 (DONKI) -- see STEP 0/1 comments above.
-- =============================================================================

-- DROP VIEW nasa.neo_browse_table;
-- DROP VIEW nasa.neo_close_approaches_table;

-- If CACHE TABLE was used above (see caveat 8), release it too:
-- UNCACHE TABLE nasa_rest.neo_browse_page0;

-- To remove the NASA_REST REST tables and Lightning database registration
-- (once both this script's and sql/06's tables are no longer needed), use
-- the Zetaris Data Explorer's "File Source & API" panel (see HOWTO.md,
-- "Removing a source").

-- Next: verify with sql/05_nasa_neows_select.sql
