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
--   (also available in af-south-1, ap-southeast-2, eu-central-1, sa-east-1)
-- =============================================================================
--
-- CAVEAT: this bucket is public/anonymous. The table options below use
-- Zetaris's public-bucket configuration and the us-east-1 S3 endpoint, so
-- this script does not need AWS credential values.
-- The snapshot date (2026-09-01 below) is a MOVING TARGET -- GBIF publishes a
-- new monthly snapshot on its own cadence. Confirm the current one with the
-- listing command above before an event.
--
-- PREREQUISITE: GBIF_S3 must be registered as a logical database before
-- the table below can reference it in FROM -- see HOWTO.md sec 1.
CREATE LIGHTNING DATABASE GBIF_S3 DESCRIBE BY "GBIF species occurrences S3 filestore source";

CREATE LIGHTNING FILESTORE TABLE gbif_occurrences FROM GBIF_S3 FORMAT PARQUET OPTIONS (
  PATH "s3a://gbif-open-data-us-east-1/occurrence/2026-09-01/occurrence.parquet/",
  inferSchema "true",
  isS3BucketPublic "true",
  useS3PathStyleAccess "true",
  s3Endpoint "s3.us-east-1.amazonaws.com"
);

-- Verify:
SELECT * FROM GBIF_S3.gbif_occurrences LIMIT 10;

-- Note: this snapshot is large (1.6B+ rows worldwide) -- for a live demo,
-- filter early and narrowly, e.g. by country code or taxonomic class, rather
-- than a bare SELECT * across the whole table:
--   SELECT scientificname, countrycode, decimallatitude, decimallongitude, eventdate
--   FROM gbif_occurrences
--   WHERE countrycode = 'AU' AND class = 'Aves'
--   LIMIT 100;
--
-- GBIF also publishes a citation.txt alongside each snapshot
-- (s3://gbif-open-data-us-east-1/occurrence/2026-09-01/citation.txt) -- pull
-- that into your demo's README/attribution notice per their citation
-- guidelines linked above.
