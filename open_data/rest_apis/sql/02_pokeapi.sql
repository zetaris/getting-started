-- =============================================================================
-- Source:   PokéAPI -- single Pokémon lookup
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
-- Investigated (not yet live-tested against Zetaris) 2026-09-18:
--   1. Response is a single top-level JSON object per Pokémon (not an
--      array) -- same shape class as EDGAR's companyconcept response.
--   2. `abilities` is array<struct<is_hidden,slot,ability:struct<name,url>>>
--      -- a genuine array-of-structs, and the nested `ability` field is
--      itself a struct (name/url) one level deeper than EDGAR's `fact`
--      struct. Dot-access two levels deep (fact.ability.name) is UNTESTED
--      -- confirm Zetaris supports nested-struct dot-access through an
--      exploded field, not just one level, before trusting this script.
--   3. Other array-of-struct fields exist on the same object if a richer
--      demo is wanted later: `types` (struct<slot,type:struct<name,url>>),
--      `stats` (struct<base_stat,effort,stat:struct<name,url>>), `moves`
--      (struct<move:struct<name,url>,version_group_details:array<...>>>) --
--      `moves` in particular has a doubly-nested array and is a good
--      "how deep can this go" stress test once the simple case works.
--   4. No known CREATE SCHEMASTORE CONTAINER naming conflict -- `pokeapi`
--      is a new container name, distinct from `edgar` (sql/01).
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
-- PIKACHU -- a single, well-known Pokémon for the first test
-- =============================================================================
CREATE LIGHTNING REST TABLE pikachu_facts FROM POKEAPI_REST REQUEST(
    endpoint "https://pokeapi.co/api/v2/pokemon/pikachu",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
) BODY ();

-- Flattened view -- abilities is the array-of-structs field, one level
-- of nested struct (ability.name/ability.url) inside it (see caveat 2):
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

-- Verify:
SELECT * FROM pokeapi.pikachu_abilities_table;

-- ---------------------------------------------------------------------------
-- Diagnostic (run if the view above fails or comes back empty):
--   SELECT * FROM pokeapi_rest.pikachu_facts;
--   DESCRIBE pokeapi_rest.pikachu_facts;
-- If the two-levels-deep dot-access (ability.ability.name) errors out,
-- that's the thing to report back -- it may mean Zetaris only supports one
-- level of struct access through an exploded array, which would also
-- affect any future source with similarly-nested JSON.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Optional, richer follow-up once the above works: repeat the pattern for
-- `types` and `stats` (single-level nested structs, same shape as
-- `abilities`), and for a second named Pokémon to prove the pattern
-- generalizes, e.g.:
--   CREATE LIGHTNING REST TABLE charizard_facts FROM POKEAPI_REST REQUEST(
--       endpoint "https://pokeapi.co/api/v2/pokemon/charizard",
--       method "get", response_type "json", http_encoding "URLENCODED"
--   ) HEADER () BODY ();
-- ---------------------------------------------------------------------------
