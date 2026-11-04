-- =============================================================================
-- Verification and example queries for 04_foursquare_places_create.sql.
-- Assumes 04_foursquare_places_create.sql has already been run.
--
-- Confirmed live 2026-10-31 on release 2024-11-19. DESCRIBE returned the
-- published Places columns (fsq_place_id, name, latitude, longitude,
-- locality, region, country, fsq_category_labels, website, date_created,
-- date_closed, and the rest). See
--   https://docs.foursquare.com/data-products/docs/places-os-data-schema
--
-- The release is more than 100 million places (Source Cooperative README)
-- across 81 Parquet files that are not split by city. Aggregations below
-- keep a Manhattan window so they aggregate a bounded set of places:
--   latitude BETWEEN 40.70 AND 40.82
--   longitude BETWEEN -74.02 AND -73.93
-- A scan of the prefix is about 63-75 seconds either way; the filter is
-- what keeps the GROUP BY on a subset (352530 places in this window on
-- 2026-10-31, all with country US).
-- =============================================================================

-- === Verification ===
SELECT * FROM FSQ_SOURCE_COOP.foursquare_places LIMIT 10;

-- 1. Confirm column names and inferred types before relying on the columns
-- used in every query below:
DESCRIBE FSQ_SOURCE_COOP.foursquare_places;

-- === Example queries ===
-- All queries below confirmed live against the window above.

-- 2. Overview -- places and distinct countries inside the window:
SELECT
    COUNT(*) AS total_places,
    COUNT(DISTINCT country) AS distinct_countries
FROM FSQ_SOURCE_COOP.foursquare_places
WHERE latitude BETWEEN 40.70 AND 40.82
  AND longitude BETWEEN -74.02 AND -73.93;

-- 3. Top 10 countries by place count:
SELECT country, COUNT(*) AS place_count
FROM FSQ_SOURCE_COOP.foursquare_places
WHERE latitude BETWEEN 40.70 AND 40.82
  AND longitude BETWEEN -74.02 AND -73.93
GROUP BY country
ORDER BY place_count DESC
LIMIT 10;

-- 4. Top 10 localities (cities) by place count, restricted to one country
-- to keep the group-by on one country inside the window -- change the
-- country code to explore another region:
SELECT locality, region, COUNT(*) AS place_count
FROM FSQ_SOURCE_COOP.foursquare_places
WHERE country = 'US'
  AND latitude BETWEEN 40.70 AND 40.82
  AND longitude BETWEEN -74.02 AND -73.93
GROUP BY locality, region
ORDER BY place_count DESC
LIMIT 10;

-- 5. Data completeness -- how many places carry a website vs. none, useful
-- for judging how enrichable this dataset is before building on top of it:
SELECT
    COUNT(*) AS total_places,
    COUNT(website) AS places_with_website,
    COUNT(*) - COUNT(website) AS places_without_website
FROM FSQ_SOURCE_COOP.foursquare_places
WHERE latitude BETWEEN 40.70 AND 40.82
  AND longitude BETWEEN -74.02 AND -73.93;

-- 6. Places marked closed -- date_closed is populated once Foursquare's
-- own data has flagged a place as no longer operating:
SELECT COUNT(*) AS closed_places
FROM FSQ_SOURCE_COOP.foursquare_places
WHERE date_closed IS NOT NULL
  AND latitude BETWEEN 40.70 AND 40.82
  AND longitude BETWEEN -74.02 AND -73.93;

-- 7. Places created per year -- a rough growth curve for this dataset's
-- own coverage over time, parsed from date_created (ISO 8601):
SELECT SUBSTR(date_created, 1, 4) AS creation_year, COUNT(*) AS place_count
FROM FSQ_SOURCE_COOP.foursquare_places
WHERE date_created IS NOT NULL
  AND latitude BETWEEN 40.70 AND 40.82
  AND longitude BETWEEN -74.02 AND -73.93
GROUP BY SUBSTR(date_created, 1, 4)
ORDER BY creation_year;

-- 8. A named lookup example -- find a specific well-known place by name
-- and locality. The window keeps the scan on the same Manhattan box
-- (the Empire State Building is inside it):
SELECT fsq_place_id, name, address, locality, region, country
FROM FSQ_SOURCE_COOP.foursquare_places
WHERE name = 'Empire State Building'
  AND latitude BETWEEN 40.70 AND 40.82
  AND longitude BETWEEN -74.02 AND -73.93
LIMIT 5;
