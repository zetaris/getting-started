-- =============================================================================
-- Source: Singapore data.gov.sg -- PM2.5 (air quality) real-time API.
-- Blocked: see ../ISSUE.md for the full investigation. This script and
-- its selects still document the working query pattern for reference,
-- but the first CREATE LIGHTNING REST TABLE statement returned an HTTP
-- 502 in testing (see caveat 4) and this source was set aside rather
-- than pursued further.
--
-- License: Singapore Open Data Licence (SODL) v1.0 --
-- https://data.gov.sg/open-data-licence -- worldwide, perpetual,
-- royalty-free, CC-BY-equivalent. Attribution required, e.g.:
-- "Contains information from data.gov.sg accessed on {date} which is
-- made available under the terms of the Singapore Open Data Licence
-- version 1.0."
--
-- Format: REST/JSON, top-level object, array-of-structs with a fixed
-- (non-array) nested struct per item -- see the SQL companion guide
-- for the general shape taxonomy.
--
-- Docs: https://guide.data.gov.sg/developer-guide/real-time-apis
--
-- Rate limit: no key needed for testing; documented as 5
-- requests/minute, though the actual burst limit observed is much
-- tighter -- see caveat 4.
--
-- Before running: sanity-check the endpoint returns something sane:
--   curl -s "https://api-open.data.gov.sg/v2/real-time/api/pm25?date=2026-09-18" | python3 -m json.tool | head -30
-- =============================================================================
--
-- Caveats:
--   1. The response is a top-level object: {code, data: {regionMetadata,
--      items}, errorMsg}. Both `regionMetadata` and `items` are arrays,
--      one level under `data` rather than at the top level. `items` is
--      one row per reading timestamp, with a fixed struct of per-region
--      values (not an array) -- unlike an array-of-structs, there's no
--      inner explode() needed for the per-region breakdown, just
--      dot-access into the fixed pm25_one_hourly struct.
--   2. An earlier version of this script selected a
--      `pm25_one_hourly.national` field that does not exist in the real
--      response -- `pm25_one_hourly` only ever has the 5 region keys
--      (east, west, north, south, central), confirmed by inspecting
--      every key across a full day of readings. There is no single
--      national figure provided by this endpoint; it has to be
--      computed (e.g. an average across the 5 regions), not read off a
--      field that isn't there. See the select script for the computed
--      replacement.
--   3. Without a `date` parameter, this endpoint returns only the
--      single latest reading. Adding `?date=YYYY-MM-DD` returns every
--      hourly reading published for that calendar day (24 items for a
--      complete past day, confirmed via curl). This script uses a
--      fixed past date (2026-09-18) so the example is reproducible.
--   4. A plain GET needs no special header or authentication at all --
--      confirmed via repeated curl testing. A single
--      CREATE LIGHTNING REST TABLE run against this endpoint still
--      returned an HTTP 502 in the Zetaris SQL Workspace, with no other
--      query run beforehand. Likely explanation: this endpoint's real
--      rate limit is much tighter than documented -- testing found it
--      trips a 429 after roughly 5-6 requests within 5-8 seconds,
--      recovering after about 30 seconds -- and a single visible
--      statement in the SQL Workspace does not necessarily mean a
--      single HTTP request reached the endpoint. See the SQL companion
--      guide for the general causes of an HTTP 502 on this kind of
--      statement.
-- =============================================================================

-- Step 0: Lightning database for this source.
CREATE LIGHTNING DATABASE SG_DATAGOVSG_REST DESCRIBE BY "Singapore data.gov.sg real-time API REST source";

-- Step 1: schemastore container. Run once -- comment out on a re-run
-- if it already exists in your environment.
CREATE SCHEMASTORE CONTAINER singapore;

-- PM2.5 -- a full day of hourly readings, 2026-09-18 (24 hours, 5 regions)
CREATE LIGHTNING REST TABLE pm25_readings_20260918 FROM SG_DATAGOVSG_REST REQUEST(
    endpoint "https://api-open.data.gov.sg/v2/real-time/api/pm25?date=2026-09-18",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
) BODY ();

-- Wide-format view -- one row per hourly reading, one column per region.
CREATE SCHEMASTORE VIEW pm25_readings_table WITH CONTAINER singapore AS
SELECT
    item.date AS reading_date,
    item.timestamp AS reading_timestamp,
    item.`updatedTimestamp` AS updated_timestamp,
    item.readings.pm25_one_hourly.north AS pm25_north,
    item.readings.pm25_one_hourly.south AS pm25_south,
    item.readings.pm25_one_hourly.east AS pm25_east,
    item.readings.pm25_one_hourly.west AS pm25_west,
    item.readings.pm25_one_hourly.central AS pm25_central
FROM sg_datagovsg_rest.pm25_readings_20260918
LATERAL VIEW explode(data.items) AS item;

-- Region reference view -- name and coordinates, a static lookup table
-- that pairs naturally with the readings above.
CREATE SCHEMASTORE VIEW pm25_regions_table WITH CONTAINER singapore AS
SELECT
    region.name AS region_name,
    region.`labelLocation`.latitude AS latitude,
    region.`labelLocation`.longitude AS longitude
FROM sg_datagovsg_rest.pm25_readings_20260918
LATERAL VIEW explode(data.regionMetadata) AS region;

-- Long-format cross-region view -- one row per (timestamp, region) pair
-- instead of one column per region, which makes GROUP BY region,
-- ORDER BY value, and per-hour ranking queries more natural than
-- pivoting on 5 separate columns every time.
CREATE SCHEMASTORE VIEW pm25_readings_long_table WITH CONTAINER singapore AS
SELECT reading_timestamp, 'north' AS region, pm25_north AS pm25 FROM singapore.pm25_readings_table
UNION ALL
SELECT reading_timestamp, 'south' AS region, pm25_south AS pm25 FROM singapore.pm25_readings_table
UNION ALL
SELECT reading_timestamp, 'east' AS region, pm25_east AS pm25 FROM singapore.pm25_readings_table
UNION ALL
SELECT reading_timestamp, 'west' AS region, pm25_west AS pm25 FROM singapore.pm25_readings_table
UNION ALL
SELECT reading_timestamp, 'central' AS region, pm25_central AS pm25 FROM singapore.pm25_readings_table;

-- =============================================================================
-- Teardown -- removes the flattened views this script created.
-- Commented out by default. See the SQL companion guide for why
-- DROP VIEW is the only reliable teardown statement, and how to remove
-- the underlying REST table and database registration (Zetaris Data
-- Explorer -- no SQL path exists). This database may be shared with
-- other data.gov.sg real-time sources if any are added later.
-- =============================================================================

-- DROP VIEW singapore.pm25_readings_long_table;
-- DROP VIEW singapore.pm25_regions_table;
-- DROP VIEW singapore.pm25_readings_table;
