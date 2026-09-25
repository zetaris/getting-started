-- =============================================================================
-- Verification / example queries for 08_gbif_create.sql
-- Assumes 08_gbif_create.sql has already been run.
--
-- Commented out by default so running this whole file doesn't silently fire
-- a read query against the table. Uncomment what you want to run, or run it
-- directly in the SQL Editor.
-- =============================================================================

-- === Verification ===
-- SELECT * FROM GBIF_S3.gbif_occurrences LIMIT 10;

-- === Example queries ===
-- Note: this snapshot is large (1.6B+ rows worldwide) -- for a live demo,
-- filter early and narrowly, e.g. by country code or taxonomic class, rather
-- than a bare SELECT * across the whole table:
--   SELECT scientificname, countrycode, decimallatitude, decimallongitude, eventdate
--   FROM gbif_occurrences
--   WHERE countrycode = 'AU' AND class = 'Aves'
--   LIMIT 100;
