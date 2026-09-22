-- =============================================================================
-- Source:   SEC EDGAR XBRL Company Facts API (companyconcept endpoint)
-- License:  Ambiguous -- filings are filer-authored, not government-authored,
--           so free API access doesn't automatically mean a copyright/license
--           grant over the underlying facts. Same posture as the PDF-filing
--           entry in the main manifest (quickstart-data-manifest.md sec 6):
--           fine to query the live API for a demo, don't bulk-redistribute a
--           copy of the extracted data.
-- Format:   REST/JSON (CREATE LIGHTNING REST TABLE, not a filestore table)
-- Docs:     https://www.sec.gov/search-filings/edgar-search-assistance/accessing-edgar-data
--           https://data.sec.gov/api/xbrl/companyconcept/CIK{10-digit-cik}/us-gaap/{tag}.json
-- Rate limit: 10 requests/sec, declared User-Agent required (SEC blocks
--           default/missing User-Agent strings), no botnets. See
--           https://www.sec.gov/os/webmaster-faq#developers
-- Before running: confirm the CIK is current for the company you want --
--           EDGAR company search: https://www.sec.gov/cgi-bin/browse-edgar
-- =============================================================================
--
-- Validated end-to-end against Apple (CIK 0000320193) on 2026-09-18:
--   1. `entityName` came back AS MIXED CASE -- must be backtick-quoted as
--      `entityName`, not "entityname" or entityname unquoted.
--   2. units.USD is array<struct<accn,end,filed,form,fp,frame,fy,start,val>>
--      -- an ARRAY OF STRUCTS, not parallel arrays -- so flattening uses a
--      plain LATERAL VIEW explode(units.USD) AS fact + dot-access
--      (fact.val, fact.accn, ...), not posexplode()-with-index. If a later
--      REST source returns parallel arrays instead of array-of-structs, that
--      needs a different flattening pattern -- don't assume this one is
--      universal.
--   3. `start`/`end` are reserved words in most SQL dialects -- backtick-
--      quoted below (fact.`start`, fact.`end`) even though the rest of the
--      struct's fields don't need it.
--   4. NOT A BUG -- CONFIRMED RESOLVED (2026-09-21): Apple's fetch returns
--      only 11 rows, all from a single accession (0000320193-18-000145,
--      filed 2018-11-05), capping out at FY2018. Originally suspected as a
--      Zetaris REST connector truncating the response mid-array. Ran the
--      verification query from HOWTO.md, "Verifying data" -- a direct
--      curl against the live SEC endpoint (no Zetaris involved) ALSO
--      returned exactly 11 rows for Apple's us-gaap:Revenues tag, and
--      Zetaris's own SELECT COUNT(*) matched it exactly (11 = 11). This
--      rules out a Zetaris-side truncation bug entirely -- the live SEC
--      API itself only has 11 data points under this specific tag for
--      Apple. Likely explanation: Apple (like many filers) switched which
--      XBRL tag it uses for total revenue at some point -- e.g. around the
--      2018 ASC 606 revenue-recognition standard change -- so an older tag
--      like `Revenues` genuinely stops appearing in later filings, which
--      is consistent with all 11 rows tracing to one 2018 filing and
--      nothing after. Still worth spot-checking other companies below the
--      same way before assuming this generalizes, but treat a low row
--      count here as "check the real API first," not "assume Zetaris
--      truncated it."
--   5. CREATE SCHEMASTORE CONTAINER has no IF NOT EXISTS support (confirmed
--      via LightningDdlParseException) -- it's simply not in that
--      statement's grammar, unlike many other CREATE statements. Running it
--      twice against an existing container name fails outright. See
--      HOWTO.md, "Known limitations", for how this script handles that.
--
-- This script repeats the same pattern for seven companies: Apple, IBM,
-- Oracle, Walmart, Target, Ford, and Tesla -- one REST table (raw JSON) and
-- one flattened SCHEMASTORE view per company, all views landing in the
-- shared `edgar` SCHEMASTORE container so they can be queried and UNIONed
-- together (see the optional cross-company view at the bottom).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- STEP 0: Lightning database holding all raw REST tables for this source.
-- Same prerequisite as the Parquet/CSV package's filestore tables -- see
-- open_data/parquet_csv/HOWTO.md sec 1. Run once.
-- ---------------------------------------------------------------------------
CREATE LIGHTNING DATABASE SEC_DATA DESCRIBE BY "SEC EDGAR XBRL company facts REST source";

