-- =============================================================================
-- 10 Demo Bank - CREATE
-- =============================================================================
-- Source:   Synthetic retail-bank dataset generated for Zetaris training and demos
--           (no real customer data; names, emails and phones are generated).
--           Files live in this repo: open_data/parquet_csv/table_data/demo_bank/
-- License:  Apache License 2.0 (same as this repository) - authored for this repo.
-- Format:   Parquet, one file per table, 11 tables, ~1 MB total, snapshot 2026-10-28.
-- Storage:  Local file store inside the Zetaris Docker containers (no cloud account).
--           Copy the files in first:
--             python3 scripts/copy_local_data.py --platform-dir <zetaris-platform-folder>
-- Docs:     open_data/parquet_csv/table_data/demo_bank/README.md
-- Listing:  confirm the files are in place before running this script:
--             docker compose exec driver ls -R /home/zetaris/customer-data/shared/demo_bank
--
-- Creates two Lightning databases that stand in for a two-platform bank:
--   SF_BANK  (core banking, "Snowflake")   branches, products, customers, accounts, transactions
--   DBX_RISK (risk lakehouse, "Databricks") merchants, cards, loans, card_transactions,
--                                           fraud_alerts, credit_scores
-- File sources show under SHOW LIGHTNING DATABASES, not SHOW DATASOURCES.
-- Companion: 10_demo_bank_select.sql. Semantic layer: open_data/usl/sql/03_demo_bank_usl_create.sql
-- =============================================================================

-- 1. The two logical databases -------------------------------------------------
CREATE LIGHTNING DATABASE SF_BANK  DESCRIBE BY "Demo Bank core banking - Parquet files in the container";
CREATE LIGHTNING DATABASE DBX_RISK DESCRIBE BY "Demo Bank cards, fraud and credit risk - Parquet files in the container";


-- 2. SF_BANK tables (5) --------------------------------------------------------
CREATE LIGHTNING FILESTORE TABLE branches FROM SF_BANK FORMAT PARQUET OPTIONS (
    PATH "file:///home/zetaris/customer-data/shared/demo_bank/sf_bank/branches.parquet",
    inferSchema "true"
);

CREATE LIGHTNING FILESTORE TABLE products FROM SF_BANK FORMAT PARQUET OPTIONS (
    PATH "file:///home/zetaris/customer-data/shared/demo_bank/sf_bank/products.parquet",
    inferSchema "true"
);

CREATE LIGHTNING FILESTORE TABLE customers FROM SF_BANK FORMAT PARQUET OPTIONS (
    PATH "file:///home/zetaris/customer-data/shared/demo_bank/sf_bank/customers.parquet",
    inferSchema "true"
);

CREATE LIGHTNING FILESTORE TABLE accounts FROM SF_BANK FORMAT PARQUET OPTIONS (
    PATH "file:///home/zetaris/customer-data/shared/demo_bank/sf_bank/accounts.parquet",
    inferSchema "true"
);

CREATE LIGHTNING FILESTORE TABLE transactions FROM SF_BANK FORMAT PARQUET OPTIONS (
    PATH "file:///home/zetaris/customer-data/shared/demo_bank/sf_bank/transactions.parquet",
    inferSchema "true"
);


-- 3. DBX_RISK tables (6) -------------------------------------------------------
CREATE LIGHTNING FILESTORE TABLE merchants FROM DBX_RISK FORMAT PARQUET OPTIONS (
    PATH "file:///home/zetaris/customer-data/shared/demo_bank/dbx_risk/merchants.parquet",
    inferSchema "true"
);

CREATE LIGHTNING FILESTORE TABLE cards FROM DBX_RISK FORMAT PARQUET OPTIONS (
    PATH "file:///home/zetaris/customer-data/shared/demo_bank/dbx_risk/cards.parquet",
    inferSchema "true"
);

CREATE LIGHTNING FILESTORE TABLE loans FROM DBX_RISK FORMAT PARQUET OPTIONS (
    PATH "file:///home/zetaris/customer-data/shared/demo_bank/dbx_risk/loans.parquet",
    inferSchema "true"
);

CREATE LIGHTNING FILESTORE TABLE card_transactions FROM DBX_RISK FORMAT PARQUET OPTIONS (
    PATH "file:///home/zetaris/customer-data/shared/demo_bank/dbx_risk/card_transactions.parquet",
    inferSchema "true"
);

CREATE LIGHTNING FILESTORE TABLE fraud_alerts FROM DBX_RISK FORMAT PARQUET OPTIONS (
    PATH "file:///home/zetaris/customer-data/shared/demo_bank/dbx_risk/fraud_alerts.parquet",
    inferSchema "true"
);

CREATE LIGHTNING FILESTORE TABLE credit_scores FROM DBX_RISK FORMAT PARQUET OPTIONS (
    PATH "file:///home/zetaris/customer-data/shared/demo_bank/dbx_risk/credit_scores.parquet",
    inferSchema "true"
);