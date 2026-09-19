-- =============================================================================
-- Source:   NASA DONKI (Space Weather Database Of Notifications, Knowledge,
--           Information) -- CME (Coronal Mass Ejection) endpoint
-- License:  NASA content is a U.S. federal government work, generally not
--           subject to copyright (17 U.S.C. §105) -- same basis as
--           sql/05_nasa_neows.sql.
-- Format:   REST/JSON -- ⚠️ TOP-LEVEL ARRAY, not a top-level object. See
--           caveat 1 below -- this is UNTESTED and may not work at all.
-- Docs:     https://api.nasa.gov/ (DONKI section) ·
--           https://ccmc.gsfc.nasa.gov/support/DONKI-webservices.php
-- Signup:   DEMO_KEY works with no signup (30 req/hour, 50/day per IP); a
--           free api.data.gov key raises this to 1,000 req/hour.
-- Before running: sanity-check the endpoint returns something sane --
--   curl -s "https://api.nasa.gov/DONKI/CME?startDate=2026-09-01&endDate=2026-09-16&api_key=DEMO_KEY" | python3 -m json.tool | head -30
-- =============================================================================
--
-- Investigated (not yet live-tested against Zetaris) 2026-09-19:
--   1. ⚠️ HIGH RISK, NOT YET CONFIRMED TO WORK AT ALL: unlike every other
--      source in this package (EDGAR, PokéAPI, Open Food Facts, Singapore
--      PM2.5, NASA NeoWs), DONKI's CME endpoint returns a TOP-LEVEL JSON
--      ARRAY -- the response starts with `[` and ends with `]`, there is
--      no wrapping object at all. Every confirmed-working REST table in
--      this package so far ingests a top-level JSON OBJECT. Whether
--      Zetaris's CREATE LIGHTNING REST TABLE can register a table directly
--      from a top-level array response is UNKNOWN -- this is the first
--      thing to test, before worrying about the flattening logic below.
--      If it fails, the likely workaround is a thin proxy/transform step
--      (outside Zetaris) that wraps the array in an object, e.g.
--      `{"events": [...]}`, before Zetaris sees it -- not yet built, flag
--      this back if the raw CREATE TABLE statement fails outright.
--   2. IF the top-level array registers successfully, the array elements
--      themselves have array-of-structs fields worth flattening:
--      `instruments` is array<struct<displayName>> (simple, one level,
--      same shape class as PokéAPI's abilities) and `cmeAnalyses` is
--      array<struct<isMostAccurate,time21_5,latitude,longitude,speed,
--      type,...>> (also one level, more fields). Both should flatten with
--      the same explode() + dot-access pattern used elsewhere in this
--      package, ASSUMING caveat 1 resolves favorably.
--   3. `activeRegionNum` and `tilt` came back as JSON `null` in the sample
--      response -- confirm Zetaris's schema inference handles null scalar
--      values gracefully (distinct from the sparse/missing-field question
--      already flagged for Open Food Facts, sql/03) before trusting a
--      column that's sometimes null.
--
-- ---------------------------------------------------------------------------
-- STEP 0: Lightning database for this source. Shared with sql/05 (NeoWs).
-- ---------------------------------------------------------------------------
CREATE LIGHTNING DATABASE NASA_REST DESCRIBE BY "NASA api.nasa.gov REST sources";

-- ---------------------------------------------------------------------------
-- STEP 1: SCHEMASTORE container. RUN ONCE -- see open_data/rest_apis/HOWTO.md
-- sec 2 (no IF NOT EXISTS support). Shared with sql/05 (NeoWs). Skip this
-- statement entirely if you already ran sql/05 in this environment (the
-- `nasa` container will already exist).
-- ---------------------------------------------------------------------------
-- CREATE SCHEMASTORE CONTAINER nasa;   -- commented: created by sql/05 already

-- =============================================================================
-- CME EVENTS -- September 2026, DEMO_KEY
-- =============================================================================
CREATE LIGHTNING REST TABLE cme_events FROM NASA_REST REQUEST(
    endpoint "https://api.nasa.gov/DONKI/CME?startDate=2026-09-01&endDate=2026-09-16&api_key=DEMO_KEY",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
) BODY ();

-- If the table above registers successfully (see caveat 1 -- untested),
-- this flattens `instruments` per event:
CREATE SCHEMASTORE VIEW cme_instruments_table WITH CONTAINER nasa AS
SELECT
    activityID,
    startTime,
    sourceLocation,
    note,
    instrument.displayName AS instrument_name
FROM nasa_rest.cme_events
LATERAL VIEW explode(instruments) AS instrument;

-- Verify:
SELECT * FROM nasa.cme_instruments_table;

-- ---------------------------------------------------------------------------
-- Diagnostic (run FIRST if the CREATE LIGHTNING REST TABLE statement itself
-- fails -- that's the top-level-array question in caveat 1, not a
-- flattening problem):
--   SELECT * FROM nasa_rest.cme_events;
--   DESCRIBE nasa_rest.cme_events;
-- If the table creation fails outright, report the exact error back before
-- attempting the view -- it'll tell us whether Zetaris supports top-level
-- array REST responses at all, which affects whether this source (and any
-- other API that returns a bare array) is viable in this package.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Optional follow-up once the above works: a second view for cmeAnalyses
-- (same explode() pattern, more fields -- speed, latitude, longitude,
-- type):
-- CREATE SCHEMASTORE VIEW cme_analyses_table WITH CONTAINER nasa AS
-- SELECT
--     activityID,
--     startTime,
--     analysis.isMostAccurate,
--     analysis.time21_5,
--     analysis.speed,
--     analysis.latitude,
--     analysis.longitude,
--     analysis.type
-- FROM nasa_rest.cme_events
-- LATERAL VIEW explode(cmeAnalyses) AS analysis;
-- ---------------------------------------------------------------------------
