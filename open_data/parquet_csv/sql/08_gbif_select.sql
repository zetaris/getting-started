-- =============================================================================
-- Verification query and example for 08_gbif_create.sql
-- Assumes 08_gbif_create.sql has already been run.
--
-- The filtered verification query runs when you execute this file.
-- Keep the broad example below commented; this snapshot contains 1.6B+ rows.
-- =============================================================================

-- === Verification ===
SELECT scientificname, countrycode, decimallatitude, decimallongitude, eventdate
FROM GBIF_S3.gbif_occurrences
WHERE countrycode = 'AU' AND class = 'Aves'
LIMIT 10;

-- === Example queries ===
-- Note: this snapshot is large (1.6B+ rows worldwide) -- for a live demo,
-- filter early and narrowly, e.g. by country code or taxonomic class, rather
-- than a bare SELECT * across the whole table:
--   SELECT scientificname, countrycode, decimallatitude, decimallongitude, eventdate
--   FROM gbif_occurrences
--   WHERE countrycode = 'AU' AND class = 'Aves'
--   LIMIT 100;
