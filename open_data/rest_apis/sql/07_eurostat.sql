-- =============================================================================
-- Source:   Eurostat REST API (Statistics API) -- unemployment rate example
-- License:  Eurostat's "Copyright notice and free re-use of data" policy is
--           generally understood to align with CC-BY 4.0 --
--           https://ec.europa.eu/eurostat/about/policies/copyright -- worth
--           reading directly, not independently confirmed as a hard match.
-- Format:   REST/JSON -- JSON-stat 2.0, NOT array-of-structs. See
--           caveat 1 below -- this was the HIGHEST-RISK source in this
--           package; both the metadata-only path AND a full decode of
--           the sparse value data into real rows are now CONFIRMED
--           WORKING (see caveats 5-6c).
-- Docs:     https://wikis.ec.europa.eu/display/EUROSTATHELP/API+Statistics+-+data+query
--           https://json-stat.org/ (the underlying open JSON-stat format spec)
-- Rate limit: fully public, no key, no registration, CORS-enabled.
-- Before running: sanity-check the endpoint returns something sane --
--   curl -s "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/une_rt_m?format=JSON&geo=PL&sex=T&age=TOTAL&unit=PC_ACT&s_adj=SA&lang=EN" | python3 -m json.tool | head -40
-- =============================================================================
--
-- Live-tested and confirmed working end to end (2026-09-19): the base
-- REST table, the metadata-only view, the snapshot view, and the full
-- value-decode view (une_rt_m_pl_series_table, all 355 rows, matching
-- the count and values found via curl during investigation) are all
-- confirmed in Zetaris -- and every one of the 8 example queries below
-- has been run and verified. This is the first source in this package
-- to go from "highest risk, likely drop candidate" to fully working,
-- including a genuinely new reusable technique (caveats 5-6c) for
-- decoding sparse dynamic-key JSON via to_json/from_json coercion.
--
-- Investigated 2026-09-19:
--   1. FUNDAMENTALLY DIFFERENT SHAPE from every array-of-structs source in
--      this package. Eurostat returns JSON-stat 2.0 (https://json-stat.org/),
--      a sparse MULTI-DIMENSIONAL ARRAY format, not row-oriented JSON:
--        - `dimension`: an object describing each axis (e.g. geo, time,
--          sex, age, unit), each with a `category.index` object mapping
--          category codes to integer positions, and a `category.label`
--          object mapping codes to human-readable names.
--        - `value`: a SPARSE object keyed by a computed flat integer
--          offset (as a string, e.g. "0", "1", "523") across all
--          dimensions in row-major order per the `size` array -- e.g. if
--          `size` is [1,1,1,1,1,1,524] (six single-value dimensions plus
--          524 time points), the offset IS the time index directly, and
--          `value` looks like {"168": 11.8, "169": 11.5, ...} (missing
--          keys mean no published data for that time point).
--      There's nothing here to LATERAL VIEW explode() the way every other
--      source in this package works -- see caveats 5-6 for what was tried
--      instead.
--   2. BUG FOUND AND FIXED, confirmed via curl (2026-09-19): the original
--      version of this script used `age=Y15-74`, which is NOT a valid age
--      code for the une_rt_m dataset -- Eurostat doesn't error on an
--      invalid code, it silently returns a dimension with ZERO valid
--      categories (`dimension.age.category.index: {}`) and therefore an
--      EMPTY `value: {}` for the whole query, which looked like "no data
--      available" rather than "wrong parameter." The actual valid age
--      codes for this dataset are `TOTAL`, `Y_LT25` (under 25), and
--      `Y25-74` (25 to 74) -- confirmed by querying without an age filter
--      and reading back `dimension.age.category.index`. Fixed below to
--      use `age=TOTAL`. General lesson: an empty JSON-stat `value` object
--      can mean "this exact combination of codes doesn't exist" just as
--      easily as "no data was ever collected" -- check
--      `dimension.<name>.category.index` for the dimension you're
--      filtering on before assuming the latter.
--   3. With the fix in caveat 2, this combination (Poland, total
--      population, seasonally adjusted unemployment rate, monthly) returns
--      355 populated values out of a possible 524 time slots, confirmed
--      CONTIGUOUS from index 168 (period "1997-01") through index 522
--      (period "2026-07") -- index 523 ("2026-08") is simply not
--      published yet, a normal reporting lag, not a gap or a bug. This is
--      a real, usable 29-year monthly time series once decoded.
--   4. `sourceLocation`-style dynamic-key gotchas don't apply here, but a
--      different one does: `label`, `source`, `updated`, `dimension`,
--      `value` are all lowercase, ordinary field names -- no
--      backtick-quoting needed for the top-level fields used in the
--      metadata view. The dynamic keys are one level down, inside
--      `value` and inside each dimension's `category.index`/
--      `category.label` objects (see caveats 5-8).
--   5. CONFIRMED (see caveat 6c): whether `value` can be flattened into a
--      proper (period, rate) table at all depends on how Zetaris's
--      underlying Spark engine infers the type of a JSON object with
--      hundreds of dynamic, purely-numeric-string keys. Spark's default
--      JSON schema inference treats such an object as a STRUCT with one
--      field per observed key (e.g. `` value.`522` `` individually
--      addressable via backtick-quoted dot-access, the same pattern
--      already confirmed elsewhere in this package) -- NOT as a MAP, so a
--      direct `LATERAL VIEW explode(value)` fails with a type-mismatch
--      error (explode() requires an ARRAY or MAP) -- confirmed live.
--   6. Two things were tried to work around caveat 5, in increasing order
--      of risk:
--        a. LOW RISK -- direct dot-access to a handful of SPECIFIC known-
--           present time indices (confirmed present via curl: 168, 510,
--           522), the exact same backtick-quoted-field technique already
--           confirmed throughout this package, just applied to numeric
--           keys instead of camelCase ones. This needs no explode() and
--           no assumption about map-vs-struct inference beyond "each
--           numeric key becomes its own addressable field" -- see the
--           une_rt_m_pl_snapshot_table view and queries 2-3 below.
--        b. HIGHER RISK, NOW CONFIRMED WORKING (see caveat 6c) -- a full
--           decode of every available value into a real (period, rate)
--           row per month,
--           using `from_json(to_json(value), 'map<string,double>')` to
--           explicitly coerce the inferred STRUCT back into a MAP via a
--           round-trip through JSON text with an explicit target schema
--           (a standard Spark SQL technique, not something specific to
--           this package), then `LATERAL VIEW explode()` on the result,
--           joined against `dimension.time.category.index` (also
--           exploded) to translate the raw numeric offset back into a
--           real period label like "2026-07". See
--           une_rt_m_pl_series_table and queries 4-8 below.
--   6c. CONFIRMED WORKING against Zetaris (2026-09-19): the first version
--       of une_rt_m_pl_series_table applied the to_json/from_json
--       coercion to `value` but NOT to `dimension.time.category.index`,
--       which has the exact same dynamic-key struct-inference problem --
--       the resulting error confirmed this precisely, showing a
--       `DATATYPE_MISMATCH` on `explode(dimension.time.category.index)`
--       specifically, with the STRUCT's ~524 individual BIGINT fields
--       spelled out in the error message, while the `value` coercion's
--       own Generate node in the query plan raised NO type error at all.
--       Applying the identical `from_json(to_json(...), 'map<string,
--       bigint>')` pattern to the time-index explode too (the version now
--       in this script) FIXED IT -- confirmed live: 355 rows returned,
--       exactly matching the count and values found via curl during
--       investigation (e.g. 1997-01 = 11.8). This is a genuinely new,
--       reusable technique for this package: ANY dynamic-key JSON object
--       (not just Eurostat's) can be exploded this way, by coercing every
--       such object through to_json/from_json with an explicit map
--       schema before calling explode() on it, rather than needing
--       Zetaris to infer MAP natively.
--   7. Caveat 6a's snapshot view and its two queries don't depend on
--      solving the struct-vs-map problem at all, so they were a safe,
--      independent fallback while caveat 6b/6c's decode view was still
--      unconfirmed -- now that the decode view is confirmed working too
--      (caveat 6c), both approaches are fully usable, kept here as two
--      genuinely different techniques rather than one being a fallback
--      for the other.
--   8. `dimension.time.category.index` maps a period label (e.g.
--      "2026-07") to its integer offset. For time, the label IS already
--      a human-readable period string (unlike, say, a country code that
--      needs `category.label` for a readable name) -- so decoding time
--      only needs `category.index`, not `category.label`.
--
-- ---------------------------------------------------------------------------
-- STEP 0: Lightning database for this source.
-- ---------------------------------------------------------------------------
CREATE LIGHTNING DATABASE EUROSTAT_REST DESCRIBE BY "Eurostat REST API JSON-stat source";

-- ---------------------------------------------------------------------------
-- STEP 1: SCHEMASTORE container. RUN ONCE -- see open_data/rest_apis/HOWTO.md,
-- "Known limitations" (no IF NOT EXISTS support). Comment out on a re-run
-- if it already exists in your environment.
-- ---------------------------------------------------------------------------
CREATE SCHEMASTORE CONTAINER eurostat;

-- =============================================================================
-- UNEMPLOYMENT RATE -- Poland, total population, monthly, seasonally
-- adjusted (une_rt_m). Uses age=TOTAL, not the originally-tried Y15-74 --
-- see caveat 2.
-- =============================================================================
CREATE LIGHTNING REST TABLE une_rt_m_pl FROM EUROSTAT_REST REQUEST(
    endpoint "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/une_rt_m?format=JSON&geo=PL&sex=T&age=TOTAL&unit=PC_ACT&s_adj=SA&lang=EN",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
) BODY ();

-- Confirmed working: the dataset's own descriptive metadata and axis
-- labels (a normal nested-struct shape), NOT the actual data values:
CREATE SCHEMASTORE VIEW une_rt_m_pl_metadata_table WITH CONTAINER eurostat AS
SELECT
    label       AS dataset_label,
    source      AS dataset_source,
    updated     AS last_updated,
    dimension.geo.category.label   AS geo_labels,
    dimension.time.category.index  AS time_index_map
FROM eurostat_rest.une_rt_m_pl;

-- LOW-RISK spot-check view (see caveat 6a) -- three specific, confirmed-
-- present time indices pulled out via direct backtick-quoted dot-access,
-- no explode() involved at all:
CREATE SCHEMASTORE VIEW une_rt_m_pl_snapshot_table WITH CONTAINER eurostat AS
SELECT
    value.`168` AS rate_1997_01,
    value.`510` AS rate_2025_07,
    value.`522` AS rate_2026_07
FROM eurostat_rest.une_rt_m_pl;

-- Full decode (see caveat 6b) -- turns the whole sparse `value` object
-- into a real (period, rate) row per available month. CONFIRMED WORKING
-- against Zetaris (2026-09-19, see caveat 6c) -- returns all 355 rows.
-- Note both dynamic-key objects being exploded (`value` and
-- `dimension.time.category.index`) need the same to_json/from_json
-- coercion -- a single plain explode() on either one (without coercion)
-- fails with a DATATYPE_MISMATCH, since both are inferred as a STRUCT,
-- not a MAP:
CREATE SCHEMASTORE VIEW une_rt_m_pl_series_table WITH CONTAINER eurostat AS
SELECT
    time_label                    AS period,
    CAST(rate_value AS DOUBLE)    AS unemployment_rate_pct
FROM eurostat_rest.une_rt_m_pl
LATERAL VIEW explode(from_json(to_json(value), 'map<string,double>')) AS time_key, rate_value
LATERAL VIEW explode(from_json(to_json(dimension.time.category.index), 'map<string,bigint>')) AS time_label, time_index_value
WHERE CAST(time_key AS INT) = time_index_value;

-- Verify:
SELECT * FROM eurostat.une_rt_m_pl_metadata_table;
SELECT * FROM eurostat.une_rt_m_pl_snapshot_table;
SELECT * FROM eurostat.une_rt_m_pl_series_table ORDER BY period;

-- ---------------------------------------------------------------------------
-- Diagnostic (kept for reference -- une_rt_m_pl_series_table is confirmed
-- working now, but this is useful if the same pattern fails on a
-- different JSON-stat/SDMX dataset elsewhere, e.g. ABS, sql/09):
--   SELECT * FROM eurostat_rest.une_rt_m_pl;
--   DESCRIBE eurostat_rest.une_rt_m_pl;
-- CONFIRMED (2026-09-19, see caveat 6c): `value` and
-- `dimension.time.category.index` are BOTH inferred as a STRUCT with one
-- field per dynamic key, not a MAP, exactly as caveat 5 predicted. The
-- to_json/from_json coercion, applied to BOTH exploded fields, resolves
-- this -- confirmed by 355 correct rows being returned. If this pattern
-- fails on a different dynamic-key source, check whether EVERY dynamic-
-- key object being exploded in the same query has the coercion applied,
-- not just the first one you noticed -- that was the exact mistake that
-- produced the DATATYPE_MISMATCH this script hit before the fix.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Example queries -- ALL CONFIRMED WORKING against Zetaris (2026-09-19).
-- Queries 1-3 use the metadata and snapshot views (no explode()
-- involved); queries 4-8 use the fully-decoded une_rt_m_pl_series_table.
-- ---------------------------------------------------------------------------

-- 1. Dataset descriptive metadata -- confirms which dataset, which
-- region, and when it was last updated at the source:
SELECT dataset_label, dataset_source, last_updated
FROM eurostat.une_rt_m_pl_metadata_table;

-- 2. Long-run change -- Poland's unemployment rate in the earliest
-- available month on record (1997-01) versus the most recent published
-- month (2026-07), using only the low-risk snapshot view:
SELECT
    rate_1997_01,
    rate_2026_07,
    ROUND(rate_2026_07 - rate_1997_01, 1) AS change_percentage_points
FROM eurostat.une_rt_m_pl_snapshot_table;

-- 3. Year-over-year change -- July 2026 versus July 2025, same
-- low-risk technique:
SELECT
    rate_2025_07,
    rate_2026_07,
    ROUND(rate_2026_07 - rate_2025_07, 1) AS year_over_year_change_pct_points
FROM eurostat.une_rt_m_pl_snapshot_table;

-- 4. Full decoded time series, chronological -- only works if
-- une_rt_m_pl_series_table above succeeded:
SELECT * FROM eurostat.une_rt_m_pl_series_table ORDER BY period;

-- 5. The highest and lowest unemployment rate ever recorded in this
-- series, and which month each occurred:
SELECT period, unemployment_rate_pct
FROM eurostat.une_rt_m_pl_series_table
ORDER BY unemployment_rate_pct DESC
LIMIT 1;

SELECT period, unemployment_rate_pct
FROM eurostat.une_rt_m_pl_series_table
ORDER BY unemployment_rate_pct ASC
LIMIT 1;

-- 6. The most recent 12 published months, most recent first -- a normal
-- "recent trend" view now that the data is in proper row form:
SELECT period, unemployment_rate_pct
FROM eurostat.une_rt_m_pl_series_table
ORDER BY period DESC
LIMIT 12;

-- 7. Average unemployment rate per decade -- extracting the year from
-- the period string and bucketing it, a simple aggregate that only makes
-- sense once the sparse value data is in real rows:
SELECT
    CONCAT(SUBSTR(period, 1, 3), '0s') AS decade,
    ROUND(AVG(unemployment_rate_pct), 1) AS avg_unemployment_rate_pct,
    COUNT(*) AS months_counted
FROM eurostat.une_rt_m_pl_series_table
GROUP BY 1
ORDER BY decade;

-- 8. First month the rate dropped to single digits (below 10%) --
-- a milestone-style query, ordered chronologically and taking the
-- earliest match:
SELECT period, unemployment_rate_pct
FROM eurostat.une_rt_m_pl_series_table
WHERE unemployment_rate_pct < 10
ORDER BY period ASC
LIMIT 1;

-- ---------------------------------------------------------------------------
-- Attribution reminder -- carry this into any README or demo that
-- displays data from this source:
--   "Source: Eurostat, une_rt_m (unemployment rate, monthly)."
-- ---------------------------------------------------------------------------

-- =============================================================================
-- TEARDOWN -- removes the flattened views this script created. Commented
-- out by default so a re-run of the file above doesn't accidentally wipe
-- a live environment; uncomment and run standalone when you want to tear
-- these views down.
--
-- DROP VIEW is the only teardown statement confirmed to work reliably in
-- this package. There is no SQL statement confirmed to remove the raw
-- REST table or the EUROSTAT_REST Lightning database registration itself
-- -- see HOWTO.md, "Removing a source" and "Troubleshooting / FAQ", for
-- the full explanation.
-- =============================================================================

-- DROP VIEW eurostat.une_rt_m_pl_metadata_table;
-- DROP VIEW eurostat.une_rt_m_pl_snapshot_table;
-- DROP VIEW eurostat.une_rt_m_pl_series_table;

-- To remove the EUROSTAT_REST REST table and Lightning database
-- registration, use the Zetaris Data Explorer's "File Source & API"
-- panel (see HOWTO.md, "Removing a source").
