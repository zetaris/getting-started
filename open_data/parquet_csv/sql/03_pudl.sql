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
-- CAVEAT: this bucket is public/anonymous, but Zetaris always signs S3
-- requests -- CONFIRMED (see HOWTO.md sec 2): a real AWS IAM key pair is
-- required below (a free-tier account with s3:GetObject/s3:ListBucket is
-- enough), even though the bucket itself doesn't require one.
-- CONFIRMED live (2026-09): the bucket responds fine to both anonymous and
-- real signed requests (unlike sql/01_nyc_tlc.sql's S3 mirror, which is
-- dead). The version originally pinned here (v2024.11.0) still exists but
-- is ~2 years stale -- switched to the `stable` rolling alias below, which
-- resolves to the current release (v2026.9.0 as of this check) and has
-- both files used below. Re-run the listing command above before an event
-- if you want to pin an exact version instead of tracking `stable`.
--
-- PREREQUISITE: PUDL_S3 must be registered as a logical database before the
-- table below can reference it in FROM -- see HOWTO.md sec 1.
CREATE LIGHTNING DATABASE PUDL_S3 DESCRIBE BY "Catalyst Cooperative PUDL S3 filestore source";

CREATE LIGHTNING FILESTORE TABLE pudl_eia_energy_sources FROM PUDL_S3 FORMAT PARQUET OPTIONS (
  PATH "s3a://pudl.catalyst.coop/stable/core_eia__codes_energy_sources.parquet",
  inferSchema "true",
  AWSACCESSKEYID "YOUR_AWS_ACCESS_KEY_ID",
  AWSSECRETACCESSKEY "YOUR_AWS_SECRET_ACCESS_KEY"
);

-- Verify:
SELECT * FROM pudl_eia_energy_sources LIMIT 10;

-- A second, larger table for a richer demo -- yearly generator-level output:
CREATE LIGHTNING FILESTORE TABLE pudl_eia_yearly_generators FROM PUDL_S3 FORMAT PARQUET OPTIONS (
  PATH "s3a://pudl.catalyst.coop/stable/out_eia__yearly_generators.parquet",
  inferSchema "true",
  AWSACCESSKEYID "YOUR_AWS_ACCESS_KEY_ID",
  AWSSECRETACCESSKEY "YOUR_AWS_SECRET_ACCESS_KEY"
);

SELECT * FROM pudl_eia_yearly_generators LIMIT 10;

-- Note: PUDL also publishes the identical data as a single SQLite file per
-- release (e.g. s3://pudl.catalyst.coop/stable/pudl.sqlite.zip) -- worth
-- knowing if you also want a §5-style "SQL RDBMS" demo sourced from the same
-- dataset as this Parquet one, for a "same data, two engines" story.
