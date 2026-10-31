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
--   or, without the AWS CLI:
--   curl -s "https://ookla-open-data.s3.amazonaws.com/?list-type=2&prefix=parquet/performance/type=fixed/year=2026/&delimiter=/"
--
-- Confirmed live 2026-10-31. Both quarter=2 files below were still listed
-- (fixed 353,986,294 bytes, mobile 184,560,046 bytes). year=2026 also
-- listed quarter=1 and quarter=3 (2026-07-01). This script pins quarter=2,
-- the files that were registered and queried. An earlier HTTP 500 at
-- CREATE did not reproduce: a new table with these same OPTIONS registered,
-- and the statements below return "already exists" when the objects are
-- already present. See sql/known_to_fail/ISSUE-07-ookla.md.
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

-- Mobile is the same path pattern with type=mobile instead of type=fixed.
CREATE LIGHTNING FILESTORE TABLE ookla_speedtest_mobile FROM OOKLA_S3 FORMAT PARQUET OPTIONS (
  PATH "s3a://ookla-open-data/parquet/performance/type=mobile/year=2026/quarter=2/2026-04-01_performance_mobile_tiles.parquet",
  inferSchema "true",
  isS3BucketPublic "true",
  useS3PathStyleAccess "true",
  s3Endpoint "s3.us-west-2.amazonaws.com"
);

-- Note: the filename date (2026-04-01 above) always reflects the *first day*
-- of the quarter, not the file's publish date -- confirm the current
-- quarter's exact filename with the listing command above rather than
-- guessing the date pattern.
--
-- tile_x and tile_y are longitude and latitude. On 2026-10-31 the
-- busiest fixed tile in the Manhattan window, quadkey 0320101101320122,
-- had tile_x -73.9792 and tile_y 40.766, and the LIMIT 10 polygons sat
-- on their own tile_x/tile_y. sql/07_ookla_speedtest_select.sql bounds every
-- aggregation to a Manhattan window on those two columns. Each query
-- reads one quarter file; on 2026-10-31 those scans took about 4-19
-- seconds.

-- Next: verify with sql/07_ookla_speedtest_select.sql
