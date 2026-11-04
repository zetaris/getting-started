-- =============================================================================
-- 03 Demo Bank USL - CREATE
-- =============================================================================
-- Requires: open_data/parquet_csv/sql/10_demo_bank_create.sql (SF_BANK, DBX_RISK).
-- License:  Apache License 2.0 (same as this repository).
-- Companion: 03_demo_bank_usl_select.sql (DQ + queries).
-- SF_BANK and DBX_RISK are local Parquet sources standing in for Snowflake and
-- Databricks; register real platforms under the same names and this runs as-is.
--
-- Join map (every arrow crosses SF_BANK <-> DBX_RISK unless marked local):
--   SF customers.customer_id  <- DBX cards / loans / credit_scores / fraud_alerts .customer_id
--   SF accounts.account_id    <- DBX cards.account_id, loans.repayment_account_id
--   SF transactions.merchant_id -> DBX merchants.merchant_id
--   SF accounts -> customers -> branches, accounts -> products      (local SF)
--   DBX card_transactions -> cards, merchants; fraud_alerts -> card_transactions (local DBX)
-- =============================================================================


-- =============================================================================
-- UNIFIED SEMANTIC LAYER (USL) spanning both sources
-- (federated demo queries are in open_data/parquet_csv/sql/10_demo_bank_select.sql)
-- =============================================================================
-- Same lifecycle as the repo's open_data/usl scripts:
--   namespace -> COMPILE (tables + PK/FK) -> describe -> ACTIVATE (map each
--   table to its source) -> RUN DQ (FKs auto-generate referential-integrity
--   rules) -> query.
-- Notes taken from the repo's verified USL runs:
--   * Send the COMPILE USL block below as ONE statement (SQL Editor, JDBC, or
--     the New USL screen). Clients that split on ';' will break it.
--   * The repo only tested varchar columns in USL DDL. If COMPILE rejects
--     int / decimal / date / timestamp / boolean, change those columns to
--     varchar and keep the CASTs in the ACTIVATE queries.
--   * FKs are declared within one USL (same DDL block) - the only pattern the
--     USL guide shows. Cross-USL FKs are unconfirmed.
--   * NOT NULL columns are wrapped in COALESCE in ACTIVATE, per the repo's
--     null-handling fix.
-- =============================================================================

-- B1. Namespace (parent first, or the child fails with
--     "parent namespace : metastore is not existing")
CREATE NAMESPACE IF NOT EXISTS lightning.metastore;
CREATE NAMESPACE IF NOT EXISTS lightning.metastore.bank_demo;

-- B2. Model: 11 tables, 14 relationships (send as ONE statement)
COMPILE USL IF NOT EXISTS demo_bank_usl DEPLOY NAMESPACE lightning.metastore.bank_demo DDL
CREATE TABLE branch (
    branch_id      varchar(5)   NOT NULL PRIMARY KEY,
    branch_name    varchar(100),
    city           varchar(60),
    state          varchar(2),
    region         varchar(20)
);

CREATE TABLE product (
    product_code      varchar(10) NOT NULL PRIMARY KEY,
    product_name      varchar(60),
    product_category  varchar(20),
    interest_rate     decimal(5,3),
    monthly_fee       decimal(6,2)
);

CREATE TABLE customer (
    customer_id     varchar(10)  NOT NULL PRIMARY KEY,
    first_name      varchar(40),
    last_name       varchar(40),
    email           varchar(120),
    phone           varchar(20),
    state           varchar(2),
    segment         varchar(20),
    kyc_status      varchar(12),
    risk_rating     varchar(8),
    home_branch_id  varchar(5)   NOT NULL FOREIGN KEY REFERENCES branch(branch_id),
    customer_since  date
);

CREATE TABLE account (
    account_id       varchar(10)  NOT NULL PRIMARY KEY,
    customer_id      varchar(10)  NOT NULL FOREIGN KEY REFERENCES customer(customer_id),
    branch_id        varchar(5)   NOT NULL FOREIGN KEY REFERENCES branch(branch_id),
    product_code     varchar(10)  NOT NULL FOREIGN KEY REFERENCES product(product_code),
    status           varchar(10),
    opened_date      date,
    current_balance  decimal(14,2)
);

