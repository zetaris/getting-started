-- =============================================================================
-- Verification and example queries for sic_usl -- see 01_sic_usl_create.sql
-- for the setup these check. Same table content and column set as
-- company_dns.sic_codes_table
-- (open_data/rest_apis/sql/non_rate_limited/10_company_dns_sic_select.sql),
-- so queries 2-8 below mirror that script's queries 1-7, adapted to this
-- USL table -- a direct side-by-side of the two mechanisms against
-- identical data.
-- =============================================================================

-- 1. Row count -- same expected count as sql/10's sic_codes_table (1005) --
-- if this differs, the row-count under-reporting bug flagged in
-- docs/guides/zetaris-lightning-sql-companion.md section 5 is a candidate
-- explanation, but check independently (curl against company_dns) before
-- assuming that.
SELECT COUNT(*) FROM lightning.metastore.usl_demo.sic_usl.sic_code;   -- expect 1005

-- 2. Overview -- total SIC codes and how many distinct divisions/major
-- groups/industry groups they roll up into. Expect 1005/10/83/416, matching
-- sql/10 query 1 (the same underlying data, only the destination differs).
SELECT
    COUNT(*) AS total_sic_codes,
    COUNT(DISTINCT division) AS total_divisions,
    COUNT(DISTINCT major_group) AS total_major_groups,
    COUNT(DISTINCT industry_group) AS total_industry_groups
FROM lightning.metastore.usl_demo.sic_usl.sic_code;

-- 3. SIC codes per division, ranked -- which division has the broadest SIC
-- coverage. Manufacturing (division D) is expected to dominate, same as
-- sql/10 query 2.
SELECT division, division_desc, COUNT(*) AS sic_code_count
FROM lightning.metastore.usl_demo.sic_usl.sic_code
GROUP BY division, division_desc
ORDER BY sic_code_count DESC;

-- 4. The 10 most granular major groups -- which 2-digit major groups
-- contain the most 4-digit SIC codes.
SELECT major_group, major_group_desc, division, COUNT(*) AS sic_code_count
FROM lightning.metastore.usl_demo.sic_usl.sic_code
GROUP BY major_group, major_group_desc, division
ORDER BY sic_code_count DESC
LIMIT 10;

-- 5. Industry-group diversity per division -- which division spans the
-- most distinct industry groups (a different cut than query 3's raw SIC
-- count -- a division could have few SIC codes spread across many narrow
-- industry groups, or many codes concentrated in a few).
SELECT division, division_desc, COUNT(DISTINCT industry_group) AS distinct_industry_groups
FROM lightning.metastore.usl_demo.sic_usl.sic_code
GROUP BY division, division_desc
ORDER BY distinct_industry_groups DESC;

-- 6. Search example -- every SIC code whose description mentions
-- "Computer" (case-sensitive as written in the source data, which is
-- consistently title-cased -- see query 7 for a case-insensitive variant).
SELECT sic_code, description, division_desc, major_group_desc, industry_group_desc
FROM lightning.metastore.usl_demo.sic_usl.sic_code
WHERE description LIKE '%Computer%'
ORDER BY sic_code;

-- 7. Same search, case-insensitive, for "software" -- confirms
-- LOWER()/LIKE works cleanly against an activated USL table the same way
-- it does against a SchemaStore view.
SELECT sic_code, description, division_desc, major_group_desc, industry_group_desc
FROM lightning.metastore.usl_demo.sic_usl.sic_code
WHERE LOWER(description) LIKE '%software%'
ORDER BY sic_code;

-- 8. One representative SIC code per division -- the alphabetically-first
-- description in each division, via ROW_NUMBER() (the standard "top row
-- per group" window-function pattern used throughout this repo).
SELECT division, division_desc, sic_code, description
FROM (
    SELECT
        division,
        division_desc,
        sic_code,
        description,
        ROW_NUMBER() OVER (PARTITION BY division ORDER BY description) AS rn
    FROM lightning.metastore.usl_demo.sic_usl.sic_code
) ranked
WHERE rn = 1
ORDER BY division;

-- 9. Self-consistency check: does every SIC code under the same
-- major_group agree on that major_group's description? Same shape as
-- sql/10 query 8 -- run here as a plain aggregate query, since this check
-- is confirmed not expressible as a REGISTER DQ rule on this table (see
-- docs/guides/zetaris-lightning-sql-companion.md section 8.6). Expect zero rows
-- back.
SELECT major_group, COUNT(DISTINCT major_group_desc) AS distinct_descriptions
FROM lightning.metastore.usl_demo.sic_usl.sic_code
GROUP BY major_group
HAVING COUNT(DISTINCT major_group_desc) > 1;

-- === Data Quality inspection (USL User Guide Appendix B) ===
-- SQL-side equivalents of the GUI's Data Quality panel -- list every rule
-- registered on this USL, then drill into a specific rule's valid/invalid
-- records the same way the GUI's drill-down view does (guide section 8.4).
-- Only the PK constraint's auto-generated rule is registered on this table
-- (the custom self-consistency check above isn't expressible as a
-- REGISTER DQ rule -- see query 9).

-- 10. Every DQ rule registered on this USL (just the PK constraint rule,
-- on this table):
LIST DQ USL lightning.metastore.usl_demo.sic_usl;

-- 11. The PK constraint rule's own valid/invalid records. Confirmed live
-- on sic_edgar_usl.company: a PK/FK constraint rule is named plainly after
-- the column it constrains (e.g. cik, sic), not a generated pk_<table>
-- name -- so this table's PK rule is very likely named sic_code (same as
-- the column, and the table). Run query 10 first to confirm the actual
-- name before relying on this:
SHOW DQ VALID RECORD sic_code TABLE lightning.metastore.usl_demo.sic_usl.sic_code;
SHOW DQ INVALID RECORD sic_code TABLE lightning.metastore.usl_demo.sic_usl.sic_code;

-- 12. Every invalid record across every rule on this table in one query:
SHOW DQ ALL INVALID TABLE lightning.metastore.usl_demo.sic_usl.sic_code;
