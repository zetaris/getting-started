# Troubleshooting

Find your error below. For detailed SQL limits, see the [SQL companion](zetaris-lightning-sql-companion.md).

## What went wrong?

| Problem | What to try |
|---|---|
| Missing URL, account or driver | For a local install, use the [Run locally page](https://cloud.enterprise.zetaris.com/dashboard/download). For an existing instance, use your supplied connection details. You can use SQL Editor without a JDBC driver. See [connection options](../connections/README.md). |
| Local install won't start | Run `preflight.sh` from the platform bundle and follow the [install guide](../install/updated_zetaris_installation_guide.md). Check registry access, memory, disk and configuration. |
| Login fails or HTTP 401 | Check your URL and credentials. Editing the platform's `.env` after setup doesn't reset an existing account. |
| Permission error or HTTP 403 | Check that your organisation, team names and account permissions match the requested operation. Use your own account. |
| Missing or invalid org ID | Follow [HTTP setup](../../scripts/HOWTO.md#find-your-organization-id). Use your actual numeric ID. SQL Editor doesn't need this setting. |
| HTTP 404 or an HTML response | Check that the UI URL supports the helper's proxy routes. The raw API port isn't a substitute. |
| JDBC won't connect | Check the driver JAR, driver class, Java and endpoint. On a remote agent, `localhost` points to the agent's machine. |
| Object already exists | Check its owner and definition. Reuse your matching objects, or ask for a new team name. |
| Table created but no rows returned | Check the source path, response, schema and Zetaris's access to the source. Try a small SELECT before adding more tables. |
| HTTP 429 | Wait as instructed by the source. Avoid repeated queries; REST views may fetch the source each time. Check the recipe's cache guidance. |
| HTTP 502 | Check the source error. For company_dns, run `deno task warmup:company-dns` from the repo root and retry once. Report other or repeated failures. |
| PUDL registration fails | It's a [known issue](../../open_data/parquet_csv/sql/known_to_fail/ISSUE-03-pudl.md). Use PokéAPI for the starter. |
| A downloaded file won't query | Put it in storage Zetaris can reach, then register it. A file on your laptop may be out of reach. |
| Chart won't read the result | Compare the real query response with the example's expected format. Check for an error response first. |

## Reruns and team isolation

On the shared instance, use your assigned team names and permissions. Names help avoid clashes; permissions control access.

1. Copy the SQL and replace all database, container, namespace, model and reference names consistently.
2. Check existing objects before creating them. See the [recipe reference](../connections/lightning-recipe-reference.md).
3. Reuse shared sources only with confirmed definitions and read permission.
4. Run one complete statement at a time. If one fails, fix it and continue from there. Earlier commands may already have created objects.
5. Cache, change or remove only your own approved objects.

`run_sql.py --skip-exists` skips duplicate errors. It doesn't check that the existing objects match your recipe. `CREATE SCHEMASTORE CONTAINER` doesn't support `IF NOT EXISTS` in the recorded run, and this repo has no container-removal command. Check before creating another container.

## Cleanup

Follow the recipe's cleanup notes. Remove only objects you own and have permission to remove.

`DROP VIEW` has worked in recorded tests. Removing REST/file registrations through SQL has been inconsistent; use Data Explorer's **File Source & API** panel for those. See the [SQL companion](zetaris-lightning-sql-companion.md) for details.

Only drop a namespace if you're allowed to remove everything it contains. Don't stop or reset the shared platform. For your own local install, follow the installation guide's shutdown steps.

## Record the error

Include the tool you're using, failed step, time, error message and last step that worked. Say whether you could log in, run SQL and query source rows. Remove passwords, tokens, Authorization headers and unrelated customer data before sharing anything.
