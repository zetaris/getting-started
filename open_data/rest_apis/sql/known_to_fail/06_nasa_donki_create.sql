-- =============================================================================
-- Source: NASA DONKI (Space Weather Database Of Notifications, Knowledge,
-- Information) -- CME (Coronal Mass Ejection) endpoint.
--
-- License: NASA content is a U.S. federal government work, generally
-- not subject to copyright (17 U.S.C. §105).
--
-- Format: REST/JSON -- a top-level array, not a top-level object. See
-- caveat 1 -- this is untested and may not work at all.
--
-- Docs: https://api.nasa.gov/ (DONKI section)
-- https://ccmc.gsfc.nasa.gov/support/DONKI-webservices.php
--
-- Signup: DEMO_KEY works with no signup (30 req/hour, 50/day per IP),
-- but a free registered key is recommended. Register directly at
-- https://api.nasa.gov/ (first name, last name, email -- key emailed
-- immediately, no approval wait) for 1,000 req/hour. This rate limit is
-- shared with 05_nasa_neows_create.sql (same DEMO_KEY, same NASA_REST
-- database, same IP) -- that script's own testing can exhaust the
-- shared quota before this script's own question (caveat 1) is ever
-- reached, independent of anything about this script's own SQL.
--
-- Before running: sanity-check the endpoint returns something sane:
--   curl -s "https://api.nasa.gov/DONKI/CME?startDate=2026-09-01&endDate=2026-09-16&api_key=DEMO_KEY" | python3 -m json.tool | head -30
--
-- Status: confirmed via curl against the exact date range this script
-- uses (2026-09-01 to 2026-09-16, 65 CME events, real data) -- not yet
-- live-tested against Zetaris.
-- =============================================================================
--
-- Caveats:
--   1. High risk, not yet confirmed to work at all: DONKI's CME
--      endpoint returns a top-level JSON array -- the response starts
--      with `[` and ends with `]`, there is no wrapping object at all.
--      Whether Zetaris's CREATE LIGHTNING REST TABLE can register a
--      table directly from a top-level array response is unknown --
--      this is the first thing to test, before worrying about the
--      flattening logic below. If it fails, the likely workaround is a
--      thin proxy/transform step outside Zetaris that wraps the array
--      in an object, e.g. `{"events": [...]}`, before Zetaris sees it
--      -- not yet built.
--   2. `instruments` is array<struct<displayName>> (simple, one level)
--      and `cmeAnalyses` is
--      array<struct<isMostAccurate,time21_5,latitude,longitude,halfAngle,
--      speed,type,featureCode,...>> (also one level, more fields). Both
--      flatten with the same explode() + dot-access pattern, assuming
--      caveat 1 resolves favorably. Confirmed via curl: every event in
--      this date range has at least one cmeAnalyses entry, and 1-4
--      instruments each.
--   3. `activeRegionNum`, `linkedEvents`, and `sentNotifications` come
--      back as JSON null on many events -- confirm Zetaris's schema
--      inference handles null scalar values gracefully before trusting
--      a column that's sometimes null. Not built into the views below
--      since they're not needed for the example queries.
--   4. `activityID`, `startTime`, `sourceLocation`, `displayName`,
--      `isMostAccurate`, `halfAngle`, and `featureCode` are all
--      mixed-case and need backtick-quoting -- fixed below.
--   5. The numeric fields here -- `speed`, `latitude`, `longitude`,
--      `halfAngle` -- are confirmed real JSON numbers in the raw
--      response, not quoted strings, so no CAST(... AS DOUBLE) gotcha
--      applies to this source. Confirmed via curl before writing the
--      queries below, not assumed.
--   6. `sourceLocation` can be an empty string (`""`), not null, when
--      the CME's solar source region is unknown or the event
--      originated behind the visible limb -- confirmed 24 of 65 events
--      in this date range have a non-empty value, the other 41 are
--      `""`. Queries that use this field filter it out explicitly
--      (`WHERE source_location <> ''`) rather than relying on a NULL
--      check, which wouldn't catch the empty-string case.
--   7. `sourceLocation`'s format is not fixed-width -- e.g. `N05E50`
--      (6 characters) and `N05W105` (7 characters, a 3-digit longitude
--      value beyond +/-99) both occur in this exact date range. The
--      latitude portion (2 digits, characters 2-3) is fixed-width, so
--      the hemisphere-pair split used in the select script
--      (`SUBSTR(source_location, 1, 1)` for N/S,
--      `SUBSTR(source_location, 4, 1)` for E/W) is reliable -- but
--      extracting the numeric longitude value itself would need to
--      handle both digit-count cases.
--   8. Most events have exactly one `cmeAnalyses` entry flagged
--      `isMostAccurate: true`, but 4 of the 65 events in this date
--      range have more than one analysis flagged `isMostAccurate: true`
--      simultaneously -- a naive `WHERE isMostAccurate = true` filter
--      intended to pick the one best analysis per event will
--      occasionally return two rows for the same event, not one. The
--      select script uses a ROW_NUMBER() OVER (PARTITION BY
--      activity_id ...) window function instead to guarantee exactly
--      one row per event even when this quirk hits.
--   9. CME `type` is DONKI's own speed-based classification: S = slow
--      (roughly <500 km/s), C = common (~500-1000 km/s), O = occasional
--      (~1000-2000 km/s), R = rare (~2000-3000 km/s), ER = extremely
--      rare (>3000 km/s). Confirmed against this date range's actual
--      speed values (S: 207-467 km/s, C: 510-966 km/s, O: 1020-1586
--      km/s -- no R/ER events in this particular window, which is
--      normal, not missing data).
-- =============================================================================

