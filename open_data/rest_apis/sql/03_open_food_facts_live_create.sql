-- =============================================================================
-- Source: Open Food Facts -- live single-product lookup API. Repeats the
-- pattern for four products picked for contrasting nutrition profiles --
-- Nutella (3017620422003), Coca-Cola (5449000000996), Prince biscuits
-- (7622210449283), and Barilla Pesto alla Genovese (8076809513753) -- one
-- REST table plus a nutrition and an ingredients view per product, all
-- landing in the shared `openfoodfacts` container, with cross-product
-- union views at the bottom.
--
-- License: ODbL (Open Database License) --
-- https://forum.openfoodfacts.org/t/conditions-to-use-the-open-food-facts-api/443
-- Attribution required; if you redistribute a combined database built
-- from this, that combined database must also be open (share-alike).
--
-- Format: REST/JSON, top-level object wrapping a `product` struct
-- (dot-access through `product.*`), array-of-structs nested fields. See
-- the SQL companion guide for the general shape taxonomy and
-- identifier-quoting rules this script relies on.
--
-- Docs: https://world.openfoodfacts.org/data (API section)
-- https://openfoodfacts.github.io/openfoodfacts-server/api/
--
-- Rate limit: per-endpoint limits apply; requires a custom user-agent
-- identifying your app (generic/missing user-agent strings are more
-- likely to be throttled).
--
-- Before running: sanity-check the endpoint returns something sane:
--   curl -s -A "YOUR_APP_NAME YOUR_CONTACT_EMAIL" \
--     "https://world.openfoodfacts.org/api/v2/product/3017620422003.json?fields=code,product_name,brands,ingredients" \
--     | python3 -m json.tool | head -20
-- =============================================================================
--
-- Caveats:
--   1. The full, unfiltered response is large and deeply nested
--      (hundreds of fields) -- this script uses the API's own `fields`
--      query parameter to request only what's needed, which keeps the
--      response and the flattened views manageable.
--   2. Not every ingredient struct field is present on every entry
--      (e.g. `percent` is sometimes missing, `from_palm_oil` only
--      appears on some entries) -- Zetaris's schema inference handles
--      this by null-filling the missing fields rather than erroring.
--   3. Compound ingredients are doubly-nested: some entries in the
--      ingredients array (e.g. Prince biscuits' "Céréale") carry their
--      own nested `ingredients` sub-array (wheat flour, whole wheat
--      flour, ...) describing what the compound ingredient is made of.
--      A single explode() only reaches the top-level entries -- the
--      nested sub-ingredients are silently not flattened; the views
--      below intentionally only surface top-level ingredients.
-- =============================================================================

-- Step 0: Lightning database for this source.
CREATE LIGHTNING DATABASE OFF_LIVE_REST DESCRIBE BY "Open Food Facts live product-lookup REST source";

-- Step 1: schemastore container. Run once -- comment out on a re-run
-- if it already exists in your environment.
CREATE SCHEMASTORE CONTAINER openfoodfacts;

-- Nutella (Ferrero) -- barcode 3017620422003
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
    product.product_name AS product_name,
    product.brands AS brands,
    product.nutriscore_grade AS nutriscore_grade,
    product.nova_group AS nova_group,
    product.nutriments.`energy-kcal_100g` AS energy_kcal_100g,
    product.nutriments.fat_100g AS fat_100g,
    product.nutriments.`saturated-fat_100g` AS saturated_fat_100g,
    product.nutriments.carbohydrates_100g AS carbohydrates_100g,
    product.nutriments.sugars_100g AS sugars_100g,
    product.nutriments.proteins_100g AS proteins_100g,
    product.nutriments.salt_100g AS salt_100g
FROM off_live_rest.nutella_product;

CREATE SCHEMASTORE VIEW nutella_ingredients_table WITH CONTAINER openfoodfacts AS
SELECT
    code,
    product.product_name AS product_name,
    ingredient.id AS ingredient_id,
    ingredient.text AS ingredient_text,
    ingredient.percent_estimate AS percent_estimate,
    ingredient.vegan AS is_vegan,
    ingredient.vegetarian AS is_vegetarian
FROM off_live_rest.nutella_product
LATERAL VIEW explode(product.ingredients) AS ingredient;

-- Coca-Cola -- barcode 5449000000996
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
    product.product_name AS product_name,
    product.brands AS brands,
    product.nutriscore_grade AS nutriscore_grade,
    product.nova_group AS nova_group,
    product.nutriments.`energy-kcal_100g` AS energy_kcal_100g,
    product.nutriments.fat_100g AS fat_100g,
    product.nutriments.`saturated-fat_100g` AS saturated_fat_100g,
    product.nutriments.carbohydrates_100g AS carbohydrates_100g,
    product.nutriments.sugars_100g AS sugars_100g,
    product.nutriments.proteins_100g AS proteins_100g,
    product.nutriments.salt_100g AS salt_100g
FROM off_live_rest.cocacola_product;

CREATE SCHEMASTORE VIEW cocacola_ingredients_table WITH CONTAINER openfoodfacts AS
SELECT
    code,
    product.product_name AS product_name,
    ingredient.id AS ingredient_id,
    ingredient.text AS ingredient_text,
    ingredient.percent_estimate AS percent_estimate,
    ingredient.vegan AS is_vegan,
    ingredient.vegetarian AS is_vegetarian
FROM off_live_rest.cocacola_product
LATERAL VIEW explode(product.ingredients) AS ingredient;

-- Prince biscuits (LU / Mondelez) -- barcode 7622210449283 -- picked
-- because its ingredients array has the doubly-nested compound entries
-- described in caveat 3 ("Céréale" wraps wheat flour and whole wheat
-- flour as sub-ingredients).
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
    product.product_name AS product_name,
    product.brands AS brands,
    product.nutriscore_grade AS nutriscore_grade,
    product.nova_group AS nova_group,
    product.nutriments.`energy-kcal_100g` AS energy_kcal_100g,
    product.nutriments.fat_100g AS fat_100g,
    product.nutriments.`saturated-fat_100g` AS saturated_fat_100g,
    product.nutriments.carbohydrates_100g AS carbohydrates_100g,
    product.nutriments.sugars_100g AS sugars_100g,
    product.nutriments.proteins_100g AS proteins_100g,
    product.nutriments.salt_100g AS salt_100g
FROM off_live_rest.prince_product;

-- This only surfaces the 13 top-level ingredient entries -- the nested
-- sub-ingredients inside compound entries like "Céréale" are not
-- flattened here (see caveat 3).
CREATE SCHEMASTORE VIEW prince_ingredients_table WITH CONTAINER openfoodfacts AS
SELECT
    code,
    product.product_name AS product_name,
    ingredient.id AS ingredient_id,
    ingredient.text AS ingredient_text,
    ingredient.percent_estimate AS percent_estimate,
    ingredient.vegan AS is_vegan,
    ingredient.vegetarian AS is_vegetarian
FROM off_live_rest.prince_product
LATERAL VIEW explode(product.ingredients) AS ingredient;

-- Barilla Pesto alla Genovese -- barcode 8076809513753
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
    product.product_name AS product_name,
    product.brands AS brands,
    product.nutriscore_grade AS nutriscore_grade,
    product.nova_group AS nova_group,
    product.nutriments.`energy-kcal_100g` AS energy_kcal_100g,
    product.nutriments.fat_100g AS fat_100g,
    product.nutriments.`saturated-fat_100g` AS saturated_fat_100g,
    product.nutriments.carbohydrates_100g AS carbohydrates_100g,
    product.nutriments.sugars_100g AS sugars_100g,
    product.nutriments.proteins_100g AS proteins_100g,
    product.nutriments.salt_100g AS salt_100g
FROM off_live_rest.pesto_product;

CREATE SCHEMASTORE VIEW pesto_ingredients_table WITH CONTAINER openfoodfacts AS
SELECT
    code,
    product.product_name AS product_name,
    ingredient.id AS ingredient_id,
    ingredient.text AS ingredient_text,
    ingredient.percent_estimate AS percent_estimate,
    ingredient.vegan AS is_vegan,
    ingredient.vegetarian AS is_vegetarian
FROM off_live_rest.pesto_product
LATERAL VIEW explode(product.ingredients) AS ingredient;

-- Cross-product views -- a fifth-plus product just needs one more
-- UNION ALL branch per view, not a redesign.
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

-- =============================================================================
-- Teardown -- removes the flattened views this script created.
-- Commented out by default. See the SQL companion guide for why
-- DROP VIEW is the only reliable teardown statement, and how to remove
-- the underlying REST tables and database registration (Zetaris Data
-- Explorer -- no SQL path exists).
-- =============================================================================

-- DROP VIEW openfoodfacts.all_products_nutrition_table;
-- DROP VIEW openfoodfacts.all_products_ingredients_table;
-- DROP VIEW openfoodfacts.nutella_nutrition_table;
-- DROP VIEW openfoodfacts.nutella_ingredients_table;
-- DROP VIEW openfoodfacts.cocacola_nutrition_table;
-- DROP VIEW openfoodfacts.cocacola_ingredients_table;
-- DROP VIEW openfoodfacts.prince_nutrition_table;
-- DROP VIEW openfoodfacts.prince_ingredients_table;
-- DROP VIEW openfoodfacts.pesto_nutrition_table;
-- DROP VIEW openfoodfacts.pesto_ingredients_table;
