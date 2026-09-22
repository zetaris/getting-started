-- =============================================================================
-- Source:   Catalyst Cooperative PUDL (Public Utility Data Liberation Project)
-- License:  CC-BY-4.0 (verified) -- https://registry.opendata.aws/catalyst-cooperative-pudl/
-- Format:   Parquet (also ships as SQLite from the same build -- see note below)
-- Docs:     https://docs.catalyst.coop/pudl/en/stable/data_access.html
--           https://docs.catalyst.coop/pudl/en/stable/data_dictionaries/pudl_db.html
-- Before running: list the current stable version and its tables --
--   aws s3 ls --no-sign-request s3://pudl.catalyst.coop/
--   aws s3 ls --no-sign-request s3://pudl.catalyst.coop/vYYYY.MM.PATCH/
-- =============================================================================
--
-- CAVEAT: this bucket is public/anonymous. The table options below use
-- Zetaris's public-bucket configuration and a regional S3 endpoint, so this
-- script does not need AWS credential values.
-- CONFIRMED live (2026-09): the bucket responds fine to both anonymous and
-- real signed requests). The version originally pinned here (v2024.11.0)
-- still exists but is ~2 years stale. The script now uses the `stable`
-- rolling alias, which resolves to the current release (v2026.9.0 as of this
-- check) and has both files used below. Re-run the listing command above
-- before an event if you want to pin an exact version instead of tracking
-- `stable`.
--
-- PREREQUISITE: PUDL_S3 must be registered as a logical database before the
-- table below can reference it in FROM -- see HOWTO.md sec 1.
CREATE LIGHTNING DATABASE PUDL_S3 DESCRIBE BY "Catalyst Cooperative PUDL S3 filestore source";

CREATE LIGHTNING FILESTORE TABLE pudl_eia_energy_sources FROM PUDL_S3 FORMAT PARQUET OPTIONS (
  PATH "s3a://pudl.catalyst.coop/stable/core_eia__codes_energy_sources.parquet",
  inferSchema "true",
  isS3BucketPublic "true",
  useS3PathStyleAccess "true",
  s3Endpoint "s3.us-west-2.amazonaws.com"
);

-- Verify:
SELECT * FROM PUDL_S3.pudl_eia_energy_sources LIMIT 10;

-- A second, larger table for a richer demo -- yearly generator-level output:
CREATE LIGHTNING FILESTORE TABLE pudl_eia_yearly_generators FROM PUDL_S3 FORMAT PARQUET OPTIONS (
  PATH "s3a://pudl.catalyst.coop/stable/out_eia__yearly_generators.parquet",
  inferSchema "true",
  isS3BucketPublic "true",
  useS3PathStyleAccess "true",
  s3Endpoint "s3.us-west-2.amazonaws.com"
);

SELECT * FROM PUDL_S3.pudl_eia_yearly_generators LIMIT 10;

-- Note: PUDL also publishes the identical data as a single SQLite file per
-- release (e.g. s3://pudl.catalyst.coop/stable/pudl.sqlite.zip) -- worth
-- knowing if you also want a §5-style "SQL RDBMS" demo sourced from the same
-- dataset as this Parquet one, for a "same data, two engines" story.
