-- =============================================================================
-- Source: Australian Bureau of Statistics (ABS) Data API -- CPI example.
--
-- License: Creative Commons Attribution 3.0 Australia by default --
-- https://data.gov.au/data/about -- note this is the older 3.0
-- Australia port, not CC-BY 4.0. Still genuinely permissive; some
-- individual datasets may specify 4.0 instead -- check per-dataset if
-- it matters.
--
-- Format: REST/JSON -- SDMX-JSON 2.0.0 (data-message format), not
-- array-of-structs. See caveat 1 for the shape and the SQL companion
-- guide for the general dynamic-key decode technique this script uses.
--
-- Docs: https://www.abs.gov.au/statistics/application-programming-interfaces-apis/data-api-user-guide/using-api
-- https://data.api.abs.gov.au/rest/ (base API root)
--
-- Rate limit: no API key required.
--
-- Before running: sanity-check the endpoint returns something sane:
--   curl -s "https://data.api.abs.gov.au/rest/data/ABS,CPI/1.10001.10.50.Q?startPeriod=2015-Q1&detail=dataonly" \
--     -H "Accept: application/vnd.sdmx.data+json" | python3 -m json.tool | head -40
--
-- Status: live-tested and confirmed working (2026-09-19) -- the REST
-- table, both views, and the full value decode all ran successfully.
-- An earlier, broader query failed -- see caveat 2.
-- =============================================================================
--
-- Caveats:
--   1. ABS returns SDMX-JSON 2.0.0's "data-message" format:
--        - `data.structures[0].dimensions.series`: the dimensions that
--          identify a series (MEASURE, INDEX, TSEST, REGION, FREQ, in
--          that dimension-position order -- confirmed via the
--          dataflow's own data structure definition, see caveat 3).
--        - `data.structures[0].dimensions.observation`: the dimension
--          identifying each point within a series (here, just
--          TIME_PERIOD).
--        - `data.dataSets[0].series`: an object keyed by a
--          colon-separated dimension-index tuple (e.g. "0:0:0:0:0") --
--          each value has its own nested `observations` object, itself
--          keyed by a time-index string (e.g. "0", "1", "2"), each
--          pointing to a one-element array `[value]`.
--      This is a doubly-nested dynamic-key structure -- see caveat 4
--      for why this script only needs one coercion, not two.
--   2. An earlier version of this script used the broad `all` query
--      (about 2.4 MB, every MEASURE/INDEX/TSEST/REGION/FREQ combination
--      for the whole CPI dataflow), which failed its
--      CREATE LIGHTNING REST TABLE statement live with a raw
--      `java.sql.SQLException: org.apache.thrift.transport.TTransportException`
--      -- a low-level transport failure, most likely the response size
--      overwhelming the Thrift transport for one fetch, not confirmed
--      by inspecting Zetaris's own logs. The fix (caveat 3) resolves it
--      either way.
--   3. Fixed, confirmed via curl: the broad `all` query has been
--      replaced with a properly-scoped one using real dimension codes,
--      derived from the dataflow's own structure and codelist
--      endpoints rather than guessed:
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
--        ("Australia"), FREQ=Q ("Quarterly") -- giving the dimension
--        key `1.10001.10.50.Q`, confirmed to return a single real,
--        populated series (46 quarters, 2015-Q1 through 2026-Q2, about
--        11 KB) rather than an empty `value: {}` or a multi-megabyte
--        response.
--   4. Deliberately scoping the query to a single series (caveat 3 --
--      every non-time dimension fixed to exactly one code) shortcuts
--      the "two levels of dynamic keys" problem down to effectively one
--      level:
--        a. `data.dataSets[0].series` only ever has one key in this
--           response -- "0:0:0:0:0" -- since every dimension has
--           exactly one valid code at position 0. Because there's only
--           one key, it can be addressed directly via backtick-quoted
--           dot-access, no explode() or coercion needed for this outer
--           level at all. This only works because the query is scoped
--           to one series; a broader query with multiple series would
--           need the harder, two-level coercion.
--        b. `data.structures[0].dimensions.observation[0].values` is a
--           genuine JSON array of {id, name, start, end} objects
--           (period labels, e.g. "2015-Q1") -- not a dynamic-key
--           object -- so it explodes directly with a plain
--           posexplode(), giving each period label's array position
--           alongside its text, with no coercion needed either.
--        c. Only the innermost `observations` object (keyed "0".."45",
--           each value a one-element array `[number]`) is genuinely
--           dynamic-key and needs the coercion, decoding cleanly into
--           46 real quarterly CPI index values, 2015-Q1 (74.16) through
--           2026-Q2 (102.31), joining the observation's array position
--           (from posexplode() in point b) against the coerced map's
--           integer key.
-- =============================================================================

-- Step 0: Lightning database for this source.
CREATE LIGHTNING DATABASE ABS_REST DESCRIBE BY "Australian Bureau of Statistics Data API SDMX-JSON source";

-- Step 1: schemastore container. Run once -- comment out on a re-run
-- if it already exists in your environment.
CREATE SCHEMASTORE CONTAINER abs_data;

-- CPI -- Australia, all groups, original (not seasonally adjusted),
-- quarterly, 2015-Q1 onward. A properly-scoped query (see caveat 3) --
-- not the broad "all" query that failed with a transport exception.
CREATE LIGHTNING REST TABLE cpi_raw FROM ABS_REST REQUEST(
    endpoint "https://data.api.abs.gov.au/rest/data/ABS,CPI/1.10001.10.50.Q?startPeriod=2015-Q1&detail=dataonly",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    accept "application/vnd.sdmx.data+json"
) BODY ();

-- The dataflow's own dimension metadata (a normal nested-struct
-- shape), not the actual observation values.
CREATE SCHEMASTORE VIEW cpi_dimensions_table WITH CONTAINER abs_data AS
SELECT
    dim.id AS dimension_id,
    dim.name AS dimension_name
FROM abs_rest.cpi_raw
LATERAL VIEW explode(data.structures[0].dimensions.series) AS dim;

-- Full decoded time series -- one row per quarter, real CPI index
-- values (see caveat 4 for exactly how this avoids needing a two-level
-- decode). The literal series key `0:0:0:0:0` is specific to this
-- exact query's dimension scoping (caveat 3) -- if you change which
-- codes you filter to, check `SELECT * FROM abs_rest.cpi_raw` for the
-- actual key first; it will still be all zeros as long as exactly one
-- code per non-time dimension is used, but don't assume it without
-- checking.
CREATE SCHEMASTORE VIEW cpi_series_table WITH CONTAINER abs_data AS
SELECT
    period_label.id AS period,
    CAST(obs_value[0] AS DOUBLE) AS cpi_index
FROM abs_rest.cpi_raw
LATERAL VIEW posexplode(data.structures[0].dimensions.observation[0].values) AS obs_position, period_label
LATERAL VIEW explode(from_json(to_json(data.dataSets[0].series.`0:0:0:0:0`.observations), 'map<string,array<double>>')) AS obs_key, obs_value
WHERE CAST(obs_key AS INT) = obs_position;

-- =============================================================================
-- Teardown -- removes the flattened view this script created.
-- Commented out by default. See the SQL companion guide for why
-- DROP VIEW is the only reliable teardown statement, and how to remove
-- the underlying REST table and database registration (Zetaris Data
-- Explorer -- no SQL path exists).
-- =============================================================================

-- DROP VIEW abs_data.cpi_dimensions_table;
-- DROP VIEW abs_data.cpi_series_table;
