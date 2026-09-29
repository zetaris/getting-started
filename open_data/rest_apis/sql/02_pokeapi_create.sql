-- =============================================================================
-- Source: PokéAPI -- per-Pokémon lookup (abilities, types, base stats).
-- Repeats the pattern for two Pokémon, Pikachu and Charizard, to prove
-- it generalizes across records -- one REST table plus one set of
-- views per Pokémon, all landing in the shared `pokeapi` container,
-- with cross-Pokémon union views at the bottom.
--
-- License: BSD-3-Clause for the code/API --
-- https://github.com/PokeAPI/pokeapi/blob/master/LICENSE.md
-- Fair Use Policy: cache responses locally, don't use this as a
-- load-testing target. Pokémon names/characters are Nintendo
-- trademarks -- fine for a technical demo, not for anything
-- Zetaris-branded.
--
-- Format: REST/JSON, top-level object per Pokémon, array-of-structs
-- nested fields (abilities, types, stats). `abilities` nests a struct
-- two levels deep (ability.ability.name) -- confirmed working; see the
-- SQL companion guide for the general shape taxonomy.
--
-- Docs: https://pokeapi.co/docs/v2
--
-- Rate limit: no formal limit (removed 2018), but respect the Fair Use
-- Policy above -- this is a shared free resource.
--
-- Before running: sanity-check the endpoint returns something sane:
--   curl -s https://pokeapi.co/api/v2/pokemon/pikachu | python3 -m json.tool | head -20
--
-- Status: live-tested and confirmed working end to end (2026-09-19) --
-- both Pokémon's REST tables, all per-Pokémon and cross-Pokémon views,
-- and the example queries all ran successfully.
-- =============================================================================
--
-- Caveats:
--   1. `moves` also exists on the response object but has a doubly-
--      nested array (`version_group_details` inside each move) -- not
--      attempted here, would need a second LATERAL VIEW explode()
--      layered on top of this pattern.
-- =============================================================================

-- Step 0: Lightning database for this source.
CREATE LIGHTNING DATABASE POKEAPI_REST DESCRIBE BY "PokeAPI REST source";

-- Step 1: schemastore container. Run once -- comment out on a re-run
-- if it already exists in your environment.
CREATE SCHEMASTORE CONTAINER pokeapi;

-- Pikachu -- id 25
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
    name AS pokemon_name,
    base_experience,
    height,
    weight,
    ability.is_hidden,
    ability.slot,
    ability.ability.name AS ability_name,
    ability.ability.url AS ability_url
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

-- Charizard -- id 6
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
    name AS pokemon_name,
    base_experience,
    height,
    weight,
    ability.is_hidden,
    ability.slot,
    ability.ability.name AS ability_name,
    ability.ability.url AS ability_url
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

-- Cross-Pokémon views -- a third-plus Pokémon just needs one more
-- UNION ALL branch per view, not a redesign.
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

-- =============================================================================
-- Teardown -- removes the flattened views this script created.
-- Commented out by default. See the SQL companion guide for why
-- DROP VIEW is the only reliable teardown statement, and how to remove
-- the underlying REST tables and database registration (Zetaris Data
-- Explorer -- no SQL path exists).
-- =============================================================================

-- DROP VIEW pokeapi.all_pokemon_types_table;
-- DROP VIEW pokeapi.all_pokemon_stats_table;
-- DROP VIEW pokeapi.all_pokemon_abilities_table;
-- DROP VIEW pokeapi.pikachu_abilities_table;
-- DROP VIEW pokeapi.pikachu_types_table;
-- DROP VIEW pokeapi.pikachu_stats_table;
-- DROP VIEW pokeapi.charizard_abilities_table;
-- DROP VIEW pokeapi.charizard_types_table;
-- DROP VIEW pokeapi.charizard_stats_table;
