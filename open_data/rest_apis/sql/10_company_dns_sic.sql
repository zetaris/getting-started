-- =============================================================================
-- Source:   company_dns -- SIC (Standard Industrial Classification) hierarchy
--           reference data: 4-digit code, description, and its full
--           division/major-group/industry-group rollup.
-- License:  company_dns itself is Apache 2.0 (github.com/miha42-github/
--           company_dns, self-hostable via Docker, also usable at the
--           hosted instance this script points at). Its SIC data traces
--           back to SEC's own public SIC list (see dependencies.data.sicData
--           in every response) -- same "query live, don't bulk-redistribute"
--           posture already applied to the raw EDGAR entries in
--           01_edgar_company_facts.sql and quickstart-data-manifest.md sec 6.
-- Format:   REST/JSON (CREATE LIGHTNING REST TABLE). ONE endpoint is used --
--           /sic/code/%25 -- confirmed (2026-09-21) to already carry every
--           field needed for the full hierarchy; see caveat 2 below for why
--           the API's other 3 SIC endpoints aren't called. The response is
--           a top-level object with a dynamic-key ("map-shaped") field, not
--           an array-of-structs -- same shape class as Eurostat/ABS
--           (07_eurostat.sql, 09_abs_data_api.sql), decoded with the same
--           from_json(to_json(...), 'map<string, STRUCT<...>>') coercion
--           technique confirmed working there.
-- Docs:     https://company-dns.mediumroast.io (interactive API reference
--           at /docs) -- hosted instance, Apache 2.0, also self-hostable
--           via Docker at http://localhost:8000 (see its own README).
-- Rate limit: no documented limit found for company_dns -- checked the
--           site, its OpenAPI spec, and lib/sic.py in its GitHub source;
--           none state one. See caveat 1 for a real but different
--           constraint (cold-start latency, not rate limiting).
-- Before running:
--   1. RUN THE WARMUP SCRIPT FIRST. The hosted instance has been observed
--      repeatedly (2026-09-20/21, 5+ separate confirmations) to return an
--      empty response, or an outright HTTP 502, on the first request after
--      a period of no traffic -- consistent with a scale-to-zero host --
--      then resolve cleanly on an immediate retry. From this directory's
--      parent (open_data/rest_apis/):
--        deno run --allow-net --allow-env scripts/warmup_company_dns.ts
--      (self-hosted instance: prefix with
--       COMPANY_DNS_BASE_URL=http://localhost:8000)
--      Re-run it again immediately before STEP 3's SELECT if any time has
--      passed since STEP 1 -- see caveat 1.
-- =============================================================================
--
-- LIVE-TESTED AND CONFIRMED WORKING END TO END AGAINST ZETARIS (2026-09-21):
-- CREATE LIGHTNING DATABASE, CREATE LIGHTNING REST TABLE, CACHE TABLE, the
-- SCHEMASTORE CONTAINER + VIEW (sic_codes_table), and all 8 example
-- queries below have all been run and verified, post-cache. The
-- from_json(to_json(...), 'map<string, STRUCT<...>>') decode technique
-- carries over cleanly from Eurostat/ABS (07/09) to this shape.
--
-- Caveats:
--   1. COLD-START 502s, NOT RATE LIMITING -- CONFIRMED, genuinely
--      different cause from every other "HTTP 502" case in this package
--      (compare Singapore PM2.5's rate-limit-driven 502,
--      failure_cases/singapore_pm25/ISSUE.md). Reproduced 5 separate times
--      in one session via the warmup script: the *first* request after
--      idle time gets a 502, an immediate retry succeeds cleanly. This can
--      surface two different ways depending on which statement hits the
--      cold instance: a plain HTTP 502 if it happens on
--      CREATE LIGHTNING REST TABLE itself, or a client-side
--      `java.sql.SQLException: org.apache.thrift.transport.TTransportException`
--      (sometimes as "Multiple exceptions were thrown (3), first ...") if
--      it happens on a later SELECT -- remember a Lightning REST table
--      re-fetches on every query, not just at CREATE time (see HOWTO.md,
--      "Known limitations"). CONFIRMED via elimination (2026-09-21): a
--      manual curl against the identical URL succeeded, DESCRIBE on the
--      table succeeded (schema-only, no live re-fetch), and the identical
--      failing SELECT succeeded immediately after re-running the warmup
--      script -- conclusively cold-start timing, not a structural/size
--      problem. See HOWTO.md, "Troubleshooting / FAQ" for the full writeup.
--   2. THE %25 WILDCARD BULK-RETRIEVAL TRICK IS NOT A DOCUMENTED API
--      FEATURE. Found by reading company_dns's own source (lib/sic.py):
--      every SIC lookup is executed as SQL `WHERE sic.sic LIKE ?` with the
--      path parameter substituted as '%' + query_str + '%', and the
--      sic_code path parameter has no minLength validation (unlike
--      sic_desc, which requires >= 2 characters) -- so a single literal
--      '%' (URL-encoded as %25) produces the SQL pattern '%%%', matching
--      every row. This is Apache-2.0-licensed, self-hostable software
--      owned by the person who asked for this script to be written, not a
--      third-party API being reverse-engineered -- but it's still
--      undocumented behavior, not a published contract, worth confirming
--      directly with them before this becomes load-bearing beyond a demo.
--   3. ONLY /sic/code/%25 IS CALLED, NOT THE 3 SIBLING ENDPOINTS
--      (/sic/division/%25, /sic/major/%25, /sic/industry/%25). Confirmed
--      live (2026-09-21): every one of /sic/code/%25's 1,005 entries
--      already carries description, division, division_desc, major_group,
--      major_group_desc, industry_group, AND industry_group_desc -- zero
--      missing fields across all 1,005 rows. The distinct division/major-
--      group/industry-group codes and descriptions DERIVABLE from that one
--      response were checked field-by-field against the 3 dedicated
--      endpoints and matched EXACTLY -- same 10/83/416 codes, zero
--      description mismatches. The only content NOT present in the single
--      call is `full_description` (a long SIC-Manual paragraph per
--      division), available only from the dedicated /sic/division/%25
--      endpoint -- add that as a 2nd REST table if that long-form text is
--      ever needed; the pattern below is directly reusable, just with a
--      smaller struct schema (description, full_description only).
--   4. CACHE TABLE CONFIRMED WORKING (2026-09-21) -- see STEP 1 below. An
--      uncached SELECT COUNT(*) against the raw REST table took Query
--      Time: 49.685s (Zetaris UI-reported); after CACHE TABLE, the
--      identical query dropped to a stable ~1.2s across repeated runs --
--      roughly 40x faster. This is the first confirmed case in this whole
--      package of CACHE TABLE actually stopping the "every query re-
--      fetches" behavior documented in HOWTO.md -- every earlier attempt
--      (05_nasa_neows.sql) was blocked by a rate limit before the test
--      could run at all. Whether the speedup propagates through the
--      SCHEMASTORE VIEW built on top of the cached raw table (STEP 2) has
--      NOT been separately measured -- time query 1 below, with and
--      without the CACHE TABLE statement, if that matters for your use.
--   5. DESCRIBE BY ONLY ACCEPTS A RESTRICTED CHARACTER SET. Confirmed live
--      (2026-09-21): a description containing parentheses and a slash was
--      rejected outright with "Description is invalid, it must be
--      alphanumeric including the _ (underscore), . (dot), - (hyphen) and
--      , (comma) character" -- before the statement ever reached the REST
--      endpoint. Plain spaces are fine (used below and throughout this
--      package) despite not being named in the error text; it's
--      punctuation like parentheses, slashes, or colons that trips this.
--      See HOWTO.md, "Known limitations" and "Troubleshooting / FAQ".
-- =============================================================================

-- ---------------------------------------------------------------------------
-- STEP 0: Lightning database for this source.
-- ---------------------------------------------------------------------------
CREATE LIGHTNING DATABASE COMPANY_DNS DESCRIBE BY "company_dns SIC reference data - division, major group, industry group, SIC code";

-- ---------------------------------------------------------------------------
-- STEP 1: the one REST table (see caveats 2-3), then CACHE TABLE it
-- immediately (see caveat 4 -- confirmed live, ~40x faster on repeated
-- queries). Small (~278 KB, 1,005 rows once flattened) and effectively
-- static (SIC 1987 hasn't been revised), making it a good candidate to
-- keep cached for the life of a session.
-- ---------------------------------------------------------------------------
CREATE LIGHTNING REST TABLE sic_codes_raw FROM COMPANY_DNS REQUEST(
    endpoint "https://company-dns.mediumroast.io/V3.0/na/sic/code/%25",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CACHE TABLE company_dns.sic_codes_raw;

-- ---------------------------------------------------------------------------
-- STEP 2: SCHEMASTORE container, then the flattened view. RUN THE
-- CONTAINER STATEMENT ONCE -- no IF NOT EXISTS support (see HOWTO.md,
-- "Known limitations"); comment it out on a re-run if it already exists.
--
-- The view decodes the one dynamic-key object (data.sics) the same way
-- Eurostat's `value` and ABS's `observations` were decoded (07/09) --
-- round-tripping through from_json(to_json(...), 'map<string,
-- STRUCT<...>>') to force Spark's inferred STRUCT (one field per SIC code)
-- back into a MAP so LATERAL VIEW explode() can work on it. Simpler than
-- Eurostat's case: only ONE coercion is needed here (no second nested
-- dynamic-key object being exploded in the same query).
-- ---------------------------------------------------------------------------
CREATE SCHEMASTORE CONTAINER company_dns;

CREATE SCHEMASTORE VIEW sic_codes_table WITH CONTAINER company_dns AS
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

-- Verify: row count should match what was found live during research
-- (caveat 3) -- if it doesn't, check the diagnostic block below before
-- trusting anything downstream (same discipline as every other source in
-- this package -- see HOWTO.md, "Verifying data"):
SELECT COUNT(*) FROM company_dns.sic_codes_table;   -- expect 1005

-- ---------------------------------------------------------------------------
-- Diagnostic (run if the view above fails or the count doesn't match):
--   SELECT * FROM company_dns.sic_codes_raw;
--   DESCRIBE company_dns.sic_codes_raw;
-- Confirmed live (2026-09-21): DESCRIBE succeeds and shows the full
-- inferred nested schema even though data has 1,005 dynamically-named
-- struct fields under it -- schema inference itself is not the bottleneck
-- here if something goes wrong; check caveat 1's cold-start possibility
-- first.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Example queries -- run these against sic_codes_table to confirm the
-- flattened data is correct and usable, not just present. Picked to
-- exercise the hierarchy end to end: overview counts, breakdowns at each
-- level, two realistic lookup/search queries, a window function (the
-- standard "top row per group" pattern used throughout this package), and
-- a data-quality self-consistency check.
-- ---------------------------------------------------------------------------

-- 1. Overview -- total SIC codes and how many distinct divisions/major
-- groups/industry groups they roll up into. Expect 1005/10/83/416,
-- matching the 4 endpoint counts found during research (caveat 3) even
-- though only 1 endpoint was actually called:
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
-- package, e.g. sql/03, sql/08):
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

-- ---------------------------------------------------------------------------
-- Downstream note: to enrich an EDGAR company profile with this hierarchy,
-- join on the company's own `sic` field (from EDGAR's submissions
-- endpoint, https://data.sec.gov/submissions/CIK{cik}.json -- see
-- docs/plans/edgar-sic-enrichment-plan.md sec 3) against sic_code here,
-- e.g.:
--   SELECT e.name, e.sic, s.description, s.division_desc, s.industry_group_desc
--   FROM <edgar_submissions_view> e
--   INNER JOIN company_dns.sic_codes_table s ON e.sic = s.sic_code;
-- Not built in this script -- this script is scoped to the company_dns
-- SIC source on its own, per the plan's build-sequence step 1-3 (sec 6).
-- ---------------------------------------------------------------------------

-- =============================================================================
-- TEARDOWN -- removes the flattened view this script created. Commented
-- out by default, same convention as every other script in this package --
-- see HOWTO.md, "Removing a source", for why DROP VIEW is the only
-- teardown statement confirmed to work reliably, and how to actually
-- remove the underlying REST table and Lightning database registration
-- (Zetaris Data Explorer, "File Source & API" panel -- no SQL path exists
-- for that part).
-- =============================================================================

-- DROP VIEW company_dns.sic_codes_table;
-- UNCACHE TABLE company_dns.sic_codes_raw;

-- To remove the sic_codes_raw REST table and the COMPANY_DNS Lightning
-- database registration, use the Zetaris Data Explorer's "File Source &
-- API" panel (see HOWTO.md, "Removing a source").
