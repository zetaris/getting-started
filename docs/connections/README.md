# Choose a connection route

Start with [the access checklist](../../START-HERE.md). This repo does not supply an instance or account. The event instance is shared; use your assigned user and team object names, not a platform administrator's credentials.

| Route | Use it for | Required beyond this repo | First check |
|---|---|---|---|
| SQL Editor | Manual onboarding and exploring SQL | Actual web UI URL, account, query/create permissions | `SELECT 7 AS seven;` returns one row with `7`. |
| Coding assistant over JDBC | An agent executing Lightning SQL | Matching Zetaris driver JAR, JDBC endpoint, account, a Java runtime and a compatible JDBC client | `SELECT 1;` returns one row with `1`. |
| HTTP helpers | Scripts and application integration | A UI origin exposing the documented proxy routes, numeric org ID, account or API token, Deno or Python | Run the query helper with `SELECT 1`; listing databases alone is insufficient. |

Coding assistants also support direct REST through the separately supplied OpenAPI specification and API key. This differs from the UI proxy helpers below. Do not mix base URLs or credential variable names.

The SQL Editor does not need the Deno/Python helpers or a JDBC driver. If a remote UI does not expose the helper proxy routes, use SQL Editor/JDBC or ask its administrator for a supported HTTP route; do not replace the UI origin with a raw API port and hope it works.

## SQL Editor

Sign in at the actual supplied URL. Execute each complete command separately, waiting for its result. Use [your first dataset](../guides/first-dataset.md) for exact starter steps and expected rows.

## Cursor and Codex over JDBC

Use [the Cursor prompt](cursor-connection.md), [the Codex guide](codex-connection.md), or [the Claude Code guide](claude-code-connection.md). Both use the matching Zetaris driver, avoid a local Spark session, and submit one Lightning command per request. The [recipe command reference](lightning-recipe-reference.md) is available in this repo; the [SQL companion](../guides/zetaris-lightning-sql-companion.md) covers more complex shapes and limitations.

The platform distribution and driver are not in this repository. Obtain them from the installation guide's distribution route or your instance administrator. Do not search an unrelated checkout or substitute a Hive/Spark driver. A documented JAR filename is an example for the guide's tested distribution, not proof that you have that file.

## HTTP helpers

Follow [scripts/HOWTO.md](../../scripts/HOWTO.md) for `.env.local`, authentication, organization ID, execution, and errors. The `.env.local` here configures clients; it does not bootstrap or change accounts in the running platform.

Only the HTTP route needs `ZETARIS_ORG_ID`. If you cannot obtain it yet, the SQL Editor route can still be used once platform access is verified.

## Multi-command onboarding

Use the [manifest](../../open_data/manifest.json) with `python3 scripts/onboard.py --list` and `plan <id>...` to inspect dependencies. `run_sql.py` is the multi-command runner; the older query helper still sends one full text. Follow [scripts/HOWTO.md](../../scripts/HOWTO.md), run dry-run first, and inspect team names before any real execution.
