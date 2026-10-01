-- =============================================================================
-- Verification and example queries for 02_noaa_ghcn_create.sql.
-- Assumes 02_noaa_ghcn_create.sql has already been run, including its
-- CACHE TABLE step -- confirmed live: these queries are slow enough
-- against the uncached table (a full CSV re-scan against S3 per query)
-- that caching is required for workable query times, not just a
-- nice-to-have.
--
-- Column names below (_c0.._c7) are Spark's default for a headerless,
-- inferSchema CSV -- confirmed live, matching the GHCN-Daily 8-column
-- layout (ID, DATE, ELEMENT, DATA_VALUE, M-FLAG, Q-FLAG, S-FLAG, OBS-TIME
-- -- see 02_noaa_ghcn_create.sql's header) in that column order. Query 1
-- (DESCRIBE) is kept below so a future run against a different year's file
-- still checks this before trusting queries 2 onward, not because the
-- mapping itself is still in doubt.
-- =============================================================================

-- === Verification ===
SELECT * FROM NOAA_GHCN_S3.noaa_ghcn_daily_2025 LIMIT 10;

-- 1. Confirm column names and inferred types before relying on the aliases
-- used in every query below:
DESCRIBE NOAA_GHCN_S3.noaa_ghcn_daily_2025;

-- === Example queries ===
-- All queries below confirmed live. Each re-aliases the raw _c0.._c7
-- columns independently -- this package doesn't build a persistent view
-- over filestore tables, unlike the REST package's SCHEMASTORE VIEW
-- pattern.

-- 2. Overview -- total observations, distinct stations, and distinct
-- element codes in this one year's file:
SELECT
    COUNT(*) AS total_observations,
    COUNT(DISTINCT _c0) AS distinct_stations,
    COUNT(DISTINCT _c2) AS distinct_elements
FROM NOAA_GHCN_S3.noaa_ghcn_daily_2025;

-- 3. Element breakdown -- which measurements dominate the file. Expect
-- TMAX/TMIN/PRCP near the top; the full code list is in the format spec
-- linked in 02_noaa_ghcn_create.sql's header:
SELECT _c2 AS element, COUNT(*) AS observation_count
FROM NOAA_GHCN_S3.noaa_ghcn_daily_2025
GROUP BY _c2
ORDER BY observation_count DESC;

-- 4. Hottest single TMAX reading in the file -- station, date, and value
-- converted from tenths of a degree Celsius to whole degrees:
SELECT _c0 AS station_id, _c1 AS obs_date, _c3 / 10.0 AS tmax_celsius
FROM NOAA_GHCN_S3.noaa_ghcn_daily_2025
WHERE _c2 = 'TMAX'
ORDER BY _c3 DESC
LIMIT 1;

-- 5. Coldest single TMIN reading in the file -- same conversion, opposite
-- direction:
SELECT _c0 AS station_id, _c1 AS obs_date, _c3 / 10.0 AS tmin_celsius
FROM NOAA_GHCN_S3.noaa_ghcn_daily_2025
WHERE _c2 = 'TMIN'
ORDER BY _c3 ASC
LIMIT 1;

-- 6. Monthly average TMAX for one example station (JFK Airport, NY --
-- USW00094728) -- demonstrates date parsing (DATE is YYYYMMDD with no
-- separators) alongside the tenths-of-a-degree unit conversion:
SELECT
    SUBSTR(_c1, 1, 6) AS year_month,
    AVG(_c3) / 10.0 AS avg_tmax_celsius
FROM NOAA_GHCN_S3.noaa_ghcn_daily_2025
WHERE _c0 = 'USW00094728'
  AND _c2 = 'TMAX'
GROUP BY SUBSTR(_c1, 1, 6)
ORDER BY year_month;

-- 7. Top 10 wettest stations in the file by total annual precipitation --
-- the standard "top row(s) per group" window-function pattern used
-- throughout this repo, here ranking stations instead of partitioning
-- within them. PRCP is in tenths of a millimeter:
SELECT station_id, total_prcp_mm, rn
FROM (
    SELECT
        _c0 AS station_id,
        SUM(_c3) / 10.0 AS total_prcp_mm,
        ROW_NUMBER() OVER (ORDER BY SUM(_c3) DESC) AS rn
    FROM NOAA_GHCN_S3.noaa_ghcn_daily_2025
    WHERE _c2 = 'PRCP'
    GROUP BY _c0
) ranked
WHERE rn <= 10
ORDER BY rn;

-- 8. Data-quality flag check -- how many observations carry a non-blank
-- Q-FLAG (GHCN's quality-suspect marker, per the format spec). A non-zero
-- count is expected and normal for a file this size; it is not itself a
-- Zetaris or ingestion problem, just GHCN's own QC process surfacing
-- suspect readings in the source data:
SELECT COUNT(*) AS suspect_flagged_observations
FROM NOAA_GHCN_S3.noaa_ghcn_daily_2025
WHERE _c5 IS NOT NULL AND _c5 <> '';
