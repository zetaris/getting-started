# Lightning commands used by these recipes

This is a small repository reference based on the supplied SQL recipes and guides. For more commands, use the included [full Lightning reference](../guides/zetaris-lightning-sql-commands.md). Neither document grants permissions. Read source-specific caveats before executing SQL. On the shared event instance, replace example names with your assigned team names.

| Task | Command or source of the exact statement |
|---|---|
| Check execution | `SELECT 1;` |
| Inspect logical databases | `SHOW LIGHTNING DATABASES;` |
| Inspect tables in an existing database | `SHOW LIGHTNING TABLES TEAM_07_REST;` |
| Register a missing logical database | `CREATE LIGHTNING DATABASE TEAM_07_REST DESCRIBE BY "Team REST source";` |
| Register a public CSV table later | Follow the [NOAA recipe](../../open_data/parquet_csv/sql/02_noaa_ghcn_create.sql), including its size/caching caveats. PUDL registration is currently known to fail. |
| Register and flatten JSON | Use `CREATE LIGHTNING REST TABLE` and `CREATE SCHEMASTORE VIEW` blocks from the selected [REST recipe](../../open_data/rest_apis/HOWTO.md). |
| Create a SchemaStore container | `CREATE SCHEMASTORE CONTAINER TEAM_07_POKEAPI;` once per assigned name. There is no documented removal path in the repo. |
| Read a bounded sample | `SELECT * FROM TEAM_07_POKEAPI.pikachu_abilities_table LIMIT 10;` |
| Cache your own raw REST table when needed | `CACHE TABLE TEAM_07_REST.raw_table;` using the actual registered name. It is not a durable data snapshot. |
| Release your own cache | `UNCACHE TABLE TEAM_07_REST.raw_table;` |

The single-query helpers execute one full request. For multi-command files use `run_sql.py`, and use `onboard.py` with the manifest for dependency planning; inspect dry-run output before real execution. A semicolon inside a string is not a command boundary. A USL compile payload with several `CREATE TABLE` definitions is also one command; follow its guide without splitting it.

For full JSON shaping, VDM/USL, verification, and recorded platform limitations, use the [SQL companion](../guides/zetaris-lightning-sql-companion.md). For removal and partial setup, use [troubleshooting](../guides/troubleshooting.md). Do not use DROP commands as a general recovery step.
