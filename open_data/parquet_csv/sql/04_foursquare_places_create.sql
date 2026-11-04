-- =============================================================================
-- Source:   Foursquare Open Source Places (hosted on Source Cooperative)
-- License:  Apache License 2.0 (verified)
--           https://docs.foursquare.com/data-products/docs/fsq-places-open-source
-- Format:   Parquet (native)
-- Docs:     https://docs.foursquare.com/data-products/docs/access-fsq-os-places
--           https://source.coop/fused/fsq-os-places
-- Before running: list what's actually in the current release folder --
--   aws s3 ls --endpoint-url https://data.source.coop --no-sign-request s3://fused/fsq-os-places/
--   or, without the AWS CLI:
--   curl -s "https://data.source.coop/fused?list-type=2&prefix=fsq-os-places/&delimiter=/"
--
-- Confirmed live 2026-10-31. The bucket listing that day had release
-- folders 2024-11-19, 2024-12-03, 2025-01-10, and 2025-02-06. This script
-- pins 2024-11-19, which is still present: 81 Parquet files, 11159985690
-- bytes (10.394 GiB). Source Cooperative's README describes the dataset as
-- more than 100 million places, so sql/04_foursquare_places_select.sql
-- bounds every aggregation to a Manhattan lat/lon window. The files are
-- not split by city; a predicate still reads the prefix (about 63-75
-- seconds on 2026-10-31). An earlier query-time HTTP 500 is recorded in
-- sql/known_to_fail/ISSUE-04-foursquare.md and did not reproduce.
-- =============================================================================
--
-- CAVEAT 1: this dataset is NOT on AWS's own S3 endpoint -- Source Cooperative
-- runs its own S3-*compatible* endpoint (https://data.source.coop). Per the
-- Zetaris kbase's MinIO how-to (the closest documented analog to a non-AWS
-- S3-compatible endpoint), that means adding s3Endpoint and
-- useS3PathStyleAccess "true" to OPTIONS, same pattern as below.
--
-- CAVEAT 2: Source Cooperative access is public and no AWS credential values
-- are needed here. The table below sets isS3BucketPublic "true" and uses the
-- S3-compatible endpoint with path-style access.
--
-- CAVEAT 3: the release date in the path (2024-11-19 below) is the release
-- folder name, not a wildcard -- confirm the current one with the listing
-- command above, since Foursquare ships new releases periodically.
--
-- PREREQUISITE: FSQ_SOURCE_COOP must be registered as a logical database
-- before the table below can reference it in FROM -- see HOWTO.md sec 1.
CREATE LIGHTNING DATABASE FSQ_SOURCE_COOP DESCRIBE BY "Foursquare Open Source Places, via Source Cooperative";

CREATE LIGHTNING FILESTORE TABLE foursquare_places FROM FSQ_SOURCE_COOP FORMAT PARQUET OPTIONS (
  PATH "s3a://fused/fsq-os-places/2024-11-19/places/",
  inferSchema "true",
  isS3BucketPublic "true",
  useS3PathStyleAccess "true",
  s3Endpoint "https://data.source.coop"
);

-- Note: the places/ prefix above is sharded into many Parquet files
-- (e.g. .../places/79.parquet, .../places/80.parquet, ...) -- pointing PATH
-- at the directory (as above) rather than a single shard lets Zetaris pick
-- up the whole release. A directory PATH queried successfully on
-- 2026-10-31 (DESCRIBE, SELECT * LIMIT 10, and the bounded analytical
-- queries).

-- Next: verify with sql/04_foursquare_places_select.sql
