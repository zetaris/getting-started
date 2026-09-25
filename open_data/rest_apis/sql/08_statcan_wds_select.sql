-- =============================================================================
-- Verification / example queries for 08_statcan_wds_create.sql
-- Assumes 08_statcan_wds_create.sql has already been run.
--
-- The verification queries below are commented out by default so that
-- running this whole file doesn't automatically fire read queries against
-- every view. Uncomment what you want to run, or run it directly in the
-- SQL Editor. The example queries further down are left live, same as
-- before.
-- =============================================================================

-- === Verification ===
-- SELECT * FROM statcan.changed_cubes_table;
-- SELECT * FROM statcan.changed_cubes_all_table;

-- Row-count cross-check (truncation-bug watch item from the EDGAR test --
-- confirm Zetaris's row count matches the direct API call):
--   Direct API count for 2026-09-17: 60 rows (confirmed via curl | jq
--   '.object | length' on 2026-09-18)
-- SELECT COUNT(*) FROM statcan.changed_cubes_table;  -- expect 60
--   Direct API counts for the 5-day window (confirmed via curl):
--   2026-09-14: 16, 2026-09-15: 14, 2026-09-16: 15, 2026-09-17: 60,
--   2026-09-18: 22 -- 127 total.
-- SELECT COUNT(*) FROM statcan.changed_cubes_all_table;  -- expect 127

-- === Diagnostics === (run if any verification query above fails or comes
-- back empty -- likely means the date in the URL had no published
-- changes, not a Zetaris problem, given how simple this shape is)
-- SELECT * FROM statcan_rest.changed_cubes_20260917;
-- DESCRIBE statcan_rest.changed_cubes_20260917;

-- === Example queries ===
-- Run these against changed_cubes_all_table to get a feel for the data
-- once everything's loaded. Picked to be genuinely interesting given the
-- data is a discovery/catalog feed of opaque product IDs (no
-- human-readable titles -- see caveat 3 in the create script): daily
-- volume trends, which products are updated continuously versus
-- sporadically, and a check on StatCan's own publishing schedule.

-- 1. Daily change volume -- how many cubes changed each day in the window:
SELECT snapshot_date, COUNT(*) AS cubes_changed
FROM statcan.changed_cubes_all_table
GROUP BY snapshot_date
ORDER BY snapshot_date;

-- 2. Busiest and quietest day, ranked -- same window-function pattern
-- confirmed working in sql/03_open_food_facts_live_select.sql,
-- failure_cases/singapore_pm25/04_singapore_pm25_select.sql, and
-- sql/05_nasa_neows_select.sql:
SELECT
    snapshot_date,
    cubes_changed,
    RANK() OVER (ORDER BY cubes_changed DESC) AS busiest_rank
FROM (
    SELECT snapshot_date, COUNT(*) AS cubes_changed
    FROM statcan.changed_cubes_all_table
    GROUP BY snapshot_date
) daily
ORDER BY busiest_rank;

-- 3. "Daily cubes" -- products that changed on EVERY day in this window
-- (see caveat 7 in the create script). CONFIRMED FAILING live
-- (2026-09-19) in its original form, which compared each product's day
-- count against a scalar subquery re-reading changed_cubes_all_table a
-- second time -- MISSING_ATTRIBUTES.RESOLVED_ATTRIBUTE_APPEAR_IN_OPERATION
-- on explode(object), the same self-reference pitfall already documented
-- in HOWTO.md, "Troubleshooting / FAQ" (referencing a UNION ALL'd
-- exploded view more than once in the same query). Fixed by referencing
-- the view exactly once and using a literal for the window size (5 days)
-- instead of a second read of the table -- update the literal if the
-- date range in the create script changes. COUNT(*) (not
-- COUNT(DISTINCT snapshot_date)) is safe here because each product
-- appears at most once per day in this feed:
SELECT product_id, COUNT(*) AS days_changed
FROM statcan.changed_cubes_all_table
GROUP BY product_id
HAVING COUNT(*) = 5
ORDER BY product_id;

-- 4. Update-frequency distribution -- across the whole window, how many
-- products changed exactly once, twice, three times, etc.:
SELECT days_changed, COUNT(*) AS product_count
FROM (
    SELECT product_id, COUNT(DISTINCT snapshot_date) AS days_changed
    FROM statcan.changed_cubes_all_table
    GROUP BY product_id
) freq
GROUP BY days_changed
ORDER BY days_changed;

-- 5. Total distinct products touched across the window, versus total
-- change events -- shows how much of the volume is repeat activity on
-- the same handful of products versus one-off changes:
SELECT
    COUNT(*)                          AS total_change_events,
    COUNT(DISTINCT product_id)        AS distinct_products,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT product_id), 2) AS avg_changes_per_product
FROM statcan.changed_cubes_all_table;

-- 6. Confirms caveat 6 in the create script from inside Zetaris rather
-- than assuming it from the curl investigation -- extracts the
-- time-of-day portion of every release timestamp and counts how many
-- distinct values exist (expect exactly 1, "08:30", if StatCan's fixed
-- publishing schedule holds for this window too):
SELECT
    SUBSTR(release_time, 12) AS release_time_of_day,
    COUNT(*)                 AS release_count
FROM statcan.changed_cubes_all_table
GROUP BY 1
ORDER BY release_count DESC;

-- 7. Full history for each "daily cube" found in query 3 -- one row per
-- day for each continuously-updated product, confirming they really did
-- change every single day rather than just coincidentally matching the
-- day count. CONFIRMED FAILING live (2026-09-19) in its original
-- WHERE product_id IN (SELECT ... FROM changed_cubes_all_table ...) form
-- -- same self-reference issue as query 3, actually worse here (the
-- table was referenced three times: outer FROM, IN-subquery, and a
-- nested scalar subquery). Fixed with a window function instead of any
-- subquery, so the view is referenced exactly once:
SELECT product_id, snapshot_date, release_time
FROM (
    SELECT
        product_id,
        snapshot_date,
        release_time,
        COUNT(*) OVER (PARTITION BY product_id) AS days_changed
    FROM statcan.changed_cubes_all_table
) with_counts
WHERE days_changed = 5
ORDER BY product_id, snapshot_date;

-- 8. The 5 products with the lowest product_id number that changed only
-- ONCE in the window -- an arbitrary but concrete "spot check a handful
-- of one-off changes" query, useful as a starting point if you want to
-- manually look up what a specific cube is via StatCan's own website
-- (https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=<product_id>).
-- CONFIRMED FAILING live (2026-09-19) in its original
-- WHERE product_id IN (SELECT ...) form -- same fix as query 7, a window
-- function instead of a subquery re-reading the same view:
SELECT product_id, snapshot_date, release_time
FROM (
    SELECT
        product_id,
        snapshot_date,
        release_time,
        COUNT(*) OVER (PARTITION BY product_id) AS days_changed
    FROM statcan.changed_cubes_all_table
) with_counts
WHERE days_changed = 1
ORDER BY product_id
LIMIT 5;

-- ---------------------------------------------------------------------------
-- Attribution reminder (Statistics Canada Open Licence, per the license
-- note in the create script) -- carry this into any README or demo:
--   "Adapted from Statistics Canada, [dataset/cube name], [access date].
--   This does not constitute an endorsement by Statistics Canada of this
--   product."
-- ---------------------------------------------------------------------------
