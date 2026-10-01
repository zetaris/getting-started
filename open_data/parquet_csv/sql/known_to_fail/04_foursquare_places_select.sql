-- =============================================================================
-- Verification and example queries for 04_foursquare_places_create.sql.
-- Assumes 04_foursquare_places_create.sql has already been run.
--
-- KNOWN TO FAIL -- every query below, including the plain verification
-- SELECT, fails with a 500 error against a live Zetaris instance, as does
-- CACHE TABLE. See sql/known_to_fail/ISSUE.md. Kept as originally written
-- (before that was discovered) so the intended queries aren't lost if the
-- underlying issue is ever fixed.
--
-- Column names below (fsq_place_id, name, latitude, longitude, locality,
-- region, country, fsq_category_labels, website, date_created, date_closed)
-- follow Foursquare's published Places schema:
--   https://docs.foursquare.com/data-products/docs/places-os-data-schema
-- They were never confirmed against a live DESCRIBE, since query 1 below
-- also hits the 500 error.
-- =============================================================================

-- === Verification ===
SELECT * FROM FSQ_SOURCE_COOP.foursquare_places LIMIT 10;

-- 1. Confirm column names and inferred types before relying on the columns
-- used in every query below:
DESCRIBE FSQ_SOURCE_COOP.foursquare_places;

-- === Example queries ===
-- Column names below are unconfirmed -- adjust to match query 1's actual
-- output if Parquet inference or a schema revision produced different names.

-- 2. Overview -- total places and distinct countries in this release:
SELECT
    COUNT(*) AS total_places,
    COUNT(DISTINCT country) AS distinct_countries
FROM FSQ_SOURCE_COOP.foursquare_places;

-- 3. Top 10 countries by place count:
SELECT country, COUNT(*) AS place_count
FROM FSQ_SOURCE_COOP.foursquare_places
GROUP BY country
ORDER BY place_count DESC
LIMIT 10;

-- 4. Top 10 localities (cities) by place count, restricted to one country
-- to keep the group-by cheap on a global dataset -- change the country
-- code to explore another region:
SELECT locality, region, COUNT(*) AS place_count
FROM FSQ_SOURCE_COOP.foursquare_places
WHERE country = 'US'
GROUP BY locality, region
ORDER BY place_count DESC
LIMIT 10;

-- 5. Data completeness -- how many places carry a website vs. none, useful
-- for judging how enrichable this dataset is before building on top of it:
SELECT
    COUNT(*) AS total_places,
    COUNT(website) AS places_with_website,
    COUNT(*) - COUNT(website) AS places_without_website
FROM FSQ_SOURCE_COOP.foursquare_places;

-- 6. Places marked closed -- date_closed is populated once Foursquare's
-- own data has flagged a place as no longer operating:
SELECT COUNT(*) AS closed_places
FROM FSQ_SOURCE_COOP.foursquare_places
WHERE date_closed IS NOT NULL;

-- 7. Places created per year -- a rough growth curve for this dataset's
-- own coverage over time, parsed from date_created (ISO 8601):
SELECT SUBSTR(date_created, 1, 4) AS creation_year, COUNT(*) AS place_count
FROM FSQ_SOURCE_COOP.foursquare_places
WHERE date_created IS NOT NULL
GROUP BY SUBSTR(date_created, 1, 4)
ORDER BY creation_year;

-- 8. A named lookup example -- find a specific well-known place by name
-- and locality, the kind of point lookup this dataset is meant to serve:
SELECT fsq_place_id, name, address, locality, region, country
FROM FSQ_SOURCE_COOP.foursquare_places
WHERE name = 'Empire State Building'
LIMIT 5;
