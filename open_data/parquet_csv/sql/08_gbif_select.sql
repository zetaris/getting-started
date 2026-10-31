-- =============================================================================
-- Verification and example queries for 08_gbif_create.sql.
-- Assumes 08_gbif_create.sql has already been run.
--
-- Confirmed live 2026-10-31 against one file of snapshot 2026-10-01:
--   s3a://gbif-open-data-us-east-1/occurrence/2026-10-01/occurrence.parquet/004990
-- DESCRIBE returned 50 columns. The file has 538620 rows. The Australia /
-- birds filter below keeps 17402 of them (589 distinct scientificname
-- values). That filter is the example slice, not what keeps the scan
-- small: the create script's PATH is one file, because the snapshot
-- directory is 10448 files and 282.17 GiB.
--
-- Column names follow this snapshot's inferred Darwin Core schema
-- (lowercase, no separators): kingdom, phylum, class, order, family,
-- genus, species, scientificname, taxonrank, countrycode, stateprovince,
-- locality, decimallatitude, decimallongitude, eventdate, year, month,
-- day, basisofrecord, occurrencestatus, institutioncode, individualcount.
-- recordedby and identifiedby are array<struct<array_element:string>>,
-- not plain strings. See
--   https://data-blog.gbif.org/post/gbif-occurrence-schema/
-- An earlier HTTP 500 on these queries is recorded in
-- sql/known_to_fail/ISSUE-08-gbif.md and did not reproduce on this file.
-- =============================================================================

-- === Verification ===
SELECT scientificname, countrycode, decimallatitude, decimallongitude, eventdate
FROM GBIF_S3.gbif_occurrences
WHERE countrycode = 'AU' AND class = 'Aves'
LIMIT 10;

-- 1. Confirm column names and inferred types:
DESCRIBE GBIF_S3.gbif_occurrences;

-- === Example queries ===
-- All queries below confirmed live against the single file above.

-- 2. Overview -- bird (Aves) occurrence records for Australia in this file,
-- and how many distinct scientific names they cover:
SELECT
    COUNT(*) AS total_occurrences,
    COUNT(DISTINCT scientificname) AS distinct_species
FROM GBIF_S3.gbif_occurrences
WHERE countrycode = 'AU' AND class = 'Aves';

-- 3. Top 10 most-recorded bird species in Australia in this file:
SELECT scientificname, COUNT(*) AS occurrence_count
FROM GBIF_S3.gbif_occurrences
WHERE countrycode = 'AU' AND class = 'Aves'
GROUP BY scientificname
ORDER BY occurrence_count DESC
LIMIT 10;

-- 4. Occurrences by year -- recording-effort trend for this same slice:
SELECT year, COUNT(*) AS occurrence_count
FROM GBIF_S3.gbif_occurrences
WHERE countrycode = 'AU' AND class = 'Aves' AND year IS NOT NULL
GROUP BY year
ORDER BY year;

-- 5. Seasonality -- occurrences by month:
SELECT month, COUNT(*) AS occurrence_count
FROM GBIF_S3.gbif_occurrences
WHERE countrycode = 'AU' AND class = 'Aves' AND month IS NOT NULL
GROUP BY month
ORDER BY month;

-- 6. Basis-of-record breakdown -- how these records were collected
-- (e.g. HUMAN_OBSERVATION, PRESERVED_SPECIMEN, MACHINE_OBSERVATION):
SELECT basisofrecord, COUNT(*) AS occurrence_count
FROM GBIF_S3.gbif_occurrences
WHERE countrycode = 'AU' AND class = 'Aves'
GROUP BY basisofrecord
ORDER BY occurrence_count DESC;

-- 7. Coordinate completeness -- how many records in this slice have usable
-- latitude/longitude vs. how many don't:
SELECT
    COUNT(*) AS total_occurrences,
    SUM(CASE WHEN decimallatitude IS NOT NULL AND decimallongitude IS NOT NULL THEN 1 ELSE 0 END) AS with_coordinates,
    SUM(CASE WHEN decimallatitude IS NULL OR decimallongitude IS NULL THEN 1 ELSE 0 END) AS without_coordinates
FROM GBIF_S3.gbif_occurrences
WHERE countrycode = 'AU' AND class = 'Aves';

-- 8. Top 10 contributing institutions for this slice:
SELECT institutioncode, COUNT(*) AS occurrence_count
FROM GBIF_S3.gbif_occurrences
WHERE countrycode = 'AU' AND class = 'Aves' AND institutioncode IS NOT NULL
GROUP BY institutioncode
ORDER BY occurrence_count DESC
LIMIT 10;
