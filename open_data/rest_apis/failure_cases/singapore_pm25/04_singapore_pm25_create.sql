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
-- Rate limit: no key needed for testing; documented as 5 requests/minute
--           (same limit documented for the initiate/poll-download API
--           used in ../../parquet_csv/scripts/fetch_datagovsg.py -- same
--           underlying platform), but the ACTUAL burst limit observed is
--           much tighter -- see caveat 6 below.
-- Before running: sanity-check the endpoint returns something sane --
--   curl -s "https://api-open.data.gov.sg/v2/real-time/api/pm25?date=2026-09-18" | python3 -m json.tool | head -30
-- =============================================================================
--
-- Investigated 2026-09-19, extended 2026-09-19 to pull a full day of
-- hourly readings instead of just the single latest one:
--   1. Response is a top-level object: {code, data: {regionMetadata,
--      items}, errorMsg}. Both `regionMetadata` and `items` are arrays --
--      `regionMetadata` is array<struct<name,
--      labelLocation:struct<latitude,longitude>>> (one row per Singapore
--      region: north/south/east/west/central); `items` is
--      array<struct<date,updatedTimestamp,timestamp,
--      readings:struct<pm25_one_hourly:struct<east,west,north,south,
--      central>>>> -- one row per reading TIMESTAMP, with a FIXED struct
--      of per-region values (not an array) -- unlike every other source
--      in this package so far, there's no inner explode() needed for the
--      per-region breakdown, just dot-access into the fixed
--      pm25_one_hourly struct.
--   2. Both arrays live under `data`, not at the top level -- dot-access
--      through `data.items`/`data.regionMetadata` is needed in the FROM/
--      LATERAL VIEW clause, one level deeper than EDGAR's top-level
--      `units.USD`.
--   3. CORRECTION: the original version of this script selected a
--      `pm25_one_hourly.national` field that does NOT exist in the real
--      response -- `pm25_one_hourly` only ever has the 5 region keys
--      (east, west, north, south, central), confirmed by inspecting every
--      key across a full day of readings. There is no single
--      "national" figure provided by this endpoint at all; a
--      national-level number has to be computed (e.g. an average across
--      the 5 regions), not read off a field that isn't there. Fixed
--      below -- see 04_singapore_pm25_select.sql query 5 for the computed
--      replacement.
--   4. Without a `date` parameter, this endpoint returns only the single
--      LATEST reading (one item) -- fine for a smoke test, but not enough
--      data for the kind of trend/comparison queries this script now
--      builds. Adding `?date=YYYY-MM-DD` returns every hourly reading
--      published for that calendar day (24 items for a complete past
--      day, confirmed via `curl`). This script uses a FIXED past date
--      (2026-09-18) rather than "today" so the example is reproducible --
--      swap to any complete past date via the Before-running curl check
--      above. Using "today" would return a partial day (fewer than 24
--      items) until the day finishes, which is fine to try but won't
--      match the row counts described in the comments below.
--   5. `updatedTimestamp` and `labelLocation` are mixed-case -- per the
--      confirmed EDGAR/PokéAPI rule (HOWTO.md, "Troubleshooting / FAQ"),
--      both need backtick-quoting.
--   6. CONFIRMED (2026-09-19, via repeated `curl` testing): no special
--      `User-Agent`, `Accept` header, or authentication is required at
--      all -- a plain GET returns 200 with any User-Agent, including
--      none. OBSERVED (2026-09-19): a single `CREATE LIGHTNING REST
--      TABLE` run against this endpoint returned an HTTP 502 in the
--      Zetaris SQL Workspace, with no other query run beforehand. This
--      is NOT a missing-header problem (see above). The likely
--      explanation: this endpoint's real rate limit is much tighter than
--      documented -- testing found it trips a 429 after roughly 5-6
--      requests within 5-8 seconds (the documented limit is "5
--      requests/minute"), recovering to 200 again after about 30
--      seconds. A single visible statement in the SQL Workspace does not
--      necessarily mean a single HTTP request was made against the
--      endpoint -- schema introspection when the table is created and a
--      separate background preview fetch by the Data Explorer panel are
--      both plausible sources of extra calls for one statement, though
--      this has not been confirmed by inspecting Zetaris's own request
--      logs. FIX: if this happens, wait about 30 seconds and re-run the
--      statement rather than retrying immediately or adding headers;
--      avoid also `curl`-testing this specific endpoint around the same
--      time, since that draws from the same tight limit.
--
-- ---------------------------------------------------------------------------
-- STEP 0: Lightning database for this source.
-- ---------------------------------------------------------------------------
CREATE LIGHTNING DATABASE SG_DATAGOVSG_REST DESCRIBE BY "Singapore data.gov.sg real-time API REST source";

-- ---------------------------------------------------------------------------
-- STEP 1: SCHEMASTORE container. RUN ONCE -- see open_data/rest_apis/HOWTO.md,
-- "Known limitations" (no IF NOT EXISTS support). Shared with any future
-- data.gov.sg real-time sources (weather forecast, rainfall, etc.) added
-- to this package later. Comment out on a re-run if it already exists.
-- ---------------------------------------------------------------------------
CREATE SCHEMASTORE CONTAINER singapore;

-- =============================================================================
-- PM2.5 -- a full day of hourly readings, 2026-09-18 (24 hours, 5 regions)
-- =============================================================================
CREATE LIGHTNING REST TABLE pm25_readings_20260918 FROM SG_DATAGOVSG_REST REQUEST(
    endpoint "https://api-open.data.gov.sg/v2/real-time/api/pm25?date=2026-09-18",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
) BODY ();

-- Wide-format view -- one row per hourly reading, one column per region.
-- data.items is the array-of-structs field, each item's
-- readings.pm25_one_hourly is a FIXED struct, not an array (see caveat 1):
CREATE SCHEMASTORE VIEW pm25_readings_table WITH CONTAINER singapore AS
SELECT
    item.date                              AS reading_date,
    item.timestamp                         AS reading_timestamp,
    item.`updatedTimestamp`                AS updated_timestamp,
    item.readings.pm25_one_hourly.north    AS pm25_north,
    item.readings.pm25_one_hourly.south    AS pm25_south,
    item.readings.pm25_one_hourly.east     AS pm25_east,
    item.readings.pm25_one_hourly.west     AS pm25_west,
    item.readings.pm25_one_hourly.central  AS pm25_central
FROM sg_datagovsg_rest.pm25_readings_20260918
LATERAL VIEW explode(data.items) AS item;

-- Region reference view -- name + coordinates, a static lookup table that
-- pairs naturally with the readings above (see
-- 04_singapore_pm25_select.sql query 8):
CREATE SCHEMASTORE VIEW pm25_regions_table WITH CONTAINER singapore AS
SELECT
    region.name                          AS region_name,
    region.`labelLocation`.latitude      AS latitude,
    region.`labelLocation`.longitude     AS longitude
FROM sg_datagovsg_rest.pm25_readings_20260918
LATERAL VIEW explode(data.regionMetadata) AS region;

-- =============================================================================
-- LONG-FORMAT CROSS-REGION VIEW -- same UNION ALL pattern as EDGAR's
-- optional all_companies_revenue_table (sql/01), PokéAPI's all_pokemon_*
-- views (sql/02), and Open Food Facts' all_products_* views (sql/03): one
-- row per (timestamp, region) pair instead of one column per region,
-- which makes GROUP BY region, ORDER BY value, and per-hour ranking
-- queries much more natural than pivoting on 5 separate columns every
-- time.
-- =============================================================================
CREATE SCHEMASTORE VIEW pm25_readings_long_table WITH CONTAINER singapore AS
SELECT reading_timestamp, 'north'   AS region, pm25_north   AS pm25 FROM singapore.pm25_readings_table
UNION ALL
SELECT reading_timestamp, 'south'   AS region, pm25_south   AS pm25 FROM singapore.pm25_readings_table
UNION ALL
SELECT reading_timestamp, 'east'    AS region, pm25_east    AS pm25 FROM singapore.pm25_readings_table
UNION ALL
SELECT reading_timestamp, 'west'    AS region, pm25_west    AS pm25 FROM singapore.pm25_readings_table
UNION ALL
SELECT reading_timestamp, 'central' AS region, pm25_central AS pm25 FROM singapore.pm25_readings_table;

-- =============================================================================
-- TEARDOWN -- removes the flattened views this script created. Commented
-- out by default so a re-run of the file above doesn't accidentally wipe
-- a live environment; uncomment and run standalone when you want to tear
-- these views down.
--
-- DROP VIEW is the only teardown statement confirmed to work reliably in
-- this package. There is no SQL statement confirmed to remove the raw
-- REST table or the SG_DATAGOVSG_REST Lightning database registration
-- itself -- see HOWTO.md, "Removing a source" and "Troubleshooting /
-- FAQ", for the full explanation. To remove the REST table and the
-- SG_DATAGOVSG_REST registration, use the Zetaris Data Explorer: locate
-- the entry under "File Source & API" and remove it from there.
-- (Note this database may be shared with other future data.gov.sg
-- sources -- see STEP 1 comment above.)
-- =============================================================================

-- DROP VIEW singapore.pm25_readings_long_table;
-- DROP VIEW singapore.pm25_regions_table;
-- DROP VIEW singapore.pm25_readings_table;

-- To remove the SG_DATAGOVSG_REST REST table and Lightning database
-- registration, use the Zetaris Data Explorer's "File Source & API"
-- panel (see HOWTO.md, "Removing a source").

-- Next: verify with 04_singapore_pm25_select.sql
