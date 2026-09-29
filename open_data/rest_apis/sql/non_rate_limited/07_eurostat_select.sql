-- =============================================================================
-- Verification / example queries for 07_eurostat_create.sql
-- Assumes 07_eurostat_create.sql has already been run.
--
-- The verification queries below are commented out by default so that
-- running this whole file doesn't automatically fire read queries
-- against every view. Uncomment what you want to run, or run it
-- directly in the SQL Editor. The example queries further down are
-- left live, same as before -- all confirmed working against Zetaris
-- (2026-09-19).
-- =============================================================================

-- === Verification ===
-- SELECT * FROM eurostat.une_rt_m_pl_metadata_table;
-- SELECT * FROM eurostat.une_rt_m_pl_snapshot_table;
-- SELECT * FROM eurostat.une_rt_m_pl_series_table ORDER BY period;

-- === Diagnostics === (kept for reference -- une_rt_m_pl_series_table
-- is confirmed working now, but this is useful if the same pattern
-- fails on a different JSON-stat/SDMX dataset elsewhere)
-- SELECT * FROM eurostat_rest.une_rt_m_pl;
-- DESCRIBE eurostat_rest.une_rt_m_pl;
-- `value` and `dimension.time.category.index` are both inferred as a
-- struct with one field per dynamic key, not a map -- the
-- to_json/from_json coercion, applied to both exploded fields,
-- resolves this (confirmed by 355 correct rows being returned). See
-- the SQL companion guide for the general lesson: check whether every
-- dynamic-key object being exploded in the same query has the
-- coercion applied, not just the first one you notice.

-- === Example queries ===
-- Queries 1-3 use the metadata and snapshot views (no explode() involved);
-- queries 4-8 use the fully-decoded une_rt_m_pl_series_table.

-- 1. Dataset descriptive metadata -- confirms which dataset, which
-- region, and when it was last updated at the source:
SELECT dataset_label, dataset_source, last_updated
FROM eurostat.une_rt_m_pl_metadata_table;

-- 2. Long-run change -- Poland's unemployment rate in the earliest
-- available month on record (1997-01) versus the most recent published
-- month (2026-07), using only the low-risk snapshot view:
SELECT
    rate_1997_01,
    rate_2026_07,
    ROUND(rate_2026_07 - rate_1997_01, 1) AS change_percentage_points
FROM eurostat.une_rt_m_pl_snapshot_table;

-- 3. Year-over-year change -- July 2026 versus July 2025, same
-- low-risk technique:
SELECT
    rate_2025_07,
    rate_2026_07,
    ROUND(rate_2026_07 - rate_2025_07, 1) AS year_over_year_change_pct_points
FROM eurostat.une_rt_m_pl_snapshot_table;

-- 4. Full decoded time series, chronological -- only works if
-- une_rt_m_pl_series_table (in the create script) succeeded:
SELECT * FROM eurostat.une_rt_m_pl_series_table ORDER BY period;

-- 5. The highest and lowest unemployment rate ever recorded in this
-- series, and which month each occurred:
SELECT period, unemployment_rate_pct
FROM eurostat.une_rt_m_pl_series_table
ORDER BY unemployment_rate_pct DESC
LIMIT 1;

SELECT period, unemployment_rate_pct
FROM eurostat.une_rt_m_pl_series_table
ORDER BY unemployment_rate_pct ASC
LIMIT 1;

-- 6. The most recent 12 published months, most recent first -- a normal
-- "recent trend" view now that the data is in proper row form:
SELECT period, unemployment_rate_pct
FROM eurostat.une_rt_m_pl_series_table
ORDER BY period DESC
LIMIT 12;

-- 7. Average unemployment rate per decade -- extracting the year from
-- the period string and bucketing it, a simple aggregate that only makes
-- sense once the sparse value data is in real rows:
SELECT
    CONCAT(SUBSTR(period, 1, 3), '0s') AS decade,
    ROUND(AVG(unemployment_rate_pct), 1) AS avg_unemployment_rate_pct,
    COUNT(*) AS months_counted
FROM eurostat.une_rt_m_pl_series_table
GROUP BY 1
ORDER BY decade;

-- 8. First month the rate dropped to single digits (below 10%) --
-- a milestone-style query, ordered chronologically and taking the
-- earliest match:
SELECT period, unemployment_rate_pct
FROM eurostat.une_rt_m_pl_series_table
WHERE unemployment_rate_pct < 10
ORDER BY period ASC
LIMIT 1;

-- ---------------------------------------------------------------------------
-- Attribution reminder -- carry this into any README or demo that
-- displays data from this source:
--   "Source: Eurostat, une_rt_m (unemployment rate, monthly)."
-- ---------------------------------------------------------------------------
