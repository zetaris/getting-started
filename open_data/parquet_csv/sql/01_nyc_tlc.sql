-- =============================================================================
-- Source:   NYC TLC Trip Record Data (Yellow/Green/FHVHV taxi trips)
-- License:  Ambiguous -- see parquet-csv-data-sources.md #1 before treating this
--           as cleared for anything beyond a live query/demo. Do not re-host a
--           copy of this data in a public repo.
-- Format:   Parquet (native)
-- Docs:     https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page
--           https://www.nyc.gov/assets/tlc/downloads/pdf/data_dictionary_trip_records_yellow.pdf
-- Before running: confirm the bucket responds and see what's actually there --
--   aws s3 ls s3://nyc-tlc/ --no-sign-request
-- =============================================================================
--
-- CAVEAT (read this before you spend time debugging a connection failure):
--   1. The s3://nyc-tlc mirror has been reported unreachable before (a July
--      2022 community report found it returning zero rows -- see
--      https://dask.discourse.group/t/s3-nyc-tlc-seems-to-have-disappeared/890).
--      Whether it's currently live, and the exact internal key layout (older
--      tooling references a "trip data/" prefix with a literal space in it),
--      isn't confirmed -- list the bucket first.
--   2. NYC TLC's primary, actively-maintained distribution channel is the
--      CloudFront URL below, which is plain HTTPS -- not an s3a:// or wasb://
--      path. Documented Zetaris CREATE LIGHTNING FILESTORE TABLE examples use
--      an S3 or Azure Blob PATH; support for a bare HTTPS file URL as PATH
--      isn't documented either way. See HOWTO.md, section 2.
--   3. Every credential value below is a PLACEHOLDER. This bucket is publicly
--      readable (no AWS account needed for `aws s3 ... --no-sign-request`),
--      but Zetaris's documented syntax always includes AWSACCESSKEYID /
--      AWSSECRETACCESSKEY. See HOWTO.md, "Credentials on a public bucket",
--      for what to try before assuming you need a real AWS account.
--
-- OPTION A -- try the S3 mirror directly (test this first):
CREATE LIGHTNING FILESTORE TABLE nyc_tlc_yellow_trips FROM NYC_TLC_S3 FORMAT PARQUET OPTIONS (
  PATH "s3a://nyc-tlc/trip data/yellow_tripdata_2025-01.parquet",
  inferSchema "true",
  AWSACCESSKEYID "YOUR_AWS_ACCESS_KEY_ID",
  AWSSECRETACCESSKEY "YOUR_AWS_SECRET_ACCESS_KEY"
);

-- Verify:
SELECT * FROM nyc_tlc_yellow_trips LIMIT 10;

-- OPTION B -- fallback if Option A's PATH/prefix is wrong or the bucket
-- doesn't respond: download the current month from the CloudFront mirror,
-- upload it into a bucket you control (your own S3, or the MinIO instance
-- referenced in sql/04_foursquare_places.sql's pattern), then point Zetaris
-- at that instead. This keeps the "don't re-host in the public repo"
-- guidance intact -- a private bucket used only to feed a live demo query
-- is a different risk profile than redistributing the files publicly.
--
--   curl -O https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2025-01.parquet
--   aws s3 cp yellow_tripdata_2025-01.parquet s3://YOUR-OWN-BUCKET/nyc_tlc/
--
-- CREATE LIGHTNING FILESTORE TABLE nyc_tlc_yellow_trips FROM NYC_TLC_MIRROR FORMAT PARQUET OPTIONS (
--   PATH "s3a://YOUR-OWN-BUCKET/nyc_tlc/yellow_tripdata_2025-01.parquet",
--   inferSchema "true",
--   AWSACCESSKEYID "YOUR_AWS_ACCESS_KEY_ID",
--   AWSSECRETACCESSKEY "YOUR_AWS_SECRET_ACCESS_KEY"
-- );
