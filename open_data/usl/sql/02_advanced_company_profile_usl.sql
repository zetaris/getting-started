-- =============================================================================
-- USL:      company_profile_usl -- a two-table, FK-related Unified Semantic
--           Layer model rebuilding the SAME "EDGAR company profile enriched
--           with SIC hierarchy" data product as
--           open_data/rest_apis/sql/11_edgar_company_profiles.sql, but
--           using USL's CREATE TABLE + FOREIGN KEY + ACTIVATE + DQ +
--           MATERIALIZE lifecycle instead of sql/11's flat UNION ALL views
--           plus a manually-built, SQL-free Virtual Data Mart.
-- Purpose:  The actual "contrast" artifact requested -- same 7 companies,
--           same join, different mechanism. See ../HOWTO.md sec 3 for the
--           specific question this script exists to test: does the FK
--           relationship's auto-generated DQ rule replace sql/11 query 8's
--           hand-written description-agreement check, or only partially?
-- Source:   Unified Semantic Layer (USL) User Guide, secs 4, 6, 8, 10-11
--           and Appendix B (supplied alongside this repo; no dedicated
--           Kbase page found as of 2026-09-23 -- see
--           docs/guides/zetaris-sql-companion.md sec 0).
-- Prerequisite: open_data/rest_apis/sql/11_edgar_company_profiles.sql,
--           Step 0 and the seven CREATE LIGHTNING REST TABLE
--           <company>_submissions_raw statements only -- the
--           CREATE SCHEMASTORE VIEW statements in that script are NOT
--           needed here (this script activates directly from the raw
--           tables). open_data/rest_apis/sql/10_company_dns_sic.sql Steps
--           0-1 must also already be run (same company_dns.sic_codes_raw
--           dependency as 01_simple_sic_usl.sql).
--   Run 01_simple_sic_usl.sql first if this is a fresh instance -- it
--   creates lightning.metastore.usl_demo (shared by this script) and is
--   the lower-risk smoke test for the USL lifecycle this script builds on.
-- =============================================================================
--
-- NOT YET LIVE-TESTED against Zetaris (written 2026-09-23), the same
-- caveat as sql/11_edgar_company_profiles.sql carried before its own first
-- live run. See docs/plans/usl-simple-advanced-build-plan.md sec 4
-- (V5-V8 cover this script specifically) and update that plan plus
-- docs/guides/zetaris-sql-companion.md sec 8 once it has been run.
--
-- Caveats (flagged in advance, not yet confirmed either way):
--   1. sic_code IS DUPLICATED FROM sic_usl, DELIBERATELY, NOT AN OVERSIGHT.
--      The USL User Guide's FOREIGN KEY ... REFERENCES example only shows
--      a same-DDL-block reference (department(id), defined in the same
--      CREATE TABLE batch) -- whether a FK can target a table in a
--      DIFFERENT USL (i.e., company_profile_usl.company referencing
--      sic_usl.sic_code across USL boundaries) is UNCONFIRMED. This script
--      defines its own copy of sic_code inside company_profile_usl rather
--      than assuming cross-USL FKs work. If a live test confirms
--      cross-USL FKs DO work, this duplication should be removed and
--      recorded as a correction the same way sql/10-era assumptions have
--      been corrected elsewhere in this repo.
--   2. cik FORMAT MISMATCH -- SIDESTEPPED THE SAME WAY sql/11 SIDESTEPPED
--      IT, NOT FIXED. company.cik below is typed to match the zero-padded
--      10-digit STRING shape from the submissions endpoint (the only shape
--      this script uses) -- this script never joins against sql/01's
--      revenue tables, where cik is a bare integer (see sql/11 caveat 1
--      for the full mismatch). A future USL extension joining company
--      to revenue data would need to resolve that format difference first
--      (e.g. normalize both sides to the same padded-string form before
--      declaring a FOREIGN KEY on cik across that boundary).
--   3. MATERIALIZE'S "Valid Records Only" HAS NO CONFIRMED SQL SYNTAX.
--      The USL User Guide's own Appendix B SQL example for MATERIALIZE
--      shows only format/path options -- the "Records: All / Valid
--      Records Only" choice is documented only in the GUI's Configure
--      Materialization dialog (guide sec 10.1). STEP 6 below is written
--      as a best-effort SQL attempt with a commented alternative pointing
--      at the GUI path -- if the SQL form doesn't support this option,
--      that's a second VDM-shaped "GUI-only" gap in USL worth recording in
--      docs/guides/zetaris-sql-companion.md sec 8.4 (see ../HOWTO.md sec 4).
--   4. THE FK-VS-CUSTOM-DQ QUESTION IS THE POINT OF THIS SCRIPT, NOT A
--      SIDE CAVEAT. See ../HOWTO.md sec 3 -- STEP 5's custom
--      sic_description_agrees rule is written on the WORKING HYPOTHESIS
--      that the FK constraint's auto-generated rule only proves
--      referential existence (a company's sic value exists in sic_code),
--      not description-string equality, so the custom rule stays
--      necessary. Confirm or refute this live (plan step V6) rather than
--      assuming the hypothesis is correct just because it's documented
--      here first.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- STEP 0: namespace -- shared with 01_simple_sic_usl.sql. Comment out if
-- that script already created it on this instance (see that script's
-- caveat 1 re: IF NOT EXISTS idempotency, unconfirmed either way).
--
-- SAME FIRST-DRAFT CAVEAT AS 01_simple_sic_usl.sql'S STEP 0: this flat
-- layout is not a settled convention. If
-- docs/plans/usl-simple-advanced-build-plan.md step V0 picks the nested
-- alternative instead, update this statement and every
-- lightning.metastore.usl_demo reference below to match.
-- ---------------------------------------------------------------------------
CREATE NAMESPACE IF NOT EXISTS lightning.metastore.usl_demo;

-- ---------------------------------------------------------------------------
-- STEP 1: design -- two tables, one FK relationship. sic below is declared
-- NOT NULL (every one of the 7 companies' submissions responses is
-- confirmed to carry a sic value, per docs/plans/edgar-sic-enrichment-plan.md
-- sec 3) so the FK's auto-generated DQ rule has something to check on every
-- row, not just the rows that happen to have a value.
-- ---------------------------------------------------------------------------
COMPILE USL IF NOT EXISTS company_profile_usl DEPLOY NAMESPACE lightning.metastore.usl_demo DDL
CREATE TABLE sic_code (
  sic_code            varchar(4) NOT NULL PRIMARY KEY,
  description         varchar(200),
  division            varchar(1),
  division_desc       varchar(200),
  major_group         varchar(2),
  major_group_desc    varchar(200),
  industry_group      varchar(3),
  industry_group_desc varchar(200)
);

CREATE TABLE company (
  cik                   varchar(10) NOT NULL PRIMARY KEY,
  entity_name           varchar(200) NOT NULL,
  sic                   varchar(4) NOT NULL FOREIGN KEY REFERENCES sic_code(sic_code),
  sic_description_edgar varchar(200)
);

-- ---------------------------------------------------------------------------
-- STEP 2: document the model.
-- ---------------------------------------------------------------------------
UPDATE USL lightning.metastore.usl_demo.company_profile_usl SET DESCRIPTION 'USL rebuild of the EDGAR plus SIC company profile data product - 7 companies, FK-related to a SIC hierarchy table. Contrast target for edgar.all_companies_profile_table and its manual Virtual Data Mart (open_data/rest_apis/sql/11_edgar_company_profiles.sql).';
UPDATE USL lightning.metastore.usl_demo.company_profile_usl.company SET TABLE DESCRIPTION 'One row per company - CIK, name, and SIC code as reported by EDGAR''s own submissions endpoint.';
UPDATE USL lightning.metastore.usl_demo.company_profile_usl.sic_code SET TABLE DESCRIPTION 'SIC hierarchy reference - same content as sic_usl.sic_code, duplicated here per caveat 1 above pending confirmation of cross-USL foreign keys.';

-- ---------------------------------------------------------------------------
-- STEP 3: activate sic_code -- identical activation query to
-- 01_simple_sic_usl.sql (see that script for the technique notes).
-- ---------------------------------------------------------------------------
ACTIVATE USL TABLE lightning.metastore.usl_demo.company_profile_usl.sic_code AS
SELECT
    sic_code,
    sic_val.description         AS description,
    sic_val.division             AS division,
    sic_val.division_desc        AS division_desc,
    sic_val.major_group          AS major_group,
    sic_val.major_group_desc     AS major_group_desc,
    sic_val.industry_group       AS industry_group,
    sic_val.industry_group_desc  AS industry_group_desc
FROM company_dns.sic_codes_raw
LATERAL VIEW explode(
    from_json(to_json(data.sics), 'map<string, struct<description:string, division:string, division_desc:string, major_group:string, major_group_desc:string, industry_group:string, industry_group_desc:string>>')
) AS sic_code, sic_val;

SELECT COUNT(*) FROM lightning.metastore.usl_demo.company_profile_usl.sic_code;   -- expect 1005

-- ---------------------------------------------------------------------------
-- STEP 4: activate company -- a SINGLE activation query UNIONing all 7
-- companies' raw submissions tables, replacing sql/11's two-layer
-- per-company-view + separate UNION ALL view with one statement. These
-- are plain scalar fields (cik, name, sic, sicDescription) with no
-- explode() involved -- see sql/11's own header note that the submissions
-- endpoint is a flat top-level object for the fields used here -- so this
-- does NOT hit the MISSING_ATTRIBUTES self-join class of error that
-- affects UNION ALL of explode()-based views
-- (docs/guides/zetaris-sql-companion.md sec 4); flagged here as a reason
-- this particular UNION ALL is lower-risk than that general warning, not
-- as a certainty until confirmed live.
-- ---------------------------------------------------------------------------
ACTIVATE USL TABLE lightning.metastore.usl_demo.company_profile_usl.company AS
SELECT cik, name AS entity_name, sic, `sicDescription` AS sic_description_edgar FROM sec_data.apple_submissions_raw
UNION ALL
SELECT cik, name AS entity_name, sic, `sicDescription` AS sic_description_edgar FROM sec_data.ibm_submissions_raw
UNION ALL
SELECT cik, name AS entity_name, sic, `sicDescription` AS sic_description_edgar FROM sec_data.oracle_submissions_raw
UNION ALL
SELECT cik, name AS entity_name, sic, `sicDescription` AS sic_description_edgar FROM sec_data.walmart_submissions_raw
UNION ALL
SELECT cik, name AS entity_name, sic, `sicDescription` AS sic_description_edgar FROM sec_data.target_submissions_raw
UNION ALL
SELECT cik, name AS entity_name, sic, `sicDescription` AS sic_description_edgar FROM sec_data.ford_submissions_raw
UNION ALL
SELECT cik, name AS entity_name, sic, `sicDescription` AS sic_description_edgar FROM sec_data.tesla_submissions_raw;

SELECT COUNT(*) FROM lightning.metastore.usl_demo.company_profile_usl.company;   -- expect 7

-- ---------------------------------------------------------------------------
-- STEP 5: Data Quality. Two rules:
--   (a) the FK on company.sic -> sic_code.sic_code should already be
--       auto-generated per the USL User Guide sec 8.1's constraint table --
--       nothing to write, just RUN DQ and confirm it exists and passes.
--   (b) a custom rule for the thing a bare FK cannot express: do the two
--       independently-sourced description strings actually agree, not just
--       does the code exist. This is sql/11 query 8's check, rewritten as
--       a per-row correlated subquery (REGISTER DQ takes a boolean
--       expression evaluated per record, not an aggregate WHERE clause).
-- ---------------------------------------------------------------------------
REGISTER DQ sic_description_agrees TABLE lightning.metastore.usl_demo.company_profile_usl.company AS
sic_description_edgar = (
    SELECT description
    FROM lightning.metastore.usl_demo.company_profile_usl.sic_code
    WHERE sic_code = company.sic
);

RUN DQ TABLE lightning.metastore.usl_demo.company_profile_usl.company;

-- Expect: the auto-generated FK rule reports total_records=7,
-- valid_records=7 (every company's sic exists in sic_code -- same
-- guarantee sql/11's INNER JOIN provided by construction). Expect
-- sic_description_agrees to ALSO report 7/7 valid, matching sql/11 query
-- 8's own "expect zero rows back" result -- if the FK rule alone had
-- already reported 7/7, that would NOT by itself prove description
-- agreement; only a divergence between the two rules' pass/fail record
-- sets would demonstrate the FK rule is insufficient on its own. Record
-- the actual comparison in docs/plans/usl-simple-advanced-build-plan.md
-- step V6, not just "both passed."

-- ---------------------------------------------------------------------------
-- STEP 6: materialize -- DEFERRED (docs/plans/usl-simple-advanced-build-plan.md
-- step V7). No cloud storage target is configured on any instance this
-- repo has touched yet, and standing one up is out of scope for now. Left
-- here, commented out, for whenever that's unblocked: Records: Valid
-- Records Only, which per the USL User Guide sec 10.1 requires at least
-- one DQ rule to already exist on the table (both rules from Step 5
-- qualify). See caveat 3 above -- the SQL form's support for this option
-- is unconfirmed; try this first, fall back to the GUI's Configure
-- Materialization dialog if it's rejected or silently ignored (compare row
-- counts before/after to tell the difference -- see ../HOWTO.md sec 4).
-- ---------------------------------------------------------------------------
-- MATERIALIZE USL TABLE lightning.metastore.usl_demo.company_profile_usl.company
--   TO STORAGE (format='parquet', path='/materialized/usl_demo/company', records='valid');
-- -- If 'records' is not accepted, try the plain form and use the GUI's
-- -- Configure Materialization dialog for the Valid Records Only choice
-- -- instead:
-- -- MATERIALIZE USL TABLE lightning.metastore.usl_demo.company_profile_usl.company
-- --   TO STORAGE (format='parquet', path='/materialized/usl_demo/company');

-- ---------------------------------------------------------------------------
-- STEP 7: contrast query -- compare against the existing manual VDM
-- built in sql/11 (companies_mart, per that script's trailing walkthrough
-- and docs/guides/zetaris-sql-companion.md sec 7's confirmed flat
-- <mart>.<table> query syntax). Both should return the same 7 rows;
-- record any difference (row count, column values, timing) rather than
-- assuming they match:
-- ---------------------------------------------------------------------------
SELECT entity_name, sic, sic_description_edgar
FROM lightning.metastore.usl_demo.company_profile_usl.company
ORDER BY entity_name;
-- Compare against:
-- SELECT entity_name, sic_code, sic_description_edgar FROM companies_mart.all_companies_profile_table ORDER BY entity_name;

-- =============================================================================
-- TEARDOWN -- commented out by default. See 01_simple_sic_usl.sql's
-- TEARDOWN block for the same caveat re: DROP NAMESPACE ... CASCADE
-- affecting both scripts if they share lightning.metastore.usl_demo.
-- =============================================================================

-- REMOVE USL company_profile_usl NAMESPACE lightning.metastore.usl_demo;
-- DROP NAMESPACE lightning.metastore.usl_demo CASCADE;
