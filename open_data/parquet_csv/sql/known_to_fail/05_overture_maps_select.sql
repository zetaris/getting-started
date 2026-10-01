-- =============================================================================
-- Verification and example queries for 05_overture_maps_create.sql.
-- Assumes 05_overture_maps_create.sql has already been run.
--
-- KNOWN TO FAIL -- live-tested results per query, against a real Zetaris
-- instance (see sql/known_to_fail/ISSUE-05-overture.md for the full
-- writeup):
--   Verification SELECT * ... LIMIT  -- succeeded, with LIMIT 10 and LIMIT 1000
--   CACHE TABLE                      -- failed with a 500 error
--   1. DESCRIBE                      -- succeeded
--   2. Overview                      -- failed with a 500 error
--   3. Top categories                -- failed with a 500 error
--   4. Top countries (explode)       -- failed with a 500 error
--   5. Confidence distribution       -- did not complete; stopped after
--                                        2m40s, assumed to also fail
--   6. Website completeness          -- skipped, not run
--   7. Top brands                    -- skipped, not run
--   8. Named lookup                  -- failed with a 500 error
-- Only the plain, unaggregated SELECT and DESCRIBE work. Every query doing
-- real work (GROUP BY, explode, CASE, a WHERE predicate on a struct field)
-- fails or times out. Kept below as originally written, since the queries
-- themselves aren't the problem -- see the ISSUE file for why.
--
-- Column names and nesting below (names.primary, categories.primary,
-- categories.alternate, addresses[].country, websites[], confidence, brand)
-- follow Overture's published Places theme schema:
--   https://docs.overturemaps.org/schema/reference/places/place/
-- =============================================================================

-- === Verification === (confirmed working, LIMIT 10 and LIMIT 1000 both)
SELECT * FROM OVERTURE_S3.overture_places LIMIT 10;

-- 1. Confirm column names, nesting, and inferred types -- confirmed working:
DESCRIBE OVERTURE_S3.overture_places;

-- === Example queries === (none of the below are confirmed working -- see
-- the per-query results in the header above)

-- 2. Overview -- total places and distinct primary categories in this
-- release. FAILED with a 500 error:
SELECT
    COUNT(*) AS total_places,
    COUNT(DISTINCT categories.primary) AS distinct_primary_categories
FROM OVERTURE_S3.overture_places;

-- 3. Top 10 primary categories by place count. FAILED with a 500 error:
SELECT categories.primary AS category, COUNT(*) AS place_count
FROM OVERTURE_S3.overture_places
GROUP BY categories.primary
ORDER BY place_count DESC
LIMIT 10;

-- 4. Top 10 countries by place count -- addresses is an array of structs,
-- so this explodes it first (a place can carry more than one address).
-- FAILED with a 500 error:
SELECT addr.country AS country, COUNT(*) AS place_count
FROM OVERTURE_S3.overture_places
LATERAL VIEW explode(addresses) exploded_addr AS addr
GROUP BY addr.country
ORDER BY place_count DESC
LIMIT 10;

-- 5. Confidence score distribution -- Overture's own per-place match
-- confidence, bucketed into rough bands. DID NOT COMPLETE -- stopped after
-- 2m40s with no result; assumed to also fail with a 500 error if left to
-- run further, consistent with queries 2-4 and 8:
SELECT
    CASE
        WHEN confidence >= 0.9 THEN '0.9-1.0'
        WHEN confidence >= 0.7 THEN '0.7-0.9'
        WHEN confidence >= 0.5 THEN '0.5-0.7'
        ELSE '<0.5'
    END AS confidence_band,
    COUNT(*) AS place_count
FROM OVERTURE_S3.overture_places
GROUP BY 1
ORDER BY confidence_band DESC;

-- 6. Data completeness -- how many places carry at least one website vs.
-- none, useful for judging how enrichable this dataset is before building
-- on top of it. SKIPPED -- not run, given queries 2-5's results:
SELECT
    COUNT(*) AS total_places,
    SUM(CASE WHEN size(websites) > 0 THEN 1 ELSE 0 END) AS places_with_website,
    SUM(CASE WHEN websites IS NULL OR size(websites) = 0 THEN 1 ELSE 0 END) AS places_without_website
FROM OVERTURE_S3.overture_places;

-- 7. Top 10 brands by location count -- brand is a struct that's null for
-- independent places, so this only counts chains/franchises. SKIPPED --
-- not run, given queries 2-5's results:
SELECT brand.names.primary AS brand_name, COUNT(*) AS location_count
FROM OVERTURE_S3.overture_places
WHERE brand IS NOT NULL
GROUP BY brand.names.primary
ORDER BY location_count DESC
LIMIT 10;

-- 8. A named lookup example -- find a specific well-known place by its
-- primary name, the kind of point lookup this dataset is meant to serve.
-- FAILED with a 500 error:
SELECT id, names.primary AS name, categories.primary AS category, confidence
FROM OVERTURE_S3.overture_places
WHERE names.primary = 'Empire State Building'
LIMIT 5;
