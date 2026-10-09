# Connect to Zetaris

[Get access first](../../START-HERE.md), then choose how you want to run SQL. The SQL Editor is the easiest place to start.

| Option | What you need | Check it works |
|---|---|---|
| SQL Editor | Website URL, your account and query permissions | Run `SELECT 1 AS one;`. Expect one row with `1`. |
| Assistant over JDBC | Zetaris driver JAR, JDBC endpoint, account and Java | Run `SELECT 1`. Expect one row with `1`. |
| HTTP helpers | Supported UI URL, numeric org ID, account or token, and Python or Deno | Run `SELECT 1` with the query helper. |

Use your own account and assigned team names on the shared instance.

## SQL Editor

Sign in and open the SQL Editor. Run one complete statement at a time. Then try [your first dataset](../guides/first-dataset.md).

You don't need Java, a JDBC driver, Python or Deno for this option.

## Coding assistants

Follow the guide for [Cursor](cursor-connection.md), [Codex](codex-connection.md), or [Claude Code](claude-code-connection.md).

For JDBC, get the matching Zetaris driver from the platform download. Use Zetaris Lightning SQL and its driver; don't substitute a Hive or Spark driver or start a local Spark session.

Direct REST uses an API key and the platform's OpenAPI spec. Its URL and credentials differ from the UI proxy helpers below. Follow your assistant's guide for the right settings.

Need SQL syntax? See the [recipe reference](lightning-recipe-reference.md) or [full SQL reference](../guides/zetaris-lightning-sql-commands.md).

## HTTP helpers

Follow [client scripts](../../scripts/HOWTO.md) to set up `.env.local`, authentication and the org ID.

Use a UI URL that supports the documented proxy routes. If it doesn't, use SQL Editor or JDBC. Changing the URL to a raw API port won't fix it.

## Run a recipe

Use `onboard.py --list` to see recipes and `onboard.py plan <id>` to see their dependencies. Use `run_sql.py` for a single SQL file with several commands. Preview with `--dry-run` and check your team names before running anything that creates objects.

The older query helper sends a whole file as one request. Use the runners above for multi-command files. Keep a multi-table `COMPILE USL` command together. See [client scripts](../../scripts/HOWTO.md) for the commands.
