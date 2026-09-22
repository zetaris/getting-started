-- =============================================================================
-- Source:   NASA DONKI (Space Weather Database Of Notifications, Knowledge,
--           Information) -- CME (Coronal Mass Ejection) endpoint
-- License:  NASA content is a U.S. federal government work, generally not
--           subject to copyright (17 U.S.C. §105) -- same basis as
--           sql/05_nasa_neows.sql.
-- Format:   REST/JSON -- TOP-LEVEL ARRAY, not a top-level object. See
--           caveat 1 below -- this is UNTESTED and may not work at all.
-- Docs:     https://api.nasa.gov/ (DONKI section) ·
--           https://ccmc.gsfc.nasa.gov/support/DONKI-webservices.php
-- Signup:   DEMO_KEY works with no signup (30 req/hour, 50/day per IP) but
--           RECOMMENDED to register a free key instead -- see sql/05's
--           caveat 9 for the full rationale (that script's own testing
--           hit the DEMO_KEY limit). Register directly at
--           https://api.nasa.gov/ (First Name, Last Name, Email -- key
--           emailed immediately, no approval wait) for 1,000 req/hour.
--           IMPORTANT, CONFIRMED (2026-09-19): this rate limit is shared
--           with sql/05_nasa_neows.sql (same DEMO_KEY, same NASA_REST
--           database, same IP) -- sql/05's own testing had already used
--           up the DEMO_KEY quota, and this script's very first
--           CREATE LIGHTNING REST TABLE statement failed with a 429
--           OVER_RATE_LIMIT before ever reaching this script's own
--           question (caveat 1, whether a top-level JSON array registers
--           at all) -- that question is STILL UNRESOLVED, blocked by the
--           shared quota, not answered by this failure. Get a registered
--           key (above) before retrying, or this script can't be tested
--           at all right now, independent of anything about its SQL.
-- Before running: sanity-check the endpoint returns something sane --
--   curl -s "https://api.nasa.gov/DONKI/CME?startDate=2026-09-01&endDate=2026-09-16&api_key=DEMO_KEY" | python3 -m json.tool | head -30
-- =============================================================================
--
-- Investigated 2026-09-19, confirmed via curl against the exact date range
-- this script uses (2026-09-01 to 2026-09-16, 65 CME events -- real data,
-- not empty) -- still NOT YET LIVE-TESTED AGAINST ZETARIS:
--   1. HIGH RISK, NOT YET CONFIRMED TO WORK AT ALL: unlike every other
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
--   2. `instruments` is array<struct<displayName>> (simple, one level,
--      same shape class as PokéAPI's abilities) and `cmeAnalyses` is
--      array<struct<isMostAccurate,time21_5,latitude,longitude,halfAngle,
--      speed,type,featureCode,...>> (also one level, more fields). Both
--      flatten with the same explode() + dot-access pattern used
--      elsewhere in this package, ASSUMING caveat 1 resolves favorably.
--      Confirmed via curl: every event in this date range has at least
--      one cmeAnalyses entry (none are empty), and 1-4 instruments each.
--   3. `activeRegionNum`, `linkedEvents`, and `sentNotifications` come
--      back as JSON `null` on many events -- confirm Zetaris's schema
--      inference handles null scalar values gracefully (distinct from
--      the sparse/missing-field question already flagged for Open Food
--      Facts, sql/03) before trusting a column that's sometimes null.
--      NOT built into the views below since they're not needed for the
--      example queries -- add them if a demo specifically wants them.
--   4. `activityID`, `startTime`, `sourceLocation`, `displayName`,
--      `isMostAccurate`, `halfAngle`, and `featureCode` are all
--      mixed-case -- per the confirmed EDGAR/PokéAPI/Open Food Facts
--      rule (HOWTO.md, "Troubleshooting / FAQ"), every one of these
--      needs backtick-quoting. Fixed below (was originally written bare,
--      before that rule had been confirmed
--      across enough sources to be treated as a blanket one).
--   5. Unlike NASA NeoWs (sql/05), the numeric fields here -- `speed`,
--      `latitude`, `longitude`, `halfAngle` -- are confirmed REAL JSON
--      NUMBERS in the raw response, not quoted strings. No CAST(...
--      AS DOUBLE) gotcha applies to this source the way it did for
--      NeoWs's miss_distance/relative_velocity fields (HOWTO.md,
--      "Troubleshooting / FAQ") -- confirmed via curl before writing the
--      queries below, not assumed.
--   6. `sourceLocation` can be an EMPTY STRING (`""`), not null, when the
--      CME's solar source region is unknown or the event originated
--      behind the visible limb -- confirmed 24 of 65 events in this date
--      range have a non-empty value, the other 41 are `""`. Queries that
--      use this field filter it out explicitly (`WHERE source_location
--      <> ''`) rather than relying on a NULL check, which wouldn't catch
--      the empty-string case.
--   7. `sourceLocation`'s format is NOT fixed-width -- e.g. `N05E50` (6
--      characters) and `N05W105` (7 characters, a 3-digit longitude
--      value beyond +/-99) both occur in this exact date range. The
--      latitude portion (2 digits, characters 2-3) is fixed-width, so
--      the hemisphere-pair split used in query 7 below
--      (`SUBSTR(source_location, 1, 1)` for N/S,
--      `SUBSTR(source_location, 4, 1)` for E/W) is reliable -- but don't
--      assume the full string is always 6 characters if extending this
--      further (e.g. extracting the numeric longitude value itself would
--      need to handle both digit-count cases).
--   8. DATA QUIRK, confirmed via curl: most events have exactly one
--      `cmeAnalyses` entry flagged `isMostAccurate: true`, but 4 of the
--      65 events in this date range have MORE THAN ONE analysis flagged
--      `isMostAccurate: true` simultaneously -- a naive
--      `WHERE isMostAccurate = true` filter intended to pick "the one
--      best analysis per event" will occasionally return two rows for
--      the same event, not one. Query 2 below uses a
--      ROW_NUMBER() OVER (PARTITION BY activity_id ...) window function
--      instead (same confirmed pattern as sql/03 and sql/05) specifically
--      to guarantee exactly one row per event even when this quirk hits.
--   9. CME `type` is DONKI's own speed-based classification, not
--      something this script invents: S = slow (roughly <500 km/s),
--      C = common (~500-1000 km/s), O = occasional (~1000-2000 km/s),
--      R = rare (~2000-3000 km/s), ER = extremely rare (>3000 km/s).
--      Confirmed against this date range's actual speed values (S:
--      207-467 km/s, C: 510-966 km/s, O: 1020-1586 km/s -- no R/ER
--      events in this particular window, which is normal, not missing
--      data).
--
-- ---------------------------------------------------------------------------
-- STEP 0: Lightning database for this source. Shared with sql/05 (NeoWs).
-- ---------------------------------------------------------------------------
CREATE LIGHTNING DATABASE NASA_REST DESCRIBE BY "NASA api.nasa.gov REST sources";

