-- =============================================================================
-- Source:   Eurostat REST API (Statistics API) -- unemployment rate example
-- License:  Eurostat's "Copyright notice and free re-use of data" policy is
--           generally understood to align with CC-BY 4.0 --
--           https://ec.europa.eu/eurostat/about/policies/copyright -- worth
--           reading directly, not independently confirmed as a hard match.
-- Format:   REST/JSON -- ⚠️ JSON-stat 2.0, NOT array-of-structs. See
--           caveat 1 below -- this is the HIGHEST-RISK source in this
--           package, likely to need a fundamentally different approach or
--           to be dropped.
-- Docs:     https://wikis.ec.europa.eu/display/EUROSTATHELP/API+Statistics+-+data+query
--           https://json-stat.org/ (the underlying open JSON-stat format spec)
-- Rate limit: fully public, no key, no registration, CORS-enabled.
-- Before running: sanity-check the endpoint returns something sane, and
-- pick a dataset code + dimension filters that actually have data for the
-- combination you choose (see caveat 2) --
--   curl -s "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/une_rt_m?format=JSON&geo=PL&sex=T&age=Y15-74&unit=PC_ACT&s_adj=SA&lang=EN" | python3 -m json.tool | head -40
-- =============================================================================
--
-- Investigated (not yet live-tested against Zetaris) 2026-09-19:
--   1. ⚠️ FUNDAMENTALLY DIFFERENT SHAPE, likely not flattenable with this
--      package's usual LATERAL VIEW explode() pattern at all. Eurostat
--      returns JSON-stat 2.0 (https://json-stat.org/), a sparse
--      MULTI-DIMENSIONAL ARRAY format, not row-oriented JSON:
--        - `dimension`: an object describing each axis (e.g. geo, time,
--          sex, age, unit), each with a `category.index` object mapping
--          category codes to integer positions.
--        - `value`: a SPARSE object keyed by a computed flat integer
--          offset (as a string, e.g. "0", "1", "523") across all
--          dimensions in row-major order per the `size` array -- e.g. if
--          `size` is [1,1,1,1,1,1,524] (six single-value dimensions plus
--          524 time points), the offset IS the time index directly, and
--          `value` looks like {"0": 5.2, "1": 5.3, ...} (missing keys mean
--          no data for that time point).
--      This is NOT an array of objects -- there's nothing to
--      LATERAL VIEW explode(). Reconstructing a proper (date, value) table
--      from this requires decoding the offset-to-dimension mapping, which
--      is either a client-side transform (outside SQL entirely) or would
--      need Zetaris to have JSON-stat-aware ingestion built in (unknown --
--      not found in any Zetaris doc referenced in this package so far).
--   2. During investigation, multiple attempted dataset/dimension
--      combinations returned an EMPTY `value: {}` -- either because the
--      specific codes tried don't have data for that slice, or because one
--      dataset tried (prc_hicp_manr) turned out to be discontinued
--      (replaced by prc_hicp_minr per the response's own `extension.
--      description` field). NOT YET FOUND a combination that returns
--      actual populated values during this pass -- confirm a working
--      query via Eurostat's own data browser (https://ec.europa.eu/
--      eurostat/databrowser/) before trusting the query below returns
--      anything.
--   3. Given caveats 1 and 2, this script demonstrates the SIMPLEST
--      possible case -- register the raw JSON-stat response as-is and
--      expose `dimension` (the structured axis metadata, which IS a
--      normal nested-struct shape) as a view, WITHOUT attempting to
--      decode `value` into a proper time series. If Zetaris can't usefully
--      query a JSON-stat response at all, this is a strong DROP candidate
--      for this package -- flag it as such rather than spending more time
--      forcing a fit.
--
-- ---------------------------------------------------------------------------
-- STEP 0: Lightning database for this source.
-- ---------------------------------------------------------------------------
CREATE LIGHTNING DATABASE EUROSTAT_REST DESCRIBE BY "Eurostat REST API JSON-stat source";

-- ---------------------------------------------------------------------------
-- STEP 1: SCHEMASTORE container. RUN ONCE -- see open_data/rest_apis/HOWTO.md
-- sec 2 (no IF NOT EXISTS support). Comment out on a re-run if it already
-- exists in your environment.
-- ---------------------------------------------------------------------------
CREATE SCHEMASTORE CONTAINER eurostat;

-- =============================================================================
-- UNEMPLOYMENT RATE -- Poland, monthly, seasonally adjusted (une_rt_m)
-- CONFIRM this combination actually returns non-empty `value` via the
-- Before-running curl check above -- swap geo/dimension codes if not.
-- =============================================================================
CREATE LIGHTNING REST TABLE une_rt_m_pl FROM EUROSTAT_REST REQUEST(
    endpoint "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/une_rt_m?format=JSON&geo=PL&sex=T&age=Y15-74&unit=PC_ACT&s_adj=SA&lang=EN",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
) BODY ();

-- Minimal view -- just the dataset's own descriptive metadata and axis
-- labels (a normal nested-struct shape), NOT the actual data values (see
-- caveat 1 -- decoding `value` into rows is unsolved):
CREATE SCHEMASTORE VIEW une_rt_m_pl_metadata_table WITH CONTAINER eurostat AS
SELECT
    label       AS dataset_label,
    source      AS dataset_source,
    updated     AS last_updated,
    dimension.geo.category.label   AS geo_labels,
    dimension.time.category.index  AS time_index_map
FROM eurostat_rest.une_rt_m_pl;

-- Verify (this only confirms the metadata view works -- it does NOT confirm
-- the actual unemployment-rate values are queryable):
SELECT * FROM eurostat.une_rt_m_pl_metadata_table;

-- ---------------------------------------------------------------------------
-- Diagnostic (run regardless of whether the view above works, to see the
-- raw `value` shape and judge whether decoding it is worth attempting):
--   SELECT * FROM eurostat_rest.une_rt_m_pl;
--   DESCRIBE eurostat_rest.une_rt_m_pl;
-- If `value` comes back as an opaque map/struct Zetaris can't index by a
-- computed string key, that's the practical end of this approach without
-- a pre-processing step outside Zetaris -- report back and treat Eurostat
-- as a DROP candidate for this package rather than continuing to iterate.
-- ---------------------------------------------------------------------------
