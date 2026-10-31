-- =============================================================================
-- Verification and example queries for 05_overture_maps_create.sql.
-- Assumes 05_overture_maps_create.sql has already been run.
--
-- Confirmed live 2026-10-31 on release 2026-10-21.0. The previous queries
-- referenced categories.primary, which this schema does not have
-- (UNRESOLVED_COLUMN). Primary category is taxonomy.primary; the coarser
-- label is basic_category. See
-- https://docs.overturemaps.org/schema/reference/places/place/
--
-- The place prefix is one worldwide set of files, not geo-partitions.
-- Aggregations below keep a Manhattan bbox so they aggregate a bounded
-- set of places rather than every place in the release:
--   bbox.xmin BETWEEN -74.02 AND -73.93
--   bbox.ymin BETWEEN 40.70 AND 40.82
-- A scan of the prefix is about 84-95 seconds either way, because the
-- files are not geographically split; the filter is what keeps the
-- GROUP BY / explode work on a subset (259457 places in this box on
-- 2026-10-31).
-- =============================================================================

-- === Verification ===
SELECT * FROM OVERTURE_S3.overture_places LIMIT 10;

-- 1. Confirm column names, nesting, and inferred types. Expect
-- basic_category and taxonomy, not categories:
DESCRIBE OVERTURE_S3.overture_places;

-- === Example queries ===
-- All queries below confirmed live against the bbox above.

-- 2. Overview -- places and distinct categories inside the bbox:
SELECT
    COUNT(*) AS total_places,
    COUNT(DISTINCT taxonomy.primary) AS distinct_primary_categories,
    COUNT(DISTINCT basic_category) AS distinct_basic_categories
FROM OVERTURE_S3.overture_places
WHERE bbox.xmin BETWEEN -74.02 AND -73.93
  AND bbox.ymin BETWEEN 40.70 AND 40.82;

-- 3. Top 10 primary categories by place count:
SELECT taxonomy.primary AS category, COUNT(*) AS place_count
FROM OVERTURE_S3.overture_places
WHERE bbox.xmin BETWEEN -74.02 AND -73.93
  AND bbox.ymin BETWEEN 40.70 AND 40.82
GROUP BY taxonomy.primary
ORDER BY place_count DESC
LIMIT 10;

-- 4. Top 10 countries by place count -- addresses is an array of structs,
-- so this explodes it first (a place can carry more than one address).
-- The bbox filter is applied before the explode:
SELECT addr.country AS country, COUNT(*) AS place_count
FROM (
    SELECT addresses
    FROM OVERTURE_S3.overture_places
    WHERE bbox.xmin BETWEEN -74.02 AND -73.93
      AND bbox.ymin BETWEEN 40.70 AND 40.82
) places
LATERAL VIEW explode(addresses) exploded_addr AS addr
GROUP BY addr.country
ORDER BY place_count DESC
LIMIT 10;

-- 5. Confidence score distribution -- Overture's own per-place match
-- confidence, bucketed into rough bands:
SELECT
    CASE
        WHEN confidence >= 0.9 THEN '0.9-1.0'
        WHEN confidence >= 0.7 THEN '0.7-0.9'
        WHEN confidence >= 0.5 THEN '0.5-0.7'
        ELSE '<0.5'
    END AS confidence_band,
    COUNT(*) AS place_count
FROM OVERTURE_S3.overture_places
WHERE bbox.xmin BETWEEN -74.02 AND -73.93
  AND bbox.ymin BETWEEN 40.70 AND 40.82
GROUP BY
    CASE
        WHEN confidence >= 0.9 THEN '0.9-1.0'
        WHEN confidence >= 0.7 THEN '0.7-0.9'
        WHEN confidence >= 0.5 THEN '0.5-0.7'
        ELSE '<0.5'
    END
ORDER BY confidence_band DESC;

-- 6. Data completeness -- how many places carry at least one website vs.
-- none, useful for judging how enrichable this dataset is before building
-- on top of it:
SELECT
    COUNT(*) AS total_places,
    SUM(CASE WHEN size(websites) > 0 THEN 1 ELSE 0 END) AS places_with_website,
    SUM(CASE WHEN websites IS NULL OR size(websites) = 0 THEN 1 ELSE 0 END) AS places_without_website
FROM OVERTURE_S3.overture_places
WHERE bbox.xmin BETWEEN -74.02 AND -73.93
  AND bbox.ymin BETWEEN 40.70 AND 40.82;

-- 7. Top 10 brands by location count -- brand is a struct that's null for
-- independent places, so this only counts chains/franchises:
SELECT brand.names.primary AS brand_name, COUNT(*) AS location_count
FROM OVERTURE_S3.overture_places
WHERE brand IS NOT NULL
  AND bbox.xmin BETWEEN -74.02 AND -73.93
  AND bbox.ymin BETWEEN 40.70 AND 40.82
GROUP BY brand.names.primary
ORDER BY location_count DESC
LIMIT 10;

-- 8. A named lookup example -- find a specific well-known place by its
-- primary name. The bbox keeps the scan on the same Manhattan window
-- (the Empire State Building is inside it):
SELECT id, names.primary AS name, taxonomy.primary AS category, basic_category, confidence
FROM OVERTURE_S3.overture_places
WHERE names.primary = 'Empire State Building'
  AND bbox.xmin BETWEEN -74.02 AND -73.93
  AND bbox.ymin BETWEEN 40.70 AND 40.82
LIMIT 5;
