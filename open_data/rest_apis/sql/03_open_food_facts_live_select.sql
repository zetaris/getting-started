-- =============================================================================
-- Verification / example queries for 03_open_food_facts_live_create.sql
-- Assumes 03_open_food_facts_live_create.sql has already been run.
--
-- The verification queries below are commented out by default so that
-- running this whole file doesn't automatically fire read queries against
-- every table. Uncomment what you want to run, or run it directly in the
-- SQL Editor. The example queries further down are left live, same as
-- before -- they're meant to be run once you're exploring the data.
-- =============================================================================

-- === Verification ===
-- SELECT * FROM openfoodfacts.nutella_nutrition_table;
-- SELECT * FROM openfoodfacts.nutella_ingredients_table;
-- SELECT * FROM openfoodfacts.cocacola_nutrition_table;
-- SELECT * FROM openfoodfacts.cocacola_ingredients_table;
-- SELECT * FROM openfoodfacts.prince_nutrition_table;
-- SELECT * FROM openfoodfacts.prince_ingredients_table;
-- SELECT * FROM openfoodfacts.pesto_nutrition_table;
-- SELECT * FROM openfoodfacts.pesto_ingredients_table;

-- === Diagnostics === (run if any verification query above fails or comes back empty)
-- SELECT * FROM off_live_rest.nutella_product;
-- DESCRIBE off_live_rest.nutella_product;
-- If sparse/optional struct fields (present on some ingredients, absent on
-- others -- caveat 2 in the create script) cause a schema-inference error
-- rather than a clean null-fill, that's worth reporting back -- it would
-- affect every REST source in this package whose nested structs aren't
-- uniformly shaped.

-- === Example queries ===
-- Run these against the views created in 03_open_food_facts_live_create.sql
-- to get a feel for the data once everything's loaded. Picked to be
-- genuinely interesting rather than just exercising syntax: nutrition
-- comparisons, ingredient overlap across unrelated brands, and a couple of
-- "which product is the odd one out" style questions.

-- 1. Sugar ranking -- which of these four products packs the most sugar
-- per 100g:
SELECT product_name, sugars_100g
FROM openfoodfacts.all_products_nutrition_table
ORDER BY sugars_100g DESC;

-- 2. Full nutrition snapshot, worst nutri-score first -- a quick
-- "healthiest to least healthy" read across very different product types
-- (a spread, a soda, a biscuit, a pasta sauce):
SELECT
    product_name,
    nutriscore_grade,
    nova_group,
    energy_kcal_100g,
    fat_100g,
    sugars_100g,
    salt_100g
FROM openfoodfacts.all_products_nutrition_table
ORDER BY nutriscore_grade, energy_kcal_100g DESC;

-- 3. "Sugar calorie share" -- roughly what fraction of each product's
-- energy comes from sugar alone (sugar has ~4 kcal/g), a normalized way
-- to compare a solid spread against a liquid soda:
SELECT
    product_name,
    sugars_100g,
    energy_kcal_100g,
    ROUND(100.0 * (sugars_100g * 4) / energy_kcal_100g, 1) AS pct_calories_from_sugar
FROM openfoodfacts.all_products_nutrition_table
WHERE energy_kcal_100g > 0
ORDER BY pct_calories_from_sugar DESC;

