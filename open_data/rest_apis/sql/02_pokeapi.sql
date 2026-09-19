-- =============================================================================
-- Source:   PokéAPI -- per-Pokémon lookup (abilities, types, base stats)
-- License:  BSD-3-Clause for the code/API -- https://github.com/PokeAPI/pokeapi/blob/master/LICENSE.md
--           Fair Use Policy: cache responses locally, don't use this as a
--           load-testing target. Pokémon names/characters are Nintendo
--           trademarks -- fine for a technical demo, not for anything
--           Zetaris-branded.
-- Format:   REST/JSON, top-level object, array-of-structs nested fields
-- Docs:     https://pokeapi.co/docs/v2
-- Rate limit: no formal limit (removed 2018), but respect the Fair Use
--           Policy above -- this is a shared free resource.
-- Before running: sanity-check the endpoint returns something sane --
--   curl -s https://pokeapi.co/api/v2/pokemon/pikachu | python3 -m json.tool | head -20
-- =============================================================================
--
-- ✅ LIVE-TESTED AND CONFIRMED WORKING (2026-09-19) against Pikachu's
-- abilities table -- 2 rows back (is_hidden false/true), all columns
-- populated including the two-levels-deep dot-access:
--   1. Response is a single top-level JSON object per Pokémon (not an
--      array) -- same shape class as EDGAR's companyconcept response.
--   2. `abilities` is array<struct<is_hidden,slot,ability:struct<name,url>>>
--      -- CONFIRMED: two-level dot-access through an exploded field
--      (ability.ability.name) works. This was the open question in the
--      original version of this script -- resolved favorably, and it
--      means the same pattern should work for any other source in this
--      package with similarly-nested JSON (e.g. NASA NeoWs's deeper
--      nesting, sql/05).
--   3. `types` and `stats` are the same shape class as `abilities`
--      (array<struct<..., X:struct<name,url>>>) -- extended below now that
--      the pattern is confirmed. `moves` also exists on the same object
--      but has a DOUBLY-nested array (`version_group_details` inside each
--      move) -- not attempted here, would need a second LATERAL VIEW
--      explode() layered on top of this pattern; flagged as a future
--      stretch example, not built.
--   4. Extended to a second Pokémon (Charizard) to prove the pattern
--      generalizes across records, same as EDGAR's multi-company
--      structure -- one REST table + one set of views per Pokémon, all
--      landing in the shared `pokeapi` container.
--
-- ---------------------------------------------------------------------------
-- STEP 0: Lightning database for this source.
-- ---------------------------------------------------------------------------
CREATE LIGHTNING DATABASE POKEAPI_REST DESCRIBE BY "PokeAPI REST source";

-- ---------------------------------------------------------------------------
-- STEP 1: SCHEMASTORE container. RUN ONCE -- see open_data/rest_apis/HOWTO.md
-- sec 2 (no IF NOT EXISTS support). Comment out on a re-run if it already
-- exists in your environment.
-- ---------------------------------------------------------------------------
CREATE SCHEMASTORE CONTAINER pokeapi;

-- =============================================================================
-- PIKACHU -- id 25
-- =============================================================================
CREATE LIGHTNING REST TABLE pikachu_facts FROM POKEAPI_REST REQUEST(
    endpoint "https://pokeapi.co/api/v2/pokemon/pikachu",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
) BODY ();

CREATE SCHEMASTORE VIEW pikachu_abilities_table WITH CONTAINER pokeapi AS
SELECT
    id,
    name          AS pokemon_name,
    base_experience,
    height,
    weight,
    ability.is_hidden,
    ability.slot,
    ability.ability.name AS ability_name,
    ability.ability.url  AS ability_url
FROM pokeapi_rest.pikachu_facts
LATERAL VIEW explode(abilities) AS ability;

CREATE SCHEMASTORE VIEW pikachu_types_table WITH CONTAINER pokeapi AS
SELECT
    id,
    name AS pokemon_name,
    t.slot,
    t.type.name AS type_name
FROM pokeapi_rest.pikachu_facts
LATERAL VIEW explode(types) AS t;

CREATE SCHEMASTORE VIEW pikachu_stats_table WITH CONTAINER pokeapi AS
SELECT
    id,
    name AS pokemon_name,
    s.stat.name AS stat_name,
    s.base_stat,
    s.effort
FROM pokeapi_rest.pikachu_facts
LATERAL VIEW explode(stats) AS s;

-- Verify:
SELECT * FROM pokeapi.pikachu_abilities_table;
SELECT * FROM pokeapi.pikachu_types_table;
SELECT * FROM pokeapi.pikachu_stats_table;

-- =============================================================================
-- CHARIZARD -- id 6 -- second Pokémon, proves the pattern generalizes
-- =============================================================================
CREATE LIGHTNING REST TABLE charizard_facts FROM POKEAPI_REST REQUEST(
    endpoint "https://pokeapi.co/api/v2/pokemon/charizard",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
) BODY ();

CREATE SCHEMASTORE VIEW charizard_abilities_table WITH CONTAINER pokeapi AS
SELECT
    id,
    name          AS pokemon_name,
    base_experience,
    height,
    weight,
    ability.is_hidden,
    ability.slot,
    ability.ability.name AS ability_name,
    ability.ability.url  AS ability_url
FROM pokeapi_rest.charizard_facts
LATERAL VIEW explode(abilities) AS ability;

