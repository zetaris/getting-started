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
-- Live-tested and confirmed working (2026-09-19) against Pikachu's
-- abilities table -- 2 rows back (is_hidden false/true), all columns
-- populated including the two-levels-deep dot-access:
--   1. Response is a single top-level JSON object per Pokémon (not an
--      array) -- same shape class as EDGAR's companyconcept response.
--   2. `abilities` is array<struct<is_hidden,slot,ability:struct<name,url>>>
--      -- confirmed: two-level dot-access through an exploded field
--      (ability.ability.name) works. This was the open question in the
--      original version of this script -- resolved favorably, and it
--      means the same pattern should work for any other source in this
--      package with similarly-nested JSON (e.g. NASA NeoWs's deeper
--      nesting, sql/05).
--   3. `types` and `stats` are the same shape class as `abilities`
--      (array<struct<..., X:struct<name,url>>>) -- extended below now that
--      the pattern is confirmed. `moves` also exists on the same object
--      but has a doubly-nested array (`version_group_details` inside each
--      move) -- not attempted here, would need a second LATERAL VIEW
--      explode() layered on top of this pattern; flagged as a future
--      stretch example, not built.
--   4. Extended to a second Pokémon (Charizard) to prove the pattern
--      generalizes across records, same as EDGAR's multi-company
--      structure -- one REST table + one set of views per Pokémon, all
--      landing in the shared `pokeapi` container.
--
-- Full script live-tested and confirmed working end-to-end (2026-09-18):
-- every CREATE (lightning database, container, both REST tables, all
-- per-Pokémon and cross-Pokémon views) and example queries 1-6 (see
-- sql/02_pokeapi_select.sql) all ran successfully against Zetaris.
--
-- See HOWTO.md, "Removing a source" and "Troubleshooting / FAQ", for
-- what does and does not work when tearing this source down. In short:
-- DROP VIEW is reliable; there is no confirmed SQL statement that
-- removes the underlying REST tables or the Lightning database
-- registration -- use the Zetaris Data Explorer for that instead.
--
-- ---------------------------------------------------------------------------
-- STEP 0: Lightning database for this source.
-- ---------------------------------------------------------------------------
CREATE LIGHTNING DATABASE POKEAPI_REST DESCRIBE BY "PokeAPI REST source";

-- ---------------------------------------------------------------------------
-- STEP 1: SCHEMASTORE container. RUN ONCE -- see open_data/rest_apis/HOWTO.md,
-- "Known limitations" (no IF NOT EXISTS support). Comment out on a re-run
-- if it already exists in your environment.
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

-- =============================================================================
-- TEARDOWN -- removes the flattened views this script created. Commented
-- out by default so a re-run of the file above doesn't accidentally wipe
-- a live environment; uncomment and run standalone when you want to tear
-- these views down.
--
-- DROP VIEW is the only teardown statement confirmed to work reliably in
-- this package. There is no SQL statement confirmed to remove the raw
-- REST tables or the POKEAPI_REST Lightning database registration itself
-- -- see HOWTO.md, "Removing a source" and "Troubleshooting / FAQ", for
-- the full explanation. To remove the REST tables and the POKEAPI_REST
-- registration, use the Zetaris Data Explorer: locate the entry under
-- "File Source & API" and remove it from there.
-- =============================================================================

-- -- Cross-Pokémon views:
-- DROP VIEW pokeapi.all_pokemon_types_table;
-- DROP VIEW pokeapi.all_pokemon_stats_table;
-- DROP VIEW pokeapi.all_pokemon_abilities_table;

-- -- Per-Pokémon views:
-- DROP VIEW pokeapi.pikachu_abilities_table;
-- DROP VIEW pokeapi.pikachu_types_table;
-- DROP VIEW pokeapi.pikachu_stats_table;
-- DROP VIEW pokeapi.charizard_abilities_table;
-- DROP VIEW pokeapi.charizard_types_table;
-- DROP VIEW pokeapi.charizard_stats_table;

-- To remove the POKEAPI_REST REST tables and Lightning database
-- registration, use the Zetaris Data Explorer's "File Source & API"
-- panel (see HOWTO.md, "Removing a source").

-- Next: verify with sql/02_pokeapi_select.sql
