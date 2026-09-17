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
--   1. CONFIRMED DEAD (2026-09): the s3://nyc-tlc mirror returns AccessDenied
--      on both an anonymous request and a real, working, signed IAM request
--      -- this isn't a credentials problem, the bucket itself doesn't grant
--      outside read access to anyone right now (consistent with, and now
--      beyond, a July 2022 community report of the same bucket being
--      unreachable -- https://dask.discourse.group/t/s3-nyc-tlc-seems-to-have-disappeared/890).
--      Option A below is left for reference only / in case access is
--      restored later -- go straight to Option B.
--   2. CONFIRMED (2026-09): Zetaris's PATH does NOT accept a plain https://
--      URL -- tried the CloudFront URL below directly and got a hard
--      "Invalid file path to access" validation error, not a fetch failure.
--      Only s3a:///wasb://-style paths work. See HOWTO.md sec 2. This means
--      NYC TLC's actively-maintained distribution channel (CloudFront) can't
--      be read by Zetaris directly at all -- Option B (re-upload to a bucket
--      you control) is the only route in, not just a fallback.
--   3. The s3://nyc-tlc key layout uses a literal space in "trip data/" --
--      confirmed live, needs percent-encoding as %20 in PATH (fixed in
--      Option A below, moot once you're on Option B with your own key
--      naming instead).
--   4. Every credential value below is a PLACEHOLDER. Zetaris always signs
--      S3 requests -- CONFIRMED (see HOWTO.md sec 2): a real AWS IAM key
--      pair is required, there's no anonymous/credential-less mode.
--
-- PREREQUISITE: the logical database (NYC_TLC_S3 or NYC_TLC_MIRROR) must be
-- registered before a table below can reference it in FROM -- see HOWTO.md
-- sec 1.
--
-- OPTION A -- the S3 mirror. CONFIRMED DEAD, reference only (see caveat 1):
CREATE LIGHTNING DATABASE NYC_TLC_S3 DESCRIBE BY "NYC TLC S3 mirror filestore source";

CREATE LIGHTNING FILESTORE TABLE nyc_tlc_yellow_trips FROM NYC_TLC_S3 FORMAT PARQUET OPTIONS (
  PATH "s3a://nyc-tlc/trip%20data/yellow_tripdata_2025-01.parquet",
  inferSchema "true",
  AWSACCESSKEYID "YOUR_AWS_ACCESS_KEY_ID",
  AWSSECRETACCESSKEY "YOUR_AWS_SECRET_ACCESS_KEY"
);

-- Verify:
SELECT * FROM nyc_tlc_yellow_trips LIMIT 10;

-- OPTION B -- CONFIRMED necessary, not just a fallback (see caveats 1 and 2):
-- download the current month from the CloudFront mirror, upload it into a
-- bucket you control (your own S3, or the MinIO instance referenced in
-- sql/04_foursquare_places.sql's pattern), then point Zetaris at that
-- instead. This keeps the "don't re-host in the public repo" guidance
-- intact -- a private bucket used only to feed a live demo query is a
-- different risk profile than redistributing the files publicly. Needs
-- s3:PutObject/s3:CreateBucket permissions, which a read-only IAM user
-- (e.g. AmazonS3ReadOnlyAccess) doesn't have -- use a separate write-capable
-- key for the upload step, or add write permissions to the existing one.
--
--   curl -O https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2025-01.parquet
--   aws s3 cp yellow_tripdata_2025-01.parquet s3://YOUR-OWN-BUCKET/nyc_tlc/
--
-- CREATE LIGHTNING DATABASE NYC_TLC_MIRROR DESCRIBE BY "NYC TLC re-uploaded to our own bucket";
--
-- CREATE LIGHTNING FILESTORE TABLE nyc_tlc_yellow_trips FROM NYC_TLC_MIRROR FORMAT PARQUET OPTIONS (
--   PATH "s3a://YOUR-OWN-BUCKET/nyc_tlc/yellow_tripdata_2025-01.parquet",
--   inferSchema "true",
--   AWSACCESSKEYID "YOUR_AWS_ACCESS_KEY_ID",
--   AWSSECRETACCESSKEY "YOUR_AWS_SECRET_ACCESS_KEY"
-- );