CREATE SCHEMASTORE VIEW charizard_types_table WITH CONTAINER pokeapi AS
SELECT
    id,
    name AS pokemon_name,
    t.slot,
    t.type.name AS type_name
FROM pokeapi_rest.charizard_facts
LATERAL VIEW explode(types) AS t;

CREATE SCHEMASTORE VIEW charizard_stats_table WITH CONTAINER pokeapi AS
SELECT
    id,
    name AS pokemon_name,
    s.stat.name AS stat_name,
    s.base_stat,
    s.effort
FROM pokeapi_rest.charizard_facts
LATERAL VIEW explode(stats) AS s;

-- Verify:
SELECT * FROM pokeapi.charizard_abilities_table;
SELECT * FROM pokeapi.charizard_types_table;
SELECT * FROM pokeapi.charizard_stats_table;

-- ---------------------------------------------------------------------------
-- Diagnostic (run if any view above fails or comes back empty):
--   SELECT * FROM pokeapi_rest.pikachu_facts;
--   SELECT * FROM pokeapi_rest.charizard_facts;
--   DESCRIBE pokeapi_rest.pikachu_facts;
-- ---------------------------------------------------------------------------

-- =============================================================================
-- CROSS-POKÉMON VIEWS -- same UNION ALL pattern as EDGAR's optional
-- all_companies_revenue_table (sql/01), so a third+ Pokémon just needs one
-- more UNION ALL branch per view, not a redesign.
-- =============================================================================
CREATE SCHEMASTORE VIEW all_pokemon_types_table WITH CONTAINER pokeapi AS
SELECT * FROM pokeapi.pikachu_types_table
UNION ALL
SELECT * FROM pokeapi.charizard_types_table;

CREATE SCHEMASTORE VIEW all_pokemon_stats_table WITH CONTAINER pokeapi AS
SELECT * FROM pokeapi.pikachu_stats_table
UNION ALL
SELECT * FROM pokeapi.charizard_stats_table;

CREATE SCHEMASTORE VIEW all_pokemon_abilities_table WITH CONTAINER pokeapi AS
SELECT pokemon_name, ability_name, is_hidden FROM pokeapi.pikachu_abilities_table
UNION ALL
SELECT pokemon_name, ability_name, is_hidden FROM pokeapi.charizard_abilities_table;

-- ---------------------------------------------------------------------------
-- Example queries -- run these against the views above to get a feel for
-- the data once everything's loaded.
-- ---------------------------------------------------------------------------

-- 1. Every type across both Pokémon, one row per (pokémon, type):
SELECT * FROM pokeapi.all_pokemon_types_table ORDER BY pokemon_name, slot;

-- 2. Total base stat ("base stat total", a common Pokémon-battling metric)
-- per Pokémon -- aggregates the exploded stats view back into one row each:
SELECT
    pokemon_name,
    SUM(base_stat) AS base_stat_total
FROM pokeapi.all_pokemon_stats_table
GROUP BY pokemon_name
ORDER BY base_stat_total DESC;

-- 3. Side-by-side stat comparison -- one row per stat, a column per
-- Pokémon (a manual pivot via CASE, since PIVOT syntax support is
-- unconfirmed for Zetaris):
SELECT
    stat_name,
    MAX(CASE WHEN pokemon_name = 'pikachu'   THEN base_stat END) AS pikachu,
    MAX(CASE WHEN pokemon_name = 'charizard' THEN base_stat END) AS charizard
FROM pokeapi.all_pokemon_stats_table
GROUP BY stat_name
ORDER BY stat_name;

-- 4. Which Pokémon have a hidden ability, and what is it:
SELECT pokemon_name, ability_name
FROM pokeapi.all_pokemon_abilities_table
WHERE is_hidden = true;

-- 5. Highest single base stat across both Pokémon (which stat, which
-- Pokémon, what value) -- a simple ORDER BY + LIMIT on the union view:
SELECT pokemon_name, stat_name, base_stat
FROM pokeapi.all_pokemon_stats_table
ORDER BY base_stat DESC
LIMIT 1;

-- 6. Full per-Pokémon profile -- join the base facts (from the abilities
-- view, which already carries height/weight/base_experience) against the
-- aggregated stat total from query 2's logic, inlined as a subquery:
SELECT DISTINCT
    a.pokemon_name,
    a.base_experience,
    a.height,
    a.weight,
    st.base_stat_total
FROM pokeapi.all_pokemon_abilities_table a
JOIN (
    SELECT pokemon_name, SUM(base_stat) AS base_stat_total
    FROM pokeapi.all_pokemon_stats_table
    GROUP BY pokemon_name
) st ON st.pokemon_name = a.pokemon_name;

-- ---------------------------------------------------------------------------
-- Optional, further follow-up once the above works: `moves` is the same
-- struct shape but has a doubly-nested array
-- (move:struct<name,url>, version_group_details:array<struct<...>>>) --
-- a good "how deep can this go" stress test, needing a second
-- LATERAL VIEW explode() layered on top of this pattern. Not built here.
-- A third Pokémon (any name/id from https://pokeapi.co/api/v2/pokemon/)
-- follows the exact same copy-paste pattern as Charizard above, plus one
-- more UNION ALL branch per cross-Pokémon view.
-- ---------------------------------------------------------------------------
