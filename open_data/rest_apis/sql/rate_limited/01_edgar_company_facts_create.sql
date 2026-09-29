-- =============================================================================
-- Source: SEC EDGAR XBRL Company Facts API (companyconcept endpoint).
-- Repeats the same pattern for seven companies -- Apple, IBM, Oracle,
-- Walmart, Target, Ford, and Tesla -- one REST table (raw JSON) and one
-- flattened schemastore view per company, all views landing in the
-- shared `edgar` schemastore container so they can be queried and
-- unioned together (see the optional cross-company view at the bottom).
--
-- License: ambiguous -- filings are filer-authored, not
-- government-authored, so free API access doesn't automatically mean a
-- copyright/license grant over the underlying facts. Fine to query the
-- live API for a demo, don't bulk-redistribute a copy of the extracted
-- data.
--
-- Format: REST/JSON (CREATE LIGHTNING REST TABLE, not a filestore
-- table). See the SQL companion guide for the general REST shape
-- taxonomy and identifier-quoting rules this script relies on.
--
-- Docs: https://www.sec.gov/search-filings/edgar-search-assistance/accessing-edgar-data
-- https://data.sec.gov/api/xbrl/companyconcept/CIK{10-digit-cik}/us-gaap/{tag}.json
--
-- Rate limit: 10 requests/sec, declared user-agent required (SEC blocks
-- default/missing user-agent strings), no botnets. See
-- https://www.sec.gov/os/webmaster-faq#developers
--
-- Before running: confirm the CIK is current for the company you want.
-- EDGAR company search: https://www.sec.gov/cgi-bin/browse-edgar
--
-- Status: validated end to end against all seven companies (2026-09-18).
-- =============================================================================
--
-- Caveats:
--   1. Apple's fetch returns only 11 rows, all from a single accession
--      (0000320193-18-000145, filed 2018-11-05), capping out at
--      FY2018. Not a truncation bug: a direct curl against the live
--      SEC endpoint returns the same 11 rows independently. Apple, like
--      many filers, appears to have switched which XBRL tag it uses for
--      total revenue around the 2018 ASC 606 revenue-recognition
--      standard change, so the older `Revenues` tag stops appearing in
--      later filings. Treat a low row count here as a reason to check
--      the real API first, not evidence of truncation.
--   2. Oracle's CIK (0001341439) is the current Oracle Corporation
--      entity. There is a separate, older, unrelated CIK (0000777676,
--      "Oracle Systems Corp") from decades ago in EDGAR's history -- if
--      oracle_revenue_facts comes back empty, check EDGAR's company
--      search before assuming the connector broke.
--   3. Tesla only started filing 10-Ks after going public in 2010, so
--      its Revenues tag history is shorter than the others by
--      construction -- a small row count here is expected and not the
--      same symptom as caveat 1.
-- =============================================================================

-- Step 0: Lightning database holding all raw REST tables for this
-- source. Run once.
CREATE LIGHTNING DATABASE SEC_DATA DESCRIBE BY "SEC EDGAR XBRL company facts REST source";

-- Step 1: shared schemastore container for every company's flattened
-- view. Run this exactly once -- CREATE SCHEMASTORE CONTAINER has no
-- IF NOT EXISTS support, so re-running it against a name that already
-- exists fails outright. If `edgar` already exists in your
-- environment, comment this line out before running the rest of the
-- script.
CREATE SCHEMASTORE CONTAINER edgar;