CREATE TABLE merchant (
    merchant_id    varchar(8)   NOT NULL PRIMARY KEY,
    merchant_name  varchar(100),
    mcc_code       varchar(4),
    category       varchar(30),
    country        varchar(2),
    risk_tier      varchar(6)
);

CREATE TABLE bank_transaction (
    txn_id       varchar(24)  NOT NULL PRIMARY KEY,
    account_id   varchar(10)  NOT NULL FOREIGN KEY REFERENCES account(account_id),
    txn_ts       timestamp,
    txn_type     varchar(20),
    direction    varchar(6),
    amount       decimal(12,2),
    channel      varchar(10),
    merchant_id  varchar(8),
    status       varchar(10)
);

CREATE TABLE card (
    card_id       varchar(10)  NOT NULL PRIMARY KEY,
    customer_id   varchar(10)  NOT NULL FOREIGN KEY REFERENCES customer(customer_id),
    account_id    varchar(10)  NOT NULL FOREIGN KEY REFERENCES account(account_id),
    card_type     varchar(6),
    network       varchar(12),
    status        varchar(12),
    credit_limit  decimal(12,2)
);

CREATE TABLE card_auth (
    auth_id      varchar(20)  NOT NULL PRIMARY KEY,
    card_id      varchar(10)  NOT NULL FOREIGN KEY REFERENCES card(card_id),
    merchant_id  varchar(8)   NOT NULL FOREIGN KEY REFERENCES merchant(merchant_id),
    auth_ts      timestamp,
    amount       decimal(12,2),
    entry_mode   varchar(12),
    auth_status  varchar(10),
    fraud_score  decimal(4,3),
    is_flagged   boolean
);

CREATE TABLE fraud_alert (
    alert_id        varchar(10)  NOT NULL PRIMARY KEY,
    auth_id         varchar(20)  NOT NULL FOREIGN KEY REFERENCES card_auth(auth_id),
    customer_id     varchar(10)  NOT NULL FOREIGN KEY REFERENCES customer(customer_id),
    alert_ts        timestamp,
    rule_triggered  varchar(40),
    severity        varchar(10),
    alert_status    varchar(20)
);

CREATE TABLE loan (
    loan_id               varchar(10)  NOT NULL PRIMARY KEY,
    customer_id           varchar(10)  NOT NULL FOREIGN KEY REFERENCES customer(customer_id),
    repayment_account_id  varchar(10)  NOT NULL FOREIGN KEY REFERENCES account(account_id),
    loan_type             varchar(10),
    principal             decimal(14,2),
    outstanding_balance   decimal(14,2),
    days_past_due         int,
    status                varchar(12)
);

CREATE TABLE credit_score (
    score_id      varchar(20)  NOT NULL PRIMARY KEY,
    customer_id   varchar(10)  NOT NULL FOREIGN KEY REFERENCES customer(customer_id),
    score_month   date,
    bureau        varchar(12),
    credit_score  int,
    risk_band     varchar(12)
);

-- bank_transaction.merchant_id has no FK on purpose: it is NULL for non-card
-- transactions, and how the auto-generated FK DQ rule treats NULLs is untested.
-- Join it to merchant in queries instead (see 03_usl_select.sql).

-- B3. Document the model
UPDATE USL lightning.metastore.bank_demo.demo_bank_usl SET DESCRIPTION 'Demo bank semantic model federated across SF_BANK (core ledger: branches, products, customers, accounts, transactions) and DBX_RISK (cards, authorisations, fraud alerts, loans, credit scores, merchants).';
UPDATE USL lightning.metastore.bank_demo.demo_bank_usl.customer SET TABLE DESCRIPTION 'Bank customers - source SF_BANK.customers (core banking).';
UPDATE USL lightning.metastore.bank_demo.demo_bank_usl.card_auth SET TABLE DESCRIPTION 'Card authorisation stream with fraud model score - source DBX_RISK.card_transactions.';
UPDATE USL lightning.metastore.bank_demo.demo_bank_usl.fraud_alert SET TABLE DESCRIPTION 'Fraud alerts raised on flagged authorisations - source DBX_RISK.fraud_alerts.';

-- B4. Activate: map each USL table to its physical source
-- ---- from SF_BANK ----
ACTIVATE USL TABLE lightning.metastore.bank_demo.demo_bank_usl.branch AS
SELECT COALESCE(branch_id, '') AS branch_id, branch_name, city, state, region
FROM SF_BANK.branches;

