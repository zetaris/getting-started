-- =============================================================================
-- Source:   Ookla Speedtest Global Fixed and Mobile Network Performance
-- License:  CC BY-NC-SA 4.0 -- NON-COMMERCIAL (verified)
--           https://creativecommons.org/licenses/by-nc-sa/4.0/
--           Fine for an internal demo/event or a tutorial repo. Do NOT anchor
--           anything resembling a commercial Zetaris feature or customer
--           deliverable on this source without a separate license
--           conversation with Ookla. Say this out loud in the demo.
-- Format:   Parquet (also ships as Shapefile -- same data, two formats)
-- Docs:     https://github.com/teamookla/ookla-open-data
--           https://github.com/teamookla/ookla-open-data/blob/master/README.md
-- Before running: confirm the current quarter is available --
--   aws s3 ls --no-sign-request s3://ookla-open-data/parquet/performance/type=fixed/
-- =============================================================================
--
-- CAVEAT: this bucket is public/anonymous. The table options below use
-- Zetaris's public-bucket configuration and the us-west-2 S3 endpoint, so
-- this script does not need AWS credential values.
--
-- PREREQUISITE: OOKLA_S3 must be registered as a logical database before
-- the tables below can reference it in FROM -- see HOWTO.md sec 1.
CREATE LIGHTNING DATABASE OOKLA_S3 DESCRIBE BY "Ookla Speedtest Global Performance S3 filestore source";

CREATE LIGHTNING FILESTORE TABLE ookla_speedtest_fixed FROM OOKLA_S3 FORMAT PARQUET OPTIONS (
  PATH "s3a://ookla-open-data/parquet/performance/type=fixed/year=2026/quarter=2/2026-04-01_performance_fixed_tiles.parquet",
  inferSchema "true",
  isS3BucketPublic "true",
  useS3PathStyleAccess "true",
  s3Endpoint "s3.us-west-2.amazonaws.com"
);

-- Verify:
SELECT * FROM OOKLA_S3.ookla_speedtest_fixed LIMIT 10;

-- Mobile is the same path pattern with type=mobile instead of type=fixed:
CREATE LIGHTNING FILESTORE TABLE ookla_speedtest_mobile FROM OOKLA_S3 FORMAT PARQUET OPTIONS (
  PATH "s3a://ookla-open-data/parquet/performance/type=mobile/year=2026/quarter=2/2026-04-01_performance_mobile_tiles.parquet",
  inferSchema "true",
  isS3BucketPublic "true",
  useS3PathStyleAccess "true",
  s3Endpoint "s3.us-west-2.amazonaws.com"
);

SELECT * FROM OOKLA_S3.ookla_speedtest_mobile LIMIT 10;

-- Note: the filename date (2026-04-01 above) always reflects the *first day*
-- of the quarter, not the file's publish date -- confirm the current
-- quarter's exact filename with the listing command above rather than
-- guessing the date pattern.
