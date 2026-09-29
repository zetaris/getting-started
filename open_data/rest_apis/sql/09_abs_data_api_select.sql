-- =============================================================================
-- Verification / example queries for 09_abs_data_api_create.sql
-- Assumes 09_abs_data_api_create.sql has already been run.
--
-- The verification queries below are commented out by default so that
-- running this whole file doesn't automatically fire read queries against
-- every view. Uncomment what you want to run, or run it directly in the
-- SQL Editor. The example queries further down are left live, same as
-- before.
-- =============================================================================

-- === Verification ===
-- SELECT * FROM abs_data.cpi_dimensions_table;
-- SELECT * FROM abs_data.cpi_series_table ORDER BY period;

-- === Diagnostics === (run if CREATE TABLE or either view in the create
-- script fails)
-- SELECT * FROM abs_rest.cpi_raw;
-- DESCRIBE abs_rest.cpi_raw;
-- If DESCRIBE shows `data.dataSets[0].series` as a struct rather than
-- having a `` `0:0:0:0:0` `` field directly addressable, the series key
-- may differ from what the create script assumes (see the note above
-- the cpi_series_table view there) -- check the actual key first. If
-- the `observations` coercion itself fails, this view already applies
-- the fix described in the SQL companion guide, so a failure here would
-- mean something beyond that specific issue is at play, worth reporting
-- with the exact error.

-- === Example queries ===
-- Run these against cpi_series_table to get a feel for the data once
-- everything's loaded. Picked to be genuinely interesting: trend,
-- volatility, and milestone questions on a real 11-year quarterly
-- economic time series.

-- 1. Full series, chronological:
SELECT period, cpi_index FROM abs_data.cpi_series_table ORDER BY period;

-- 2. Highest and lowest index values on record, and which quarter each
-- occurred:
SELECT period, cpi_index FROM abs_data.cpi_series_table ORDER BY cpi_index DESC LIMIT 1;
SELECT period, cpi_index FROM abs_data.cpi_series_table ORDER BY cpi_index ASC LIMIT 1;

-- 3. Quarter-over-quarter change -- a new pattern for this package,
-- LAG() instead of ROW_NUMBER()/RANK(), for "compare this row to the
-- previous row" rather than "rank within a group":
SELECT
    period,
    cpi_index,
    ROUND(cpi_index - LAG(cpi_index) OVER (ORDER BY period), 2) AS qoq_change
FROM abs_data.cpi_series_table
ORDER BY period;

-- 4. Year-over-year percentage change -- LAG by 4 quarters instead of 1,
-- the standard way inflation is usually reported:
SELECT
    period,
    cpi_index,
    ROUND(100.0 * (cpi_index - LAG(cpi_index, 4) OVER (ORDER BY period))
        / LAG(cpi_index, 4) OVER (ORDER BY period), 2) AS yoy_pct_change
FROM abs_data.cpi_series_table
ORDER BY period;

-- 5. Average CPI index per year -- extracting the year from the period
-- string and aggregating (2026 will show fewer quarters than other years
-- since the series doesn't run a full year yet -- not a bug):
SELECT
    SUBSTR(period, 1, 4) AS year,
    ROUND(AVG(cpi_index), 2) AS avg_cpi_index,
    COUNT(*) AS quarters_counted
FROM abs_data.cpi_series_table
GROUP BY 1
ORDER BY year;

-- 6. The 8 most recent quarters (roughly the last 2 years), most recent
-- first -- a normal "recent trend" view now the sparse data is in rows:
SELECT period, cpi_index
FROM abs_data.cpi_series_table
ORDER BY period DESC
LIMIT 8;

-- 7. Cumulative change from the first quarter on record to the most
-- recent one -- how much has the index grown over the full series.
-- Uses FIRST_VALUE/LAST_VALUE windows (not MIN/MAX(cpi_index), which
-- would just find the overall smallest/largest value -- only equal to
-- the first/last chronological value because this series happens to be
-- monotonically increasing) and touches cpi_series_table exactly once,
-- avoiding the multi-reference self-join limitation covered in the SQL
-- companion guide:
SELECT DISTINCT
    first_val AS earliest_cpi_index,
    last_val AS latest_cpi_index,
    ROUND(100.0 * (last_val - first_val) / first_val, 2) AS total_pct_growth
FROM (
    SELECT
        FIRST_VALUE(cpi_index) OVER (ORDER BY period ASC) AS first_val,
        LAST_VALUE(cpi_index) OVER (ORDER BY period ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_val
    FROM abs_data.cpi_series_table
) t;

-- 8. Quarters where the index fell versus rose versus stayed flat --
-- a distribution over the whole series, using the same LAG() pattern as
-- query 3:
SELECT
    CASE
        WHEN qoq_change > 0 THEN 'increase'
        WHEN qoq_change < 0 THEN 'decrease'
        ELSE 'flat'
    END AS direction,
    COUNT(*) AS quarter_count
FROM (
    SELECT cpi_index - LAG(cpi_index) OVER (ORDER BY period) AS qoq_change
    FROM abs_data.cpi_series_table
) t
WHERE qoq_change IS NOT NULL
GROUP BY 1
ORDER BY quarter_count DESC;