-- 4. Ingredient count and vegan share per product -- how many declared
-- ingredients each product has, and what fraction are tagged fully vegan:
SELECT
    product_name,
    COUNT(*)                                              AS ingredient_count,
    SUM(CASE WHEN is_vegan = 'yes' THEN 1 ELSE 0 END)      AS vegan_ingredient_count,
    ROUND(100.0 * SUM(CASE WHEN is_vegan = 'yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_vegan_ingredients
FROM openfoodfacts.all_products_ingredients_table
GROUP BY product_name
ORDER BY pct_vegan_ingredients DESC;

-- 5. Shared ingredients across unrelated brands -- which raw ingredients
-- (by Open Food Facts taxonomy id) show up in more than one of these four
-- otherwise-unrelated products (e.g. sugar showing up in both Coca-Cola
-- and Prince biscuits):
SELECT
    ingredient_id,
    COUNT(DISTINCT product_name) AS product_count,
    COLLECT_SET(product_name) AS products
FROM openfoodfacts.all_products_ingredients_table
GROUP BY ingredient_id
HAVING COUNT(DISTINCT product_name) > 1
ORDER BY product_count DESC;

-- 6. Oil-family ingredients and how concentrated they are per product --
-- a simple substring search across the exploded ingredient list, useful
-- for spotting palm oil / sunflower oil / vegetable oil without knowing
-- the exact taxonomy id in advance:
SELECT product_name, ingredient_id, ingredient_text, percent_estimate
FROM openfoodfacts.all_products_ingredients_table
WHERE ingredient_id LIKE '%oil%'
ORDER BY percent_estimate DESC;

-- 7. Each product's single dominant ingredient by percent_estimate -- the
-- one ingredient that makes up the largest share of the product, a good
-- "what is this actually mostly made of" question.
--
-- NOTE: not a JOIN-back-to-itself pattern (unlike PokéAPI's superficially
-- similar per-Pokémon top-stat query, sql/02_pokeapi_select.sql query 6) --
-- that was tried first here and failed live (2026-09-18) with:
--   MISSING_ATTRIBUTES.RESOLVED_ATTRIBUTE_APPEAR_IN_OPERATION ... Resolved
--   attribute(s) "product" missing from "code", "product", "status",
--   "status_verbose" ... Attribute(s) with the same name appear in the
--   operation: "product".
-- Root cause: `all_products_ingredients_table` is a UNION ALL of four
-- schemastore views, each itself built from `LATERAL VIEW
-- explode(product.ingredients)`. Self-joining that UNION'd view against
-- an aggregate SUBQUERY OF ITSELF (`... a JOIN (SELECT ... FROM
-- all_products_ingredients_table GROUP BY ...) top ON ...`) makes Spark's
-- analyzer see the same underlying `product` struct attribute (left
-- behind by the Generate/explode operator, never actually selected) show
-- up twice with conflicting expression ids -- a known Spark self-join
-- pitfall, not a mistake in the SQL's logic. PokéAPI's query 6 avoided
-- this because it joined two DIFFERENT views (a union of raw per-Pokémon
-- ability views vs. the stats view), not the same view against a
-- derivative of itself.
-- FIX, CONFIRMED WORKING (2026-09-18): use a window function instead --
-- a single pass over the view, no self-join, so the conflicting-attribute
-- problem never arises. ROW_NUMBER() OVER (...) is standard ANSI/Spark
-- SQL and uses the WINDOW syntax the Lightning SQL Manual documents
-- (sec 6 of the manual, HOWTO.md references it as sec 1's syntax basis).
-- Returned exactly one row per product as expected: Coca-Cola/carbonated
-- water (83.4%), Nutella/sugar (52.16%), Pesto/sunflower oil (34.94%),
-- Prince/Céréale (47.75%):
SELECT product_name, ingredient_text, percent_estimate
FROM (
    SELECT
        product_name,
        ingredient_text,
        percent_estimate,
        ROW_NUMBER() OVER (PARTITION BY product_name ORDER BY percent_estimate DESC) AS rn
    FROM openfoodfacts.all_products_ingredients_table
) ranked
WHERE rn = 1;

-- 8. Saltiest product per 100g, alongside how many ingredients it has --
-- pairs a nutrition-view fact with an ingredients-view aggregate in a
-- single query. Structurally different from query 7's failure above: the
-- outer reference is `all_products_nutrition_table` (no explode() in its
-- lineage at all) and only the INNER aggregate subquery touches
-- `all_products_ingredients_table` -- the same view is never referenced
-- twice in this query, so the self-join attribute conflict from query 7
-- shouldn't apply here. Still unverified live as of 2026-09-18 (this
-- query hasn't been reached yet) -- if it fails with the same
-- MISSING_ATTRIBUTES error, the window-function pattern from query 7's
-- fix likely doesn't directly apply (this genuinely needs two different
-- views' data in one row) -- report back and we'll find a workaround.
SELECT
    n.product_name,
    n.salt_100g,
    ing.ingredient_count
FROM openfoodfacts.all_products_nutrition_table n
JOIN (
    SELECT product_name, COUNT(*) AS ingredient_count
    FROM openfoodfacts.all_products_ingredients_table
    GROUP BY product_name
) ing ON ing.product_name = n.product_name
ORDER BY n.salt_100g DESC;

-- ---------------------------------------------------------------------------
-- Attribution reminder (ODbL, per the license note in the create script) --
-- carry this into any README or demo that displays data from this source:
--   "Data from Open Food Facts (https://world.openfoodfacts.org/), licensed
--   under the Open Database License (ODbL)."
-- ---------------------------------------------------------------------------