-- ---------------------------------------------------------------------------
-- STEP 1: Shared SCHEMASTORE container for every company's flattened view.
-- RUN THIS EXACTLY ONCE. CREATE SCHEMASTORE CONTAINER has no IF NOT EXISTS
-- -- re-running it against a name that already exists fails outright (see
-- caveat 5 above and HOWTO.md, "Known limitations"). If `edgar` already
-- exists in your environment, comment this line out before running the
-- rest of the script.
-- ---------------------------------------------------------------------------
CREATE SCHEMASTORE CONTAINER edgar;

-- =============================================================================
-- APPLE INC. -- CIK 0000320193
-- =============================================================================
CREATE LIGHTNING REST TABLE apple_revenue_facts FROM SEC_DATA REQUEST(
    endpoint "https://data.sec.gov/api/xbrl/companyconcept/CIK0000320193/us-gaap/Revenues.json",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW apple_revenue_table WITH CONTAINER edgar AS
SELECT
    cik,
    `entityName` AS entity_name,
    tag          AS concept,
    fact.`start` AS period_start,
    fact.`end`   AS period_end,
    fact.val     AS value_usd,
    fact.accn    AS accession_number,
    fact.fy      AS fiscal_year,
    fact.fp      AS fiscal_period,
    fact.frame   AS period_frame,
    fact.form    AS form_type,
    fact.filed   AS filed_date
FROM sec_data.apple_revenue_facts
LATERAL VIEW explode(units.USD) AS fact;

-- =============================================================================
-- IBM (INTERNATIONAL BUSINESS MACHINES CORP) -- CIK 0000051143
-- =============================================================================
CREATE LIGHTNING REST TABLE ibm_revenue_facts FROM SEC_DATA REQUEST(
    endpoint "https://data.sec.gov/api/xbrl/companyconcept/CIK0000051143/us-gaap/Revenues.json",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW ibm_revenue_table WITH CONTAINER edgar AS
SELECT
    cik,
    `entityName` AS entity_name,
    tag          AS concept,
    fact.`start` AS period_start,
    fact.`end`   AS period_end,
    fact.val     AS value_usd,
    fact.accn    AS accession_number,
    fact.fy      AS fiscal_year,
    fact.fp      AS fiscal_period,
    fact.frame   AS period_frame,
    fact.form    AS form_type,
    fact.filed   AS filed_date
FROM sec_data.ibm_revenue_facts
LATERAL VIEW explode(units.USD) AS fact;

-- =============================================================================
-- ORACLE CORPORATION -- CIK 0001341439
-- NOTE: this is the current Oracle Corporation entity. There is a separate,
-- older, unrelated CIK (0000777676, "Oracle Systems Corp") from decades ago
-- in EDGAR's history -- if oracle_revenue_facts comes back empty, check
-- EDGAR's company search before assuming the connector broke.
-- =============================================================================
CREATE LIGHTNING REST TABLE oracle_revenue_facts FROM SEC_DATA REQUEST(
    endpoint "https://data.sec.gov/api/xbrl/companyconcept/CIK0001341439/us-gaap/Revenues.json",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW oracle_revenue_table WITH CONTAINER edgar AS
SELECT
    cik,
    `entityName` AS entity_name,
    tag          AS concept,
    fact.`start` AS period_start,
    fact.`end`   AS period_end,
    fact.val     AS value_usd,
    fact.accn    AS accession_number,
    fact.fy      AS fiscal_year,
    fact.fp      AS fiscal_period,
    fact.frame   AS period_frame,
    fact.form    AS form_type,
    fact.filed   AS filed_date
FROM sec_data.oracle_revenue_facts
LATERAL VIEW explode(units.USD) AS fact;

-- =============================================================================
-- WALMART INC. -- CIK 0000104169
-- =============================================================================
CREATE LIGHTNING REST TABLE walmart_revenue_facts FROM SEC_DATA REQUEST(
    endpoint "https://data.sec.gov/api/xbrl/companyconcept/CIK0000104169/us-gaap/Revenues.json",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW walmart_revenue_table WITH CONTAINER edgar AS
SELECT
    cik,
    `entityName` AS entity_name,
    tag          AS concept,
    fact.`start` AS period_start,
    fact.`end`   AS period_end,
    fact.val     AS value_usd,
    fact.accn    AS accession_number,
    fact.fy      AS fiscal_year,
    fact.fp      AS fiscal_period,
    fact.frame   AS period_frame,
    fact.form    AS form_type,
    fact.filed   AS filed_date
FROM sec_data.walmart_revenue_facts
LATERAL VIEW explode(units.USD) AS fact;

-- =============================================================================
-- TARGET CORPORATION -- CIK 0000027419
-- =============================================================================
CREATE LIGHTNING REST TABLE target_revenue_facts FROM SEC_DATA REQUEST(
    endpoint "https://data.sec.gov/api/xbrl/companyconcept/CIK0000027419/us-gaap/Revenues.json",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW target_revenue_table WITH CONTAINER edgar AS
SELECT
    cik,
    `entityName` AS entity_name,
    tag          AS concept,
    fact.`start` AS period_start,
    fact.`end`   AS period_end,
    fact.val     AS value_usd,
    fact.accn    AS accession_number,
    fact.fy      AS fiscal_year,
    fact.fp      AS fiscal_period,
    fact.frame   AS period_frame,
    fact.form    AS form_type,
    fact.filed   AS filed_date
FROM sec_data.target_revenue_facts
LATERAL VIEW explode(units.USD) AS fact;

-- =============================================================================
-- FORD MOTOR COMPANY -- CIK 0000037996
-- =============================================================================
CREATE LIGHTNING REST TABLE ford_revenue_facts FROM SEC_DATA REQUEST(
    endpoint "https://data.sec.gov/api/xbrl/companyconcept/CIK0000037996/us-gaap/Revenues.json",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW ford_revenue_table WITH CONTAINER edgar AS
SELECT
    cik,
    `entityName` AS entity_name,
    tag          AS concept,
    fact.`start` AS period_start,
    fact.`end`   AS period_end,
    fact.val     AS value_usd,
    fact.accn    AS accession_number,
    fact.fy      AS fiscal_year,
    fact.fp      AS fiscal_period,
    fact.frame   AS period_frame,
    fact.form    AS form_type,
    fact.filed   AS filed_date
FROM sec_data.ford_revenue_facts
LATERAL VIEW explode(units.USD) AS fact;

-- =============================================================================
-- TESLA, INC. -- CIK 0001318605
-- NOTE: Tesla only started filing 10-Ks after going public in 2010, so its
-- Revenues tag history is shorter than the others by construction -- a small
-- row count here is expected and not necessarily the same truncation
-- symptom flagged for Apple in caveat 4 above.
-- =============================================================================
CREATE LIGHTNING REST TABLE tesla_revenue_facts FROM SEC_DATA REQUEST(
    endpoint "https://data.sec.gov/api/xbrl/companyconcept/CIK0001318605/us-gaap/Revenues.json",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW tesla_revenue_table WITH CONTAINER edgar AS
SELECT
    cik,
    `entityName` AS entity_name,
    tag          AS concept,
    fact.`start` AS period_start,
    fact.`end`   AS period_end,
    fact.val     AS value_usd,
    fact.accn    AS accession_number,
    fact.fy      AS fiscal_year,
    fact.fp      AS fiscal_period,
    fact.frame   AS period_frame,
    fact.form    AS form_type,
    fact.filed   AS filed_date
FROM sec_data.tesla_revenue_facts
LATERAL VIEW explode(units.USD) AS fact;

-- ---------------------------------------------------------------------------
-- Diagnostic (run per company if a view comes back empty or looks wrong):
--   SELECT * FROM sec_data.<company>_revenue_facts;
--   DESCRIBE sec_data.<company>_revenue_facts;
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Verification (do this BEFORE relying on any of the above -- see caveat 4):
-- confirm each REST table's row count matches the live SEC endpoint. Run
-- once per company, swapping the CIK in the URL and the table name:
--   curl -s -A "YOUR_APP_NAME YOUR_CONTACT_EMAIL" \
--     https://data.sec.gov/api/xbrl/companyconcept/CIK0000320193/us-gaap/Revenues.json \
--     | jq '.units.USD | length'
-- Then compare against:
--   SELECT COUNT(*) FROM edgar.apple_revenue_table;
-- If the Zetaris count is lower, the connector is truncating and every view
-- above inherits the same problem until that's fixed upstream.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Downstream note: EDGAR's companyconcept payload often contains overlapping
-- periods across 10-Q and 10-K filings (a quarter appears standalone AND
-- rolled into the annual figure). Keep each view above as raw fact history;
-- filter at query time, e.g.:
--   SELECT * FROM edgar.apple_revenue_table WHERE form_type = '10-K';
--   SELECT * FROM edgar.tesla_revenue_table WHERE fiscal_period = 'Q1';
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Optional: single cross-company view for side-by-side comparison. Only
-- build this once every individual view above has been verified (see
-- Verification above) -- a UNION over unverified, possibly-truncated data
-- just makes the problem harder to spot.
-- ---------------------------------------------------------------------------
-- CREATE SCHEMASTORE VIEW all_companies_revenue_table WITH CONTAINER edgar AS
-- SELECT * FROM edgar.apple_revenue_table
-- UNION ALL
-- SELECT * FROM edgar.ibm_revenue_table
-- UNION ALL
-- SELECT * FROM edgar.oracle_revenue_table
-- UNION ALL
-- SELECT * FROM edgar.walmart_revenue_table
-- UNION ALL
-- SELECT * FROM edgar.target_revenue_table
-- UNION ALL
-- SELECT * FROM edgar.ford_revenue_table
-- UNION ALL
-- SELECT * FROM edgar.tesla_revenue_table;

-- =============================================================================
-- TEARDOWN -- removes the flattened views this script created. Commented
-- out by default so a re-run of the file above doesn't accidentally wipe
-- a live environment; uncomment and run standalone when you want to tear
-- these views down.
--
-- DROP VIEW is the only teardown statement confirmed to work reliably in
-- this package. There is no SQL statement confirmed to remove the raw
-- REST tables or the SEC_DATA Lightning database registration itself --
-- see HOWTO.md, "Removing a source" and "Troubleshooting / FAQ", for the
-- full explanation. To remove the REST tables and the SEC_DATA
-- registration, use the Zetaris Data Explorer: locate the entry under
-- "File Source & API" and remove it from there.
-- =============================================================================

-- -- Optional cross-company view, if it was ever uncommented and run above:
-- DROP VIEW edgar.all_companies_revenue_table;

-- -- Per-company views:
-- DROP VIEW edgar.apple_revenue_table;
-- DROP VIEW edgar.ibm_revenue_table;
-- DROP VIEW edgar.oracle_revenue_table;
-- DROP VIEW edgar.walmart_revenue_table;
-- DROP VIEW edgar.target_revenue_table;
-- DROP VIEW edgar.ford_revenue_table;
-- DROP VIEW edgar.tesla_revenue_table;

-- To remove the SEC_DATA REST tables and Lightning database registration,
-- use the Zetaris Data Explorer's "File Source & API" panel (see
-- HOWTO.md, "Removing a source").
