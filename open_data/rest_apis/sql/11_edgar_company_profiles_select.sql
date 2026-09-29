-- =============================================================================
-- Verification / example queries for 11_edgar_company_profiles_create.sql
-- Assumes 11_edgar_company_profiles_create.sql has already been run.
--
-- The verification queries below are commented out by default so that
-- running this whole file doesn't automatically fire read queries against
-- every view. Uncomment what you want to run, or run it directly in the
-- SQL Editor. The example queries further down are left live, same as
-- before.
-- =============================================================================

-- === Verification ===
-- Verify each profile individually before combining them (same discipline
-- as every other multi-record source in this package). Each should return
-- exactly 1 row. sic_description_edgar and sic_description_reference
-- should match for every company (both trace back to the same underlying
-- SEC SIC list) -- query 8 below checks this programmatically instead of
-- eyeballing all 7.
-- SELECT * FROM edgar.apple_profile_table;
-- SELECT * FROM edgar.ibm_profile_table;
-- SELECT * FROM edgar.oracle_profile_table;
-- SELECT * FROM edgar.walmart_profile_table;
-- SELECT * FROM edgar.target_profile_table;
-- SELECT * FROM edgar.ford_profile_table;
-- SELECT * FROM edgar.tesla_profile_table;

-- SELECT COUNT(*) FROM edgar.all_companies_profile_table;   -- expect 7

-- === Example queries ===
-- Run against all_companies_profile_table (and, for query 4, the existing
-- per-company revenue tables from 01_edgar_company_facts_create.sql).
-- Picked to exercise the actual payoff of this plan: a readable industry
-- profile per company, peer-grouping by classification, and a join back
-- to financial data.

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
-- COLLECT_LIST/CONCAT_WS as an aggregate-to-string pattern are standard
-- Spark SQL but unconfirmed against this Zetaris instance -- no earlier
-- script in this package has used them. If either errors, fall back to
-- GROUP_CONCAT(entity_name) (if supported) or drop the `companies`
-- column and just look up which companies matched via query 1:
SELECT major_group, major_group_desc, COUNT(*) AS company_count,
       CONCAT_WS(', ', COLLECT_LIST(entity_name)) AS companies
FROM edgar.all_companies_profile_table
GROUP BY major_group, major_group_desc
HAVING COUNT(*) > 1;

-- 4. Profile + latest available revenue per company -- the actual
-- cross-script join (this file's profiles +
-- 01_edgar_company_facts_create.sql's revenue facts), demonstrating the
-- full "advanced data product." See caveat 2 in the create script --
-- "latest" is the latest value under the us-gaap:Revenues tag
-- specifically, which may be stale for some companies:
-- Each side of every pair below is guaranteed exactly one row (the
-- profile view is scoped to a single company; the subquery is LIMIT 1),
-- so a plain comma cross join is safe and correct here -- used instead
-- of CROSS JOIN or JOIN...ON TRUE, neither of which appears in
-- Zetaris's own documented join_type grammar (INNER | (LEFT|RIGHT)
-- SEMI | (LEFT|RIGHT|FULL) [OUTER] | [LEFT] ANTI -- see the SQL
-- Manual's "3. JOIN" section); the comma-join form is documented there
-- ("Joining multiple data sources").
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

-- 6. Industry-group detail for every company -- a finer cut than
-- query 2, useful for spotting which companies are actually close
-- industry peers versus just sharing a broad division (same
-- COLLECT_LIST/CONCAT_WS caveat as query 3):
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
-- agrees with company_dns's reference description for every one of the
-- 7 companies. Expect zero rows back -- any row returned would mean the
-- two sources disagree on what a given SIC code means, worth
-- investigating before trusting either source further:
SELECT entity_name, sic_code, sic_description_edgar, sic_description_reference
FROM edgar.all_companies_profile_table
WHERE sic_description_edgar <> sic_description_reference;

-- =============================================================================
-- Manual step -- Virtual Data Mart (no SQL equivalent exists). Build
-- this by hand in the Zetaris UI's Virtual Data Mart tab once every
-- view above is verified. Walkthrough (matches the kbase's own
-- documented steps, "Processes for Automation: Virtual Data Mart
-- creation / deletion"):
--
--   1. Go to the Virtual Data Mart tab (left nav, under Data Product in
--      the newer UI / "Virtual Data Mart" in the older Using Zetaris nav).
--   2. Click the "+" button next to Data Marts.
--   3. Name it something like "EDGAR Company Profiles" and give it a
--      short description (e.g. "SIC-enriched company profiles and
--      revenue, 7 companies"), then click Create.
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
--      kbase's own guidance) and not recommended here: recall caveat 1 in
--      the create script -- the revenue tables' cik is a bare integer
--      while the profile view's cik came from a zero-padded string
--      source; even though they represent the same company, Zetaris has
--      no reason to know that unless you rename/cast a column, and a
--      naive drag-to-relate on a mismatched-format cik would likely fail
--      silently or produce no matches. If you want a real relationship
--      line in the VDM canvas, rename one side's column (e.g. alias the
--      profile view's cik) and confirm the values actually line up in a
--      preview first.
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
