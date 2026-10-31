-- =============================================================================
-- Verification queries for 03_pudl_create.sql
-- Assumes 03_pudl_create.sql has already been run.
--
-- Confirmed live 2026-10-31. Both queries returned 10 rows. A separate
-- COUNT(*) matched the Parquet footers: 42 rows in
-- core_eia__codes_energy_sources and 666788 rows in
-- out_eia__yearly_generators.
-- =============================================================================

-- === Verification ===
SELECT * FROM PUDL_S3.pudl_eia_energy_sources LIMIT 10;
SELECT * FROM PUDL_S3.pudl_eia_yearly_generators LIMIT 10;
