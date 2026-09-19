-- =============================================================================
-- Source:   Open Food Facts -- live single-product lookup API
-- NOTE:     this is the LIVE API, distinct from the bulk CSV/JSONL export
--           already onboarded as a filestore source in
--           ../../parquet_csv/sql/ (see that package's recipe notes) -- the
--           manifest recommends the bulk export for anything beyond
--           single-record lookups. This script demonstrates the
--           single-record REST pattern specifically, not a bulk-data path.
-- License:  ODbL (Open Database License) --
--           https://forum.openfoodfacts.org/t/conditions-to-use-the-open-food-facts-api/443
--           Attribution required; if you redistribute a combined database
--           built from this, that combined database must also be open
--           (share-alike).
-- Format:   REST/JSON, top-level object, array-of-structs nested fields
-- Docs:     https://world.openfoodfacts.org/data (API section) ·
--           https://openfoodfacts.github.io/openfoodfacts-server/api/
-- Rate limit: per-endpoint limits apply; requires a custom User-Agent
--           identifying your app (generic/missing User-Agent strings are
--           more likely to be throttled).
-- Before running: sanity-check the endpoint returns something sane --
--   curl -s -A "YOUR_APP_NAME YOUR_CONTACT_EMAIL" \
--     "https://world.openfoodfacts.org/api/v2/product/3017620422003.json?fields=code,product_name,brands,ingredients" \
--     | python3 -m json.tool | head -20
-- =============================================================================
--
-- Investigated 2026-09-19, extended 2026-09-18 to four products picked for
-- contrasting nutrition profiles -- Nutella (3017620422003, a well-known
-- stable example), Coca-Cola (5449000000996), Prince biscuits
-- (7622210449283), and Barilla Pesto alla Genovese (8076809513753):
--   1. Full, unfiltered response is LARGE and deeply nested (hundreds of
--      fields) -- this script uses the API's own `fields` query parameter
--      to request only what's needed (code, product_name, brands,
--      nutriscore_grade, nova_group, nutriments, ingredients), which keeps
--      the response (and the flattened views) manageable. Confirmed the
--      `fields` parameter works via the `Before running` curl check above.
--   2. `ingredients` is array<struct<id,text,percent,percent_estimate,
--      quantity_estimate,vegan,vegetarian,ciqual_food_code,...>> -- a
--      genuine array-of-structs, same explode() + dot-access pattern as
--      EDGAR (sql/01) and PokéAPI (sql/02). NOT every struct field is
--      present on every ingredient (e.g. `percent` is sometimes missing,
--      `from_palm_oil` only appears on some entries) -- confirm Zetaris's
--      schema inference handles sparse/optional struct fields gracefully
--      (null-fills the missing ones) rather than erroring.
--   3. Top-level `product` is itself a nested struct wrapping everything
--      (the real shape is `{code, product: {product_name, brands,
--      ingredients, nutriments, ...}}`) -- dot-access through `product.*`
--      is needed, not flat top-level fields like EDGAR's `cik`/
--      `entityName`.
--   4. COMPOUND INGREDIENTS ARE DOUBLY-NESTED: some entries in the
--      `ingredients` array (e.g. Prince biscuits' "Céréale") carry their
--      own nested `ingredients` sub-array (wheat flour, whole wheat flour,
--      ...) describing what the compound ingredient is made of. A single
--      `LATERAL VIEW explode(product.ingredients)` only reaches the
--      TOP-LEVEL entries -- the nested sub-ingredients are silently not
--      flattened (they'd need a second `explode()` layered on top, same
--      "how deep can this go" pattern flagged as a future stretch for
--      PokéAPI's `moves` field, sql/02). Not built here -- the views below
--      intentionally only surface top-level ingredients.
--   5. `nutriments` is a FLAT struct on `product.nutriments` (not an array
--      -- no `explode()` needed for it), but several of its useful keys
--      have HYPHENS in the JSON field name (`energy-kcal_100g`,
--      `saturated-fat_100g`) -- these need backtick-quoting
--      (`` `energy-kcal_100g` ``) same as the mixed-case/reserved-word
--      gotcha already documented for EDGAR/PokéAPI, just for a different
--      reason (a bare hyphen would otherwise parse as subtraction).
--
-- ---------------------------------------------------------------------------
-- STEP 0: Lightning database for this source.
-- ---------------------------------------------------------------------------
CREATE LIGHTNING DATABASE OFF_LIVE_REST DESCRIBE BY "Open Food Facts live product-lookup REST source";

-- ---------------------------------------------------------------------------
-- STEP 1: SCHEMASTORE container. RUN ONCE -- see open_data/rest_apis/HOWTO.md
-- sec 2 (no IF NOT EXISTS support). Comment out on a re-run if it already
-- exists in your environment.
-- ---------------------------------------------------------------------------
CREATE SCHEMASTORE CONTAINER openfoodfacts;

-- =============================================================================
-- NUTELLA (Ferrero) -- barcode 3017620422003
-- =============================================================================
CREATE LIGHTNING REST TABLE nutella_product FROM OFF_LIVE_REST REQUEST(
    endpoint "https://world.openfoodfacts.org/api/v2/product/3017620422003.json?fields=code,product_name,brands,nutriscore_grade,nova_group,nutriments,ingredients",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW nutella_nutrition_table WITH CONTAINER openfoodfacts AS
SELECT
    code,
    product.product_name              AS product_name,
    product.brands                    AS brands,
    product.nutriscore_grade          AS nutriscore_grade,
    product.nova_group                AS nova_group,
    product.nutriments.`energy-kcal_100g`     AS energy_kcal_100g,
    product.nutriments.fat_100g               AS fat_100g,
    product.nutriments.`saturated-fat_100g`   AS saturated_fat_100g,
    product.nutriments.carbohydrates_100g     AS carbohydrates_100g,
    product.nutriments.sugars_100g            AS sugars_100g,
    product.nutriments.proteins_100g          AS proteins_100g,
    product.nutriments.salt_100g              AS salt_100g
FROM off_live_rest.nutella_product;

-- Flattened ingredients view -- product.ingredients is the top-level
-- array-of-structs field (see caveats 2-4 above):
CREATE SCHEMASTORE VIEW nutella_ingredients_table WITH CONTAINER openfoodfacts AS
SELECT
    code,
    product.product_name AS product_name,
    ingredient.id         AS ingredient_id,
    ingredient.text       AS ingredient_text,
    ingredient.percent_estimate AS percent_estimate,
    ingredient.vegan      AS is_vegan,
    ingredient.vegetarian AS is_vegetarian
FROM off_live_rest.nutella_product
LATERAL VIEW explode(product.ingredients) AS ingredient;

-- Verify:
SELECT * FROM openfoodfacts.nutella_nutrition_table;
SELECT * FROM openfoodfacts.nutella_ingredients_table;

-- =============================================================================
-- COCA-COLA -- barcode 5449000000996
-- =============================================================================
CREATE LIGHTNING REST TABLE cocacola_product FROM OFF_LIVE_REST REQUEST(
    endpoint "https://world.openfoodfacts.org/api/v2/product/5449000000996.json?fields=code,product_name,brands,nutriscore_grade,nova_group,nutriments,ingredients",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW cocacola_nutrition_table WITH CONTAINER openfoodfacts AS
SELECT
    code,
    product.product_name              AS product_name,
    product.brands                    AS brands,
    product.nutriscore_grade          AS nutriscore_grade,
    product.nova_group                AS nova_group,
    product.nutriments.`energy-kcal_100g`     AS energy_kcal_100g,
    product.nutriments.fat_100g               AS fat_100g,
    product.nutriments.`saturated-fat_100g`   AS saturated_fat_100g,
    product.nutriments.carbohydrates_100g     AS carbohydrates_100g,
    product.nutriments.sugars_100g            AS sugars_100g,
    product.nutriments.proteins_100g          AS proteins_100g,
    product.nutriments.salt_100g              AS salt_100g
FROM off_live_rest.cocacola_product;

CREATE SCHEMASTORE VIEW cocacola_ingredients_table WITH CONTAINER openfoodfacts AS
SELECT
    code,
    product.product_name AS product_name,
    ingredient.id         AS ingredient_id,
    ingredient.text       AS ingredient_text,
    ingredient.percent_estimate AS percent_estimate,
    ingredient.vegan      AS is_vegan,
    ingredient.vegetarian AS is_vegetarian
FROM off_live_rest.cocacola_product
LATERAL VIEW explode(product.ingredients) AS ingredient;

-- Verify:
SELECT * FROM openfoodfacts.cocacola_nutrition_table;
SELECT * FROM openfoodfacts.cocacola_ingredients_table;

-- =============================================================================
-- PRINCE BISCUITS (LU / Mondelez) -- barcode 7622210449283 -- deliberately
-- picked because its ingredients array has the doubly-nested compound
-- entries described in caveat 4 above ("Céréale" wraps wheat-flour and
-- whole-wheat-flour as sub-ingredients).
-- =============================================================================
CREATE LIGHTNING REST TABLE prince_product FROM OFF_LIVE_REST REQUEST(
    endpoint "https://world.openfoodfacts.org/api/v2/product/7622210449283.json?fields=code,product_name,brands,nutriscore_grade,nova_group,nutriments,ingredients",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW prince_nutrition_table WITH CONTAINER openfoodfacts AS
SELECT
    code,
    product.product_name              AS product_name,
    product.brands                    AS brands,
    product.nutriscore_grade          AS nutriscore_grade,
    product.nova_group                AS nova_group,
    product.nutriments.`energy-kcal_100g`     AS energy_kcal_100g,
    product.nutriments.fat_100g               AS fat_100g,
    product.nutriments.`saturated-fat_100g`   AS saturated_fat_100g,
    product.nutriments.carbohydrates_100g     AS carbohydrates_100g,
    product.nutriments.sugars_100g            AS sugars_100g,
    product.nutriments.proteins_100g          AS proteins_100g,
    product.nutriments.salt_100g              AS salt_100g
FROM off_live_rest.prince_product;

-- NOTE: this only surfaces the 13 TOP-LEVEL ingredient entries -- the
-- nested sub-ingredients inside compound entries like "Céréale" are not
-- flattened here (see caveat 4).
CREATE SCHEMASTORE VIEW prince_ingredients_table WITH CONTAINER openfoodfacts AS
SELECT
    code,
    product.product_name AS product_name,
    ingredient.id         AS ingredient_id,
    ingredient.text       AS ingredient_text,
    ingredient.percent_estimate AS percent_estimate,
    ingredient.vegan      AS is_vegan,
    ingredient.vegetarian AS is_vegetarian
FROM off_live_rest.prince_product
LATERAL VIEW explode(product.ingredients) AS ingredient;

-- Verify:
SELECT * FROM openfoodfacts.prince_nutrition_table;
SELECT * FROM openfoodfacts.prince_ingredients_table;

-- =============================================================================
-- BARILLA PESTO ALLA GENOVESE -- barcode 8076809513753
-- =============================================================================
CREATE LIGHTNING REST TABLE pesto_product FROM OFF_LIVE_REST REQUEST(
    endpoint "https://world.openfoodfacts.org/api/v2/product/8076809513753.json?fields=code,product_name,brands,nutriscore_grade,nova_group,nutriments,ingredients",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

CREATE SCHEMASTORE VIEW pesto_nutrition_table WITH CONTAINER openfoodfacts AS
SELECT
    code,
    product.product_name              AS product_name,
    product.brands                    AS brands,
    product.nutriscore_grade          AS nutriscore_grade,
    product.nova_group                AS nova_group,
    product.nutriments.`energy-kcal_100g`     AS energy_kcal_100g,
    product.nutriments.fat_100g               AS fat_100g,
    product.nutriments.`saturated-fat_100g`   AS saturated_fat_100g,
    product.nutriments.carbohydrates_100g     AS carbohydrates_100g,
    product.nutriments.sugars_100g            AS sugars_100g,
    product.nutriments.proteins_100g          AS proteins_100g,
    product.nutriments.salt_100g              AS salt_100g
FROM off_live_rest.pesto_product;

CREATE SCHEMASTORE VIEW pesto_ingredients_table WITH CONTAINER openfoodfacts AS
SELECT
    code,
    product.product_name AS product_name,
    ingredient.id         AS ingredient_id,
    ingredient.text       AS ingredient_text,
    ingredient.percent_estimate AS percent_estimate,
    ingredient.vegan      AS is_vegan,
    ingredient.vegetarian AS is_vegetarian
FROM off_live_rest.pesto_product
LATERAL VIEW explode(product.ingredients) AS ingredient;

-- Verify:
SELECT * FROM openfoodfacts.pesto_nutrition_table;
SELECT * FROM openfoodfacts.pesto_ingredients_table;

-- ---------------------------------------------------------------------------
-- Diagnostic (run if any view above fails or comes back empty):
--   SELECT * FROM off_live_rest.nutella_product;
--   DESCRIBE off_live_rest.nutella_product;
-- If sparse/optional struct fields (present on some ingredients, absent on
-- others -- caveat 2) cause a schema-inference error rather than a clean
-- null-fill, that's worth reporting back -- it would affect every REST
-- source in this package whose nested structs aren't uniformly shaped.
-- ---------------------------------------------------------------------------

-- =============================================================================
-- CROSS-PRODUCT VIEWS -- same UNION ALL pattern as EDGAR's optional
-- all_companies_revenue_table (sql/01) and PokéAPI's all_pokemon_* views
-- (sql/02), so a fifth+ product just needs one more UNION ALL branch per
-- view, not a redesign.
-- =============================================================================
CREATE SCHEMASTORE VIEW all_products_nutrition_table WITH CONTAINER openfoodfacts AS
SELECT * FROM openfoodfacts.nutella_nutrition_table
UNION ALL
SELECT * FROM openfoodfacts.cocacola_nutrition_table
UNION ALL
SELECT * FROM openfoodfacts.prince_nutrition_table
UNION ALL
SELECT * FROM openfoodfacts.pesto_nutrition_table;

CREATE SCHEMASTORE VIEW all_products_ingredients_table WITH CONTAINER openfoodfacts AS
SELECT * FROM openfoodfacts.nutella_ingredients_table
UNION ALL
SELECT * FROM openfoodfacts.cocacola_ingredients_table
UNION ALL
SELECT * FROM openfoodfacts.prince_ingredients_table
UNION ALL
SELECT * FROM openfoodfacts.pesto_ingredients_table;

-- ---------------------------------------------------------------------------
-- Example queries -- run these against the views above to get a feel for
-- the data once everything's loaded. Picked to be genuinely interesting
-- rather than just exercising syntax: nutrition comparisons, ingredient
-- overlap across unrelated brands, and a couple of "which product is the
-- odd one out" style questions.
-- ---------------------------------------------------------------------------

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
-- similar per-Pokémon top-stat query, sql/02 query 6) -- that was tried
-- first here and failed live (2026-09-18) with:
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
-- Attribution reminder (ODbL, per the license note above) -- carry this into
-- any README or demo that displays data from this source:
--   "Data from Open Food Facts (https://world.openfoodfacts.org/), licensed
--   under the Open Database License (ODbL)."
-- ---------------------------------------------------------------------------

-- =============================================================================
-- TEARDOWN -- removes the flattened views this script created. Commented
-- out by default so a re-run of the file above doesn't accidentally wipe
-- a live environment; uncomment and run standalone when you want to tear
-- these views down.
--
-- DROP VIEW is the only teardown statement confirmed to work reliably in
-- this package. There is no SQL statement confirmed to remove the raw
-- REST tables or the OFF_LIVE_REST Lightning database registration
-- itself -- see HOWTO.md, "Removing a source" and "Troubleshooting /
-- FAQ", for the full explanation. To remove the REST tables and the
-- OFF_LIVE_REST registration, use the Zetaris Data Explorer: locate the
-- entry under "File Source & API" and remove it from there.
-- =============================================================================

-- -- Cross-product views:
-- DROP VIEW openfoodfacts.all_products_nutrition_table;
-- DROP VIEW openfoodfacts.all_products_ingredients_table;

-- -- Per-product views:
-- DROP VIEW openfoodfacts.nutella_nutrition_table;
-- DROP VIEW openfoodfacts.nutella_ingredients_table;
-- DROP VIEW openfoodfacts.cocacola_nutrition_table;
-- DROP VIEW openfoodfacts.cocacola_ingredients_table;
-- DROP VIEW openfoodfacts.prince_nutrition_table;
-- DROP VIEW openfoodfacts.prince_ingredients_table;
-- DROP VIEW openfoodfacts.pesto_nutrition_table;
-- DROP VIEW openfoodfacts.pesto_ingredients_table;

-- To remove the OFF_LIVE_REST REST tables and Lightning database
-- registration, use the Zetaris Data Explorer's "File Source & API"
-- panel (see HOWTO.md, "Removing a source").
