-- =============================================================================
-- Verification queries for 04_foursquare_places_create.sql
-- Assumes 04_foursquare_places_create.sql has already been run.
--
-- The verification query runs when you execute this file.
-- =============================================================================

-- === Verification ===
SELECT * FROM FSQ_SOURCE_COOP.foursquare_places LIMIT 10;
