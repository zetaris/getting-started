-- =============================================================================
-- Verification and contrast queries for sic_edgar_usl -- see
-- 02_sic_edgar_usl_create.sql for the setup these check.
-- =============================================================================

SELECT COUNT(*) FROM lightning.metastore.usl_demo.sic_edgar_usl.sic_code;   -- expect 1005
SELECT COUNT(*) FROM lightning.metastore.usl_demo.sic_edgar_usl.company;    -- expect 7

-- Description-agreement check: do the two independently-sourced SIC
-- descriptions (EDGAR's own, vs. the sic_code reference table) actually
-- agree, not just does the code exist. This is sql/11 query 8's check --
-- run here as a plain join, since it's confirmed not expressible as a
-- REGISTER DQ rule on this table (docs/guides/zetaris-sql-companion.md
-- section 8.6).
--
-- This is an INNER JOIN, so it has the same blind spot as sql/11's own
-- version: a company whose sic doesn't match any sic_code row (a
-- referential problem, not a description-agreement one) is silently
-- excluded here rather than flagged. Confirmed live: IBM's sic (3570) has
-- no matching sic_code row -- the FK rule below (RUN DQ) catches this;
-- this INNER JOIN silently drops IBM instead.
SELECT c.entity_name, c.sic, c.sic_description_edgar, sc.description AS sic_description_reference
FROM lightning.metastore.usl_demo.sic_edgar_usl.company c
JOIN lightning.metastore.usl_demo.sic_edgar_usl.sic_code sc ON sc.sic_code = c.sic
WHERE c.sic_description_edgar <> sc.description;   -- expect zero rows back

-- Referential diagnostic: which company's sic doesn't match any sic_code
-- row at all. This is exactly what the auto-generated FK rule below
-- (RUN DQ) checks -- a LEFT JOIN surfaces the same company its invalid
-- record set does, without needing the DQ panel. Confirmed live: IBM,
-- sic 3570 -- likely missing from company_dns's 1,005-row SIC reference
-- list rather than a null/empty artifact of this script's COALESCE
-- (Step 4), since 3570 is a real 4-digit code.
SELECT c.cik, c.entity_name, c.sic
FROM lightning.metastore.usl_demo.sic_edgar_usl.company c
LEFT JOIN lightning.metastore.usl_demo.sic_edgar_usl.sic_code sc ON sc.sic_code = c.sic
WHERE sc.sic_code IS NULL;

-- === Data Quality inspection (USL User Guide Appendix B) ===
-- SQL-side equivalents of the GUI's Data Quality panel. Only the FK
-- constraint's auto-generated rule is registered on this table (the
-- description-agreement check above isn't expressible as a REGISTER DQ
-- rule -- see the query above).

-- Every DQ rule registered on this USL (just the FK constraint rule, on
-- the company table). Confirmed live: named plainly after the column it
-- constrains -- sic (Foreign Key Constraint, 7 total / 6 valid / 1
-- invalid) -- not a generated fk_company_sic-style name.
LIST DQ USL lightning.metastore.usl_demo.sic_edgar_usl;

-- The FK rule's own valid/invalid records:
SHOW DQ VALID RECORD sic TABLE lightning.metastore.usl_demo.sic_edgar_usl.company;
SHOW DQ INVALID RECORD sic TABLE lightning.metastore.usl_demo.sic_edgar_usl.company;

-- Every invalid record across every rule on this table in one query:
SHOW DQ ALL INVALID TABLE lightning.metastore.usl_demo.sic_edgar_usl.company;

-- Contrast query: compare against the existing manual VDM built in sql/11
-- (companies_mart, per that script's trailing walkthrough and
-- docs/guides/zetaris-sql-companion.md section 7's confirmed flat
-- <mart>.<table> query syntax). Both should return the same 7 rows; record
-- any difference (row count, column values, timing) rather than assuming
-- they match.
SELECT entity_name, sic, sic_description_edgar
FROM lightning.metastore.usl_demo.sic_edgar_usl.company
ORDER BY entity_name;

-- Compare against:
-- SELECT entity_name, sic_code, sic_description_edgar FROM companies_mart.all_companies_profile_table ORDER BY entity_name;