-- ---------------------------------------------------------------------------
-- STEP 1: SCHEMASTORE container. RUN ONCE -- see open_data/rest_apis/HOWTO.md,
-- "Known limitations" (no IF NOT EXISTS support). Shared with sql/05
-- (NeoWs). Skip this statement entirely if you already ran sql/05 in this
-- environment (the `nasa` container will already exist).
-- ---------------------------------------------------------------------------
CREATE SCHEMASTORE CONTAINER nasa;

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
    `activityID`     AS activity_id,
    `startTime`      AS start_time,
    `sourceLocation` AS source_location,
    note,
    instrument.`displayName` AS instrument_name
FROM nasa_rest.cme_events
LATERAL VIEW explode(instruments) AS instrument;

-- Flattens `cmeAnalyses` per event -- one row per analysis (an event can
-- have more than one, see caveat 8):
CREATE SCHEMASTORE VIEW cme_analyses_table WITH CONTAINER nasa AS
SELECT
    `activityID` AS activity_id,
    `startTime`  AS start_time,
    analysis.`isMostAccurate` AS is_most_accurate,
    analysis.time21_5,
    analysis.speed,
    analysis.latitude,
    analysis.longitude,
    analysis.`halfAngle` AS half_angle,
    analysis.type,
    analysis.`featureCode` AS feature_code
FROM nasa_rest.cme_events
LATERAL VIEW explode(cmeAnalyses) AS analysis;

-- Verify:
SELECT * FROM nasa.cme_instruments_table;
SELECT * FROM nasa.cme_analyses_table;

-- ---------------------------------------------------------------------------
-- Diagnostic (run FIRST if the CREATE LIGHTNING REST TABLE statement itself
-- fails -- that's the top-level-array question in caveat 1, not a
-- flattening problem):
--   SELECT * FROM nasa_rest.cme_events;
--   DESCRIBE nasa_rest.cme_events;
-- If the table creation fails outright, report the exact error back before
-- attempting the views -- it'll tell us whether Zetaris supports top-level
-- array REST responses at all, which affects whether this source (and any
-- other API that returns a bare array) is viable in this package.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Example queries -- run these against the views above to get a feel for
-- the data once everything's loaded. Picked to be genuinely interesting:
-- fastest events, a speed-classification breakdown, which events got the
-- most observational attention, and a look at where on the Sun these
-- eruptions actually came from.
-- ---------------------------------------------------------------------------

