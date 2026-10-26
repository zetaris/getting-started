# Driver memory and wide JSON

Use this guide when caching nested JSON uses too much memory, or queries report `Cannot call methods on a stopped SparkContext`.

## 1. Recover a stopped query engine

From the platform bundle folder, read the driver logs:

```bash
docker compose logs --tail=100 driver
docker stats --no-stream
```

Look for `OutOfMemoryError`, repeated garbage collection, or a stopped SparkContext. A small cache size in the Spark UI does not show all driver memory: schemas, query plans, execution history and temporary work also use heap.

A port healthcheck can stay green after Spark stops. Restart the driver to recover:

```bash
docker compose restart driver
```

Wait for it to start, then run `SELECT 1` in SQL Workspace. A restart clears in-memory caches, so reduce the workload before caching again. Do not delete data volumes to fix an OOM.

## 2. Keep caching bounded

- Cache only data you reuse, and release it when finished.
- Select the fields you need instead of keeping a large nested document.
- Load sources one at a time rather than starting many cache operations together.
- Watch total driver memory, not just the cache size shown in the UI.

Release a SQL cache using its original name, for example:

```sql
UNCACHE TABLE analytics.raw_entity_a
```

A narrow view can help if your build supports caching it. Check the supported syntax before using Spark examples such as `CACHE TABLE ... AS SELECT`; do not assume every Spark SQL cache option is available in Zetaris.

There is no useful fixed limit on the number of REST tables. The JSON shape, cached working set and memory available matter more than the table count.

## 3. Store repeated JSON data as tall Parquet

For repeated analysis, fetch each source when adding or refreshing it, turn its nested JSON into rows, and save those rows as Parquet. Query the Parquet table afterward.

For example, use columns like these instead of making every metric a separate nested field:

| entity_id | namespace | metric | unit | period_end | value |
|---|---|---|---|---|---|
| entity_a | financial | Revenue | USD | 2025-12-31 | 100000 |
| entity_a | financial | NetIncome | USD | 2025-12-31 | 12000 |
| entity_b | financial | Revenue | USD | 2025-12-31 | 250000 |

All entities share the same columns. Adding another metric adds rows rather than widening the schema. Queries still need working memory, but they no longer need to fetch the original API document each time.

### Turn nested maps into rows

This example assumes an existing REST table named `analytics.raw_entity_a` with a `facts` field shaped as:

```text
namespace → metric → units → unit name → array of observations
```

Each observation has `end` and `val` fields. Replace the table and field names to match your source, and run one statement at a time:

```sql
SELECT
  'entity_a' AS entity_id,
  ns_key AS namespace,
  metric_key AS metric,
  unit_key AS unit,
  observation.end AS period_end,
  observation.val AS value
FROM (
  SELECT from_json(
    to_json(facts),
    'map<string,map<string,struct<units:map<string,array<struct<end:string,val:decimal(28,4)>>>>>>'
  ) AS parsed
  FROM analytics.raw_entity_a
)
LATERAL VIEW explode(parsed) ns AS ns_key, ns_value
LATERAL VIEW explode(ns_value) metrics AS metric_key, metric_value
LATERAL VIEW explode(metric_value.units) units AS unit_key, unit_value
LATERAL VIEW explode(unit_value) observations AS observation
```

`from_json` gives the JSON a known schema. `explode` turns each map or array into rows. Include any other fields you need, such as period start, source record ID or publication date. Fields left out of the schema are discarded. Choose a numeric type that preserves your source's range and precision; this example keeps four decimal places.

### Write the rows through a pipeline

Create a pipeline container if you do not already have one:

```sql
CREATE PIPELINE CONTAINER json_loaders
DESCRIPTION 'Load nested JSON into Parquet'
```

In **Workbench → Pipeline**, configure a loader with:

| Node | Settings |
|---|---|
| `SQLTable` | Use the flattening query above. Define its output columns with the matching types. |
| `FileSink` | Connect it to the SQL node. Use storage `dffs`, format `parquet`, mode `overwrite`, and path `analytics_tall/entity_id=entity_a`. |

