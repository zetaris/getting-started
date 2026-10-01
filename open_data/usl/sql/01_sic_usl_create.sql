-- =============================================================================
-- USL: sic_usl -- a single-table Unified Semantic Layer model over the same
-- company_dns SIC hierarchy reference data already onboarded via REST in
-- open_data/rest_apis/sql/non_rate_limited/10_company_dns_sic_create.sql.
--
-- Purpose: the baseline USL model -- confirms the namespace/COMPILE/
-- ACTIVATE/DQ/MATERIALIZE lifecycle works before the two-table, FK-related
-- sic_edgar_usl (02_sic_edgar_usl_create.sql). Kept alongside, not instead
-- of, sql/10's CREATE SCHEMASTORE VIEW version -- see ../HOWTO.md for why
-- both exist.
--
-- Source: Unified Semantic Layer (USL) User Guide, sections 3-11 and
-- Appendix B (supplied alongside this repo; no dedicated Kbase page found --
-- see docs/guides/zetaris-sql-companion.md section 0).
--
-- Prerequisite: open_data/rest_apis/sql/non_rate_limited/10_company_dns_sic_create.sql,
-- Steps 0-1 only (through CACHE TABLE company_dns.sic_codes_raw;), must
-- already have been run on this instance -- this script activates directly
-- from that raw REST table rather than re-registering the company_dns
-- endpoint under USL.
--
-- Verification status: see ../usl-sources.md. The lifecycle through
-- ACTIVATE is confirmed working. The self-consistency check in Step 4 is
-- confirmed not expressible as a REGISTER DQ rule on this table -- see
-- docs/guides/zetaris-sql-companion.md section 8.6 for why -- and runs
-- instead as a plain query in 01_sic_usl_select.sql. RUN DQ (the PK
-- constraint's auto-generated rule) has not yet been confirmed to pass.
--
-- Caveats:
--   1. COMPILE USL IF NOT EXISTS's idempotency on a second run is
--      unconfirmed (docs/guides/zetaris-sql-companion.md section 8.4) --
--      comment out the CREATE NAMESPACE / COMPILE USL statements on a
--      re-run if either turns out not to tolerate being re-run cleanly.
--   2. The namespace layout in Step 0 is a first draft, not a settled
--      convention -- see that step's comment.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Step 0: namespace for this package's USLs. Shared with
-- 02_sic_edgar_usl_create.sql -- only run this once across both scripts on
-- a given instance (see caveat 1 above re: idempotency).
--
-- This flat layout is a first draft, not a settled convention -- a nested,
-- per-source alternative (CREATE NAMESPACE IF NOT EXISTS
-- lightning.metastore.company_dns.sic_usl;) hasn't been compared against it
-- live yet. Update this statement and every lightning.metastore.usl_demo
-- reference below if a later comparison shows the nested form is
-- preferable.
-- ---------------------------------------------------------------------------
CREATE NAMESPACE IF NOT EXISTS lightning.metastore.usl_demo;

-- ---------------------------------------------------------------------------
-- Step 1: design the table (DDL only, no data yet -- the card renders grey
-- until Step 3's ACTIVATE). Column set matches sql/10's sic_codes_table
-- view exactly, so the two can be compared row for row.
-- ---------------------------------------------------------------------------
COMPILE USL IF NOT EXISTS sic_usl DEPLOY NAMESPACE lightning.metastore.usl_demo DDL
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

-- ---------------------------------------------------------------------------
-- Step 2: document the model (optional but cheap -- exercises UPDATE USL
-- ... SET DESCRIPTION per the guide section 11).
-- ---------------------------------------------------------------------------
UPDATE USL lightning.metastore.usl_demo.sic_usl SET DESCRIPTION 'Baseline USL model - SIC hierarchy reference, single table, no relationships. Contrast target for company_dns.sic_codes_table (open_data/rest_apis/sql/non_rate_limited/10_company_dns_sic_create.sql).';

-- ---------------------------------------------------------------------------
-- Step 3: activate -- reuses sql/10's exact flattening query verbatim (same
-- from_json(to_json(...), 'map<string, struct<...>>') coercion technique,
-- unaffected by the USL wrapper -- see docs/guides/zetaris-sql-companion.md
-- section 3 and section 8.1). This is the schema-validation test: the
-- SELECT's output columns/types must match the CREATE TABLE above or
-- ACTIVATE should report a mismatch (per the USL User Guide section 6.1).
-- See 01_sic_usl_select.sql for the row-count verification query.
-- ---------------------------------------------------------------------------
ACTIVATE USL TABLE lightning.metastore.usl_demo.sic_usl.sic_code AS
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
-- Step 4: self-consistency check -- does every SIC code under the same
-- major_group agree on that major_group's description? Not expressible as
-- a REGISTER DQ rule on this table -- see
-- docs/guides/zetaris-sql-companion.md section 8.6 for the confirmed
-- limitations that rule it out. The check runs instead as a plain
-- aggregate query in 01_sic_usl_select.sql (the same shape as sql/10
-- query 8).
-- ---------------------------------------------------------------------------

-- Run the PK constraint's auto-generated rule (the only DQ rule registered
-- on this table):
RUN DQ TABLE lightning.metastore.usl_demo.sic_usl.sic_code;

-- Expect: total_records = 1005, valid_records = 1005, invalid_records = 0.

-- ---------------------------------------------------------------------------
-- Step 5: materialize -- deferred (docs/plans/archive/usl-build-plan.md step V4).
-- No cloud storage target is configured on any instance this repo has
-- touched yet, and standing one up is out of scope for now. Left here,
-- commented out, for whenever that's unblocked: Records: All (no DQ
-- gating needed for "All", per the USL User Guide section 10.1 -- "Valid
-- Records Only" is what requires a DQ rule to already exist, exercised
-- instead in 02_sic_edgar_usl_create.sql step V7). Adjust
-- CLOUD_STORAGE_TARGET to a configured storage setting on the target
-- instance before running.
-- ---------------------------------------------------------------------------
-- MATERIALIZE USL TABLE lightning.metastore.usl_demo.sic_usl.sic_code
--   TO STORAGE (format='parquet', path='/materialized/usl_demo/sic_code');

-- =============================================================================
-- TEARDOWN -- commented out by default. Unlike open_data/rest_apis and
-- open_data/parquet_csv, USL documents a real SQL removal path (REMOVE USL,
-- DROP NAMESPACE ... CASCADE) with no GUI-only step -- but this is itself
-- unconfirmed live (plan V10). DROP NAMESPACE ... CASCADE also removes
-- 02_sic_edgar_usl_create.sql's USL if it shares this namespace -- don't
-- run it until both scripts' testing is actually done.
-- =============================================================================

-- REMOVE USL sic_usl NAMESPACE lightning.metastore.usl_demo;
-- DROP NAMESPACE lightning.metastore.usl_demo CASCADE;