-- 1. Total CME count and date range actually covered by this table:
SELECT
    COUNT(DISTINCT activity_id) AS cme_count,
    MIN(start_time)             AS earliest_event,
    MAX(start_time)             AS latest_event
FROM nasa.cme_analyses_table;

-- 2. The 5 fastest CMEs in this window -- one row per event even when an
-- event has more than one analysis flagged "most accurate" (see caveat
-- 8), using the same ROW_NUMBER() OVER (...) window-function pattern
-- confirmed working in sql/03 and sql/05, preferring the accurate flag
-- first and the highest speed as a tiebreaker:
SELECT activity_id, start_time, speed, type, latitude, longitude
FROM (
    SELECT
        activity_id,
        start_time,
        speed,
        type,
        latitude,
        longitude,
        ROW_NUMBER() OVER (
            PARTITION BY activity_id
            ORDER BY is_most_accurate DESC, speed DESC
        ) AS rn
    FROM nasa.cme_analyses_table
) ranked
WHERE rn = 1
ORDER BY speed DESC
LIMIT 5;

-- 3. CME speed classification breakdown (see caveat 9 for what S/C/O/R/ER
-- mean) -- count and speed range per type, across every analysis on
-- file (not deduplicated to one-per-event, since this is about the
-- distribution of recorded measurements, not a per-event count):
SELECT
    type,
    COUNT(*)             AS analysis_count,
    ROUND(MIN(speed), 0) AS min_speed_kms,
    ROUND(AVG(speed), 0) AS avg_speed_kms,
    ROUND(MAX(speed), 0) AS max_speed_kms
FROM nasa.cme_analyses_table
WHERE speed IS NOT NULL AND type IS NOT NULL
GROUP BY type
ORDER BY avg_speed_kms DESC;

-- 4. Most-observed events -- CMEs picked up by the most instruments,
-- a proxy for how well-documented/significant an event was:
SELECT activity_id, start_time, COUNT(*) AS instrument_count
FROM nasa.cme_instruments_table
GROUP BY activity_id, start_time
ORDER BY instrument_count DESC
LIMIT 5;

-- 5. Events that needed more than one analysis on file -- often the
-- harder-to-measure or more scientifically interesting eruptions (see
-- caveat 8 -- some of these are the same events with the
-- multiple-isMostAccurate quirk):
SELECT activity_id, start_time, COUNT(*) AS analysis_count
FROM nasa.cme_analyses_table
GROUP BY activity_id, start_time
HAVING COUNT(*) > 1
ORDER BY analysis_count DESC;

-- 6. Which solar hemisphere produced more CMEs with a known source
-- region -- north/south and east/west, using the fixed-width latitude
-- portion of source_location (see caveat 7 for why this substring split
-- is safe even though the full string isn't fixed-width):
SELECT
    SUBSTR(source_location, 1, 1) AS ns_hemisphere,
    SUBSTR(source_location, 4, 1) AS ew_hemisphere,
    COUNT(DISTINCT activity_id)   AS cme_count
FROM nasa.cme_instruments_table
WHERE source_location <> ''
GROUP BY 1, 2
ORDER BY cme_count DESC;

-- 7. Daily CME frequency across the date range -- a simple trend line,
-- extracting just the date portion of the ISO timestamp:
SELECT
    SUBSTR(start_time, 1, 10) AS event_date,
    COUNT(DISTINCT activity_id) AS cme_count
FROM nasa.cme_analyses_table
GROUP BY 1
ORDER BY event_date;

-- 8. Full detail on the single fastest CME in this window -- joins the
-- deduplicated-fastest-analysis logic from query 2 against the
-- instruments view for a complete picture, the same
-- join-across-two-view-families pattern as sql/03 query 8 and sql/04
-- query 8:
SELECT
    a.activity_id,
    a.start_time,
    a.speed,
    a.type,
    i.source_location,
    i.instrument_name
FROM (
    SELECT activity_id, start_time, speed, type,
           ROW_NUMBER() OVER (PARTITION BY activity_id ORDER BY is_most_accurate DESC, speed DESC) AS rn
    FROM nasa.cme_analyses_table
) a
JOIN nasa.cme_instruments_table i ON i.activity_id = a.activity_id
WHERE a.rn = 1
ORDER BY a.speed DESC
LIMIT 1;

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
-- sql/05 (NeoWs) -- see STEP 0/1 comments above. This whole script is
-- still unverified even to CREATE successfully (see caveat 1).
-- =============================================================================

-- DROP VIEW nasa.cme_instruments_table;
-- DROP VIEW nasa.cme_analyses_table;

-- To remove the NASA_REST REST tables and Lightning database registration
-- (once both this script's and sql/05's tables are no longer needed), use
-- the Zetaris Data Explorer's "File Source & API" panel (see HOWTO.md,
-- "Removing a source").