Use a separate folder for each entity. **Overwrite replaces that entity's folder**, so do not point it at the shared `analytics_tall` root. If a refresh contains only new records, combine them with existing history before overwriting, or use an appropriate append/deduplication design.

Run the saved pipeline. A pipeline registered as `json_loaders.load_entity_a` can be run with:

```sql
SELECT * FROM json_loaders.load_entity_a
```

After the first load has written Parquet files, register the shared folder. Use your existing Lightning database, or create `analytics` first if needed:

```sql
CREATE LIGHTNING FILESTORE TABLE facts_tall
FROM analytics
FORMAT PARQUET
OPTIONS (path "dffs://analytics_tall")
```

Query it with normal SQL:

```sql
SELECT entity_id, metric, period_end, value
FROM analytics.facts_tall
WHERE metric = 'Revenue' AND unit = 'USD'
LIMIT 20
```

Inspect row counts, missing values and a few known records after loading. Keep the same output schema across loaders and confirm that your build discovers each entity folder. Saving the original wide struct unchanged as Parquet keeps the changing-schema problem; flatten it first.

## 4. Give the driver enough heap

In the platform bundle's `.env`, adjust `ZSPARK_DRIVER_MEM` to fit the machine. For example, on a machine with 16 GB available, a possible allocation is:

```dotenv
ZSPARK_DRIVER_MEM=5g
```

This is an example, not a default for every bundle. Leave room for Postgres, the API, other containers, native memory and the operating system. On Docker Desktop, its memory allocation must also be large enough. More heap gives headroom; it does not make unlimited caching safe.

Apply a changed `.env` value by recreating the driver while its dependencies are running:

```bash
docker compose up -d --no-deps --force-recreate driver
```

A plain `docker compose restart driver` does not apply changed container environment variables. Set heap through `ZSPARK_DRIVER_MEM`, not `-Xmx` in the Spark options below.

## 5. Exit on Java OOM and retain less history

In the bundle's `conf/spark-defaults.conf`, add or update these entries:

```properties
spark.driver.defaultJavaOptions   -XX:+ExitOnOutOfMemoryError
spark.sql.ui.retainedExecutions   100
```

Preserve any other options already on the `spark.driver.defaultJavaOptions` line. Use a single entry for each setting.

The first setting asks Java to exit on an `OutOfMemoryError`. The second limits how many SQL executions the Spark UI remembers. These are separate controls: neither fixes a bad query or prevents memory exhaustion.

Use `defaultJavaOptions` so the flag is combined with the launcher's `extraJavaOptions`. A command-line `extraJavaOptions` setting can override the same setting in the file. See [Spark configuration](https://spark.apache.org/docs/3.5.6/configuration.html).

Restart the driver to reload this mounted configuration file:

```bash
docker compose restart driver
```

Check that the running Java command includes the flag, without printing its other arguments:

```bash
docker compose exec -T driver sh -c "ps -eo args | grep '[j]ava' | grep -o -- '-XX:+ExitOnOutOfMemoryError'"
```

Confirm the SQL history setting in the Spark UI's **Environment** tab. Check that the driver service in `docker-compose.yml` has `restart: unless-stopped` if you want Docker to restart it after Java exits.

Verify the effective settings on your bundle before relying on this recovery behaviour. It does not replace a query-aware healthcheck or change HTTP error handling. A Docker or host memory kill is also different from a Java heap OOM.

## 6. Capture useful diagnostics

For recurring failures, record the failed query, driver heap setting, active caches and driver logs. An exception such as `DefaultCachedBatchSerializer` / `ArrayIndexOutOfBoundsException` needs investigation separately; more heap is not a confirmed fix for it.

If the driver produced a heap dump at the following path, copy it out:

```bash
docker compose cp driver:/home/zetaris/zetaris-ndp-driver/logs/driver_heap_dump.log ./driver_heap_dump.hprof
```

The path depends on the bundle's JVM settings. A heap dump can be as large as the heap and contain source data or credentials. Keep it private and out of commits; use an access-controlled link when sharing it with support.
