-- =============================================================================
-- USL:      sic_usl -- a single-table Unified Semantic Layer model over the
--           same company_dns SIC hierarchy reference data already onboarded
--           via REST in open_data/rest_apis/sql/non_rate_limited/10_company_dns_sic_create.sql.
-- Purpose:  Lowest-risk USL smoke test -- confirms the basic
--           namespace/COMPILE/ACTIVATE/DQ/MATERIALIZE lifecycle works at all
--           before attempting the two-table, FK-related advanced USL
--           (02_advanced_company_profile_usl.sql). Kept alongside, not
--           instead of, sql/10's CREATE SCHEMASTORE VIEW version -- see
--           ../HOWTO.md for why both exist.
-- Source:   Unified Semantic Layer (USL) User Guide, secs 3-11 and
--           Appendix B (supplied alongside this repo; no dedicated Kbase
--           page found as of 2026-09-23 -- see
--           docs/guides/zetaris-sql-companion.md sec 0).
-- Prerequisite: open_data/rest_apis/sql/non_rate_limited/10_company_dns_sic_create.sql, Steps 0-1
--           only (through CACHE TABLE company_dns.sic_codes_raw;), must
--           already have been run on this instance -- this script activates
--           directly from that raw REST table rather than re-registering
--           the company_dns endpoint under USL.
-- =============================================================================
--
-- NOT YET LIVE-TESTED against Zetaris (written 2026-09-23). Every statement
-- below follows the USL User Guide's documented grammar; none of it has
-- been run. See docs/plans/usl-simple-advanced-build-plan.md sec 4 for the
-- verify checklist (V1-V4 cover this script specifically) and update that
-- plan plus docs/guides/zetaris-sql-companion.md sec 8 once it has been.
--
-- Caveats (flagged in advance, not yet confirmed either way):
--   1. COMPILE USL IF NOT EXISTS's idempotency on a second run is UNTESTED.
--      docs/guides/zetaris-sql-companion.md sec 8.4 flags this by analogy
--      to CREATE SCHEMASTORE CONTAINER, which documents IF NOT EXISTS in
--      its own grammar but does NOT actually support it live (sec 5) --
--      don't assume COMPILE USL's IF NOT EXISTS is safe until V1 confirms
--      it, and comment out the CREATE NAMESPACE / COMPILE USL statements on
--      a re-run if either turns out not to tolerate being re-run cleanly.
--   2. The custom DQ rule below (mirroring sql/10 query 8's aggregate
--      self-consistency check) is written as a correlated subquery boolean
--      expression, since REGISTER DQ per the USL User Guide sec 8.2 takes
--      "any SQL boolean expression" evaluated per record, not an aggregate
--      HAVING clause. Whether a correlated subquery against the SAME
--      activated USL table is supported (as opposed to hitting some
--      variant of the MISSING_ATTRIBUTES self-join class of error
--      documented in docs/guides/zetaris-sql-companion.md sec 4 for
--      SchemaStore views) is UNCONFIRMED -- this table's activation query
--      is NOT itself a UNION ALL of explode()-based views (it's the same
--      from_json/to_json map-decode technique used in sql/10, wrapped in
--      one activation), so that specific error class may not apply here,
--      but this needs a live check (V3), not an assumption.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- STEP 0: namespace for this package's USLs. Shared with
-- 02_advanced_company_profile_usl.sql -- only run this once across both
-- scripts on a given instance (see caveat 1 re: idempotency).
--
-- THIS FLAT LAYOUT IS A FIRST DRAFT, NOT A SETTLED CONVENTION -- per
-- docs/plans/usl-simple-advanced-build-plan.md step V0, run BOTH this flat
-- layout AND a nested, per-source alternative
-- (CREATE NAMESPACE IF NOT EXISTS lightning.metastore.company_dns.sic_usl;)
-- live before treating either as final, and update this statement (and
-- every lightning.metastore.usl_demo reference below) to match whichever
-- one V0's experiment shows is preferable.
-- ---------------------------------------------------------------------------
CREATE NAMESPACE IF NOT EXISTS lightning.metastore.usl_demo;

