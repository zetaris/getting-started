-- =============================================================================
-- Source:   NOAA Global Historical Climatology Network - Daily (GHCN-D)
-- License:  CC0-1.0 Universal Public Domain Dedication (verified)
--           https://registry.opendata.aws/noaa-ghcn/
-- Format:   CSV (native) -- the cleanest license in this whole set, included
--           specifically as the "CSV onboarding" demo
-- Docs:     https://docs.opendata.aws/noaa-ghcn-pds/readme.html
--           https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt (column spec)
-- Before running: list what years are available --
--   aws s3 ls s3://noaa-ghcn-pds/csv/by_year/ --no-sign-request
-- =============================================================================
--
-- CAVEAT: this bucket is public/anonymous (no AWS account required for the
-- `--no-sign-request` CLI access above), but Zetaris always signs S3
-- requests -- CONFIRMED (see HOWTO.md sec 2): a real AWS IAM key pair is
-- required below (a free-tier account with s3:GetObject/s3:ListBucket is
-- enough), even though the bucket itself doesn't require one.
--
-- PREREQUISITE: NOAA_GHCN_S3 must be registered as a logical database before
-- the table below can reference it in FROM -- see HOWTO.md sec 1.
CREATE LIGHTNING DATABASE NOAA_GHCN_S3 DESCRIBE BY "NOAA GHCN-Daily S3 filestore source";

CREATE LIGHTNING FILESTORE TABLE noaa_ghcn_daily_2025 FROM NOAA_GHCN_S3 FORMAT CSV OPTIONS (
  PATH "s3a://noaa-ghcn-pds/csv/by_year/2025.csv",
  inferSchema "true",
  header "false",
  AWSACCESSKEYID "YOUR_AWS_ACCESS_KEY_ID",
  AWSSECRETACCESSKEY "YOUR_AWS_SECRET_ACCESS_KEY"
);

-- Verify:
SELECT * FROM noaa_ghcn_daily_2025 LIMIT 10;

-- Note: GHCN-D's by_year CSVs ship without a header row (see the readme
-- linked above for the 8-column layout: ID, DATE, ELEMENT, DATA_VALUE,
-- M-FLAG, Q-FLAG, S-FLAG, OBS-TIME) -- hence header "false" above. If you
-- want named columns instead of the default col1..col8, rename them after
-- creation with your usual Zetaris column-rename/ALTER workflow, or wrap
-- this table in a view that aliases the columns per the readme.
--
-- Bonus demo (this is why GHCN is in the Parquet catalog despite being CSV-
-- native): once this table is queryable, converting it to Parquet is exactly
-- the kind of "onboard messy CSV, land it as Parquet" story a quick-start
-- audience wants to see. If your event demo also uses a DuckDB or Spark
-- step outside Zetaris, the equivalent one-liner is:
--   COPY (SELECT * FROM read_csv_auto('s3://noaa-ghcn-pds/csv/by_year/2025.csv'))
--   TO 'ghcn_2025.parquet' (FORMAT PARQUET);
