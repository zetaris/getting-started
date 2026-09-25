-- =============================================================================
-- Source:   SEC EDGAR Submissions API (a DIFFERENT endpoint than
--           01_edgar_company_facts_create.sql's companyconcept) joined
--           against company_dns's SIC hierarchy reference
--           (10_company_dns_sic_create.sql) -- the "advanced data product"
--           this whole plan set out to build: a readable company profile
--           (name, SIC code and description, full division/major-group/
--           industry-group hierarchy) for each of the same 7 companies
--           already in 01_edgar_company_facts_create.sql.
-- License:  Same ambiguous/query-live-don't-redistribute posture as
--           01_edgar_company_facts_create.sql (filer-authored EDGAR
--           content) and 10_company_dns_sic_create.sql (SIC data traces to
--           SEC's public list).
-- Format:   REST/JSON. The submissions endpoint is a flat top-level
--           object -- no explode() needed for the fields this script
--           uses (cik, name, sic, sicDescription are plain scalars).
-- Docs:     https://data.sec.gov/submissions/CIK{10-digit-cik}.json
-- Rate limit: same as 01_edgar_company_facts_create.sql -- 10 req/sec,
--           declared User-Agent required (SEC blocks default/missing ones).
-- Before running:
--   1. This script REUSES 01_edgar_company_facts_create.sql's SEC_DATA
--      database and edgar SCHEMASTORE CONTAINER -- both already exist on
--      this instance (confirmed 2026-09-21: Steps 0-1 of that script,
--      plus all 7 per-company revenue tables/views, have been run).
--      STEP 0 below is commented out for that reason -- uncomment only on
--      a fresh instance that hasn't run 01_edgar_company_facts_create.sql
--      yet.
--   2. company_dns.sic_codes_table (10_company_dns_sic_create.sql) must
--      also already exist -- confirmed 2026-09-21, live-tested end to end.
-- =============================================================================
--
-- NOT YET LIVE-TESTED against Zetaris (as of 2026-09-21) -- written the
-- same way 01_edgar_company_facts_create.sql and
-- 10_company_dns_sic_create.sql were before their own first live runs.
-- Every endpoint's shape was verified live via curl/fetch during research
-- (docs/plans/edgar-sic-enrichment-plan.md sec 3); what's unconfirmed is
-- Zetaris-side behavior for this specific combination (submissions REST
-- table + cross-container-free join against an already-existing
-- SCHEMASTORE VIEW).
--
-- Caveats:
--   1. cik FORMAT MISMATCH -- DELIBERATELY SIDESTEPPED, NOT FIXED. EDGAR's
--      submissions endpoint returns cik as a zero-padded 10-digit STRING
--      (e.g. "0000320193"). 01_edgar_company_facts_create.sql's own
--      revenue tables carry cik as a BARE INTEGER instead (confirmed
--      live, 2026-09-21: the apple_revenue_table grid shows cik = 320193,
--      not "0000320193"). This script never joins the two ON cik -- every
--      view below is already scoped to one hardcoded company (same
--      pattern as 01_edgar_company_facts_create.sql's own per-company
--      tables), so submissions data and revenue data for "the same
--      company" are combined by construction (which company's block
--      you're in), not by a runtime join key. If a future version needs a
--      dynamic join on cik across companies, normalize the format first
--      (e.g. LPAD(CAST(r.cik AS STRING), 10, '0') = s.cik) rather than
--      assuming they match as-is.
--   2. "LATEST REVENUE" IN sql/11_edgar_company_profiles_select.sql'S
--      QUERY 4 IS NOT GUARANTEED TO BE GENUINELY RECENT.
--      01_edgar_company_facts_create.sql's own header (caveat 4, resolved
--      2026-09-21) found that Apple's us-gaap:Revenues tag has only 11
--      data points, all from a single 2018 filing -- confirmed NOT a
--      Zetaris bug, but a real gap in that specific tag's upstream
--      coverage (companies often switch which XBRL tag they use for total
--      revenue over time, e.g. around the 2018 ASC 606 standard change).
--      The "latest revenue" per company in that query is the latest value
--      *available under this specific tag*, which may be several years
--      stale for some companies -- not necessarily their actual most
--      recent reported revenue. Treat that query as a demonstration of
--      the join mechanic (profile + financials, combining this script
--      with 01_edgar_company_facts_create.sql), not as a source of
--      current financial figures.
--   3. This script only builds SQL objects -- SCHEMASTORE VIEWs and
--      queries. A Virtual Data Mart has NO SQL surface at all (confirmed,
--      docs/plans/edgar-sic-enrichment-plan.md sec 5.3) -- building one
--      over the views below is manual GUI work, walked through in
--      sql/11_edgar_company_profiles_select.sql rather than scripted.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- STEP 0: prerequisites, already satisfied on this instance -- see
-- "Before running" above. Uncomment only on a fresh instance.
-- ---------------------------------------------------------------------------
-- CREATE LIGHTNING DATABASE SEC_DATA DESCRIBE BY "SEC EDGAR XBRL company facts REST source";
-- CREATE SCHEMASTORE CONTAINER edgar;

-- =============================================================================
-- Per-company: submissions REST table, then a profile view joining that
-- company's own `sic` code against company_dns.sic_codes_table. Same 7
-- companies and CIKs as 01_edgar_company_facts_create.sql.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- APPLE INC. -- CIK 0000320193
-- ---------------------------------------------------------------------------
CREATE LIGHTNING REST TABLE apple_submissions_raw FROM SEC_DATA REQUEST(
    endpoint "https://data.sec.gov/submissions/CIK0000320193.json",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW apple_profile_table WITH CONTAINER edgar AS
SELECT
    s.cik                        AS cik,
    s.name                       AS entity_name,
    s.sic                        AS sic_code,
    s.`sicDescription`           AS sic_description_edgar,
    r.description                AS sic_description_reference,
    r.division                   AS division,
    r.division_desc              AS division_desc,
    r.major_group                AS major_group,
    r.major_group_desc           AS major_group_desc,
    r.industry_group             AS industry_group,
    r.industry_group_desc        AS industry_group_desc
FROM sec_data.apple_submissions_raw s
INNER JOIN company_dns.sic_codes_table r
    ON s.sic = r.sic_code;

-- ---------------------------------------------------------------------------
-- IBM (INTERNATIONAL BUSINESS MACHINES CORP) -- CIK 0000051143
-- ---------------------------------------------------------------------------
CREATE LIGHTNING REST TABLE ibm_submissions_raw FROM SEC_DATA REQUEST(
    endpoint "https://data.sec.gov/submissions/CIK0000051143.json",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW ibm_profile_table WITH CONTAINER edgar AS
SELECT
    s.cik                        AS cik,
    s.name                       AS entity_name,
    s.sic                        AS sic_code,
    s.`sicDescription`           AS sic_description_edgar,
    r.description                AS sic_description_reference,
    r.division                   AS division,
    r.division_desc              AS division_desc,
    r.major_group                AS major_group,
    r.major_group_desc           AS major_group_desc,
    r.industry_group             AS industry_group,
    r.industry_group_desc        AS industry_group_desc
FROM sec_data.ibm_submissions_raw s
INNER JOIN company_dns.sic_codes_table r
    ON s.sic = r.sic_code;

-- ---------------------------------------------------------------------------
-- ORACLE CORPORATION -- CIK 0001341439
-- ---------------------------------------------------------------------------
CREATE LIGHTNING REST TABLE oracle_submissions_raw FROM SEC_DATA REQUEST(
    endpoint "https://data.sec.gov/submissions/CIK0001341439.json",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW oracle_profile_table WITH CONTAINER edgar AS
SELECT
    s.cik                        AS cik,
    s.name                       AS entity_name,
    s.sic                        AS sic_code,
    s.`sicDescription`           AS sic_description_edgar,
    r.description                AS sic_description_reference,
    r.division                   AS division,
    r.division_desc              AS division_desc,
    r.major_group                AS major_group,
    r.major_group_desc           AS major_group_desc,
    r.industry_group             AS industry_group,
    r.industry_group_desc        AS industry_group_desc
FROM sec_data.oracle_submissions_raw s
INNER JOIN company_dns.sic_codes_table r
    ON s.sic = r.sic_code;

-- ---------------------------------------------------------------------------
-- WALMART INC. -- CIK 0000104169
-- ---------------------------------------------------------------------------
CREATE LIGHTNING REST TABLE walmart_submissions_raw FROM SEC_DATA REQUEST(
    endpoint "https://data.sec.gov/submissions/CIK0000104169.json",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW walmart_profile_table WITH CONTAINER edgar AS
SELECT
    s.cik                        AS cik,
    s.name                       AS entity_name,
    s.sic                        AS sic_code,
    s.`sicDescription`           AS sic_description_edgar,
    r.description                AS sic_description_reference,
    r.division                   AS division,
    r.division_desc              AS division_desc,
    r.major_group                AS major_group,
    r.major_group_desc           AS major_group_desc,
    r.industry_group             AS industry_group,
    r.industry_group_desc        AS industry_group_desc
FROM sec_data.walmart_submissions_raw s
INNER JOIN company_dns.sic_codes_table r
    ON s.sic = r.sic_code;

-- ---------------------------------------------------------------------------
-- TARGET CORPORATION -- CIK 0000027419
-- ---------------------------------------------------------------------------
CREATE LIGHTNING REST TABLE target_submissions_raw FROM SEC_DATA REQUEST(
    endpoint "https://data.sec.gov/submissions/CIK0000027419.json",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW target_profile_table WITH CONTAINER edgar AS
SELECT
    s.cik                        AS cik,
    s.name                       AS entity_name,
    s.sic                        AS sic_code,
    s.`sicDescription`           AS sic_description_edgar,
    r.description                AS sic_description_reference,
    r.division                   AS division,
    r.division_desc              AS division_desc,
    r.major_group                AS major_group,
    r.major_group_desc           AS major_group_desc,
    r.industry_group             AS industry_group,
    r.industry_group_desc        AS industry_group_desc
FROM sec_data.target_submissions_raw s
INNER JOIN company_dns.sic_codes_table r
    ON s.sic = r.sic_code;

-- ---------------------------------------------------------------------------
-- FORD MOTOR COMPANY -- CIK 0000037996
-- ---------------------------------------------------------------------------
CREATE LIGHTNING REST TABLE ford_submissions_raw FROM SEC_DATA REQUEST(
    endpoint "https://data.sec.gov/submissions/CIK0000037996.json",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW ford_profile_table WITH CONTAINER edgar AS
SELECT
    s.cik                        AS cik,
    s.name                       AS entity_name,
    s.sic                        AS sic_code,
    s.`sicDescription`           AS sic_description_edgar,
    r.description                AS sic_description_reference,
    r.division                   AS division,
    r.division_desc              AS division_desc,
    r.major_group                AS major_group,
    r.major_group_desc           AS major_group_desc,
    r.industry_group             AS industry_group,
    r.industry_group_desc        AS industry_group_desc
FROM sec_data.ford_submissions_raw s
INNER JOIN company_dns.sic_codes_table r
    ON s.sic = r.sic_code;

-- ---------------------------------------------------------------------------
-- TESLA, INC. -- CIK 0001318605
-- ---------------------------------------------------------------------------
CREATE LIGHTNING REST TABLE tesla_submissions_raw FROM SEC_DATA REQUEST(
    endpoint "https://data.sec.gov/submissions/CIK0001318605.json",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW tesla_profile_table WITH CONTAINER edgar AS
SELECT
    s.cik                        AS cik,
    s.name                       AS entity_name,
    s.sic                        AS sic_code,
    s.`sicDescription`           AS sic_description_edgar,
    r.description                AS sic_description_reference,
    r.division                   AS division,
    r.division_desc              AS division_desc,
    r.major_group                AS major_group,
    r.major_group_desc           AS major_group_desc,
    r.industry_group             AS industry_group,
    r.industry_group_desc        AS industry_group_desc
FROM sec_data.tesla_submissions_raw s
INNER JOIN company_dns.sic_codes_table r
    ON s.sic = r.sic_code;

-- ---------------------------------------------------------------------------
-- Cross-company view -- all 7 profiles in one place, the UNION ALL pattern
-- already used throughout this package (PokéAPI, Open Food Facts, StatCan).
-- Verify each individual profile above FIRST -- see
-- sql/11_edgar_company_profiles_select.sql, "Verification" -- HOWTO.md's
-- own caution about unioning before individually verifying
-- (01_edgar_company_facts_create.sql applies the same discipline to its
-- own commented-out cross-company view).
-- ---------------------------------------------------------------------------
CREATE SCHEMASTORE VIEW all_companies_profile_table WITH CONTAINER edgar AS
SELECT * FROM edgar.apple_profile_table
UNION ALL
SELECT * FROM edgar.ibm_profile_table
UNION ALL
SELECT * FROM edgar.oracle_profile_table
UNION ALL
SELECT * FROM edgar.walmart_profile_table
UNION ALL
SELECT * FROM edgar.target_profile_table
UNION ALL
SELECT * FROM edgar.ford_profile_table
UNION ALL
SELECT * FROM edgar.tesla_profile_table;

-- =============================================================================
-- TEARDOWN -- removes the views this script created. Commented out by
-- default, same convention as every other script in this package -- see
-- HOWTO.md, "Removing a source", for why DROP VIEW is the only teardown
-- statement confirmed to work reliably, and how to actually remove the
-- underlying REST tables (Zetaris Data Explorer, "File Source & API"
-- panel -- no SQL path exists for that part). Deleting a Virtual Data
-- Mart is also manual/GUI-only -- see its own left-panel bin icon in the
-- Virtual Data Mart tab, per the kbase's documented delete steps.
-- =============================================================================

-- DROP VIEW edgar.all_companies_profile_table;
-- DROP VIEW edgar.apple_profile_table;
-- DROP VIEW edgar.ibm_profile_table;
-- DROP VIEW edgar.oracle_profile_table;
-- DROP VIEW edgar.walmart_profile_table;
-- DROP VIEW edgar.target_profile_table;
-- DROP VIEW edgar.ford_profile_table;
-- DROP VIEW edgar.tesla_profile_table;

-- To remove the *_submissions_raw REST tables, use the Zetaris Data
-- Explorer's "File Source & API" panel (see HOWTO.md, "Removing a
-- source") -- they live under the existing SEC_DATA registration, same
-- as 01_edgar_company_facts_create.sql's own REST tables.

-- Next: verify with sql/11_edgar_company_profiles_select.sql
