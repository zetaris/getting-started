-- =============================================================================
-- Verification / example queries for 06_nasa_donki_create.sql
-- Assumes 06_nasa_donki_create.sql has already been run.
--
-- The verification queries below are commented out by default so that
-- running this whole file doesn't automatically fire read queries against
-- every view. Uncomment what you want to run, or run it directly in the
-- SQL Editor. The example queries further down are left live, same as
-- before.
-- =============================================================================

-- === Diagnostics === (run FIRST if CREATE LIGHTNING REST TABLE itself failed
-- in the create script -- that's the top-level-array question in caveat 1,
-- not a flattening problem)
-- SELECT * FROM nasa_rest.cme_events;
-- DESCRIBE nasa_rest.cme_events;
-- If the table creation fails outright, report the exact error back before
-- attempting the views -- it'll tell us whether Zetaris supports top-level
-- array REST responses at all, which affects whether this source (and any
-- other API that returns a bare array) is viable in this package.

-- === Verification ===
-- SELECT * FROM nasa.cme_instruments_table;
-- SELECT * FROM nasa.cme_analyses_table;

-- === Example queries ===
-- Run these against the views created in 06_nasa_donki_create.sql to get a
-- feel for the data once everything's loaded. Picked to be genuinely
-- interesting: fastest events, a speed-classification breakdown, which
-- events got the most observational attention, and a look at where on the
-- Sun these eruptions actually came from.

-- 1. Total CME count and date range actually covered by this table:
SELECT
    COUNT(DISTINCT activity_id) AS cme_count,
    MIN(start_time)             AS earliest_event,
    MAX(start_time)             AS latest_event
FROM nasa.cme_analyses_table;

-- 2. The 5 fastest CMEs in this window -- one row per event even when an
-- event has more than one analysis flagged "most accurate" (see caveat
-- 8 in the create script), using the same ROW_NUMBER() OVER (...)
-- window-function pattern confirmed working in
-- sql/03_open_food_facts_live_select.sql and
-- sql/05_nasa_neows_select.sql, preferring the accurate flag first and
-- the highest speed as a tiebreaker:
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

-- 3. CME speed classification breakdown (see caveat 9 in the create
-- script for what S/C/O/R/ER mean) -- count and speed range per type,
-- across every analysis on file (not deduplicated to one-per-event,
-- since this is about the distribution of recorded measurements, not a
-- per-event count):
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
-- caveat 8 in the create script -- some of these are the same events
-- with the multiple-isMostAccurate quirk):
SELECT activity_id, start_time, COUNT(*) AS analysis_count
FROM nasa.cme_analyses_table
GROUP BY activity_id, start_time
HAVING COUNT(*) > 1
ORDER BY analysis_count DESC;

-- 6. Which solar hemisphere produced more CMEs with a known source
-- region -- north/south and east/west, using the fixed-width latitude
-- portion of source_location (see caveat 7 in the create script for why
-- this substring split is safe even though the full string isn't
-- fixed-width):
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
-- join-across-two-view-families pattern as
-- sql/03_open_food_facts_live_select.sql query 8 and
-- failure_cases/singapore_pm25/04_singapore_pm25_select.sql query 8:
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
