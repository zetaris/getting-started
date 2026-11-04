-- =============================================================================
-- Verification and example queries for 07_ookla_speedtest_create.sql.
-- Assumes 07_ookla_speedtest_create.sql has already been run.
--
-- Confirmed live 2026-10-31 on the 2026 quarter=2 files (one Parquet file
-- per network type). DESCRIBE returned the same 11 columns on both tables:
-- quadkey, tile (WKT polygon), tile_x, tile_y, avg_d_kbps, avg_u_kbps,
-- avg_lat_ms, avg_lat_down_ms, avg_lat_up_ms, tests, devices.
-- avg_*_kbps values are kilobits per second. tile_x / tile_y are the tile
-- centroid longitude and latitude.
--
-- Each file is one global quarter, not a city partition. Aggregations
-- below keep a Manhattan window so they aggregate a bounded set of tiles:
--   tile_x BETWEEN -74.02 AND -73.93
--   tile_y BETWEEN 40.70 AND 40.82
-- On 2026-10-31 that window held 406 fixed tiles (77,758 tests) and 385
-- mobile tiles (15,686 tests). Scans of one file took about 4-19 seconds.
-- An earlier HTTP 500 at CREATE is recorded in
-- sql/known_to_fail/ISSUE-07-ookla.md and did not reproduce.
-- =============================================================================

-- === Verification ===
SELECT * FROM OOKLA_S3.ookla_speedtest_fixed LIMIT 10;
SELECT * FROM OOKLA_S3.ookla_speedtest_mobile LIMIT 10;

-- 1. Confirm column names and inferred types:
DESCRIBE OOKLA_S3.ookla_speedtest_fixed;
DESCRIBE OOKLA_S3.ookla_speedtest_mobile;

-- === Example queries ===
-- All queries below confirmed live against the window above.
-- Download and upload averages are weighted by tests.

-- 2. Fixed overview inside the window:
SELECT
    COUNT(*) AS tiles,
    SUM(tests) AS tests,
    SUM(devices) AS devices,
    CAST(SUM(avg_d_kbps * tests) / SUM(tests) AS BIGINT) AS tests_weighted_avg_d_kbps,
    CAST(SUM(avg_u_kbps * tests) / SUM(tests) AS BIGINT) AS tests_weighted_avg_u_kbps,
    CAST(SUM(avg_lat_ms * tests) / SUM(tests) AS BIGINT) AS tests_weighted_avg_lat_ms
FROM OOKLA_S3.ookla_speedtest_fixed
WHERE tile_x BETWEEN -74.02 AND -73.93
  AND tile_y BETWEEN 40.70 AND 40.82;

-- 3. Mobile overview, same window:
SELECT
    COUNT(*) AS tiles,
    SUM(tests) AS tests,
    SUM(devices) AS devices,
    CAST(SUM(avg_d_kbps * tests) / SUM(tests) AS BIGINT) AS tests_weighted_avg_d_kbps,
    CAST(SUM(avg_u_kbps * tests) / SUM(tests) AS BIGINT) AS tests_weighted_avg_u_kbps,
    CAST(SUM(avg_lat_ms * tests) / SUM(tests) AS BIGINT) AS tests_weighted_avg_lat_ms
FROM OOKLA_S3.ookla_speedtest_mobile
WHERE tile_x BETWEEN -74.02 AND -73.93
  AND tile_y BETWEEN 40.70 AND 40.82;

-- 4. Fixed download bands. Thresholds are on avg_d_kbps
-- (100000 kbps = 100 Mbps, 1000000 kbps = 1000 Mbps):
SELECT
    CASE
        WHEN avg_d_kbps >= 1000000 THEN '>=1000 Mbps'
        WHEN avg_d_kbps >= 100000 THEN '100-1000 Mbps'
        WHEN avg_d_kbps >= 25000 THEN '25-100 Mbps'
        ELSE '<25 Mbps'
    END AS download_band,
    COUNT(*) AS tiles,
    SUM(tests) AS tests
FROM OOKLA_S3.ookla_speedtest_fixed
WHERE tile_x BETWEEN -74.02 AND -73.93
  AND tile_y BETWEEN 40.70 AND 40.82
GROUP BY
    CASE
        WHEN avg_d_kbps >= 1000000 THEN '>=1000 Mbps'
        WHEN avg_d_kbps >= 100000 THEN '100-1000 Mbps'
        WHEN avg_d_kbps >= 25000 THEN '25-100 Mbps'
        ELSE '<25 Mbps'
    END
ORDER BY download_band;

-- 5. Busiest fixed tiles in the window:
SELECT quadkey, tile_x, tile_y, avg_d_kbps, avg_u_kbps, avg_lat_ms, tests, devices
FROM OOKLA_S3.ookla_speedtest_fixed
WHERE tile_x BETWEEN -74.02 AND -73.93
  AND tile_y BETWEEN 40.70 AND 40.82
ORDER BY tests DESC
LIMIT 10;
