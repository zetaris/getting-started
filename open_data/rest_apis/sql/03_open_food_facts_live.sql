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
-- Investigated (not yet live-tested against Zetaris) 2026-09-18, using
-- Nutella's barcode (3017620422003) as the example product:
--   1. Full, unfiltered response is LARGE and deeply nested (hundreds of
--      fields) -- this script uses the API's own `fields` query parameter
--      to request only what's needed (code, product_name, brands,
--      ingredients), which keeps the response (and the flattened view)
--      manageable. Confirmed the `fields` parameter works via the
--      `Before running` curl check above.
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
--      ingredients, ...}}`) -- dot-access through `product.*` is needed,
--      not flat top-level fields like EDGAR's `cik`/`entityName`.
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
-- NUTELLA (Ferrero) -- barcode 3017620422003, a well-known stable example
-- =============================================================================
CREATE LIGHTNING REST TABLE nutella_product FROM OFF_LIVE_REST REQUEST(
    endpoint "https://world.openfoodfacts.org/api/v2/product/3017620422003.json?fields=code,product_name,brands,ingredients",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
    user-agent "YOUR_APP_NAME YOUR_CONTACT_EMAIL"
) BODY ();

-- Flattened view -- product.ingredients is the array-of-structs field
-- (see caveat 2 and 3 above):
CREATE SCHEMASTORE VIEW nutella_ingredients_table WITH CONTAINER openfoodfacts AS
SELECT
    code,
    product.product_name AS product_name,
    product.brands       AS brands,
    ingredient.id         AS ingredient_id,
    ingredient.text       AS ingredient_text,
    ingredient.percent    AS percent_declared,
    ingredient.percent_estimate AS percent_estimate,
    ingredient.vegan      AS is_vegan,
    ingredient.vegetarian AS is_vegetarian
FROM off_live_rest.nutella_product
LATERAL VIEW explode(product.ingredients) AS ingredient;

-- Verify:
SELECT * FROM openfoodfacts.nutella_ingredients_table;

-- ---------------------------------------------------------------------------
-- Diagnostic (run if the view above fails or comes back empty):
--   SELECT * FROM off_live_rest.nutella_product;
--   DESCRIBE off_live_rest.nutella_product;
-- If sparse/optional struct fields (present on some ingredients, absent on
-- others -- caveat 2) cause a schema-inference error rather than a clean
-- null-fill, that's worth reporting back -- it would affect every REST
-- source in this package whose nested structs aren't uniformly shaped.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Attribution reminder (ODbL, per the license note above) -- carry this into
-- any README or demo that displays data from this source:
--   "Data from Open Food Facts (https://world.openfoodfacts.org/), licensed
--   under the Open Database License (ODbL)."
-- ---------------------------------------------------------------------------
