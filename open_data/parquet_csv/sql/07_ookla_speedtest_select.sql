-- =============================================================================
-- Verification queries for 07_ookla_speedtest_create.sql
-- Assumes 07_ookla_speedtest_create.sql has already been run.
--
-- The verification queries run when you execute this file.
-- =============================================================================

-- === Verification ===
SELECT * FROM OOKLA_S3.ookla_speedtest_fixed LIMIT 10;
SELECT * FROM OOKLA_S3.ookla_speedtest_mobile LIMIT 10;