ACTIVATE USL TABLE lightning.metastore.bank_demo.demo_bank_usl.product AS
SELECT COALESCE(product_code, '') AS product_code, product_name, product_category,
       CAST(interest_rate AS DECIMAL(5,3)) AS interest_rate,
       CAST(monthly_fee   AS DECIMAL(6,2)) AS monthly_fee
FROM SF_BANK.products;

ACTIVATE USL TABLE lightning.metastore.bank_demo.demo_bank_usl.customer AS
SELECT COALESCE(customer_id, '') AS customer_id, first_name, last_name, email, phone, state,
       segment, kyc_status, risk_rating,
       COALESCE(home_branch_id, '') AS home_branch_id,
       CAST(customer_since AS DATE) AS customer_since
FROM SF_BANK.customers;

ACTIVATE USL TABLE lightning.metastore.bank_demo.demo_bank_usl.account AS
SELECT COALESCE(account_id, '') AS account_id,
       COALESCE(customer_id, '') AS customer_id,
       COALESCE(branch_id, '') AS branch_id,
       COALESCE(product_code, '') AS product_code,
       status,
       CAST(opened_date AS DATE) AS opened_date,
       CAST(current_balance AS DECIMAL(14,2)) AS current_balance
FROM SF_BANK.accounts;

ACTIVATE USL TABLE lightning.metastore.bank_demo.demo_bank_usl.bank_transaction AS
SELECT COALESCE(txn_id, '') AS txn_id,
       COALESCE(account_id, '') AS account_id,
       CAST(txn_ts AS TIMESTAMP) AS txn_ts,
       txn_type, direction,
       CAST(amount AS DECIMAL(12,2)) AS amount,
       channel, merchant_id, status
FROM SF_BANK.transactions;

-- ---- from DBX_RISK ----
ACTIVATE USL TABLE lightning.metastore.bank_demo.demo_bank_usl.merchant AS
SELECT COALESCE(merchant_id, '') AS merchant_id, merchant_name, mcc_code, category, country, risk_tier
FROM DBX_RISK.merchants;

ACTIVATE USL TABLE lightning.metastore.bank_demo.demo_bank_usl.card AS
SELECT COALESCE(card_id, '') AS card_id,
       COALESCE(customer_id, '') AS customer_id,
       COALESCE(account_id, '') AS account_id,
       card_type, network, status, credit_limit
FROM DBX_RISK.cards;

ACTIVATE USL TABLE lightning.metastore.bank_demo.demo_bank_usl.card_auth AS
SELECT COALESCE(auth_id, '') AS auth_id,
       COALESCE(card_id, '') AS card_id,
       COALESCE(merchant_id, '') AS merchant_id,
       auth_ts, amount, entry_mode, auth_status, fraud_score, is_flagged
FROM DBX_RISK.card_transactions;

ACTIVATE USL TABLE lightning.metastore.bank_demo.demo_bank_usl.fraud_alert AS
SELECT COALESCE(alert_id, '') AS alert_id,
       COALESCE(auth_id, '') AS auth_id,
       COALESCE(customer_id, '') AS customer_id,
       alert_ts, rule_triggered, severity, alert_status
FROM DBX_RISK.fraud_alerts;

ACTIVATE USL TABLE lightning.metastore.bank_demo.demo_bank_usl.loan AS
SELECT COALESCE(loan_id, '') AS loan_id,
       COALESCE(customer_id, '') AS customer_id,
       COALESCE(repayment_account_id, '') AS repayment_account_id,
       loan_type, principal, outstanding_balance, days_past_due, status
FROM DBX_RISK.loans;

ACTIVATE USL TABLE lightning.metastore.bank_demo.demo_bank_usl.credit_score AS
SELECT COALESCE(score_id, '') AS score_id,
       COALESCE(customer_id, '') AS customer_id,
       score_month, bureau, credit_score, risk_band
FROM DBX_RISK.credit_scores;

-- =============================================================================
-- Teardown (commented):
-- REMOVE USL demo_bank_usl NAMESPACE lightning.metastore.bank_demo;
-- DROP NAMESPACE lightning.metastore.bank_demo CASCADE;
-- =============================================================================
