-- =============================================================================
-- Source:   GBIF (Global Biodiversity Information Facility) species occurrences
-- License:  Registry states aggregate CC-BY-NC -- NON-COMMERCIAL (verified via
--           https://github.com/awslabs/open-data-registry/blob/main/datasets/gbif.yaml)
--           Individual records may carry CC0 or CC-BY instead, but the safe
--           conservative assumption for the whole snapshot is CC-BY-NC. GBIF
--           also expects citation/DOI credit on any published use -- see docs.
-- Format:   Parquet (native)
-- Docs:     https://github.com/gbif/occurrence/blob/master/aws-public-data.md
--           https://www.gbif.org/citation-guidelines
-- Before running: confirm the current snapshot date and your nearest region --
--   aws s3 ls --no-sign-request s3://gbif-open-data-us-east-1/occurrence/
--   or, without the AWS CLI:
--   curl -s "https://gbif-open-data-us-east-1.s3.amazonaws.com/?list-type=2&prefix=occurrence/&delimiter=/"
--   (also available in af-south-1, ap-southeast-2, eu-central-1, sa-east-1)
--
-- Confirmed live 2026-10-31. The latest listed snapshot is 2026-10-01
-- (citation.txt: "GBIF.org (1 October 2026) GBIF Occurrence Download
-- https://doi.org/10.15468/dl.tup2g6"). Its occurrence.parquet/ prefix is
-- 10448 files and 302977702510 bytes (282.17 GiB). Do not register that
-- directory: an aggregate over it would read the whole snapshot. This
-- script pins one file that contains Australian bird records:
--   occurrence/2026-10-01/occurrence.parquet/004990
--   47796744 bytes, 538620 rows, of which 17402 are countrycode AU and
--   class Aves (589 distinct scientificname values).
-- An earlier query-time HTTP 500 is recorded in
-- sql/known_to_fail/ISSUE-08-gbif.md. On 2026-10-31 a filtered
-- SELECT ... LIMIT 10 against the already-registered 2026-09-01 directory
-- returned 10 rows (timeUsed 2809 ms) and did not reproduce that 500.
-- Aggregates were run only against the single file above.
-- =============================================================================
--
-- CAVEAT: this bucket is public/anonymous. The table options below use
-- Zetaris's public-bucket configuration and the us-east-1 S3 endpoint, so
-- this script does not need AWS credential values.
-- The snapshot date and the file name are a MOVING TARGET -- GBIF publishes
-- a new monthly snapshot on its own cadence, and file 004990 in a later
-- snapshot is not the same slice. Confirm the file still exists, and that
-- a bounded SELECT returns rows, before an event.
--
-- PREREQUISITE: GBIF_S3 must be registered as a logical database before
-- the table below can reference it in FROM -- see HOWTO.md sec 1.
CREATE LIGHTNING DATABASE GBIF_S3 DESCRIBE BY "GBIF species occurrences S3 filestore source";

CREATE LIGHTNING FILESTORE TABLE gbif_occurrences FROM GBIF_S3 FORMAT PARQUET OPTIONS (
  PATH "s3a://gbif-open-data-us-east-1/occurrence/2026-10-01/occurrence.parquet/004990",
  inferSchema "true",
  isS3BucketPublic "true",
  useS3PathStyleAccess "true",
  s3Endpoint "s3.us-east-1.amazonaws.com"
);

-- GBIF also publishes a citation.txt alongside each snapshot
-- (s3://gbif-open-data-us-east-1/occurrence/2026-10-01/citation.txt). The
-- 2026-10-01 text is: GBIF.org (1 October 2026) GBIF Occurrence Download
-- https://doi.org/10.15468/dl.tup2g6
-- Pull that into any published use, per the citation guidelines linked above.
-- identifiedby, recordedby, typestatus, mediatype, and issue are arrays of
-- structs. The example queries in sql/08_gbif_select.sql stay on scalar columns.

-- Next: verify with sql/08_gbif_select.sql
