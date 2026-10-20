# Connecting Codex to Zetaris

Open this repository as the Codex workspace. Codex reads the root `AGENTS.md`,
which sets the connection, SQL, and permission rules for this repository.

<a id="contents"></a>
## 1. Purpose

Use Codex to inspect a Zetaris instance, run Lightning SQL, or work through a
data recipe. It checks the connection before starting your goal.

## Repository and instance scope

Use the shared [client setup](client-setup.md) for connection details, API
authentication, and troubleshooting. Use your own local or AWS Zetaris
instance. Inspect existing objects before changing or reusing them.

## 2. Prerequisites

- This repository open as the workspace.
- Access to the Zetaris instance you want to use.
- Permission for Codex to run the repository's scripts and reach that instance.

For a local REST or JDBC instance, `Operation not permitted` when connecting
to `localhost` can mean Codex's command environment blocked local network
access; it does not by itself indicate a bad URL, key, or closed port. Retry
the same read-only preflight with network access if Codex offers it. If that
permission is unavailable, run the command in a terminal that can reach the
instance. For JDBC, remember that `localhost` is the machine running the JDBC
client; use the supplied host and port for a remote instance.

JDBC also needs Java, the Zetaris driver JAR, and your Zetaris user ID and
password. REST needs an API key that you create in the Zetaris GUI. See the
[shared connection settings](client-setup.md#2-set-up-envlocal).

## 3. Choosing a protocol

Use [JDBC or REST](client-setup.md#1-choose-a-protocol) based on the work and
access you have. The repository's REST runner calls the raw API; the small
`query_zetaris` and `check_zetaris` helpers use the UI proxy.

## 4. Connection parameters

Put settings in `.env.local`, not in a prompt. See the [connection settings and
authentication steps](client-setup.md#2-set-up-envlocal).

## 5. JDBC starter prompt

Copy the [JDBC starter prompt](client-setup.md#5-jdbc-starter-prompt) after
setting up the driver and `.env.local`.

## 6. REST starter prompt

### 6.1 Create an API key

Follow the shared [API key steps](client-setup.md#create-an-api-key).

### 6.2 Starter prompt

Set up `.env.local`, then copy the [REST starter prompt](client-setup.md#6-rest-starter-prompt).

### 6.3 Local or Zetaris Cloud

Use the REST URL and organisation ID for your instance from the [shared settings](client-setup.md#2-set-up-envlocal).

### 6.4 Fetch the OpenAPI specification

Fetch the spec with Basic authentication using the [shared instructions](client-setup.md#9-fetch-the-openapi-specification).

## 7. Verification

The shared guide explains the `SELECT 1`, REST endpoint, and instance-list
checks. Codex runs the read-only preflight before it starts your goal.

## 8. Usage rules

Follow root [`AGENTS.md`](../../AGENTS.md): start with read-only SQL, send one
statement per call, keep multi-table `COMPILE USL` intact, and wait for your
go-ahead before creating anything.

## 9. Troubleshooting

See [shared troubleshooting](client-setup.md#10-troubleshooting). It covers
JDBC setup, REST authentication and organisation IDs, and missing Lightning
databases.
