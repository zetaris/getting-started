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
-- Before running: confirm the current release folder name (changes monthly) --
--   aws s3 ls --no-sign-request s3://overturemaps-us-west-2/release/
-- =============================================================================
--
-- CAVEAT: this bucket is public/anonymous, but Zetaris always signs S3
-- requests -- CONFIRMED (see HOWTO.md sec 2): a real AWS IAM key pair is
-- required below (a free-tier account with s3:GetObject/s3:ListBucket is
-- enough), even though the bucket itself doesn't require one.
-- The release folder (2026-08-19.0 below) is a MOVING TARGET -- Overture
-- ships a new one roughly monthly. Confirm the current one with the listing
-- command above before an event.
--
-- PREREQUISITE: OVERTURE_S3 must be registered as a logical database before
-- the table below can reference it in FROM -- see HOWTO.md sec 1.
CREATE LIGHTNING DATABASE OVERTURE_S3 DESCRIBE BY "Overture Maps Places theme S3 filestore source";

CREATE LIGHTNING FILESTORE TABLE overture_places FROM OVERTURE_S3 FORMAT PARQUET OPTIONS (
  PATH "s3a://overturemaps-us-west-2/release/2026-08-19.0/theme=places/type=place/",
  inferSchema "true",
  AWSACCESSKEYID "YOUR_AWS_ACCESS_KEY_ID",
  AWSSECRETACCESSKEY "YOUR_AWS_SECRET_ACCESS_KEY"
);

-- Verify:
SELECT * FROM overture_places LIMIT 10;

-- Note: this table includes a "geometry" column encoded per the GeoParquet
-- spec (WKB) and nested struct columns (names, categories, socials, bbox).
-- If your Zetaris version doesn't flatten nested/struct Parquet columns
-- automatically, plan on a follow-up view/CAST step to pull out the fields
-- you want to demo (e.g. names.primary, categories.primary) -- same
-- flattening story DuckDB's example query handles with dot-notation.