-- Apple Inc. -- CIK 0000320193
CREATE LIGHTNING REST TABLE apple_revenue_facts FROM SEC_DATA REQUEST(
    endpoint "https://data.sec.gov/api/xbrl/companyconcept/CIK0000320193/us-gaap/Revenues.json",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW apple_revenue_table WITH CONTAINER edgar AS
SELECT
    cik,
    `entityName` AS entity_name,
    tag AS concept,
    fact.`start` AS period_start,
    fact.`end` AS period_end,
    fact.val AS value_usd,
    fact.accn AS accession_number,
    fact.fy AS fiscal_year,
    fact.fp AS fiscal_period,
    fact.frame AS period_frame,
    fact.form AS form_type,
    fact.filed AS filed_date
FROM sec_data.apple_revenue_facts
LATERAL VIEW explode(units.USD) AS fact;

-- IBM (International Business Machines Corp) -- CIK 0000051143
CREATE LIGHTNING REST TABLE ibm_revenue_facts FROM SEC_DATA REQUEST(
    endpoint "https://data.sec.gov/api/xbrl/companyconcept/CIK0000051143/us-gaap/Revenues.json",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW ibm_revenue_table WITH CONTAINER edgar AS
SELECT
    cik,
    `entityName` AS entity_name,
    tag AS concept,
    fact.`start` AS period_start,
    fact.`end` AS period_end,
    fact.val AS value_usd,
    fact.accn AS accession_number,
    fact.fy AS fiscal_year,
    fact.fp AS fiscal_period,
    fact.frame AS period_frame,
    fact.form AS form_type,
    fact.filed AS filed_date
FROM sec_data.ibm_revenue_facts
LATERAL VIEW explode(units.USD) AS fact;

-- Oracle Corporation -- CIK 0001341439 (see caveat 2)
CREATE LIGHTNING REST TABLE oracle_revenue_facts FROM SEC_DATA REQUEST(
    endpoint "https://data.sec.gov/api/xbrl/companyconcept/CIK0001341439/us-gaap/Revenues.json",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW oracle_revenue_table WITH CONTAINER edgar AS
SELECT
    cik,
    `entityName` AS entity_name,
    tag AS concept,
    fact.`start` AS period_start,
    fact.`end` AS period_end,
    fact.val AS value_usd,
    fact.accn AS accession_number,
    fact.fy AS fiscal_year,
    fact.fp AS fiscal_period,
    fact.frame AS period_frame,
    fact.form AS form_type,
    fact.filed AS filed_date
FROM sec_data.oracle_revenue_facts
LATERAL VIEW explode(units.USD) AS fact;

-- Walmart Inc. -- CIK 0000104169
CREATE LIGHTNING REST TABLE walmart_revenue_facts FROM SEC_DATA REQUEST(
    endpoint "https://data.sec.gov/api/xbrl/companyconcept/CIK0000104169/us-gaap/Revenues.json",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW walmart_revenue_table WITH CONTAINER edgar AS
SELECT
    cik,
    `entityName` AS entity_name,
    tag AS concept,
    fact.`start` AS period_start,
    fact.`end` AS period_end,
    fact.val AS value_usd,
    fact.accn AS accession_number,
    fact.fy AS fiscal_year,
    fact.fp AS fiscal_period,
    fact.frame AS period_frame,
    fact.form AS form_type,
    fact.filed AS filed_date
FROM sec_data.walmart_revenue_facts
LATERAL VIEW explode(units.USD) AS fact;

-- Target Corporation -- CIK 0000027419
CREATE LIGHTNING REST TABLE target_revenue_facts FROM SEC_DATA REQUEST(
    endpoint "https://data.sec.gov/api/xbrl/companyconcept/CIK0000027419/us-gaap/Revenues.json",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW target_revenue_table WITH CONTAINER edgar AS
SELECT
    cik,
    `entityName` AS entity_name,
    tag AS concept,
    fact.`start` AS period_start,
    fact.`end` AS period_end,
    fact.val AS value_usd,
    fact.accn AS accession_number,
    fact.fy AS fiscal_year,
    fact.fp AS fiscal_period,
    fact.frame AS period_frame,
    fact.form AS form_type,
    fact.filed AS filed_date
FROM sec_data.target_revenue_facts
LATERAL VIEW explode(units.USD) AS fact;

-- Ford Motor Company -- CIK 0000037996
CREATE LIGHTNING REST TABLE ford_revenue_facts FROM SEC_DATA REQUEST(
    endpoint "https://data.sec.gov/api/xbrl/companyconcept/CIK0000037996/us-gaap/Revenues.json",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW ford_revenue_table WITH CONTAINER edgar AS
SELECT
    cik,
    `entityName` AS entity_name,
    tag AS concept,
    fact.`start` AS period_start,
    fact.`end` AS period_end,
    fact.val AS value_usd,
    fact.accn AS accession_number,
    fact.fy AS fiscal_year,
    fact.fp AS fiscal_period,
    fact.frame AS period_frame,
    fact.form AS form_type,
    fact.filed AS filed_date
FROM sec_data.ford_revenue_facts
LATERAL VIEW explode(units.USD) AS fact;

-- Tesla, Inc. -- CIK 0001318605 (see caveat 3)
CREATE LIGHTNING REST TABLE tesla_revenue_facts FROM SEC_DATA REQUEST(
    endpoint "https://data.sec.gov/api/xbrl/companyconcept/CIK0001318605/us-gaap/Revenues.json",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW tesla_revenue_table WITH CONTAINER edgar AS
SELECT
    cik,
    `entityName` AS entity_name,
    tag AS concept,
    fact.`start` AS period_start,
    fact.`end` AS period_end,
    fact.val AS value_usd,
    fact.accn AS accession_number,
    fact.fy AS fiscal_year,
    fact.fp AS fiscal_period,
    fact.frame AS period_frame,
    fact.form AS form_type,
    fact.filed AS filed_date
FROM sec_data.tesla_revenue_facts
LATERAL VIEW explode(units.USD) AS fact;

-- Optional: single cross-company view for side-by-side comparison.
-- Only build this once every individual view above has been verified
-- -- a union over unverified, possibly-incomplete data just makes the
-- problem harder to spot.
-- CREATE SCHEMASTORE VIEW all_companies_revenue_table WITH CONTAINER edgar AS
-- SELECT * FROM edgar.apple_revenue_table
-- UNION ALL
-- SELECT * FROM edgar.ibm_revenue_table
-- UNION ALL
-- SELECT * FROM edgar.oracle_revenue_table
-- UNION ALL
-- SELECT * FROM edgar.walmart_revenue_table
-- UNION ALL
-- SELECT * FROM edgar.target_revenue_table
-- UNION ALL
-- SELECT * FROM edgar.ford_revenue_table
-- UNION ALL
-- SELECT * FROM edgar.tesla_revenue_table;

-- =============================================================================
-- Teardown -- removes the flattened views this script created.
-- Commented out by default. See the SQL companion guide for why
-- DROP VIEW is the only reliable teardown statement, and how to remove
-- the underlying REST tables and database registration (Zetaris Data
-- Explorer -- no SQL path exists).
-- =============================================================================

-- DROP VIEW edgar.all_companies_revenue_table;
-- DROP VIEW edgar.apple_revenue_table;
-- DROP VIEW edgar.ibm_revenue_table;
-- DROP VIEW edgar.oracle_revenue_table;
-- DROP VIEW edgar.walmart_revenue_table;
-- DROP VIEW edgar.target_revenue_table;
-- DROP VIEW edgar.ford_revenue_table;
-- DROP VIEW edgar.tesla_revenue_table;
