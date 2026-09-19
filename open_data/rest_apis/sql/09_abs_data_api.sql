-- =============================================================================
-- Source:   Australian Bureau of Statistics (ABS) Data API -- CPI example
-- License:  Creative Commons Attribution 3.0 Australia by default --
--           https://data.gov.au/data/about -- note this is the OLDER 3.0
--           Australia port, not CC-BY 4.0 like most other sources in this
--           package. Still genuinely permissive; some individual datasets
--           may specify 4.0 instead -- check per-dataset if it matters.
-- Format:   REST/JSON -- SDMX-JSON 2.0.0 (data-message format), NOT
--           array-of-structs. See caveat 1 below -- same shape class as
--           sql/07_eurostat.sql; both are now fully working, including a
--           full value decode (see caveat 4).
-- Docs:     https://www.abs.gov.au/statistics/application-programming-interfaces-apis/data-api-user-guide/using-api
--           https://data.api.abs.gov.au/rest/ (base API root)
-- Rate limit: no API key required.
-- Before running: sanity-check the endpoint returns something sane --
--   curl -s "https://data.api.abs.gov.au/rest/data/ABS,CPI/1.10001.10.50.Q?startPeriod=2015-Q1&detail=dataonly" \
--     -H "Accept: application/vnd.sdmx.data+json" | python3 -m json.tool | head -40
-- =============================================================================
--
-- Investigated 2026-09-19, confirmed via real (not guessed) queries --
-- CONFIRMED FAILING then FIXED (2026-09-19): the version of this script
-- that used the broad `all` query (~2.4 MB, every MEASURE/INDEX/TSEST/
-- REGION/FREQ combination for the whole CPI dataflow) failed its
-- CREATE LIGHTNING REST TABLE statement live with a raw
-- `java.sql.SQLException: org.apache.thrift.transport.TTransportException`
-- -- a low-level transport failure, not a SQL or REST error, giving no
-- direct indication of cause. The most likely explanation, consistent
-- with this script's own pre-existing warning about the response size:
-- ~2.4 MB was too large for the Thrift transport between the SQL client
-- and the backend to handle for one CREATE TABLE fetch (a timeout or a
-- message-size limit) -- NOT confirmed by inspecting Zetaris's own logs,
-- but the fix below (narrowing to a tiny, properly-scoped query)
-- resolves it either way, so this wasn't investigated further.
--   1. SHAPE: ABS returns SDMX-JSON 2.0.0's "data-message" format,
--      structurally similar to but not identical to Eurostat's JSON-stat:
--        - `data.structures[0].dimensions.series`: the dimensions that
--          identify a SERIES (MEASURE, INDEX, TSEST, REGION, FREQ, in
--          that dimension-position order -- confirmed via the dataflow's
--          own data structure definition, see caveat 2).
--        - `data.structures[0].dimensions.observation`: the dimension
--          identifying each POINT within a series (here, just TIME_PERIOD).
--        - `data.dataSets[0].series`: an object keyed by a
--          COLON-SEPARATED DIMENSION-INDEX TUPLE (e.g. "0:0:0:0:0") --
--          each value has its OWN nested `observations` object, itself
--          keyed by a TIME-INDEX STRING (e.g. "0", "1", "2"), each
--          pointing to a one-element array `[value]`.
--      This is a doubly-nested dynamic-key structure -- not one level of
--      sparse indexing like Eurostat, but two (series key, then
--      observation key within that series).
--   2. FIXED, confirmed via curl (2026-09-19): the broad `all` query has
--      been replaced with a properly-scoped one using REAL dimension
--      codes, derived from the dataflow's own structure and codelist
--      endpoints rather than guessed (an earlier guess, "M1.AUS.10001.Q",
--      404'd with "Could not find Dataflow and/or DSD related with this
--      data request" -- the dataflow ID was valid, the key syntax and
--      codes were wrong):
--        curl -s "https://data.api.abs.gov.au/rest/datastructure/ABS/CPI"
--          -H "Accept: application/vnd.sdmx.structure+json"
--        -- confirms dimension order: MEASURE(0), INDEX(1), TSEST(2),
--        REGION(3), FREQ(4), then TIME_PERIOD.
--        curl -s "https://data.api.abs.gov.au/rest/codelist/ABS/<codelist_id>"
--          -H "Accept: application/vnd.sdmx.structure+json"
--        -- run once per dimension's codelist (CL_CPI_MEASURES,
--        CL_CPI_INDEX, CL_TSEST, CL_CPI_REGION, CL_FREQ) to find valid
--        codes. Used here: MEASURE=1 ("Index numbers"), INDEX=10001
--        ("All groups CPI"), TSEST=10 ("Original"), REGION=50
--        ("Australia"), FREQ=Q ("Quarterly") -- giving the dimension key
--        `1.10001.10.50.Q`, confirmed to return a single real, populated
--        series (46 quarters, 2015-Q1 through 2026-Q2, ~11 KB) rather
--        than an empty `value: {}` or a multi-megabyte response.
--   3. Live-tested and confirmed working (2026-09-19): the fixed
--      CREATE LIGHTNING REST TABLE statement and cpi_dimensions_table
--      view both succeeded in Zetaris.
--   4. FULL VALUE DECODE, confirmed via curl AND live in Zetaris (2026-09-19) -- extended the
--      same day with cpi_series_table, a real (period, cpi_index) row
--      per quarter. Deliberately scoping the query to a SINGLE series
--      (caveat 2 -- every non-time dimension fixed to exactly one code)
--      turns out to shortcut ABS's "two levels of dynamic keys" problem
--      down to effectively ONE level:
--        a. `data.dataSets[0].series` only ever has ONE key in this
--           response -- "0:0:0:0:0" (all zeros, since every dimension
--           has exactly one valid code at position 0). Because there's
--           only one key, it can be addressed directly via backtick-
--           quoted dot-access (`` series.`0:0:0:0:0` ``), the same
--           low-risk technique as Eurostat's snapshot view (sql/07) --
--           no explode() or coercion needed for this outer level at all.
--           This ONLY works because the query is scoped to one series;
--           a broader query with multiple series would need the harder,
--           two-level coercion originally anticipated in caveat 1.
--        b. `data.structures[0].dimensions.observation[0].values` is a
--           genuine JSON ARRAY of {id, name, start, end} objects (period
--           labels, e.g. "2015-Q1") -- NOT a dynamic-key object -- so it
--           explodes directly with a plain `posexplode()`, giving each
--           period label's ARRAY POSITION alongside its text, with no
--           coercion needed either.
--        c. Only the innermost `observations` object (keyed "0".."45",
--           each value a one-element array `[number]`) is genuinely
--           dynamic-key and needs the Eurostat-style
--           `from_json(to_json(...), 'map<string,array<double>>')`
--           coercion -- confirmed via curl to decode cleanly into 46
--           real quarterly CPI index values, 2015-Q1 (74.16) through
--           2026-Q2 (102.31), joining the observation's array POSITION
--           (from posexplode() in point b) against the coerced map's
--           integer key.
--      Net result: only ONE coercion is needed here, not two -- the
--      "two levels of dynamic keys" risk in caveat 1 turned out to be
--      avoidable specifically because of how this query was scoped.
--
-- ---------------------------------------------------------------------------
-- STEP 0: Lightning database for this source.
-- ---------------------------------------------------------------------------
CREATE LIGHTNING DATABASE ABS_REST DESCRIBE BY "Australian Bureau of Statistics Data API SDMX-JSON source";

