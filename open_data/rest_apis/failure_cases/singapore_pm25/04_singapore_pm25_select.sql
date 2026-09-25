-- =============================================================================
-- Verification / example queries for 04_singapore_pm25_create.sql
-- Assumes 04_singapore_pm25_create.sql has already been run.
--
-- The verification queries below are commented out by default so that
-- running this whole file doesn't automatically fire read queries against
-- every view -- this source is excluded from the main sequence (see
-- HOWTO.md and ISSUE.md) precisely because of a tight, easy-to-trip rate
-- limit. Uncomment what you want to run, or run it directly in the SQL
-- Editor. The example queries further down are left live, same as before.
-- =============================================================================

-- === Verification ===
-- SELECT * FROM singapore.pm25_readings_table ORDER BY reading_timestamp;
-- SELECT * FROM singapore.pm25_regions_table;

-- === Diagnostics === (run if any verification query above fails or comes back empty)
-- SELECT * FROM sg_datagovsg_rest.pm25_readings_20260918;
-- DESCRIBE sg_datagovsg_rest.pm25_readings_20260918;
-- If dot-access through data.items (nested under a non-array `data`
-- struct) fails, that's a different failure mode from every other script
-- in this package -- worth isolating from the "array at the top level"
-- sources (EDGAR, PokéAPI) when reporting back.

-- === Example queries ===
-- Run these against the views created in 04_singapore_pm25_create.sql to
-- get a feel for the data once everything's loaded. Picked to be
-- genuinely interesting: a full-day trend, a region-vs-region comparison,
-- worst/best moments of the day, a health-threshold check, and an
-- hour-by-hour "which region is worst right now" ranking.

-- 1. Full 24-hour trend, one row per hour with all 5 regions side by
-- side -- the rawest view of the day:
SELECT * FROM singapore.pm25_readings_table ORDER BY reading_timestamp;

-- 2. Daily summary per region -- average, minimum, and maximum PM2.5
-- across the day, worst average first:
SELECT
    region,
    ROUND(AVG(pm25), 1) AS avg_pm25,
    MIN(pm25)           AS min_pm25,
    MAX(pm25)           AS max_pm25
FROM singapore.pm25_readings_long_table
GROUP BY region
ORDER BY avg_pm25 DESC;

-- 3. The single worst (region, hour) reading of the day:
SELECT reading_timestamp, region, pm25
FROM singapore.pm25_readings_long_table
ORDER BY pm25 DESC
LIMIT 1;

-- 4. The single cleanest (region, hour) reading of the day:
SELECT reading_timestamp, region, pm25
FROM singapore.pm25_readings_long_table
ORDER BY pm25 ASC
LIMIT 1;

-- 5. Computed "national" hourly average -- the API itself has no such
-- field (see caveat 3 in the create script), so this derives one as the
-- average of the 5 regions per hour, then shows the trend across the day:
SELECT
    reading_timestamp,
    ROUND(AVG(pm25), 1) AS national_avg_pm25
FROM singapore.pm25_readings_long_table
GROUP BY reading_timestamp
ORDER BY reading_timestamp;

-- 6. Hours each region spent "elevated" (PM2.5 > 55, a commonly used
-- unhealthy-for-sensitive-groups style threshold) -- a health-relevant
-- summary rather than a raw average:
SELECT
    region,
    COUNT(*)                                     AS hours_elevated,
    ROUND(100.0 * COUNT(*) / 24, 1)               AS pct_of_day_elevated
FROM singapore.pm25_readings_long_table
WHERE pm25 > 55
GROUP BY region
ORDER BY hours_elevated DESC;

-- 7. Which region was worst in EACH hour -- a window function ranks the
-- 5 regions within every hour, same ROW_NUMBER() OVER (...) pattern
-- confirmed working in sql/03_open_food_facts_live_select.sql query 7,
-- applied here to a genuine "top-N per group" question rather than a
-- self-join:
SELECT reading_timestamp, region AS worst_region, pm25
FROM (
    SELECT
        reading_timestamp,
        region,
        pm25,
        ROW_NUMBER() OVER (PARTITION BY reading_timestamp ORDER BY pm25 DESC) AS rn
    FROM singapore.pm25_readings_long_table
) ranked
WHERE rn = 1
ORDER BY reading_timestamp;

-- 8. Worst daily-average region, alongside where it actually is --
-- joins the long-format readings (aggregated) against the region
-- reference view for its coordinates, the same nutrition-view-plus-
-- ingredients-view cross-view join pattern as
-- sql/03_open_food_facts_live_select.sql query 8:
SELECT
    r.region_name,
    daily.avg_pm25,
    r.latitude,
    r.longitude
FROM singapore.pm25_regions_table r
JOIN (
    SELECT region, ROUND(AVG(pm25), 1) AS avg_pm25
    FROM singapore.pm25_readings_long_table
    GROUP BY region
) daily ON daily.region = r.region_name
ORDER BY daily.avg_pm25 DESC;

-- ---------------------------------------------------------------------------
-- Attribution reminder (SODL v1.0, per the license note in the create script):
--   "Contains information from data.gov.sg accessed on {date} which is
--   made available under the terms of the Singapore Open Data Licence
--   version 1.0."
-- ---------------------------------------------------------------------------
