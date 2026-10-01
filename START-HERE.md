# Start here

This repo helps you make data queryable in Zetaris and turn a query into a project. You choose the question and the result you want to build.

It contains recipes, connection helpers, and documentation. It does **not** include a running platform, the platform distribution, an issued account, registry credentials, a JDBC driver, or the complete platform SQL manual. A [recipe command reference](docs/connections/lightning-recipe-reference.md) is included for this repo’s starter commands. Check access before running SQL.

## 1. Check your prerequisites

| Requirement | How to resolve it |
|---|---|
| A Zetaris instance and a user permitted to query and create the required objects | Use the existing-instance path below if access has actually been supplied; otherwise follow the installation path. |
| Platform access details | Record the web UI URL, account, and allowed workspace/objects. For JDBC, also obtain the JDBC endpoint and matching driver. For HTTP, obtain the numeric organization ID and confirm the UI exposes the proxy routes. |
| Outbound source access | The Zetaris server must reach the selected public source. A successful request from your laptop alone does not prove this. |
| Execution tool | Start in the SQL Editor. Deno/Python and JDBC are optional routes; see [connection choices](docs/connections/README.md). |
| Scope and naming | The event instance is shared. Obtain an assigned team prefix and confirm which objects you may create. See [reruns and team isolation](docs/guides/troubleshooting.md#reruns-and-team-isolation). |

Do not fill unknown endpoints or credentials with example values. If required access is missing, use the [organizer checklist](docs/guides/hackathon-organizer-checklist.md) to identify exactly what to request.

### Path A: an existing instance

1. Obtain the actual web URL, user account, and permissions from its administrator.
2. Sign in and open the SQL Editor.
3. Run `SELECT 7 AS seven;`. Expect one row containing `7`.
4. If this fails, resolve [connection and permission errors](docs/guides/troubleshooting.md) before registering sources.

This path works only once access is confirmed. This repo does not grant access to an instance.

### Path B: install locally

Follow the [installation guide](docs/install/updated_zetaris_installation_guide.md), starting with obtaining the separate distribution and registry access. It covers machine requirements, configuration, startup, `verify.sh`, first login, and teardown. The [test record](docs/install/zetaris-installation-test-record.md) records a local fresh-install run. AWS is an optional documented path whose steps have not been live-tested in that record.

Keep the platform bundle's `.env` separate from this repo's optional client `.env`. Configure the initial account before the bundle's first startup; later edits do not recreate existing accounts.

## 2. Choose how to execute SQL

Use the **SQL Editor** for the shortest manual path. Select one complete statement and execute it, then wait for its result before the next dependent statement.

For agent-driven work, use [Cursor](docs/connections/cursor-connection.md) or [Codex](docs/connections/codex-connection.md) over JDBC after obtaining the required driver and reference. For application work, use the [HTTP helpers](scripts/HOWTO.md).

The helpers' `--file` option sends the entire file in one request. It does not split SQL or roll back a partially completed recipe. Use one-statement files. A `COMPILE USL ... DDL` payload containing several table definitions is one command and must stay intact.

## 3. Get your first real rows

Follow [your first dataset](docs/guides/first-dataset.md). The default uses only the small PUDL energy-source code table. A small PokéAPI JSON alternative is included if you want to learn REST flattening or the PUDL source is unavailable.

Success means nonempty rows with the expected fields and values. A login, `SELECT 1`, a visible registration, or a successful CREATE alone does not establish that the external data works.

These recipes register access to remote data. They do not necessarily make a durable copy. REST queries may fetch again; cache and materialization are separate steps with the limits in the [SQL companion](docs/guides/zetaris-sql-companion.md).

## 4. Choose your direction

After verification, choose an [analysis, data product, or application path](docs/guides/project-paths.md). These are starting points, not assigned objectives. For more datasets, use the [recipe readiness index](docs/guides/recipe-readiness.md). Planned and known-to-fail work is clearly separated from starter choices.

## 5. Save a result someone else can reproduce

Use the [demo template](docs/guides/demo-template.md) to record the question, setup, query, real result, and limitations. Confirm event submission and judging requirements with the organizer; this repo does not define them.

For errors, partial setup, shared-instance naming, or cleanup, start with [troubleshooting](docs/guides/troubleshooting.md). Before stopping a locally installed platform, use the installation guide's lifecycle instructions. Do not tear down a shared instance.
