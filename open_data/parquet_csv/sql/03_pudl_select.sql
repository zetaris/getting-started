-- =============================================================================
-- Verification queries for 03_pudl_create.sql
-- Assumes 03_pudl_create.sql has already been run.
--
-- The energy-source verification runs when you execute this file.
-- The generator query is optional and remains commented until that table
-- has been created.
-- =============================================================================

-- === Verification ===
SELECT * FROM PUDL_S3.pudl_eia_energy_sources LIMIT 10;
-- SELECT * FROM PUDL_S3.pudl_eia_yearly_generators LIMIT 10;
