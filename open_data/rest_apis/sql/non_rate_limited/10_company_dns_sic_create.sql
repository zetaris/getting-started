-- =============================================================================
-- Source: company_dns SIC (Standard Industrial Classification) hierarchy
-- reference data -- 4-digit code, description, and its full
-- division/major-group/industry-group rollup.
--
-- License: company_dns is Apache 2.0 (github.com/miha42-github/company_dns,
-- self-hostable via Docker, also usable at the hosted instance below). Its
-- SIC data traces back to SEC's own public SIC list (see
-- dependencies.data.sicData in every response) -- query live, don't
-- bulk-redistribute the extracted data.
--
-- Format: REST/JSON (CREATE LIGHTNING REST TABLE). One endpoint is used,
-- /sic/code/%25, which already carries every field needed for the full
-- hierarchy (see caveat 2). The response is a top-level object with a
-- dynamic-key ("map-shaped") field, not an array-of-structs -- see the
-- SQL companion guide for the general decode technique.
--
-- Docs: https://company-dns.mediumroast.io (interactive API reference at
-- /docs). Also self-hostable via Docker at http://localhost:8000 (see its
-- own README).
--
-- Rate limit: none documented -- checked the site, its OpenAPI spec, and
-- lib/sic.py in its GitHub source; none state one. See caveat 1 for a
-- real but different constraint (cold-start latency, not rate limiting).
--
-- Before running: run the warmup script first. The hosted instance has
-- been observed to return an empty response, or an HTTP 502, on the
-- first request after a period of no traffic, then resolve cleanly on an
-- immediate retry (see caveat 1). From open_data/rest_apis/:
--   deno run --allow-net --allow-env scripts/warmup_company_dns.ts
-- Self-hosted instance: prefix with
-- COMPANY_DNS_BASE_URL=http://localhost:8000. Re-run the warmup script
-- again immediately before verifying if time has passed since running it
-- here.
--
-- Status: live-tested and confirmed working end to end against Zetaris
-- (2026-09-21) -- database registration, REST table, cache, schemastore
-- view, and example queries have all run successfully.
-- =============================================================================
--
-- Caveats:
--   1. Cold-start HTTP 502s, not rate limiting. Reproduced 5 separate
--      times: the first request after idle time gets a 502 or an empty
--      response, then an immediate retry succeeds cleanly. Depending on
--      which statement hits the cold instance this can also surface as a
--      client-side TTransportException on a later SELECT, since a
--      Lightning REST table re-fetches on every query. See the SQL
--      companion guide for the general cause and fix.
--   2. The %25 wildcard bulk-retrieval trick is not a documented API
--      feature. Found by reading company_dns's own source (lib/sic.py):
--      every SIC lookup runs as SQL `WHERE sic.sic LIKE ?` with the path
--      parameter substituted as '%' + query_str + '%', and the sic_code
--      path parameter has no minimum-length validation -- so a single
--      literal '%' (url-encoded as %25) matches every row. This is
--      undocumented behavior, not a published contract, worth confirming
--      directly with the maintainer before it becomes load-bearing
--      beyond a demo.
--   3. Only /sic/code/%25 is called, not the 3 sibling endpoints
--      (/sic/division/%25, /sic/major/%25, /sic/industry/%25). Every one
--      of /sic/code/%25's 1,005 entries already carries description,
--      division, division_desc, major_group, major_group_desc,
--      industry_group, and industry_group_desc, with zero missing
--      fields. The distinct division/major-group/industry-group codes
--      and descriptions derivable from that one response were checked
--      field-by-field against the 3 dedicated endpoints and matched
--      exactly (10/83/416 codes, zero description mismatches). The only
--      content not present in the single call is full_description (a
--      long SIC-Manual paragraph per division), available only from the
--      dedicated /sic/division/%25 endpoint -- add that as a second REST
--      table if that long-form text is ever needed.
--   4. CACHE TABLE, applied in step 1, cut a repeated SELECT COUNT(*)
--      from 49.7s uncached to a stable 1.2s cached -- roughly 40x
--      faster. Whether the speedup propagates through the schemastore
--      view built on top of the cached raw table hasn't been separately
--      measured. See the SQL companion guide for what CACHE TABLE
--      actually is and its known limitations.
--   5. DESCRIBE BY only accepts a restricted character set (letters,
--      digits, spaces, and _ . - ,) -- see the SQL companion guide.
-- =============================================================================

-- Step 0: register the logical database.
CREATE LIGHTNING DATABASE COMPANY_DNS DESCRIBE BY "company_dns SIC reference data - division, major group, industry group, SIC code";

-- Step 1: the one REST table (see caveats 2-3), cached immediately (see
-- caveat 4). Small (about 278 KB, 1,005 rows once flattened) and
-- effectively static -- SIC 1987 hasn't been revised -- a good candidate
-- to keep cached for the life of a session.
CREATE LIGHTNING REST TABLE sic_codes_raw FROM COMPANY_DNS REQUEST(
    endpoint "https://company-dns.mediumroast.io/V3.0/na/sic/code/%25",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CACHE TABLE company_dns.sic_codes_raw;

-- Step 2: schemastore container, then the flattened view. Run the
-- container statement once. The view decodes the one dynamic-key object
-- (data.sics), forcing Spark's inferred struct (one field per SIC code)
-- into a map so LATERAL VIEW explode() can work on it -- see the SQL
-- companion guide for the general decode technique.
CREATE SCHEMASTORE CONTAINER company_dns;

CREATE SCHEMASTORE VIEW sic_codes_table WITH CONTAINER company_dns AS
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

-- =============================================================================
-- Teardown -- removes the flattened view. Commented out by default. See
-- the SQL companion guide for why DROP VIEW is the only reliable
-- teardown statement, and how to remove the underlying REST table and
-- database registration (Zetaris Data Explorer -- no SQL path exists).
-- =============================================================================

-- DROP VIEW company_dns.sic_codes_table;
-- UNCACHE TABLE company_dns.sic_codes_raw;
