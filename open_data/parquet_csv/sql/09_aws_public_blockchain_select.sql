-- =============================================================================
-- Verification and example queries for 09_aws_public_blockchain_create.sql.
-- Assumes 09_aws_public_blockchain_create.sql has already been run.
--
-- Column names below follow the AWS Public Blockchain Data analytics guide's
-- published schema:
--   https://github.com/aws-solutions-library-samples/guidance-for-digital-assets-on-aws/blob/main/analytics/README.md
-- BTC's "transactions" table: hash, size, virtual_size, version, lock_time,
-- block_hash, block_number, index, inputs/outputs (arrays of structs with a
-- "value" field in whole BTC, not satoshis), input_count, output_count,
-- input_value, output_value, is_coinbase, fee, date.
-- ETH's "transactions" table: hash, nonce, transaction_index, from_address,
-- to_address, value (Wei), gas, gas_price, receipt_gas_used,
-- receipt_contract_address, receipt_status, block_timestamp, block_number,
-- date.
-- Live-tested and confirmed working -- every query below, against both
-- tables, succeeded. The eth_transactions queries ran noticeably faster
-- than the btc_transactions queries; see the caching note (and open
-- question) in 09_aws_public_blockchain_create.sql's header, and
-- parquet-csv-data-sources.md #9 for the current state of that question.
-- As with Overture and Foursquare, the BTC table's inputs/outputs are
-- nested arrays of structs -- query 7 below (the explode-based one) is the
-- one most likely to need a flattening view instead if a different Zetaris
-- version doesn't expose nested Parquet columns directly, though it ran
-- successfully in this live test.
-- =============================================================================

-- === Verification ===
SELECT * FROM AWS_BLOCKCHAIN_S3.btc_transactions LIMIT 10;
SELECT * FROM AWS_BLOCKCHAIN_S3.eth_transactions LIMIT 10;

-- 1. Confirm BTC column names and inferred types before relying on the
-- columns used in the BTC queries below:
DESCRIBE AWS_BLOCKCHAIN_S3.btc_transactions;

-- 2. Confirm ETH column names and inferred types before relying on the
-- columns used in the ETH queries below:
DESCRIBE AWS_BLOCKCHAIN_S3.eth_transactions;

-- === BTC example queries ===
-- Column names below are unconfirmed -- adjust to match query 1's actual
-- output if Parquet inference or a schema revision produced different names.

-- 3. Overview -- total transactions and how many are coinbase (block-reward)
-- transactions in this day's partition:
SELECT
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN is_coinbase THEN 1 ELSE 0 END) AS coinbase_transactions
FROM AWS_BLOCKCHAIN_S3.btc_transactions;

-- 4. Fee statistics -- min/avg/max transaction fee (in BTC) for this day's
-- partition, excluding coinbase transactions (which pay no fee):
SELECT
    MIN(fee) AS min_fee_btc,
    AVG(fee) AS avg_fee_btc,
    MAX(fee) AS max_fee_btc
FROM AWS_BLOCKCHAIN_S3.btc_transactions
WHERE is_coinbase = false;

-- 5. Top 10 highest-value BTC transactions by total output value:
SELECT hash, block_number, output_value, fee
FROM AWS_BLOCKCHAIN_S3.btc_transactions
ORDER BY output_value DESC
LIMIT 10;

-- 6. Input/output count distribution -- a rough shape check (most BTC
-- transactions have a small, similar number of inputs and outputs; a long
-- tail of consolidation/mixing transactions have many more):
SELECT
    input_count,
    output_count,
    COUNT(*) AS transaction_count
FROM AWS_BLOCKCHAIN_S3.btc_transactions
GROUP BY input_count, output_count
ORDER BY transaction_count DESC
LIMIT 10;

-- 7. Top 10 largest BTC output values across all individual outputs (not
-- transaction totals) -- outputs is an array of structs, exploded here:
SELECT t.hash, out.address, out.value AS output_value_btc
FROM AWS_BLOCKCHAIN_S3.btc_transactions t
LATERAL VIEW explode(t.outputs) exploded_out AS out
ORDER BY out.value DESC
LIMIT 10;

-- === ETH example queries ===

-- 8. Overview -- total transactions and how many created a new contract
-- (receipt_contract_address populated) in this day's partition:
SELECT
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN receipt_contract_address IS NOT NULL THEN 1 ELSE 0 END) AS contract_creations
FROM AWS_BLOCKCHAIN_S3.eth_transactions;

-- 9. Gas price statistics -- min/avg/max gas price paid, in Wei:
SELECT
    MIN(gas_price) AS min_gas_price_wei,
    AVG(gas_price) AS avg_gas_price_wei,
    MAX(gas_price) AS max_gas_price_wei
FROM AWS_BLOCKCHAIN_S3.eth_transactions;

-- 10. Top 10 highest-value ETH transfers by value (in Wei -- divide by
-- 1e18 for whole ETH):
SELECT hash, from_address, to_address, value / 1e18 AS value_eth
FROM AWS_BLOCKCHAIN_S3.eth_transactions
ORDER BY value DESC
LIMIT 10;

-- 11. Failed transaction count -- receipt_status is 0 for a reverted/failed
-- transaction, 1 for success (post-Byzantium fork; this dataset is well
-- past that point):
SELECT
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN receipt_status = 0 THEN 1 ELSE 0 END) AS failed_transactions
FROM AWS_BLOCKCHAIN_S3.eth_transactions;

-- 12. Top 10 busiest "to" addresses by transaction count -- a rough proxy
-- for the day's most-active contracts or exchange hot wallets:
SELECT to_address, COUNT(*) AS transaction_count
FROM AWS_BLOCKCHAIN_S3.eth_transactions
WHERE to_address IS NOT NULL
GROUP BY to_address
ORDER BY transaction_count DESC
LIMIT 10;
