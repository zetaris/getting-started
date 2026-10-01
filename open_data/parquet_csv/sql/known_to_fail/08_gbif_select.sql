-- =============================================================================
-- Verification and example queries for 08_gbif_create.sql
-- Assumes 08_gbif_create.sql has already been run.
--
-- KNOWN TO FAIL -- live-tested results per query, against a real Zetaris
-- instance (see sql/known_to_fail/ISSUE-08-gbif.md for the full writeup):
--   CACHE TABLE (via Data Explorer GUI)  -- succeeded
--   Verification SELECT (filtered)       -- failed with a 500 error
--   1. DESCRIBE                          -- succeeded
--   2. Overview                          -- failed with a 500 error
--   3. Top species                       -- failed with a 500 error
--   4. Occurrences by year               -- failed with a 500 error
--   5. Seasonality (by month)            -- skipped, not run
--   6. Basis-of-record breakdown         -- failed with a 500 error
--   7. Coordinate completeness           -- skipped, not run
--   8. Top institutions                  -- skipped, not run
-- Only DESCRIBE and the GUI's own cache action work. Every SELECT against
-- the table fails, including the filtered, narrowly-scoped verification
-- query this package otherwise relies on everywhere else (NOAA, AWS
-- Public Blockchain) to prove a source is actually queryable. Kept below as
-- originally written, since the queries themselves aren't the problem --
-- see the ISSUE file for why.
--
-- Column names below follow GBIF's published Darwin Core occurrence schema
-- (the standard GBIF uses for every occurrence export):
--   https://data-blog.gbif.org/post/gbif-occurrence-schema/
-- kingdom, phylum, class, order, family, genus, species, scientificname,
-- taxonrank, countrycode, stateprovince, locality, decimallatitude,
-- decimallongitude, eventdate, year, month, day, basisofrecord,
-- occurrencestatus, institutioncode, recordedby, individualcount. DESCRIBE
-- succeeding confirms the table itself exposes a schema; whether these
-- specific column names match what DESCRIBE reported is not re-confirmed
-- here, since every query that would exercise them failed.
--
-- IMPORTANT -- this snapshot is 1.6B+ rows worldwide. Every query below
-- keeps 08_gbif_create.sql's own narrow-filter discipline (country code
-- and/or taxonomic class) rather than scanning the whole table. That
-- discipline did not avoid the 500 errors above -- see the ISSUE file for
-- why scale is one hypothesis among several, not a confirmed cause.
-- =============================================================================

-- === Verification === FAILED with a 500 error
SELECT scientificname, countrycode, decimallatitude, decimallongitude, eventdate
FROM GBIF_S3.gbif_occurrences
WHERE countrycode = 'AU' AND class = 'Aves'
LIMIT 10;

-- 1. Confirm column names and inferred types -- confirmed working:
DESCRIBE GBIF_S3.gbif_occurrences;

-- === Example queries === (none of the below are confirmed working -- see
-- the per-query results in the header above)

-- 2. Overview -- total bird (Aves) occurrence records for Australia, and
-- how many distinct species they cover. FAILED with a 500 error:
SELECT
    COUNT(*) AS total_occurrences,
    COUNT(DISTINCT scientificname) AS distinct_species
FROM GBIF_S3.gbif_occurrences
WHERE countrycode = 'AU' AND class = 'Aves';

-- 3. Top 10 most-recorded bird species in Australia. FAILED with a 500 error:
SELECT scientificname, COUNT(*) AS occurrence_count
FROM GBIF_S3.gbif_occurrences
WHERE countrycode = 'AU' AND class = 'Aves'
GROUP BY scientificname
ORDER BY occurrence_count DESC
LIMIT 10;

-- 4. Occurrences by year -- a rough recording-effort trend over time for
-- this same filtered slice. FAILED with a 500 error:
SELECT year, COUNT(*) AS occurrence_count
FROM GBIF_S3.gbif_occurrences
WHERE countrycode = 'AU' AND class = 'Aves' AND year IS NOT NULL
GROUP BY year
ORDER BY year;

-- 5. Seasonality -- occurrences by month, to see when most bird sightings
-- get recorded in this slice (citizen-science apps like eBird typically
-- show strong seasonal peaks). SKIPPED -- not run, given queries 2-4's
-- results:
SELECT month, COUNT(*) AS occurrence_count
FROM GBIF_S3.gbif_occurrences
WHERE countrycode = 'AU' AND class = 'Aves' AND month IS NOT NULL
GROUP BY month
ORDER BY month;

-- 6. Basis-of-record breakdown -- how these records were collected
-- (e.g. HUMAN_OBSERVATION, PRESERVED_SPECIMEN, MACHINE_OBSERVATION).
-- FAILED with a 500 error:
SELECT basisofrecord, COUNT(*) AS occurrence_count
FROM GBIF_S3.gbif_occurrences
WHERE countrycode = 'AU' AND class = 'Aves'
GROUP BY basisofrecord
ORDER BY occurrence_count DESC;

-- 7. Coordinate completeness -- how many records in this slice have usable
-- latitude/longitude vs. how many don't, useful before building anything
-- that maps the data. SKIPPED -- not run, given queries 2-4 and 6's results:
SELECT
    COUNT(*) AS total_occurrences,
    SUM(CASE WHEN decimallatitude IS NOT NULL AND decimallongitude IS NOT NULL THEN 1 ELSE 0 END) AS with_coordinates,
    SUM(CASE WHEN decimallatitude IS NULL OR decimallongitude IS NULL THEN 1 ELSE 0 END) AS without_coordinates
FROM GBIF_S3.gbif_occurrences
WHERE countrycode = 'AU' AND class = 'Aves';

-- 8. Top 10 contributing institutions for this slice -- useful for
-- understanding who's actually submitting the data behind the numbers.
-- SKIPPED -- not run, given queries 2-4 and 6's results:
SELECT institutioncode, COUNT(*) AS occurrence_count
FROM GBIF_S3.gbif_occurrences
WHERE countrycode = 'AU' AND class = 'Aves' AND institutioncode IS NOT NULL
GROUP BY institutioncode
ORDER BY occurrence_count DESC
LIMIT 10;
