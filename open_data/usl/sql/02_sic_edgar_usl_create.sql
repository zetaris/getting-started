-- =============================================================================
-- USL: sic_edgar_usl -- a two-table, FK-related Unified Semantic Layer
-- model rebuilding the same "EDGAR company profile enriched with SIC
-- hierarchy" data product as
-- open_data/rest_apis/sql/rate_limited/11_edgar_company_profiles_create.sql,
-- but using USL's CREATE TABLE + FOREIGN KEY + ACTIVATE + DQ + MATERIALIZE
-- lifecycle instead of sql/11's flat UNION ALL views plus a manually-built,
-- SQL-free Virtual Data Mart.
--
-- Purpose: the actual contrast artifact -- same 7 companies, same join,
-- different mechanism. See ../HOWTO.md section 3 for the specific question
-- this script exists to test: does the FK relationship's auto-generated DQ
-- rule replace sql/11 query 8's hand-written description-agreement check,
-- or only partially?
--
-- Source: Unified Semantic Layer (USL) User Guide, sections 4, 6, 8, 10-11
-- and Appendix B (supplied alongside this repo; no dedicated Kbase page
-- found -- see docs/guides/zetaris-sql-companion.md section 0).
--
-- Prerequisite: open_data/rest_apis/sql/rate_limited/11_edgar_company_profiles_create.sql,
-- Step 0 and the seven CREATE LIGHTNING REST TABLE <company>_submissions_raw
-- statements only -- the CREATE SCHEMASTORE VIEW statements in that script
-- are not needed here (this script activates directly from the raw
-- tables). open_data/rest_apis/sql/non_rate_limited/10_company_dns_sic_create.sql
-- Steps 0-1 must also already be run (same company_dns.sic_codes_raw
-- dependency as 01_sic_usl_create.sql).
--   Run 01_sic_usl_create.sql first if this is a fresh instance -- it
--   creates lightning.metastore.usl_demo (shared by this script) and is
--   the lower-risk smoke test for the USL lifecycle this script builds on.
--
-- Verification status: see ../usl-sources.md. The lifecycle through Step 4
-- is confirmed working (after a null-handling fix, commit 8f18f4f). The
-- description-agreement check in Step 5 is not registered as a REGISTER DQ
-- rule -- two attempts failed live (see
-- docs/guides/zetaris-sql-companion.md section 8.6) -- and runs instead as
-- a plain join query in 02_sic_edgar_usl_select.sql.
--
-- Caveats:
--   1. sic_code is duplicated from sic_usl, deliberately, not an oversight.
--      The USL User Guide's FOREIGN KEY ... REFERENCES example only shows
--      a same-DDL-block reference (department(id), defined in the same
--      CREATE TABLE batch) -- whether a FK can target a table in a
--      different USL (i.e. sic_edgar_usl.company referencing
--      sic_usl.sic_code across USL boundaries) is unconfirmed. This script
--      defines its own copy of sic_code inside sic_edgar_usl rather than
--      assuming cross-USL FKs work. If a live test confirms cross-USL FKs
--      do work, this duplication should be removed.
--   2. cik format mismatch, sidestepped the same way
--      sql/11_edgar_company_profiles_create.sql sidestepped it, not fixed.
--      company.cik below is typed to match the zero-padded 10-digit STRING
--      shape from the submissions endpoint (the only shape this script
--      uses) -- this script never joins against
--      sql/01_edgar_company_facts_create.sql's revenue tables, where cik
--      is a bare integer (see sql/11_edgar_company_profiles_create.sql
--      caveat 1 for the full mismatch).
--   3. MATERIALIZE's "Valid Records Only" has no confirmed SQL syntax. The
--      USL User Guide's own Appendix B SQL example for MATERIALIZE shows
--      only format/path options -- the "Records: All / Valid Records Only"
--      choice is documented only in the GUI's Configure Materialization
--      dialog (guide section 10.1). Step 6 below is written as a
--      best-effort SQL attempt with a commented alternative pointing at the
--      GUI path.
--   4. The FK-vs-description-agreement question is the point of this
--      script, not a side caveat. Step 5's FK rule only proves referential
--      existence (a company's sic value exists in sic_code), not
--      description-string equality -- 02_sic_edgar_usl_select.sql's plain
--      join query checks the latter directly. Compare the two results
--      (docs/plans/archive/usl-build-plan.md step V6) rather than assuming the FK
--      rule alone is sufficient.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Step 0: namespace -- shared with 01_sic_usl_create.sql. Comment out if
-- that script already created it on this instance (see that script's
-- caveat 1 re: IF NOT EXISTS idempotency, unconfirmed either way).
--
-- Same first-draft caveat as 01_sic_usl_create.sql's Step 0: this flat
-- layout is not a settled convention. If docs/plans/archive/usl-build-plan.md step
-- V0 picks the nested alternative instead, update this statement and every
-- lightning.metastore.usl_demo reference below to match.
-- ---------------------------------------------------------------------------
CREATE NAMESPACE IF NOT EXISTS lightning.metastore.usl_demo;

-- ---------------------------------------------------------------------------
-- Step 1: design -- two tables, one FK relationship. sic below is declared
-- NOT NULL (every one of the 7 companies' submissions responses is
-- confirmed to carry a sic value, per docs/plans/archive/edgar-sic-enrichment-plan.md
-- section 3) so the FK's auto-generated DQ rule has something to check on
-- every row, not just the rows that happen to have a value.
-- ---------------------------------------------------------------------------
COMPILE USL IF NOT EXISTS sic_edgar_usl DEPLOY NAMESPACE lightning.metastore.usl_demo DDL
CREATE TABLE sic_code (
    sic_code varchar(4) NOT NULL PRIMARY KEY,
    description varchar(200),
    division varchar(1),
    division_desc varchar(200),
    major_group varchar(2),
    major_group_desc varchar(200),
    industry_group varchar(3),
    industry_group_desc varchar(200)
);

CREATE TABLE company (
    cik varchar(10) NOT NULL PRIMARY KEY,
    entity_name varchar(200) NOT NULL,
    sic varchar(4) NOT NULL FOREIGN KEY REFERENCES sic_code(sic_code),
    sic_description_edgar varchar(200)
);

-- ---------------------------------------------------------------------------
-- Step 2: document the model.
-- ---------------------------------------------------------------------------
UPDATE USL lightning.metastore.usl_demo.sic_edgar_usl SET DESCRIPTION 'USL rebuild of the EDGAR plus SIC company profile data product - 7 companies, FK-related to a SIC hierarchy table. Contrast target for edgar.all_companies_profile_table and its manual Virtual Data Mart (open_data/rest_apis/sql/rate_limited/11_edgar_company_profiles_create.sql).';
UPDATE USL lightning.metastore.usl_demo.sic_edgar_usl.company SET TABLE DESCRIPTION 'One row per company - CIK, name, and SIC code as reported by EDGAR''s own submissions endpoint.';
UPDATE USL lightning.metastore.usl_demo.sic_edgar_usl.sic_code SET TABLE DESCRIPTION 'SIC hierarchy reference - same content as sic_usl.sic_code, duplicated here per caveat 1 above pending confirmation of cross-USL foreign keys.';

-- ---------------------------------------------------------------------------
-- Step 3: activate sic_code -- identical activation query to
-- 01_sic_usl_create.sql (see that script for the technique notes).
-- ---------------------------------------------------------------------------
ACTIVATE USL TABLE lightning.metastore.usl_demo.sic_edgar_usl.sic_code AS
SELECT
    sic_code,
    sic_val.description AS description,
    sic_val.division AS division,
    sic_val.division_desc AS division_desc,
    sic_val.major_group AS major_group,
    sic_val.major_group_desc AS major_group_desc,
    sic_val.industry_group AS industry_group,
    sic_val.industry_group_desc AS industry_group_desc
FROM company_dns.sic_codes_raw
LATERAL VIEW explode(
    from_json(to_json(data.sics), 'map<string, struct<description:string, division:string, division_desc:string, major_group:string, major_group_desc:string, industry_group:string, industry_group_desc:string>>')
) AS sic_code, sic_val;

-- ---------------------------------------------------------------------------
-- Step 4: activate company -- a single activation query UNIONing all 7
-- companies' raw submissions tables, replacing sql/11's two-layer
-- per-company-view + separate UNION ALL view with one statement. These are
-- plain scalar fields (cik, name, sic, sicDescription) with no explode()
-- involved -- see sql/11's own header note that the submissions endpoint is
-- a flat top-level object for the fields used here -- so this does not hit
-- the MISSING_ATTRIBUTES self-join class of error that affects UNION ALL
-- of explode()-based views (docs/guides/zetaris-sql-companion.md
-- section 4).
-- ---------------------------------------------------------------------------
ACTIVATE USL TABLE lightning.metastore.usl_demo.sic_edgar_usl.company AS
SELECT
    COALESCE(cik, '') AS cik,
    COALESCE(entity_name, '') AS entity_name,
    COALESCE(sic, '') AS sic,
    sic_description_edgar
FROM (
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
    SELECT cik, name AS entity_name, sic, `sicDescription` AS sic_description_edgar FROM sec_data.tesla_submissions_raw
) AS companies;

-- ---------------------------------------------------------------------------
-- Step 5: data quality. The FK on company.sic -> sic_code.sic_code
-- auto-generates a DQ rule (USL User Guide section 8.1's constraint table)
-- -- nothing to write, just RUN DQ and confirm it exists and passes. The
-- description-agreement check (do the two independently-sourced SIC
-- description strings actually agree, not just does the code exist, which
-- is all a bare FK proves) is not registered as a REGISTER DQ rule here --
-- see docs/guides/zetaris-sql-companion.md section 8.6 for why -- and runs
-- instead as a plain join query in 02_sic_edgar_usl_select.sql.
-- ---------------------------------------------------------------------------

-- Run the FK rule (the only DQ rule registered on this table):
RUN DQ TABLE lightning.metastore.usl_demo.sic_edgar_usl.company;

-- Expect: total_records=7, valid_records=7 (every company's sic exists in
-- sic_code -- the same guarantee sql/11's INNER JOIN provided by
-- construction). This alone does not prove description agreement -- see
-- 02_sic_edgar_usl_select.sql for that check, and record the comparison in
-- docs/plans/archive/usl-build-plan.md step V6.

-- ---------------------------------------------------------------------------
-- Step 6: materialize -- deferred (docs/plans/archive/usl-build-plan.md step V7).
-- No cloud storage target is configured on any instance this repo has
-- touched yet, and standing one up is out of scope for now. Left here,
-- commented out, for whenever that's unblocked: Records: Valid Records
-- Only, which per the USL User Guide section 10.1 requires at least one DQ
-- rule to already exist on the table (the FK rule qualifies). See caveat 3
-- above -- the SQL form's support for this option is unconfirmed; try this
-- first, fall back to the GUI's Configure Materialization dialog if it's
-- rejected or silently ignored (compare row counts before/after to tell
-- the difference).
-- ---------------------------------------------------------------------------
-- MATERIALIZE USL TABLE lightning.metastore.usl_demo.sic_edgar_usl.company
--   TO STORAGE (format='parquet', path='/materialized/usl_demo/company', records='valid');
-- -- If 'records' is not accepted, try the plain form and use the GUI's
-- -- Configure Materialization dialog for the Valid Records Only choice
-- -- instead:
-- -- MATERIALIZE USL TABLE lightning.metastore.usl_demo.sic_edgar_usl.company
-- --   TO STORAGE (format='parquet', path='/materialized/usl_demo/company');

-- =============================================================================
-- TEARDOWN -- commented out by default. See 01_sic_usl_create.sql's
-- TEARDOWN block for the same caveat re: DROP NAMESPACE ... CASCADE
-- affecting both scripts if they share lightning.metastore.usl_demo.
-- =============================================================================

-- REMOVE USL sic_edgar_usl NAMESPACE lightning.metastore.usl_demo;
-- DROP NAMESPACE lightning.metastore.usl_demo CASCADE;
