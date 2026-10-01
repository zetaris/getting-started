# Your first dataset

Return to [Start here](../../START-HERE.md) if platform access or query execution is not verified. This guide uses the existing recipes and recorded results. Source availability can change; this documentation update did not rerun them live.

## Default: PUDL energy-source codes

This is a small reference table, rather than the larger generator history. The [original recipe](../../open_data/parquet_csv/sql/03_pudl_create.sql) uses public-bucket options and needs no AWS keys. Its [recorded installation test](../install/zetaris-installation-test-record.md) documents a successful read on 24 September 2026. See its section “§6 Parquet/CSV: PUDL”.

Use the SQL Editor. Execute **each block separately**. The event instance is shared. Get an assigned team prefix and permission to create these objects first. `TEAM_07_PUDL` below is an example, not an assigned name. Replace it with your permitted database name in every block and later example. On a separate local install you can use the same convention. Do not rename or remove another team's objects.

### Check existing objects

```sql
SHOW LIGHTNING DATABASES;
```

If `TEAM_07_PUDL` exists, inspect its tables before creating anything:

```sql
SHOW LIGHTNING TABLES TEAM_07_PUDL;
```

If `pudl_eia_energy_sources` already exists, run the verification below. Reuse it only if its definition and source match the recipe. If you cannot inspect it, ask the administrator; a matching name alone does not establish matching data.

### Register the database, only if absent

```sql
CREATE LIGHTNING DATABASE TEAM_07_PUDL DESCRIBE BY "Catalyst Cooperative PUDL S3 filestore source";
```

### Register the small table, only if absent

```sql
CREATE LIGHTNING FILESTORE TABLE pudl_eia_energy_sources FROM TEAM_07_PUDL FORMAT PARQUET OPTIONS (
  PATH "s3a://pudl.catalyst.coop/stable/core_eia__codes_energy_sources.parquet",
  inferSchema "true",
  isS3BucketPublic "true",
  useS3PathStyleAccess "true",
  s3Endpoint "s3.us-west-2.amazonaws.com"
);
```

The `stable` path follows the publisher's current release. For a reproducible project, inspect the release-listing instructions in the recipe header and record or pin the release you actually use. An AWS CLI is optional for that listing; it is not required to execute this starter's SQL.

### Verify actual rows

```sql
SELECT * FROM TEAM_07_PUDL.pudl_eia_energy_sources LIMIT 10;
```

Expect nonempty rows with fields including `code`, `label`, `fuel_units`, and `description`. The recorded run returned 10 rows and included `AB` agricultural by-products and `ANT` anthracite coal. Row order is not guaranteed without ORDER BY, so those codes need not be the first rows.

If no rows return, check the source path and configuration using [troubleshooting](troubleshooting.md). Do not register the larger generator table as a workaround.

### Ask a first question

How many energy-source codes use each fuel unit?

```sql
SELECT fuel_units, COUNT(*) AS code_count
FROM TEAM_07_PUDL.pudl_eia_energy_sources
GROUP BY fuel_units
ORDER BY code_count DESC;
```

Explain any null fuel unit instead of discarding it silently. This is a count of **reference codes**, not power generation, consumption, or number of generators. Save the query and actual result. The new aggregation is supplied as an extension and still needs a live run in your instance.

## JSON alternative: PokéAPI

Use the [PokéAPI CREATE file](../../open_data/rest_apis/sql/non_rate_limited/02_pokeapi_create.sql). Read its caveats and copy the following complete statements into a working SQL file. Replace `POKEAPI_REST` and `pokeapi_rest` with your assigned team database, and replace the SchemaStore container `pokeapi` consistently with your assigned team container. The original fixed names are unsuitable for independent teams on a shared instance. Run one statement at a time:

1. `CREATE LIGHTNING DATABASE POKEAPI_REST`, if absent.
2. `CREATE SCHEMASTORE CONTAINER pokeapi`, if absent.
3. `CREATE LIGHTNING REST TABLE pikachu_facts`.
4. `CREATE SCHEMASTORE VIEW pikachu_abilities_table`.

Stop before the types, stats, Charizard, and union-view statements. Those are optional extensions; the complete SELECT file's analytical examples depend on more objects than this minimal subset.

Run this verification directly, after replacing the example container name, even though the matching SELECT file comments out its verification queries:

```sql
-- Replace TEAM_07_POKEAPI with your assigned SchemaStore container.
SELECT pokemon_name, ability_name, is_hidden
FROM TEAM_07_POKEAPI.pikachu_abilities_table;
```

The recorded installation test returned two Pikachu ability rows, `static` and `lightning-rod`, with `lightning-rod` hidden. Source responses can change; inspect `pikachu_facts` in your assigned raw REST database if they differ. Respect the source's fair-use guidance. REST registration does not guarantee a durable snapshot.

On rerun, inspect existing database/table registrations and the SchemaStore container/views in the platform first. Skip successful matching objects. If setup stopped partway through, resume from the failed statement after diagnosing it. Do not rerun the whole file or drop a container to make the recipe pass.

## Continue

Choose a [project path](project-paths.md), or select another source from [recipe readiness](recipe-readiness.md). You have completed this starter only when an external-data query returns plausible real rows.
