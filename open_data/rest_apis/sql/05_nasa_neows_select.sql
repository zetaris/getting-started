-- =============================================================================
-- Verification / example queries for 05_nasa_neows_create.sql
-- Assumes 05_nasa_neows_create.sql has already been run.
--
-- The verification queries below are commented out by default so that
-- running this whole file doesn't automatically fire read queries against
-- every view -- each one re-hits the NASA API per the create script's
-- caveat 8, and DEMO_KEY's rate limit is easy to exhaust. Uncomment what
-- you want to run, or run it directly in the SQL Editor. The example
-- queries further down are left live, same as before.
-- =============================================================================

-- === Verification ===
-- SELECT * FROM nasa.neo_browse_table;
-- SELECT * FROM nasa.neo_close_approaches_table;

-- === Diagnostics === (run if either verification query above fails or comes back empty)
-- SELECT * FROM nasa_rest.neo_browse_page0;
-- DESCRIBE nasa_rest.neo_browse_page0;
-- If array-indexing syntax (close_approach_data[0], used in
-- neo_browse_table) isn't supported by Zetaris's SQL dialect, that's
-- worth reporting back -- neo_close_approaches_table's plain double
-- explode() doesn't depend on it and should be unaffected either way.

-- === Example queries ===
-- Run these against the views above to get a feel for the data once
-- everything's loaded. Picked to be genuinely interesting: size and hazard
-- comparisons, the closest and fastest approaches on record, an object's
-- full approach count, and a look at predicted future approaches.

-- 1. The 5 largest objects on this page by estimated maximum diameter:
SELECT name, diameter_km_min, diameter_km_max, is_potentially_hazardous_asteroid
FROM nasa.neo_browse_table
ORDER BY diameter_km_max DESC
LIMIT 5;

-- 2. Potentially hazardous asteroids on this page, largest first:
SELECT name, diameter_km_max, absolute_magnitude_h
FROM nasa.neo_browse_table
WHERE is_potentially_hazardous_asteroid = true
ORDER BY diameter_km_max DESC;

-- 3. Average estimated diameter, hazardous vs. non-hazardous -- do the
-- objects NASA flags as potentially hazardous actually tend to be
-- bigger, on this sample?
SELECT
    is_potentially_hazardous_asteroid,
    COUNT(*)                          AS object_count,
    ROUND(AVG(diameter_km_max), 3)    AS avg_diameter_km_max
FROM nasa.neo_browse_table
GROUP BY is_potentially_hazardous_asteroid;

-- 4. Most-tracked objects -- how many recorded close approaches (past
-- and predicted future) does each object have on file, most first. A
-- proxy for how long/well an object has been observed:
SELECT name, COUNT(*) AS approach_count
FROM nasa.neo_close_approaches_table
GROUP BY id, name
ORDER BY approach_count DESC
LIMIT 5;

-- 5. The single closest approach ever recorded across every object and
-- every approach on this page -- note the explicit CAST already applied
-- in the view (see caveat 6 in the create script); ordering the raw
-- string field here would give a wrong answer:
SELECT name, close_approach_date, miss_distance_km, relative_velocity_kmh
FROM nasa.neo_close_approaches_table
ORDER BY miss_distance_km ASC
LIMIT 1;

-- 6. The single fastest recorded relative velocity across every object
-- and every approach on this page:
SELECT name, close_approach_date, relative_velocity_kmh, miss_distance_km
FROM nasa.neo_close_approaches_table
ORDER BY relative_velocity_kmh DESC
LIMIT 1;

-- 7. Each object's closest-ever approach (not just its earliest, as
-- neo_browse_table gives) -- a window function ranks every object's own
-- approaches by distance, same ROW_NUMBER() OVER (...) pattern confirmed
-- working in sql/03 (Open Food Facts) query 7 and sql/04 (Singapore
-- PM2.5, failure_cases/) query 7, applied here to a genuine "top-N per
-- group" question:
SELECT name, close_approach_date, miss_distance_km
FROM (
    SELECT
        name,
        close_approach_date,
        miss_distance_km,
        ROW_NUMBER() OVER (PARTITION BY id ORDER BY miss_distance_km ASC) AS rn
    FROM nasa.neo_close_approaches_table
) ranked
WHERE rn = 1
ORDER BY miss_distance_km ASC;

-- 8. Predicted future approaches (after this script's test date) for
-- hazardous objects only, soonest first -- confirms the dataset isn't
-- purely historical: some objects have close-approach predictions out
-- to the year 2187. Swap the literal date for whatever "today" is when
-- you run this:
SELECT name, close_approach_date, miss_distance_km
FROM nasa.neo_close_approaches_table
WHERE is_potentially_hazardous_asteroid = true
  AND close_approach_date > '2026-09-19'
ORDER BY close_approach_date ASC;
