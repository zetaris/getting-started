-- =============================================================================
-- Source:   Australian Bureau of Statistics (ABS) Data API -- CPI example
-- License:  Creative Commons Attribution 3.0 Australia by default --
--           https://data.gov.au/data/about -- note this is the OLDER 3.0
--           Australia port, not CC-BY 4.0 like most other sources in this
--           package. Still genuinely permissive; some individual datasets
--           may specify 4.0 instead -- check per-dataset if it matters.
-- Format:   REST/JSON -- ⚠️ SDMX-JSON 2.0.0 (data-message format), NOT
--           array-of-structs. See caveat 1 below -- same risk class as
--           sql/07_eurostat.sql, likely to need a fundamentally different
--           approach or to be dropped.
-- Docs:     https://www.abs.gov.au/statistics/application-programming-interfaces-apis/data-api-user-guide/using-api
--           https://data.api.abs.gov.au/rest/ (base API root)
-- Rate limit: no API key required.
-- Before running: sanity-check the endpoint returns something sane --
--   curl -s "https://data.api.abs.gov.au/rest/data/ABS,CPI/all?startPeriod=2025-Q1&detail=dataonly" \
--     -H "Accept: application/vnd.sdmx.data+json" | python3 -m json.tool | head -40
-- WARNING: the query above returns ~2.4 MB of JSON (every CPI series) --
-- narrow to a specific dimension combination (see caveat 2) before
-- registering it as a Zetaris table, not the "all" query used for
-- investigation below.
-- =============================================================================
--
-- Investigated (not yet live-tested against Zetaris) 2026-09-19, confirmed
-- via a real (not guessed) query -- earlier attempts at guessing a specific
-- dimension key (e.g. "M1.AUS.10001.Q") 404'd with "Could not find Dataflow
-- and/or DSD related with this data request"; the dataflow ID itself is
-- valid ("CPI"), the key SYNTAX guessed initially was wrong:
--   1. ⚠️ FUNDAMENTALLY DIFFERENT SHAPE, in the same risk class as Eurostat
--      (sql/07) -- ABS returns SDMX-JSON 2.0.0's "data-message" format,
--      structurally similar to but not identical to Eurostat's JSON-stat:
--        - `data.structures[0].dimensions.series`: the dimensions that
--          identify a SERIES (e.g. MEASURE, INDEX, TSEST, REGION, FREQ).
--        - `data.structures[0].dimensions.observation`: the dimension
--          identifying each POINT within a series (here, just TIME_PERIOD).
--        - `data.dataSets[0].series`: an object keyed by a
--          COLON-SEPARATED DIMENSION-INDEX TUPLE (e.g. "0:0:0:0:0",
--          "0:1:0:1:0") -- each value has its OWN nested `observations`
--          object, itself keyed by a TIME-INDEX STRING (e.g. "0", "1",
--          "2"), each pointing to a one-element array `[value]`.
--      This is a doubly-nested dynamic-key structure -- not one level of
--      sparse indexing like Eurostat, but two (series key, then
--      observation key within that series). There is no array-of-structs
--      anywhere in this response to LATERAL VIEW explode() against.
--      Reconstructing a proper (dimension-labels, time, value) table needs
--      decoding two levels of compound-key indices against the
--      `structures[0].dimensions` metadata -- a client-side transform, not
--      a plain SQL flattening operation. Same conclusion as Eurostat:
--      UNKNOWN whether Zetaris has any SDMX-JSON-aware ingestion built in.
--   2. The "all" query used for investigation returns ~2.4 MB (every
--      MEASURE/INDEX/TSEST/REGION/FREQ combination for the whole CPI
--      dataflow) -- far too broad for a real table. A usable query needs a
--      properly-formed dimension key in the URL path (dataflow-specific
--      dimension ORDER and valid codes -- not guessable without checking
--      the dataflow's own data structure definition first, e.g. via
--      `https://data.api.abs.gov.au/rest/datastructure/ABS/CPI`). NOT YET
--      DONE in this investigation pass -- this script's endpoint below
--      still uses the broad "all" query as a placeholder; narrow it before
--      actually registering this as a Zetaris table.
--   3. Given caveats 1 and 2, treat this as the SECOND highest-risk source
--      in this package after Eurostat -- worth trying the same
--      metadata-only approach (expose `structures[0].dimensions` as a
--      view, don't attempt to decode `dataSets[0].series` into rows) if
--      it's tried at all, and a real DROP candidate if that doesn't prove
--      useful.
--
-- ---------------------------------------------------------------------------
-- STEP 0: Lightning database for this source.
-- ---------------------------------------------------------------------------
CREATE LIGHTNING DATABASE ABS_REST DESCRIBE BY "Australian Bureau of Statistics Data API SDMX-JSON source";

-- ---------------------------------------------------------------------------
-- STEP 1: SCHEMASTORE container. RUN ONCE -- see open_data/rest_apis/HOWTO.md
-- sec 2 (no IF NOT EXISTS support). Comment out on a re-run if it already
-- exists in your environment.
-- ---------------------------------------------------------------------------
CREATE SCHEMASTORE CONTAINER abs_data;

-- =============================================================================
-- CPI -- PLACEHOLDER query (see caveat 2 -- this is the broad "all" query
-- used for investigation, NOT a properly scoped one; narrow the endpoint
-- below using a real dimension key from the dataflow's data structure
-- definition before actually running this).
-- =============================================================================
CREATE LIGHTNING REST TABLE cpi_raw FROM ABS_REST REQUEST(
    endpoint "https://data.api.abs.gov.au/rest/data/ABS,CPI/all?startPeriod=2025-Q1&detail=dataonly",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    accept "application/vnd.sdmx.data+json"
) BODY ();

-- Minimal view -- just the dataflow's own dimension metadata (a normal
-- nested-struct shape), NOT the actual observation values (see caveat 1 --
-- decoding the double-compound-key series/observations structure into
-- rows is unsolved):
CREATE SCHEMASTORE VIEW cpi_dimensions_table WITH CONTAINER abs_data AS
SELECT
    dim.id    AS dimension_id,
    dim.name  AS dimension_name
FROM abs_rest.cpi_raw
LATERAL VIEW explode(data.structures[0].dimensions.series) AS dim;

-- Verify (this only confirms the dimension-metadata view works -- it does
-- NOT confirm the actual CPI values are queryable):
SELECT * FROM abs_data.cpi_dimensions_table;

-- ---------------------------------------------------------------------------
-- Diagnostic (run regardless of whether the view above works, to see the
-- raw dataSets[0].series shape and judge whether decoding it is worth
-- attempting):
--   SELECT * FROM abs_rest.cpi_raw;
--   DESCRIBE abs_rest.cpi_raw;
-- If the compound-key `series` object comes back as an opaque map Zetaris
-- can't meaningfully query, treat ABS as a DROP candidate for this
-- package, same conclusion as Eurostat (sql/07) -- both are SDMX-family
-- formats fundamentally mismatched with the array-of-structs pattern this
-- package otherwise relies on.
-- ---------------------------------------------------------------------------
