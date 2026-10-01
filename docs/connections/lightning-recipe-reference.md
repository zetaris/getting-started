# Lightning commands used by these recipes

This is a small repository reference based on the supplied SQL recipes and guides. It is not a complete platform SQL manual and does not grant permissions. Read source-specific caveats before executing SQL. On the shared event instance, replace example names with your assigned team names.

| Task | Command or source of the exact statement |
|---|---|
| Check execution | `SELECT 1;` |
| Inspect logical databases | `SHOW LIGHTNING DATABASES;` |
| Inspect tables in an existing database | `SHOW LIGHTNING TABLES TEAM_07_PUDL;` |
| Register a missing logical database | `CREATE LIGHTNING DATABASE TEAM_07_PUDL DESCRIBE BY "Team PUDL source";` |
| Register a public Parquet table | Use the complete `CREATE LIGHTNING FILESTORE TABLE ... FORMAT PARQUET OPTIONS (...)` block in [your first dataset](../guides/first-dataset.md). |
| Register and flatten JSON | Use `CREATE LIGHTNING REST TABLE` and `CREATE SCHEMASTORE VIEW` blocks from the selected [REST recipe](../../open_data/rest_apis/HOWTO.md). |
| Create a SchemaStore container | `CREATE SCHEMASTORE CONTAINER TEAM_07_POKEAPI;` once per assigned name. There is no documented removal path in the repo. |
| Read a bounded sample | `SELECT * FROM TEAM_07_PUDL.pudl_eia_energy_sources LIMIT 10;` |
| Cache your own raw REST table when needed | `CACHE TABLE TEAM_07_REST.raw_table;` using the actual registered name. It is not a durable data snapshot. |
| Release your own cache | `UNCACHE TABLE TEAM_07_REST.raw_table;` |

Execute one command per JDBC request or one-statement HTTP file. A semicolon inside a string is not a command boundary. A USL compile payload with several `CREATE TABLE` definitions is also one command; follow its guide without splitting it.

For full JSON shaping, VDM/USL, verification, and recorded platform limitations, use the [SQL companion](../guides/zetaris-sql-companion.md). For removal and partial setup, use [troubleshooting](../guides/troubleshooting.md). Do not use DROP commands as a general recovery step.