-- ---------------------------------------------------------------------------
-- STEP 1: SCHEMASTORE container. RUN ONCE -- see open_data/rest_apis/HOWTO.md,
-- "Known limitations" (no IF NOT EXISTS support). Comment out on a re-run
-- if it already exists in your environment.
-- ---------------------------------------------------------------------------
CREATE SCHEMASTORE CONTAINER abs_data;

-- =============================================================================
-- CPI -- Australia, all groups, original (not seasonally adjusted),
-- quarterly, 2015-Q1 onward. A properly-scoped query (see caveat 2) --
-- NOT the broad "all" query that failed with a transport exception.
-- =============================================================================
CREATE LIGHTNING REST TABLE cpi_raw FROM ABS_REST REQUEST(
    endpoint "https://data.api.abs.gov.au/rest/data/ABS,CPI/1.10001.10.50.Q?startPeriod=2015-Q1&detail=dataonly",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    accept "application/vnd.sdmx.data+json"
) BODY ();

-- Confirmed working -- the dataflow's own dimension metadata (a normal
-- nested-struct shape), NOT the actual observation values:
CREATE SCHEMASTORE VIEW cpi_dimensions_table WITH CONTAINER abs_data AS
SELECT
    dim.id    AS dimension_id,
    dim.name  AS dimension_name
