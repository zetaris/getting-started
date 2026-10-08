# Your first dataset

Let's query Pikachu's abilities using [PokéAPI](https://pokeapi.co/). [Connect to Zetaris](../connections/README.md) first.

## Set it up

Open the [PokéAPI setup SQL](../../open_data/rest_apis/sql/non_rate_limited/02_pokeapi_create.sql). For this starter, you only need these four complete statements:

1. Create the Lightning database `POKEAPI_REST`.
2. Create the SchemaStore container `pokeapi`.
3. Create the REST table `pikachu_facts`.
4. Create the view `pikachu_abilities_table`.

Copy those statements into your own SQL file. On the shared instance, replace `POKEAPI_REST`, `pokeapi_rest` and `pokeapi` with your assigned database and container names throughout. Get permission to create them, then run one statement at a time in the SQL Editor.

If you use `run_sql.py`, preview your file with `--dry-run` first. `onboard.py plan pokeapi` covers the full recipe, including the optional tables below.

Leave the types, stats, Charizard and union views for later. Skip objects you've already created after checking their definitions match.

## Check the rows

Replace `TEAM_07_POKEAPI` with your assigned SchemaStore container, then run:

```sql
SELECT pokemon_name, ability_name, is_hidden
FROM TEAM_07_POKEAPI.pikachu_abilities_table;
```

The [recorded test](../install/zetaris-installation-test-record.md) returned:

| Ability | Hidden? |
|---|---|
| static | No |
| lightning-rod | Yes |

Check your actual result. If it differs, inspect `pikachu_facts` in your database. The source can change, and REST queries may fetch it again. Follow PokéAPI's fair-use guidance.

## Ask a question

Which ability is hidden?

```sql
SELECT pokemon_name, ability_name
FROM TEAM_07_POKEAPI.pikachu_abilities_table
WHERE is_hidden = true;
```

Use your container name here too. You should see `lightning-rod` if the source still matches the recorded test. Save your query and result.

## Try more data

The [NOAA recipe](../../open_data/parquet_csv/sql/02_noaa_ghcn_create.sql) is a later option. It reads a large annual CSV and needs caching for its analysis queries. Check the [file guide](../../open_data/parquet_csv/HOWTO.md) and your cache permissions first.

PUDL is currently blocked by a registration failure. Use PokéAPI for the starter. The [issue](../../open_data/parquet_csv/sql/known_to_fail/ISSUE-03-pudl.md), [historical SQL](../../open_data/parquet_csv/sql/known_to_fail/03_pudl_create.sql) and [test record](../install/zetaris-installation-test-record.md) keep the earlier details. Only try PUDL after your administrator confirms it works or approves a fix.

Once you have real rows, [choose what to build](project-paths.md). If a step fails, check [troubleshooting](troubleshooting.md) before rerunning it.
