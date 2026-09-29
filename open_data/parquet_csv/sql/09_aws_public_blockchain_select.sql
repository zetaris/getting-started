-- =============================================================================
-- Verification queries for 09_aws_public_blockchain_create.sql
-- Assumes 09_aws_public_blockchain_create.sql has already been run.
--
-- The verification queries run when you execute this file.
-- =============================================================================

-- === Verification ===
SELECT * FROM AWS_BLOCKCHAIN_S3.btc_transactions LIMIT 10;
SELECT * FROM AWS_BLOCKCHAIN_S3.eth_transactions LIMIT 10;