FROM abs_rest.cpi_raw
LATERAL VIEW explode(data.structures[0].dimensions.series) AS dim;

-- Full decoded time series -- one row per quarter, real CPI index values
-- (see caveat 4 for exactly how this avoids needing a two-level decode).
-- The literal series key `0:0:0:0:0` is specific to this exact query's
-- dimension scoping (caveat 2) -- if you change which codes you filter
-- to, check `SELECT * FROM abs_rest.cpi_raw` for the actual key first,
-- it will still be all zeros as long as exactly one code per non-time
-- dimension is used, but don't assume it without checking:
CREATE SCHEMASTORE VIEW cpi_series_table WITH CONTAINER abs_data AS
SELECT
    period_label.id                                  AS period,
    CAST(obs_value[0] AS DOUBLE)                      AS cpi_index
FROM abs_rest.cpi_raw
LATERAL VIEW posexplode(data.structures[0].dimensions.observation[0].values) AS obs_position, period_label
LATERAL VIEW explode(from_json(to_json(data.dataSets[0].series.`0:0:0:0:0`.observations), 'map<string,array<double>>')) AS obs_key, obs_value
WHERE CAST(obs_key AS INT) = obs_position;

-- Verify:
SELECT * FROM abs_data.cpi_dimensions_table;
SELECT * FROM abs_data.cpi_series_table ORDER BY period;

-- ---------------------------------------------------------------------------
-- Diagnostic (run if the CREATE TABLE or either view above fails):
--   SELECT * FROM abs_rest.cpi_raw;
--   DESCRIBE abs_rest.cpi_raw;
-- If DESCRIBE shows `data.dataSets[0].series` as a STRUCT rather than
-- having a `` `0:0:0:0:0` `` field directly addressable, the series key
-- may differ from what this script assumes (see the note above the
-- cpi_series_table view) -- check the actual key first. If the
-- `observations` coercion itself fails, that's the same struct-inference
-- behavior confirmed on Eurostat's `value` field (HOWTO.md,
-- "Troubleshooting / FAQ") -- this view already applies the fix, so a
-- failure here would mean something beyond that specific issue is at
-- play, worth reporting with the exact error.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Example queries -- run these against cpi_series_table to get a feel for
-- the data once everything's loaded. Picked to be genuinely interesting:
-- trend, volatility, and milestone questions on a real 11-year quarterly
-- economic time series.
-- ---------------------------------------------------------------------------

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
-- avoiding the multi-reference limitation documented in HOWTO.md (the
-- same MISSING_ATTRIBUTES.RESOLVED_ATTRIBUTE_APPEAR_IN_OPERATION class
-- of error found on Open Food Facts and StatCan):
SELECT DISTINCT
    first_val AS earliest_cpi_index,
    last_val  AS latest_cpi_index,
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

-- =============================================================================
-- TEARDOWN -- removes the flattened view this script created. Commented
-- out by default so a re-run of the file above doesn't accidentally wipe
-- a live environment; uncomment and run standalone when you want to tear
-- this view down.
--
-- DROP VIEW is the only teardown statement confirmed to work reliably in
-- this package. There is no SQL statement confirmed to remove the raw
-- REST table or the ABS_REST Lightning database registration itself --
-- see HOWTO.md, "Removing a source" and "Troubleshooting / FAQ", for the
-- full explanation.
-- =============================================================================

-- DROP VIEW abs_data.cpi_dimensions_table;

-- To remove the ABS_REST REST table and Lightning database registration,
-- use the Zetaris Data Explorer's "File Source & API" panel (see
-- HOWTO.md, "Removing a source").
