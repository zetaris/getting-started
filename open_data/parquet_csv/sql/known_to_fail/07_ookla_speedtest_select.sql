-- =============================================================================
-- Verification queries for 07_ookla_speedtest_create.sql
-- Assumes 07_ookla_speedtest_create.sql has already been run.
--
-- KNOWN TO FAIL -- never reached. Both CREATE LIGHTNING FILESTORE TABLE
-- statements in 07_ookla_speedtest_create.sql fail with a 500 error, so
-- neither table this file queries was ever successfully created. See
-- sql/known_to_fail/ISSUE-07-ookla.md for the full writeup.
-- =============================================================================

-- === Verification ===
SELECT * FROM OOKLA_S3.ookla_speedtest_fixed LIMIT 10;
SELECT * FROM OOKLA_S3.ookla_speedtest_mobile LIMIT 10;
