-- =============================================================================
-- Source:   Foursquare Open Source Places (hosted on Source Cooperative)
-- License:  Apache License 2.0 (verified)
--           https://docs.foursquare.com/data-products/docs/fsq-places-open-source
-- Format:   Parquet (native)
-- Docs:     https://docs.foursquare.com/data-products/docs/access-fsq-os-places
--           https://source.coop/fused/fsq-os-places
-- Before running: list what's actually in the current release folder --
--   aws s3 ls --endpoint-url https://data.source.coop --no-sign-request s3://fused/fsq-os-places/
--
-- KNOWN TO FAIL -- kept here as-is, not in the main sql/ sequence. The
-- CREATE LIGHTNING FILESTORE TABLE statement below succeeds, but CACHE
-- TABLE and every SELECT against the resulting table fail with a 500
-- error. See sql/known_to_fail/ISSUE.md for the full writeup.
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
  useS3PathStyleAccess "true",
  inferSchema "true",
  isS3BucketPublic "true",
  useS3PathStyleAccess "true",
  s3Endpoint "https://data.source.coop"
);

-- Note: the places/ prefix above is sharded into many Parquet files
-- (e.g. .../places/79.parquet, .../places/80.parquet, ...) -- pointing PATH
-- at the directory (as above) rather than a single shard lets Zetaris pick
-- up the whole dataset. If your Zetaris version requires a single-file PATH
-- instead of a directory prefix, use one shard directly, e.g.:
--   PATH "s3a://fused/fsq-os-places/2024-11-19/places/79.parquet"

-- Next: verify with sql/04_foursquare_places_select.sql
