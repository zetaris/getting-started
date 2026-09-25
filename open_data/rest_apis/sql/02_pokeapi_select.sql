-- =============================================================================
-- Verification / example queries for 02_pokeapi_create.sql
-- Assumes 02_pokeapi_create.sql has already been run.
--
-- The verification queries below are commented out by default so that
-- running this whole file doesn't automatically fire read queries against
-- every table. Uncomment what you want to run, or run it directly in the
-- SQL Editor. The example queries further down are left live, same as
-- before -- they're meant to be run once you're exploring the data.
-- =============================================================================

-- === Verification ===
-- SELECT * FROM pokeapi.pikachu_abilities_table;
-- SELECT * FROM pokeapi.pikachu_types_table;
-- SELECT * FROM pokeapi.pikachu_stats_table;
-- SELECT * FROM pokeapi.charizard_abilities_table;
-- SELECT * FROM pokeapi.charizard_types_table;
-- SELECT * FROM pokeapi.charizard_stats_table;

-- === Diagnostics === (run if any verification query above fails or comes back empty)
-- SELECT * FROM pokeapi_rest.pikachu_facts;
-- SELECT * FROM pokeapi_rest.charizard_facts;
-- DESCRIBE pokeapi_rest.pikachu_facts;

-- === Example queries ===
-- Run these against the views created in 02_pokeapi_create.sql to get a
-- feel for the data once everything's loaded.

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

-- 6. Full per-Pokémon profile -- join the base facts against the
-- aggregated stat total from query 2's logic, inlined as a subquery.
-- NOTE: base_experience/height/weight live on the per-Pokémon
-- pikachu_abilities_table/charizard_abilities_table views (see
-- sql/02_pokeapi_create.sql), NOT on all_pokemon_abilities_table -- that
-- cross-Pokémon view was deliberately narrowed to (pokemon_name,
-- ability_name, is_hidden) when it was defined there, so it explodes to
-- one row per ability without carrying duplicate per-Pokémon facts along
-- for the ride. Union the per-Pokémon views directly here instead, and
-- DISTINCT collapses each Pokémon's multiple ability rows back down to one
-- profile row:
SELECT DISTINCT
    a.pokemon_name,
    a.base_experience,
    a.height,
    a.weight,
    st.base_stat_total
FROM (
    SELECT pokemon_name, base_experience, height, weight FROM pokeapi.pikachu_abilities_table
    UNION ALL
    SELECT pokemon_name, base_experience, height, weight FROM pokeapi.charizard_abilities_table
) a
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
-- follows the exact same copy-paste pattern as Charizard in
-- sql/02_pokeapi_create.sql, plus one more UNION ALL branch per
-- cross-Pokémon view.
-- ---------------------------------------------------------------------------
