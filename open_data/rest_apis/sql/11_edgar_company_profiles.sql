-- =============================================================================
-- Source:   SEC EDGAR Submissions API (a DIFFERENT endpoint than
--           01_edgar_company_facts.sql's companyconcept) joined against
--           company_dns's SIC hierarchy reference (10_company_dns_sic.sql)
--           -- the "advanced data product" this whole plan set out to
--           build: a readable company profile (name, SIC code and
--           description, full division/major-group/industry-group
--           hierarchy) for each of the same 7 companies already in
--           01_edgar_company_facts.sql.
-- License:  Same ambiguous/query-live-don't-redistribute posture as
--           01_edgar_company_facts.sql (filer-authored EDGAR content) and
--           10_company_dns_sic.sql (SIC data traces to SEC's public list).
-- Format:   REST/JSON. The submissions endpoint is a flat top-level
--           object -- no explode() needed for the fields this script
--           uses (cik, name, sic, sicDescription are plain scalars).
-- Docs:     https://data.sec.gov/submissions/CIK{10-digit-cik}.json
-- Rate limit: same as 01_edgar_company_facts.sql -- 10 req/sec, declared
--           User-Agent required (SEC blocks default/missing ones).
-- Before running:
--   1. This script REUSES 01_edgar_company_facts.sql's SEC_DATA database
--      and edgar SCHEMASTORE CONTAINER -- both already exist on this
--      instance (confirmed 2026-09-21: Steps 0-1 of that script, plus all
--      7 per-company revenue tables/views, have been run). STEP 0 below
--      is commented out for that reason -- uncomment only on a fresh
--      instance that hasn't run 01_edgar_company_facts.sql yet.
--   2. company_dns.sic_codes_table (10_company_dns_sic.sql) must also
--      already exist -- confirmed 2026-09-21, live-tested end to end.
-- =============================================================================
--
-- NOT YET LIVE-TESTED against Zetaris (as of 2026-09-21) -- written the
-- same way 01_edgar_company_facts.sql and 10_company_dns_sic.sql were
-- before their own first live runs. Every endpoint's shape was verified
-- live via curl/fetch during research (docs/plans/edgar-sic-enrichment-plan.md
-- sec 3); what's unconfirmed is Zetaris-side behavior for this specific
-- combination (submissions REST table + cross-container-free join against
-- an already-existing SCHEMASTORE VIEW).
--
-- Caveats:
--   1. cik FORMAT MISMATCH -- DELIBERATELY SIDESTEPPED, NOT FIXED. EDGAR's
--      submissions endpoint returns cik as a zero-padded 10-digit STRING
--      (e.g. "0000320193"). 01_edgar_company_facts.sql's own revenue
--      tables carry cik as a BARE INTEGER instead (confirmed live,
--      2026-09-21: the apple_revenue_table grid shows cik = 320193, not
--      "0000320193"). This script never joins the two ON cik -- every
--      view below is already scoped to one hardcoded company (same
--      pattern as 01_edgar_company_facts.sql's own per-company tables),
--      so submissions data and revenue data for "the same company" are
--      combined by construction (which company's block you're in), not by
--      a runtime join key. If a future version needs a dynamic join on
--      cik across companies, normalize the format first (e.g.
--      LPAD(CAST(r.cik AS STRING), 10, '0') = s.cik) rather than assuming
--      they match as-is.
--   2. "LATEST REVENUE" IN QUERY 4 IS NOT GUARANTEED TO BE GENUINELY
--      RECENT. 01_edgar_company_facts.sql's own header (caveat 4,
--      resolved 2026-09-21) found that Apple's us-gaap:Revenues tag has
--      only 11 data points, all from a single 2018 filing -- confirmed
--      NOT a Zetaris bug, but a real gap in that specific tag's upstream
--      coverage (companies often switch which XBRL tag they use for total
--      revenue over time, e.g. around the 2018 ASC 606 standard change).
--      The "latest revenue" per company below is the latest value
--      *available under this specific tag*, which may be several years
--      stale for some companies -- not necessarily their actual most
--      recent reported revenue. Treat query 4 as a demonstration of the
--      join mechanic (profile + financials, combining this script with
--      01_edgar_company_facts.sql), not as a source of current financial
--      figures.
--   3. This script only builds SQL objects -- SCHEMASTORE VIEWs and
--      queries. A Virtual Data Mart has NO SQL surface at all (confirmed,
--      docs/plans/edgar-sic-enrichment-plan.md sec 5.3) -- building one
--      over the views below is manual GUI work, walked through at the
--      end of this file rather than scripted.
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
-- companies and CIKs as 01_edgar_company_facts.sql.
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
-- Verify each profile individually before combining them (same discipline
-- as every other multi-record source in this package):
--   SELECT * FROM edgar.apple_profile_table;
--   SELECT * FROM edgar.ibm_profile_table;
--   ... etc for oracle/walmart/target/ford/tesla
-- Each should return exactly 1 row. sic_description_edgar and
-- sic_description_reference should match for every company (both trace
-- back to the same underlying SEC SIC list) -- query 8 below checks this
-- programmatically instead of eyeballing all 7.
-- ---------------------------------------------------------------------------

-- Cross-company view -- all 7 profiles in one place, the UNION ALL pattern
-- already used throughout this package (PokéAPI, Open Food Facts, StatCan).
-- Verify each individual profile above FIRST -- see HOWTO.md's own caution
-- about unioning before individually verifying (01_edgar_company_facts.sql
-- applies the same discipline to its own commented-out cross-company view):
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

SELECT COUNT(*) FROM edgar.all_companies_profile_table;   -- expect 7

-- ---------------------------------------------------------------------------
-- Example queries -- run against all_companies_profile_table (and, for
-- query 4, the existing per-company revenue tables from
-- 01_edgar_company_facts.sql). Picked to exercise the actual payoff of
-- this plan: a readable industry profile per company, peer-grouping by
-- classification, and a join back to financial data.
-- ---------------------------------------------------------------------------

-- 1. All 7 profiles, readable side by side -- the core deliverable this
-- whole plan set out to build (a SIC code alone, e.g. "3571", unpacked
-- into something a reader can actually use):
SELECT entity_name, sic_code, sic_description_edgar, division_desc, major_group_desc, industry_group_desc
FROM edgar.all_companies_profile_table
ORDER BY entity_name;

-- 2. How many of these 7 companies fall in each SIC division:
SELECT division, division_desc, COUNT(*) AS company_count
FROM edgar.all_companies_profile_table
GROUP BY division, division_desc
ORDER BY company_count DESC;

-- 3. Peer groups -- major groups shared by more than one of these 7
-- companies (expect Walmart/Target to share one, given both are general
-- merchandise retailers; the rest are likely each in their own group).
-- NOTE: COLLECT_LIST/CONCAT_WS as an aggregate-to-string pattern are
-- standard Spark SQL but UNCONFIRMED against this Zetaris instance --
-- no earlier script in this package has used them. If either errors,
-- fall back to GROUP_CONCAT(entity_name) (if supported) or drop the
-- `companies` column and just look up which companies matched via query 1:
SELECT major_group, major_group_desc, COUNT(*) AS company_count,
       CONCAT_WS(', ', COLLECT_LIST(entity_name)) AS companies
FROM edgar.all_companies_profile_table
GROUP BY major_group, major_group_desc
HAVING COUNT(*) > 1;

-- 4. Profile + latest available revenue per company -- the actual
-- cross-script join (this file's profiles + 01_edgar_company_facts.sql's
-- revenue facts), demonstrating the full "advanced data product." See
-- caveat 2 -- "latest" is the latest value under the us-gaap:Revenues tag
-- specifically, which may be stale for some companies:
-- Note: each side of every pair below is guaranteed exactly one row (the
-- profile view is scoped to a single company; the subquery is LIMIT 1),
-- so a plain comma cross join is safe and correct here -- used instead of
-- CROSS JOIN or JOIN...ON TRUE, neither of which appears in Zetaris's own
-- documented join_type grammar (INNER | (LEFT|RIGHT) SEMI |
-- (LEFT|RIGHT|FULL) [OUTER] | [LEFT] ANTI -- see the SQL Manual's "3.
-- JOIN" section); the comma-join form IS documented there ("Joining
-- multiple data sources").
SELECT p.entity_name, p.division_desc, p.industry_group_desc, f.fiscal_year, f.value_usd AS latest_revenue_usd
FROM edgar.apple_profile_table p, (SELECT * FROM edgar.apple_revenue_table ORDER BY period_end DESC LIMIT 1) f
UNION ALL
SELECT p.entity_name, p.division_desc, p.industry_group_desc, f.fiscal_year, f.value_usd AS latest_revenue_usd
FROM edgar.ibm_profile_table p, (SELECT * FROM edgar.ibm_revenue_table ORDER BY period_end DESC LIMIT 1) f
UNION ALL
SELECT p.entity_name, p.division_desc, p.industry_group_desc, f.fiscal_year, f.value_usd AS latest_revenue_usd
FROM edgar.oracle_profile_table p, (SELECT * FROM edgar.oracle_revenue_table ORDER BY period_end DESC LIMIT 1) f
UNION ALL
SELECT p.entity_name, p.division_desc, p.industry_group_desc, f.fiscal_year, f.value_usd AS latest_revenue_usd
FROM edgar.walmart_profile_table p, (SELECT * FROM edgar.walmart_revenue_table ORDER BY period_end DESC LIMIT 1) f
UNION ALL
SELECT p.entity_name, p.division_desc, p.industry_group_desc, f.fiscal_year, f.value_usd AS latest_revenue_usd
FROM edgar.target_profile_table p, (SELECT * FROM edgar.target_revenue_table ORDER BY period_end DESC LIMIT 1) f
UNION ALL
SELECT p.entity_name, p.division_desc, p.industry_group_desc, f.fiscal_year, f.value_usd AS latest_revenue_usd
FROM edgar.ford_profile_table p, (SELECT * FROM edgar.ford_revenue_table ORDER BY period_end DESC LIMIT 1) f
UNION ALL
SELECT p.entity_name, p.division_desc, p.industry_group_desc, f.fiscal_year, f.value_usd AS latest_revenue_usd
FROM edgar.tesla_profile_table p, (SELECT * FROM edgar.tesla_revenue_table ORDER BY period_end DESC LIMIT 1) f
ORDER BY latest_revenue_usd DESC;

-- 5. Same latest-revenue figures, ranked within division via a window
-- function (the standard "top row per group" pattern used throughout
-- this package) -- run query 4 first and wrap it, or persist query 4 as
-- a view if you want to reuse it (not done here to keep this script's
-- object count minimal):
-- SELECT *, RANK() OVER (PARTITION BY division_desc ORDER BY latest_revenue_usd DESC) AS rank_in_division
-- FROM (<query 4 above>) q4
-- ORDER BY division_desc, rank_in_division;

-- 6. Industry-group detail for every company -- a finer cut than query 2,
-- useful for spotting which companies are actually close industry peers
-- versus just sharing a broad division (same COLLECT_LIST/CONCAT_WS
-- caveat as query 3):
SELECT industry_group, industry_group_desc, division_desc,
       CONCAT_WS(', ', COLLECT_LIST(entity_name)) AS companies
FROM edgar.all_companies_profile_table
GROUP BY industry_group, industry_group_desc, division_desc
ORDER BY division_desc, industry_group;

-- 7. Every company's full SIC code and its plain-English unpacking,
-- alphabetized by division then major group -- a readable "industry
-- directory" view of the 7 companies, the kind of output a downstream
-- consumer of this data product would actually want to see:
SELECT division_desc, major_group_desc, industry_group_desc, entity_name, sic_code, sic_description_edgar
FROM edgar.all_companies_profile_table
ORDER BY division_desc, major_group_desc, industry_group_desc, entity_name;

-- 8. Data-quality cross-check -- confirms EDGAR's own sicDescription
-- agrees with company_dns's reference description for every one of the 7
-- companies. Expect ZERO rows back -- any row returned would mean the
-- two sources disagree on what a given SIC code means, worth
-- investigating before trusting either source further:
SELECT entity_name, sic_code, sic_description_edgar, sic_description_reference
FROM edgar.all_companies_profile_table
WHERE sic_description_edgar <> sic_description_reference;

-- =============================================================================
-- MANUAL STEP -- Virtual Data Mart (no SQL equivalent exists; confirmed,
-- docs/plans/edgar-sic-enrichment-plan.md sec 5.3). Build this by hand in
-- the Zetaris UI's Virtual Data Mart tab once every view above is
-- verified. Walkthrough (matches the kbase's own documented steps,
-- "Processes for Automation: Virtual Data Mart creation / deletion"):
--
--   1. Go to the Virtual Data Mart tab (left nav, under Data Product in
--      the newer UI / "Virtual Data Mart" in the older Using Zetaris nav).
--   2. Click the "+" button next to Data Marts.
--   3. Name it something like "EDGAR Company Profiles" and give it a
--      short description (e.g. "SIC-enriched company profiles + revenue,
--      7 companies -- see docs/plans/edgar-sic-enrichment-plan.md"), then
--      click Create.
--   4. The middle pane becomes a drag-and-drop canvas. From the left
--      panel's data source tree, drag in:
--        - edgar.all_companies_profile_table (the main deliverable)
--        - edgar.apple_revenue_table, ibm_revenue_table, ... (optional --
--          only if you want raw per-company revenue history alongside
--          the profile, rather than just the query-4-style latest figure)
--        - company_dns.sic_codes_table (optional -- lets a VDM consumer
--          drill into the full 1,005-code reference without needing a
--          second data mart)
--   5. Relationships between the dragged-in tables are optional (per the
--      kbase's own guidance) and NOT recommended here: recall caveat 1 --
--      the revenue tables' cik is a bare integer while the profile
--      view's cik came from a zero-padded string source; even though
--      they represent the same company, Zetaris has no reason to know
--      that unless you rename/cast a column, and a naive drag-to-relate
--      on a mismatched-format cik would likely fail silently or produce
--      no matches. If you want a real relationship line in the VDM
--      canvas, rename one side's column (e.g. alias the profile view's
--      cik) and confirm the values actually line up in a preview first.
--   6. Click "Save changes" in the top right.
--   7. The VDM is now a reusable, named entry point -- share it with
--      other users/roles per the kbase's User Management docs rather
--      than requiring them to know the underlying edgar.* view names.
--
-- To update it later: reopen the Virtual Data Mart tab, click the
-- existing "EDGAR Company Profiles" mart in the left list, and drag
-- additional tables in (or use "Clear model" to start over) -- same
-- canvas, no need to recreate it.
-- =============================================================================

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
-- as 01_edgar_company_facts.sql's own REST tables.
