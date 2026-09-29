-- =============================================================================
-- Verification queries for 02_noaa_ghcn_create.sql
-- Assumes 02_noaa_ghcn_create.sql has already been run.
--
-- The verification query runs when you execute this file.
-- =============================================================================

-- === Verification ===
SELECT * FROM NOAA_GHCN_S3.noaa_ghcn_daily_2025 LIMIT 10;