-- Step 0: Lightning database for this source. Shared with
-- 05_nasa_neows_create.sql.
CREATE LIGHTNING DATABASE NASA_REST DESCRIBE BY "NASA api.nasa.gov REST sources";

-- Step 1: schemastore container. Shared with 05_nasa_neows_create.sql
-- -- skip this statement entirely if that script already ran in this
-- environment (the `nasa` container will already exist).
-- CREATE SCHEMASTORE CONTAINER nasa;   -- commented: created by 05_nasa_neows_create.sql already

-- CME events -- September 2026, DEMO_KEY
CREATE LIGHTNING REST TABLE cme_events FROM NASA_REST REQUEST(
    endpoint "https://api.nasa.gov/DONKI/CME?startDate=2026-09-01&endDate=2026-09-16&api_key=DEMO_KEY",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
) BODY ();

-- If the table above registers successfully (see caveat 1 -- untested),
-- this flattens `instruments` per event.
CREATE SCHEMASTORE VIEW cme_instruments_table WITH CONTAINER nasa AS
SELECT
    `activityID` AS activity_id,
    `startTime` AS start_time,
    `sourceLocation` AS source_location,
    note,
    instrument.`displayName` AS instrument_name
FROM nasa_rest.cme_events
LATERAL VIEW explode(instruments) AS instrument;

-- Flattens `cmeAnalyses` per event -- one row per analysis (an event
-- can have more than one, see caveat 8).
CREATE SCHEMASTORE VIEW cme_analyses_table WITH CONTAINER nasa AS
SELECT
    `activityID` AS activity_id,
    `startTime` AS start_time,
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

-- =============================================================================
-- Teardown -- removes the flattened views this script created.
-- Commented out by default. See the SQL companion guide for why
-- DROP VIEW is the only reliable teardown statement, and how to remove
-- the underlying REST table and database registration (Zetaris Data
-- Explorer -- no SQL path exists). NASA_REST and the `nasa` container
-- are shared with 05_nasa_neows_create.sql. This whole script is still
-- unverified even to CREATE successfully (see caveat 1).
-- =============================================================================

-- DROP VIEW nasa.cme_instruments_table;
-- DROP VIEW nasa.cme_analyses_table;
