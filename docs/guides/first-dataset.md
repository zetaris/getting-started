# Your first dataset

After [querying the supplied samples](../connections/lightning-recipe-reference.md), connect PokéAPI and query Pikachu's abilities.

## What you need

- Your own local or AWS Zetaris instance with permission to create objects.
- Outbound access from Zetaris to `https://pokeapi.co`.

Replace `POKEAPI_REST` and `pokeapi_rest` with your assigned database name, and `pokeapi` with your assigned container name everywhere below. Reuse an existing object only if it belongs to your team and its definition matches.

## Set it up

Run these four blocks in order, one at a time. Stop if a block fails.

Create the Lightning database:

```sql
CREATE LIGHTNING DATABASE POKEAPI_REST DESCRIBE BY "PokeAPI REST source";
```

Create the SchemaStore container:

```sql
CREATE SCHEMASTORE CONTAINER pokeapi;
```

Create the REST table:

```sql
CREATE LIGHTNING REST TABLE pikachu_facts FROM POKEAPI_REST REQUEST(
    endpoint "https://pokeapi.co/api/v2/pokemon/pikachu",
    method "get",
    response_type "json",
    http_encoding "URLENCODED"
) HEADER (
) BODY ();
```

Create the abilities view:

```sql
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
```

## Check the rows

```sql
SELECT pokemon_name, ability_name, is_hidden
FROM pokeapi.pikachu_abilities_table;
```

The [recorded test](../install/zetaris-installation-test-record.md) returned:

| Ability | Hidden? |
|---|---|
| static | No |
| lightning-rod | Yes |

If your result differs, inspect `pikachu_facts`. REST queries can fetch the API again; follow PokéAPI's fair-use guidance.

## Ask a question

Which ability is hidden?

```sql
SELECT pokemon_name, ability_name
FROM pokeapi.pikachu_abilities_table
WHERE is_hidden = true;
```

Expect `lightning-rod`. Use your assigned container name in both queries.

## Next step

[Choose what to build](project-paths.md). For additional sources, see [Cookbooks](recipe-readiness.md). If a step fails, use [troubleshooting](troubleshooting.md) before rerunning.

Using scripts? Follow [client scripts](../../scripts/HOWTO.md) and preview with `--dry-run` before creating objects.
