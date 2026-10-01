# Troubleshooting and reruns

Return to [Start here](../../START-HERE.md). Use this guide to decide the next check before changing registrations. The [SQL companion](zetaris-sql-companion.md) records deeper platform limitations.

## Errors and next steps

| Symptom | Check next | Stop or resume condition |
|---|---|---|
| No instance/account/driver | Check [connection prerequisites](../connections/README.md) and request the missing item from the instance administrator | Do not guess endpoints or credentials. SQL Editor does not need a JDBC driver. |
| Local install fails before startup | In the **platform bundle** directory, run its preflight and follow the [install guide](../install/updated_zetaris_installation_guide.md) | Resolve registry access, memory, disk, and configuration before starting recipes. This repo does not contain preflight.sh. |
| Login or HTTP 401 | Confirm the actual URL, user, and current credential/token | A healthy service does not prove the account works. Editing a bootstrapped bundle .env does not reset users. |
| Permission failure or HTTP 403 | Confirm organization, assigned team names, and query/create permissions with the administrator | Do not borrow admin credentials or change permissions yourself. |
| Missing/invalid numeric org ID | Follow [HTTP configuration](../../scripts/HOWTO.md#find-your-organization-id) | Do not use an example number. The SQL Editor can be used without this helper setting. |
| HTTP 404 or HTML response | Confirm the base URL is the UI origin and its proxy route is supported | Raw API port 8888 is not a replacement for the UI proxy. |
| JDBC driver/connection error | Check actual JAR, driver class, Java runtime, and endpoint from the execution host | `localhost` on a remote agent is not your laptop or the shared platform. |
| Duplicate database/table/container/view | Inspect existing objects and determine whether they are your own matching objects | Skip successful matching objects, or ask for a new assigned name. Do not rerun every CREATE. |
| CREATE succeeded but SELECT is empty | Check the path, actual source response, schema, server outbound access, and selected object | Resume only after a real bounded query returns plausible rows. Do not treat metadata as data proof. |
| HTTP 429 / source rate limit | Stop repeated queries, wait according to the source guidance, and review caching in the selected recipe | REST views may refetch the upstream source. Avoid running every example at once. |
| HTTP 502 / transport exception | Inspect the selected source's diagnostics. company_dns has a documented cold start; warm it using `deno task warmup:company-dns` from the repo root and retry once | Do not classify every 502 as cold start. Singapore PM2.5 is known to fail. Escalate persistent failures with a redacted record. |
| File exists on the laptop but cannot be queried | Check whether Zetaris can reach the file's storage location | A local download does not create a platform table or a usable remote PATH. |
| Chart example rejects a response | Save the real query response locally and compare it with the example's documented schema | Do not invent header fields or silently chart a wrapper/error response. |

## Reruns and team isolation

The event instance is shared. A name prefix is a collision-avoidance convention, **not** an authorization boundary. The administrator must assign account permissions and allowed names separately.

1. Obtain a unique team prefix and approved object scope. Examples such as `TEAM_07_PUDL` are not actual assignments.
2. Make a team working copy of the selected SQL. Replace every relevant database, container, namespace, model, and fully qualified reference consistently. Keep credentials out of SQL.
3. Inspect databases/tables with the commands in the [recipe reference](../connections/lightning-recipe-reference.md); inspect containers/views/models in the platform where needed. Ask the administrator if inspection is unavailable.
4. Reuse an existing source only if its definition/source and your read permission are confirmed. Matching names alone are insufficient.
5. Execute one statement at a time and record the last successful step. If a later statement fails, inspect persisted objects and resume only the missing/failed step after diagnosing it. There is no assumed transaction rollback for a whole recipe.
6. Cache only your own approved raw tables. Do not uncache, alter, or remove a shared object without its owner's permission.

`CREATE SCHEMASTORE CONTAINER` does not support `IF NOT EXISTS` in the recorded behavior, and the repo documents no container-removal path. Avoid repeatedly creating new containers as a troubleshooting tactic.

## Cleanup

Follow the selected recipe's caveats. The SQL companion records reliable `DROP VIEW` removal but inconsistent SQL removal of underlying REST/file registrations. It identifies Data Explorer's “File Source & API” panel as the confirmed removal route for those registrations. Ask the administrator before removing objects on the shared instance.

USL cleanup blocks have their own verification limits. Do not run a `DROP NAMESPACE ... CASCADE` against a shared namespace. Never stop or destroy the shared platform to reset your team. Local installation teardown applies only to a platform you own.

## Ask for help

The event support destination is unresolved. A Discord channel may be added later; no channel is currently specified. Until then, use the administrator who issued your access, or ask the organizer to identify one.

Send the route, failed step, redacted object name/query, time, error code/message, and last successful result. Redact credentials, Authorization headers, tokens, and unrelated customer data. Distinguish “login works,” “SQL executes,” and “source rows verified.” Use the [organizer checklist](hackathon-organizer-checklist.md) for missing event details.
