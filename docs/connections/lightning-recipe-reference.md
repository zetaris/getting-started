# Run your first SQL commands

[Connect to Zetaris](README.md). You need login and query permission on the supplied NY Taxi and TPCDS filestore samples. These steps only read data and metadata.

Run each SQL block separately and wait for the result.

## 1. Check execution

```sql
SELECT 1 AS one;
```

Expect one row with `1`.

```sql
SHOW SERVER VERSION;
```

This returns your Zetaris version.

## 2. See what is available

```sql
SHOW LIGHTNING DATABASES;
```

Look for `NY_TAXI` and `TPCDS_DB`.

```sql
SHOW DATASOURCES;
```

This lists external database connections, so it may be empty. File and REST sources appear under `SHOW LIGHTNING DATABASES`.

Results reflect your access. Empty discovery lists are valid; ask the organisers if you cannot see the supplied samples.

## 3. Inspect the sample tables

```sql
SHOW LIGHTNING TABLES NY_TAXI;
```

```sql
SHOW LIGHTNING TABLES TPCDS_DB;
```

These return table lists. Inspect the columns of one table:

```sql
DESCRIBE DATASOURCE TABLE NY_TAXI.taxi_zones;
```

This also works for file and REST tables. Names use `database.table`.

## 4. Read a small sample

```sql
SELECT * FROM NY_TAXI.taxi_zones LIMIT 5;
```

```sql
SELECT * FROM TPCDS_DB.reason LIMIT 5;
```

Expect up to five rows from each query. To choose columns and order the result:

```sql
SELECT r_reason_sk, r_reason_desc
FROM TPCDS_DB.reason
ORDER BY r_reason_sk
LIMIT 5;
```

## Next step

Connect [your first dataset](../guides/first-dataset.md) using PokéAPI. That step needs creation permission on your instance and API access from Zetaris.

For scripts, use [client scripts](../../scripts/HOWTO.md). For more SQL, use the [full reference](../guides/zetaris-lightning-sql-commands.md) and its setup requirements. If a step fails, see [troubleshooting](../guides/troubleshooting.md).
