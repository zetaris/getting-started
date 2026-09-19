-- =============================================================================
-- Source:   Singapore data.gov.sg -- PM2.5 (air quality) real-time API
-- License:  Singapore Open Data Licence (SODL) v1.0 --
--           https://data.gov.sg/open-data-licence -- worldwide, perpetual,
--           royalty-free, CC-BY-equivalent. Attribution required, e.g.:
--           "Contains information from data.gov.sg accessed on {date} which
--           is made available under the terms of the Singapore Open Data
--           Licence version 1.0."
-- Format:   REST/JSON, top-level object, array-of-structs with a FIXED
--           (non-array) nested struct per item -- the simplest shape in
--           this package so far.
-- Docs:     https://guide.data.gov.sg/developer-guide/real-time-apis
-- Rate limit: no key needed for testing; unauthenticated calls capped at
--           5 requests/minute (same limit documented for the initiate/
--           poll-download API used in ../../parquet_csv/scripts/fetch_datagovsg.py
--           -- same underlying platform).
-- Before running: sanity-check the endpoint returns something sane --
--   curl -s "https://api-open.data.gov.sg/v2/real-time/api/pm25" | python3 -m json.tool | head -30
-- =============================================================================
--
-- Investigated (not yet live-tested against Zetaris) 2026-09-19, confirmed
-- working with no API key at all:
--   1. Response is a top-level object: {code, data: {regionMetadata,
--      items}, paginationToken}. Both `regionMetadata` and `items` are
--      arrays -- `regionMetadata` is array<struct<name,
--      labelLocation:struct<latitude,longitude>>> (one row per Singapore
--      region: north/south/east/west/central); `items` is
--      array<struct<date,updatedTimestamp,timestamp,
--      readings:struct<pm25_one_hourly:struct<national,east,west,north,
--      south,central>>>> -- one row per reading TIMESTAMP, with a FIXED
--      struct of per-region values (not an array) -- unlike every other
--      source in this package so far, there's no inner explode() needed
--      for the per-region breakdown, just dot-access into the fixed
--      pm25_one_hourly struct.
--   2. Both arrays live under `data`, not at the top level -- dot-access
--      through `data.items`/`data.regionMetadata` is needed in the FROM/
--      LATERAL VIEW clause, one level deeper than EDGAR's top-level
--      `units.USD`.
--   3. This endpoint is real-time -- the exact PM2.5 values will differ
--      every time you run this, by design. That's expected, not a bug;
--      don't expect the verification row count to match a fixed number,
--      just confirm rows come back at all with sane-looking values
--      (typically low double digits under normal air quality).
--
-- ---------------------------------------------------------------------------
-- STEP 0: Lightning database for this source.
-- ---------------------------------------------------------------------------
CREATE LIGHTNING DATABASE SG_DATAGOVSG_REST DESCRIBE BY "Singapore data.gov.sg real-time API REST source";

-- ---------------------------------------------------------------------------
-- STEP 1: SCHEMASTORE container. RUN ONCE -- see open_data/rest_apis/HOWTO.md
-- sec 2 (no IF NOT EXISTS support). Shared with any future data.gov.sg
-- real-time sources (weather forecast, rainfall, etc.) added to this
-- package later. Comment out on a re-run if it already exists.
-- ---------------------------------------------------------------------------
CREATE SCHEMASTORE CONTAINER singapore;

-- =============================================================================
-- PM2.5 -- national air-quality readings, latest available
-- =============================================================================
CREATE LIGHTNING REST TABLE pm25_readings FROM SG_DATAGOVSG_REST REQUEST(
    endpoint "https://api-open.data.gov.sg/v2/real-time/api/pm25",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
) BODY ();

-- Flattened view -- data.items is the array-of-structs field, each item's
-- readings.pm25_one_hourly is a FIXED struct, not an array (see caveat 1):
CREATE SCHEMASTORE VIEW pm25_readings_table WITH CONTAINER singapore AS
SELECT
    item.date              AS reading_date,
    item.timestamp         AS reading_timestamp,
    item.updatedTimestamp  AS updated_timestamp,
    item.readings.pm25_one_hourly.national AS pm25_national,
    item.readings.pm25_one_hourly.north    AS pm25_north,
    item.readings.pm25_one_hourly.south    AS pm25_south,
    item.readings.pm25_one_hourly.east     AS pm25_east,
    item.readings.pm25_one_hourly.west     AS pm25_west,
    item.readings.pm25_one_hourly.central  AS pm25_central
FROM sg_datagovsg_rest.pm25_readings
LATERAL VIEW explode(data.items) AS item;

-- Verify:
SELECT * FROM singapore.pm25_readings_table;

-- ---------------------------------------------------------------------------
-- Diagnostic (run if the view above fails or comes back empty):
--   SELECT * FROM sg_datagovsg_rest.pm25_readings;
--   DESCRIBE sg_datagovsg_rest.pm25_readings;
-- If dot-access through data.items (nested under a non-array `data`
-- struct) fails, that's a different failure mode from every other script
-- in this package -- worth isolating from the "array at the top level"
-- sources (EDGAR, PokéAPI) when reporting back.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Attribution reminder (SODL v1.0, per the license note above):
--   "Contains information from data.gov.sg accessed on {date} which is
--   made available under the terms of the Singapore Open Data Licence
--   version 1.0."
-- ---------------------------------------------------------------------------
