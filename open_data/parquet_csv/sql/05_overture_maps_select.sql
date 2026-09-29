-- =============================================================================
-- Verification queries for 05_overture_maps_create.sql
-- Assumes 05_overture_maps_create.sql has already been run.
--
-- The verification query runs when you execute this file.
-- =============================================================================

-- === Verification ===
SELECT * FROM OVERTURE_S3.overture_places LIMIT 10;