-- ---------------------------------------------------------------------------
-- STEP 1: design the table (DDL only, no data yet -- card renders grey
-- until Step 3's ACTIVATE). Column set matches sql/10's sic_codes_table
-- view exactly, so the two can be compared row-for-row.
-- ---------------------------------------------------------------------------
COMPILE USL IF NOT EXISTS sic_usl DEPLOY NAMESPACE lightning.metastore.usl_demo DDL
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

-- ---------------------------------------------------------------------------
-- STEP 2: document the model (optional but cheap -- exercises UPDATE USL
-- ... SET DESCRIPTION per the guide sec 11).
-- ---------------------------------------------------------------------------
UPDATE USL lightning.metastore.usl_demo.sic_usl SET DESCRIPTION 'Simple USL smoke test - SIC hierarchy reference, single table, no relationships. Contrast target for company_dns.sic_codes_table (open_data/rest_apis/sql/non_rate_limited/10_company_dns_sic_create.sql).';

-- ---------------------------------------------------------------------------
-- STEP 3: activate -- reuses sql/10's exact flattening query verbatim
-- (same from_json(to_json(...), 'map<string, struct<...>>') coercion
-- technique, unaffected by the USL wrapper -- see
-- docs/guides/zetaris-sql-companion.md sec 3 and sec 8.1). This is the
-- schema-validation test: the SELECT's output columns/types must match the
-- CREATE TABLE above or ACTIVATE should report a mismatch (per the USL
-- User Guide sec 6.1) -- confirm this actually happens on a deliberately
-- broken variant, not just that the correct version succeeds (see plan V2).
-- ---------------------------------------------------------------------------
ACTIVATE USL TABLE lightning.metastore.usl_demo.sic_usl.sic_code AS
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

-- Verify: same expected count as sql/10's sic_codes_table (1005) -- if this
-- differs, the row-count under-reporting bug flagged in
-- docs/guides/zetaris-sql-companion.md sec 5 is a candidate explanation,
-- but check independently (curl against company_dns) before assuming that:
SELECT COUNT(*) FROM lightning.metastore.usl_demo.sic_usl.sic_code;   -- expect 1005

-- ---------------------------------------------------------------------------
-- STEP 4: a custom Data Quality rule -- the per-row correlated-subquery
-- form of sql/10 query 8's aggregate check ("does every SIC code under the
-- same major_group agree on that major_group's description"). See caveat 2
-- above re: whether this correlated-subquery form is actually supported.
-- ---------------------------------------------------------------------------

-- ! Does not work
-- ! org.apache.hive.service.cli.HiveSQLException: Error running query: [INVALID_EXTRACT_BASE_FIELD_TYPE] org.apache.spark.sql.AnalysisException: [INVALID_EXTRACT_BASE_FIELD_TYPE] Can't extract a value from "sic_code". Need a complex type [STRUCT, ARRAY, MAP] but got "STRING".; line 4 pos 27
-- !
REGISTER DQ major_group_desc_consistent TABLE lightning.metastore.usl_demo.sic_usl.sic_code AS
NOT EXISTS (
    SELECT 1
    FROM lightning.metastore.usl_demo.sic_usl.sic_code s2
    WHERE s2.major_group = sic_code.major_group
      AND s2.major_group_desc <> sic_code.major_group_desc
);

-- Run it (and the PK constraint's auto-generated rule alongside it):
RUN DQ TABLE lightning.metastore.usl_demo.sic_usl.sic_code;

-- Expect: total_records = 1005, valid_records = 1005, invalid_records = 0
-- for BOTH the auto-generated PRIMARY KEY rule and
-- major_group_desc_consistent -- matching sql/10 query 8's own "expect zero
-- rows back" result. Inspect any invalid records via the Data Quality panel
-- (see docs/guides/zetaris-sql-companion.md sec 8.2's table for how
-- constraint rules vs. custom rules differ in editability) if this
-- doesn't hold.

-- ---------------------------------------------------------------------------
-- STEP 5: materialize -- DEFERRED (docs/plans/usl-simple-advanced-build-plan.md
-- step V4). No cloud storage target is configured on any instance this
-- repo has touched yet, and standing one up is out of scope for now. Left
-- here, commented out, for whenever that's unblocked: Records: All (no DQ
-- gating needed for "All", per the USL User Guide sec 10.1 -- "Valid
-- Records Only" is what requires a DQ rule to already exist, exercised
-- instead in 02_advanced_company_profile_usl.sql step V7). Adjust
-- CLOUD_STORAGE_TARGET to a configured storage setting on the target
-- instance before running.
-- ---------------------------------------------------------------------------
-- MATERIALIZE USL TABLE lightning.metastore.usl_demo.sic_usl.sic_code
--   TO STORAGE (format='parquet', path='/materialized/usl_demo/sic_code');

-- After materializing, time a COUNT(*) in LIVE mode vs. MATERIALIZED mode
-- (the per-table toggle described in the USL User Guide sec 10.3) and
-- record both durations -- this is the first real data point on how USL
-- materialization compares to CACHE TABLE's confirmed ~40x speedup on this
-- same underlying raw table (docs/guides/zetaris-sql-companion.md sec 5).

-- =============================================================================
-- TEARDOWN -- commented out by default. Unlike open_data/rest_apis and
-- open_data/parquet_csv, USL documents a real SQL removal path (REMOVE USL,
-- DROP NAMESPACE ... CASCADE) with no GUI-only step -- but this is itself
-- unconfirmed live (plan V10). DROP NAMESPACE ... CASCADE also removes
-- 02_advanced_company_profile_usl.sql's USL if it shares this namespace --
-- don't run it until both scripts' testing is actually done.
-- =============================================================================

-- REMOVE USL sic_usl NAMESPACE lightning.metastore.usl_demo;
-- DROP NAMESPACE lightning.metastore.usl_demo CASCADE;
