-- =============================================================================
-- Source: Eurostat REST API (Statistics API) -- unemployment rate example.
--
-- License: Eurostat's "Copyright notice and free re-use of data" policy
-- is generally understood to align with CC-BY 4.0 --
-- https://ec.europa.eu/eurostat/about/policies/copyright -- worth
-- reading directly, not independently confirmed as a hard match.
--
-- Format: REST/JSON -- JSON-stat 2.0, a sparse, dynamic-key format, not
-- array-of-structs. See the SQL companion guide for the general decode
-- technique this script uses (from_json(to_json(...)) coercion); the
-- caveats below cover only what's specific to this dataset.
--
-- Docs: https://wikis.ec.europa.eu/display/EUROSTATHELP/API+Statistics+-+data+query
-- https://json-stat.org/ (the underlying open JSON-stat format spec)
--
-- Rate limit: fully public, no key, no registration, CORS-enabled.
--
-- Before running: sanity-check the endpoint returns something sane:
--   curl -s "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/une_rt_m?format=JSON&geo=PL&sex=T&age=TOTAL&unit=PC_ACT&s_adj=SA&lang=EN" | python3 -m json.tool | head -40
--
-- Status: live-tested and confirmed working end to end (2026-09-19) --
-- the base REST table, the metadata view, the snapshot view, and the
-- full value-decode view (355 rows, matching curl) are all confirmed,
-- and every example query has been run and verified.
-- =============================================================================
--
-- Caveats:
--   1. An earlier version of this script used `age=Y15-74`, which is
--      not a valid age code for the une_rt_m dataset -- Eurostat
--      doesn't error on an invalid code, it silently returns a
--      dimension with zero valid categories
--      (`dimension.age.category.index: {}`) and therefore an empty
--      `value: {}` for the whole query, which looked like "no data
--      available" rather than "wrong parameter." The actual valid age
--      codes for this dataset are `TOTAL`, `Y_LT25` (under 25), and
--      `Y25-74` (25 to 74) -- confirmed by querying without an age
--      filter and reading back `dimension.age.category.index`. Fixed
--      below to use `age=TOTAL`. See the SQL companion guide for the
--      general lesson this confirms about JSON-stat sources.
--   2. With that fix, this combination (Poland, total population,
--      seasonally adjusted unemployment rate, monthly) returns 355
--      populated values out of a possible 524 time slots, confirmed
--      contiguous from index 168 (period "1997-01") through index 522
--      (period "2026-07") -- index 523 ("2026-08") is simply not
--      published yet, a normal reporting lag, not a gap or a bug.
--   3. `label`, `source`, `updated`, `dimension`, `value` are all
--      lowercase, ordinary field names -- no backtick-quoting needed
--      for the top-level fields used in the metadata view. The dynamic
--      keys are one level down, inside `value` and inside each
--      dimension's `category.index`/`category.label` objects.
--   4. `dimension.time.category.index` maps a period label (e.g.
--      "2026-07") to its integer offset. For time, the label is
--      already a human-readable period string, so decoding time only
--      needs `category.index`, not `category.label`.
-- =============================================================================

-- Step 0: Lightning database for this source.
CREATE LIGHTNING DATABASE EUROSTAT_REST DESCRIBE BY "Eurostat REST API JSON-stat source";

-- Step 1: schemastore container. Run once -- comment out on a re-run
-- if it already exists in your environment.
CREATE SCHEMASTORE CONTAINER eurostat;

-- Unemployment rate -- Poland, total population, monthly, seasonally
-- adjusted (une_rt_m). Uses age=TOTAL, not the originally-tried
-- Y15-74 -- see caveat 1.
CREATE LIGHTNING REST TABLE une_rt_m_pl FROM EUROSTAT_REST REQUEST(
    endpoint "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/une_rt_m?format=JSON&geo=PL&sex=T&age=TOTAL&unit=PC_ACT&s_adj=SA&lang=EN",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
) BODY ();

-- The dataset's own descriptive metadata and axis labels (a normal
-- nested-struct shape), not the actual data values.
CREATE SCHEMASTORE VIEW une_rt_m_pl_metadata_table WITH CONTAINER eurostat AS
SELECT
    label AS dataset_label,
    source AS dataset_source,
    updated AS last_updated,
    dimension.geo.category.label AS geo_labels,
    dimension.time.category.index AS time_index_map
FROM eurostat_rest.une_rt_m_pl;

-- Low-risk spot-check view -- three specific, confirmed-present time
-- indices pulled out via direct backtick-quoted dot-access, no
-- explode() involved at all.
CREATE SCHEMASTORE VIEW une_rt_m_pl_snapshot_table WITH CONTAINER eurostat AS
SELECT
    value.`168` AS rate_1997_01,
    value.`510` AS rate_2025_07,
    value.`522` AS rate_2026_07
FROM eurostat_rest.une_rt_m_pl;

-- Full decode -- turns the whole sparse `value` object into a real
-- (period, rate) row per available month. Both dynamic-key objects
-- being exploded (`value` and `dimension.time.category.index`) need
-- the same to_json/from_json coercion -- a plain explode() on either
-- one without coercion fails with a DATATYPE_MISMATCH, since both are
-- inferred as a struct, not a map. See the SQL companion guide for why.
CREATE SCHEMASTORE VIEW une_rt_m_pl_series_table WITH CONTAINER eurostat AS
SELECT
    time_label AS period,
    CAST(rate_value AS DOUBLE) AS unemployment_rate_pct
FROM eurostat_rest.une_rt_m_pl
LATERAL VIEW explode(from_json(to_json(value), 'map<string,double>')) AS time_key, rate_value
LATERAL VIEW explode(from_json(to_json(dimension.time.category.index), 'map<string,bigint>')) AS time_label, time_index_value
WHERE CAST(time_key AS INT) = time_index_value;

-- =============================================================================
-- Teardown -- removes the flattened views this script created.
-- Commented out by default. See the SQL companion guide for why
-- DROP VIEW is the only reliable teardown statement, and how to remove
-- the underlying REST table and database registration (Zetaris Data
-- Explorer -- no SQL path exists).
-- =============================================================================

-- DROP VIEW eurostat.une_rt_m_pl_metadata_table;
-- DROP VIEW eurostat.une_rt_m_pl_snapshot_table;
-- DROP VIEW eurostat.une_rt_m_pl_series_table;
