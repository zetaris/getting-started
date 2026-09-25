-- =============================================================================
-- Source:   NASA DONKI (Space Weather Database Of Notifications, Knowledge,
--           Information) -- CME (Coronal Mass Ejection) endpoint
-- License:  NASA content is a U.S. federal government work, generally not
--           subject to copyright (17 U.S.C. §105) -- same basis as
--           sql/05_nasa_neows_create.sql.
-- Format:   REST/JSON -- TOP-LEVEL ARRAY, not a top-level object. See
--           caveat 1 below -- this is UNTESTED and may not work at all.
-- Docs:     https://api.nasa.gov/ (DONKI section) ·
--           https://ccmc.gsfc.nasa.gov/support/DONKI-webservices.php
-- Signup:   DEMO_KEY works with no signup (30 req/hour, 50/day per IP) but
--           RECOMMENDED to register a free key instead -- see
--           sql/05_nasa_neows_create.sql's caveat 9 for the full rationale
--           (that script's own testing hit the DEMO_KEY limit). Register
--           directly at https://api.nasa.gov/ (First Name, Last Name,
--           Email -- key emailed immediately, no approval wait) for
--           1,000 req/hour.
--           IMPORTANT, CONFIRMED (2026-09-19): this rate limit is shared
--           with sql/05_nasa_neows_create.sql (same DEMO_KEY, same
--           NASA_REST database, same IP) -- sql/05's own testing had
--           already used up the DEMO_KEY quota, and this script's very
--           first CREATE LIGHTNING REST TABLE statement failed with a 429
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
--      the hemisphere-pair split used in sql/06_nasa_donki_select.sql
--      query 6 (`SUBSTR(source_location, 1, 1)` for N/S,
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
--      the same event, not one. sql/06_nasa_donki_select.sql query 2
--      uses a ROW_NUMBER() OVER (PARTITION BY activity_id ...) window
--      function instead (same confirmed pattern as sql/03 and sql/05)
--      specifically to guarantee exactly one row per event even when
--      this quirk hits.
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

-- Next: verify with sql/06_nasa_donki_select.sql
