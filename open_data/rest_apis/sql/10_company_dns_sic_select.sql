-- =============================================================================
-- Verification / example queries for 10_company_dns_sic_create.sql
-- Assumes 10_company_dns_sic_create.sql has already been run.
--
-- The verification query below is commented out by default so that running
-- this whole file doesn't automatically fire a read query. Uncomment it,
-- or run it directly in the SQL Editor. The example queries further down
-- are left live, same as before.
-- =============================================================================

-- === Verification ===
-- Row count should match what was found live during research (caveat 3 in
-- the create script) -- if it doesn't, check the diagnostic block below
-- before trusting anything downstream (same discipline as every other
-- source in this package -- see HOWTO.md, "Verifying data"):
-- SELECT COUNT(*) FROM company_dns.sic_codes_table;   -- expect 1005

-- === Diagnostics === (run if the view above fails or the count doesn't match)
-- SELECT * FROM company_dns.sic_codes_raw;
-- DESCRIBE company_dns.sic_codes_raw;
-- Confirmed live (2026-09-21): DESCRIBE succeeds and shows the full
-- inferred nested schema even though data has 1,005 dynamically-named
-- struct fields under it -- schema inference itself is not the bottleneck
-- here if something goes wrong; check caveat 1 in the create script's
-- cold-start possibility first.

-- === Example queries ===
-- Run these against sic_codes_table to confirm the flattened data is
-- correct and usable, not just present. Picked to exercise the hierarchy
-- end to end: overview counts, breakdowns at each level, two realistic
-- lookup/search queries, a window function (the standard "top row per
-- group" pattern used throughout this package), and a data-quality
-- self-consistency check.

-- 1. Overview -- total SIC codes and how many distinct divisions/major
-- groups/industry groups they roll up into. Expect 1005/10/83/416,
-- matching the 4 endpoint counts found during research (caveat 3 in the
-- create script) even though only 1 endpoint was actually called:
SELECT
    COUNT(*)                            AS total_sic_codes,
    COUNT(DISTINCT division)            AS total_divisions,
    COUNT(DISTINCT major_group)         AS total_major_groups,
    COUNT(DISTINCT industry_group)      AS total_industry_groups
FROM company_dns.sic_codes_table;

-- 2. SIC codes per division, ranked -- which division has the broadest
-- SIC coverage. Manufacturing (division D) is expected to dominate, given
-- how much of the 1987 SIC system is devoted to manufacturing subclasses:
SELECT division, division_desc, COUNT(*) AS sic_code_count
FROM company_dns.sic_codes_table
GROUP BY division, division_desc
ORDER BY sic_code_count DESC;

-- 3. The 10 most granular major groups -- which 2-digit major groups
-- contain the most 4-digit SIC codes:
SELECT major_group, major_group_desc, division, COUNT(*) AS sic_code_count
FROM company_dns.sic_codes_table
GROUP BY major_group, major_group_desc, division
ORDER BY sic_code_count DESC
LIMIT 10;

-- 4. Industry-group diversity per division -- which division spans the
-- most distinct industry groups (a different cut than query 2's raw SIC
-- count -- a division could have few SIC codes spread across many narrow
-- industry groups, or many codes concentrated in a few):
SELECT division, division_desc, COUNT(DISTINCT industry_group) AS distinct_industry_groups
FROM company_dns.sic_codes_table
GROUP BY division, division_desc
ORDER BY distinct_industry_groups DESC;

-- 5. Search example -- every SIC code whose description mentions
-- "Computer" (case-sensitive as written in the source data, which is
-- consistently title-cased -- see query 6 for a case-insensitive variant
-- if that matters for your data):
SELECT sic_code, description, division_desc, major_group_desc, industry_group_desc
FROM company_dns.sic_codes_table
WHERE description LIKE '%Computer%'
ORDER BY sic_code;

-- 6. Same search, case-insensitive, for "software" -- demonstrates the
-- practical "unpack an EDGAR SIC code into something readable" use case
-- this source exists for, and confirms LOWER()/LIKE works cleanly against
-- the flattened view:
SELECT sic_code, description, division_desc, major_group_desc, industry_group_desc
FROM company_dns.sic_codes_table
WHERE LOWER(description) LIKE '%software%'
ORDER BY sic_code;

-- 7. One representative SIC code per division -- the alphabetically-first
-- description in each division, via ROW_NUMBER() (the standard "top row
-- per group" window-function pattern already proven throughout this
-- package, e.g. sql/03_open_food_facts_live_select.sql,
-- sql/08_statcan_wds_select.sql):
SELECT division, division_desc, sic_code, description
FROM (
    SELECT
        division,
        division_desc,
        sic_code,
        description,
        ROW_NUMBER() OVER (PARTITION BY division ORDER BY description) AS rn
    FROM company_dns.sic_codes_table
) ranked
WHERE rn = 1
ORDER BY division;

-- 8. Data-quality self-consistency check -- confirms every SIC code
-- rolled up under the same major_group agrees on that major_group's
-- description (i.e. the denormalization in the source data is internally
-- consistent, not just individually plausible). Expect ZERO rows back --
-- any row returned here would mean the same major_group code maps to more
-- than one description somewhere in the 1,005 SIC entries, worth
-- investigating before trusting the reference data further:
SELECT major_group, COUNT(DISTINCT major_group_desc) AS distinct_descriptions_for_this_major_group
FROM company_dns.sic_codes_table
GROUP BY major_group
HAVING COUNT(DISTINCT major_group_desc) > 1;
