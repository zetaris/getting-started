-- =============================================================================
-- Source:   Overture Maps Foundation -- Places theme
-- License:  CDLA-Permissive-2.0 for the Places theme specifically (verified)
--           https://docs.overturemaps.org/attribution/
--           NOTE: other Overture themes (Base/Buildings/Divisions/Transportation)
--           are ODbL, and Addresses varies by country -- this script sticks to
--           Places for the cleanest license story. See
--           parquet-csv-data-sources.md #5 if you want a different theme.
-- Format:   GeoParquet (native)
-- Docs:     https://docs.overturemaps.org/getting-data/
--           https://docs.overturemaps.org/getting-data/duckdb/
--           https://docs.overturemaps.org/schema/reference/places/place/
-- Before running: confirm the current release folder name (changes monthly) --
--   aws s3 ls --no-sign-request s3://overturemaps-us-west-2/release/
--   or, without the AWS CLI:
--   curl -s "https://overturemaps-us-west-2.s3.us-west-2.amazonaws.com/?list-type=2&prefix=release/&delimiter=/"
--
-- Confirmed live 2026-10-31 against release 2026-10-21.0. The previous
-- script pinned release/2026-08-19.0, which is no longer listed in the
-- bucket, and its example queries still referenced categories.primary.
-- Current Places GeoParquet has no categories column: category is
-- basic_category (string) plus taxonomy (struct of primary, hierarchy,
-- alternates). See sql/05_overture_maps_select.sql.
-- =============================================================================
--
-- CAVEAT: this bucket is public/anonymous. The table options below use
-- Zetaris's public-bucket configuration and the us-west-2 S3 endpoint, so
-- this script does not need AWS credential values.
-- The release folder (2026-10-21.0 below) is a MOVING TARGET -- Overture
-- ships a new one roughly monthly. Confirm the current one with the listing
-- command above before an event.
--
-- PREREQUISITE: OVERTURE_S3 must be registered as a logical database before
-- the table below can reference it in FROM -- see HOWTO.md sec 1.
CREATE LIGHTNING DATABASE OVERTURE_S3 DESCRIBE BY "Overture Maps Places theme S3 filestore source";

CREATE LIGHTNING FILESTORE TABLE overture_places FROM OVERTURE_S3 FORMAT PARQUET OPTIONS (
  PATH "s3a://overturemaps-us-west-2/release/2026-10-21.0/theme=places/type=place/",
  inferSchema "true",
  isS3BucketPublic "true",
  useS3PathStyleAccess "true",
  s3Endpoint "s3.us-west-2.amazonaws.com"
);

-- Note: geometry is GeoParquet WKB. Names, taxonomy, brand, and addresses
-- are nested. Dot-access works (names.primary, taxonomy.primary,
-- brand.names.primary, bbox.xmin). The place files are not split by
-- geography, so a predicate on bbox still reads the release; it only
-- limits which rows the aggregation keeps. sql/05_overture_maps_select.sql
-- bounds every aggregation to a Manhattan bbox for that reason. Those
-- bounded scans still read the prefix and took about 84-95 seconds on
-- 2026-10-31.

-- Next: verify with sql/05_overture_maps_select.sql
