# Connecting Codex to Zetaris

## Contents

1. [Purpose](#1-purpose)
2. [Prerequisites](#2-prerequisites)
3. [Choosing a protocol](#3-choosing-a-protocol)
4. [Connection parameters](#4-connection-parameters)
5. [JDBC connection prompts](#5-jdbc-connection-prompts)
6. [REST connection prompts](#6-rest-connection-prompts)
7. [Verification](#7-verification)
8. [Usage rules](#8-usage-rules)
9. [Troubleshooting](#9-troubleshooting)

## 1. Purpose

This document describes how to connect Codex to a Zetaris instance at the
start of a Datathon session, using either of the two supported protocols:
**JDBC** and the **REST API**. Submit the relevant prompt from section 5 or 6 as
the first instruction of the session. After Codex verifies the connection, it
can execute Zetaris Lightning SQL from the supplied *Lightning Command Reference*,
and, over REST, call the endpoints described in the supplied OpenAPI
specification (`docs.yaml`).

## Repository and shared-instance scope

Start with [Start here](../../START-HERE.md) and the [connection choices](README.md). The instance/account, matching JDBC JAR, and direct-REST OpenAPI specification are external prerequisites; do not assume another checkout or platform bundle is present. This repo includes both a [starter recipe reference](lightning-recipe-reference.md) and the [full Lightning reference](../guides/zetaris-lightning-sql-commands.md).

The event instance is shared. Obtain an assigned team prefix and query/create permissions before creating objects. Inspect matching existing registrations and do not alter or remove another team's objects. Credentials stay in your local execution environment and out of saved prompts and reports.

The direct REST API described below uses its own API key and OpenAPI contract. The repository's [HTTP helpers](../../scripts/HOWTO.md) use the UI proxy, `ZETARIS_API_TOKEN` or login, and `.env`. A raw API origin and `ZETARIS_API_KEY` in `.env.local` are not drop-in replacements for those helpers.

## 2. Prerequisites

- A Zetaris user account issued by the Datathon organisers.
- The *Lightning Command Reference* ([`zetaris-lightning-sql-commands.md`](../guides/zetaris-lightning-sql-commands.md)).
- Codex, with a local workspace that permits the agent to run code. Use this repository and the included command reference. Supply the actual absolute driver path when choosing JDBC. For direct REST, obtain the matching `docs.yaml` separately; it is not supplied here.

For **JDBC**:

- The Zetaris JDBC driver JAR. The agent will ask you for its location; have the
  full path ready. For a local instance, `zetaris-platform` includes the driver
  at `jdbc/ndp-jdbc-driver-2.4.3.1-7eff043-driver.jar`.
- The driver class, `com.zetaris.lightning.jdbc.LightningDriver`.
- A Java runtime (JDK 11 or later) on the machine where the agent runs code. The
  driver is a Java JAR and cannot be loaded without one.
- Python with the `jaydebeapi` package, or another way to load a JDBC driver.
  Install it in a virtual environment (`python3 -m venv`), because system
  Python installations commonly refuse global `pip install`.
- The JDBC URL of the endpoint.

For **REST**:

- The base URL of the REST API: `http://localhost:8888/api/v1.0` for a local
  instance, or the URL supplied by the organisers for Zetaris Cloud.
- A Zetaris API key (a bearer token), **which you create yourself in the Zetaris
  GUI** (see section 6.1), and the numeric organisation ID. Store the key in a
  local file that is excluded from version control, for example
  `.env.local` containing `ZETARIS_API_KEY=...`. Do not paste the key into the
  prompt.
- The OpenAPI specification, `docs.yaml`.

Allow network access if Codex asks to connect to Zetaris Cloud.

## 3. Choosing a protocol

| Need | Use |
|---|---|
| Run Lightning SQL and read result sets | JDBC, or REST `sqls/run` |
| Manage objects through the platform API (datasources, pipelines, users, access control, files) | REST |
| Fetch table and column metadata, including keys | REST (`.../relations/{table}/schema`), or Lightning `DESCRIBE DATASOURCE TABLE` |
| No Java runtime available | REST |

Both protocols reach the same engine, so the same Lightning SQL gives the same
results. Verified against the local instance: row counts and integrity checks
over REST matched JDBC exactly. Differences: REST returns every value as a
string, and REST applies the `limit` you send, so set it deliberately.

## 4. Connection parameters

| Placeholder | Protocol | Description |
|---|---|---|
| `{{JDBC_URL}}` | JDBC | Zetaris Cloud JDBC URL supplied by the organisers. For a local instance use `jdbc:zetaris:lightning@localhost:10000`. |
| `{{DRIVER_JAR}}` | JDBC | Path to the Zetaris JDBC driver JAR. Leave it out of the prompt: the agent asks for it. |
| `{{USER_ID}}` | JDBC | Zetaris user ID, normally an email address. |
| `{{PASSWORD}}` | JDBC | Zetaris user password. |
| `{{REST_URL}}` | REST | REST base URL, ending in `/api/v1.0`. |
| `{{ORG_ID}}` | REST | Numeric organisation ID. The local instance uses `1`. |
| `ZETARIS_API_KEY` | REST | API key you create in the Zetaris GUI, read from `.env.local`. |

Replace each placeholder before submitting the prompt. Do not save credentials
in source files or commit them to a repository. The REST key belongs only in the
environment file.

## 5. JDBC connection prompts

Use the prompt for the target instance.

### 5.1 Zetaris Cloud

```text
Establish a JDBC connection to Zetaris Cloud using:

JDBC URL: {{JDBC_URL}}

Credentials:
- User ID: {{USER_ID}}
- Password: {{PASSWORD}}

Ask me for the full path of the Zetaris JDBC driver JAR before connecting, and
use that JAR directly (for example, via JayDeBeApi) with the driver class
com.zetaris.lightning.jdbc.LightningDriver. If Java or JayDeBeApi is missing,
tell me what you need to install and ask before installing it.

Use the JDBC endpoint directly and follow the supplied Lightning Command
Reference. Although the connection uses the Hive JDBC protocol, queries must be
executed using Zetaris Lightning SQL, not Spark SQL or Hive SQL. Do not
substitute a Hive or Spark driver.

Write Zetaris Lightning SQL, one statement per JDBC call, without a trailing
semicolon. Do not print my credentials back to me.

Do not initialize Spark or create a SparkSession.

Once connected, verify the connection by executing:

SELECT 1
```

### 5.2 Local instance

```text
Establish a JDBC connection to the local Zetaris instance using:

- JDBC URL: jdbc:zetaris:lightning@localhost:10000
- Driver class: com.zetaris.lightning.jdbc.LightningDriver

Credentials:
- User ID: {{USER_ID}}
- Password: {{PASSWORD}}

Ask me for the full path of the Zetaris JDBC driver JAR before connecting. In
the zetaris-platform folder it is jdbc/ndp-jdbc-driver-2.4.3.1-7eff043-driver.jar.
Use this JAR directly (for example, via JayDeBeApi) and load the specified
driver class. If Java or JayDeBeApi is missing, tell me what you need to
install and ask before installing it. Use a virtual environment for Python
packages.

Use the JDBC endpoint directly and follow the supplied Lightning Command
Reference. Do not substitute a Hive or Spark driver.

Write Zetaris Lightning SQL, one statement per JDBC call, without a trailing
semicolon. Do not print my credentials back to me.

Do not initialize Spark or create a SparkSession.

Once connected, verify the connection by executing:

SELECT 1
```

## 6. REST connection prompts

### 6.1 Create an API key

The agent cannot use REST until you have an API key, and the key is created by
the user, not the agent. Do this once before submitting a REST prompt:

1. Sign in to the Zetaris GUI with your own account (the local instance serves
   it on port 3000; Zetaris Cloud uses the URL from the organisers).
2. In the GUI, create a new API key for your user and copy it. If the GUI shows
   the key only once, copy it before closing the dialog.
3. Save it in `.env.local` in your workspace, as the single line
   `ZETARIS_API_KEY=<your key>`.
4. Make sure `.env.local` is excluded from version control (for example, add it
   to `.gitignore`).

The key acts as your user: it sees the same objects and carries the same
permissions as your account. If a REST call returns `401`, create a fresh key in
the GUI and replace the value in `.env.local`. Do not ask the agent to create or
fetch the key for you, and do not paste it into the prompt.

### 6.2 Zetaris Cloud

```text
Connect to the Zetaris REST API using:

- Base URL: {{REST_URL}}
- Organisation ID: {{ORG_ID}}
- API key: read ZETARIS_API_KEY from .env.local (I created it in the Zetaris
  GUI; do not create or request another). Never print it, log it, or put it
  in a URL.

Use the supplied OpenAPI specification (docs.yaml) as the reference for
endpoints. Send these headers on every request:

- Authorization: Bearer <ZETARIS_API_KEY>
- X-Request-ID: a new UUID for each request
- X-Org-ID: {{ORG_ID}}

To run Lightning SQL, POST to /sql-editor/sqls/run with a JSON body of
{"queryId": "<new UUID>", "sql": "<statement>", "source": "SqlEditor",
"limit": <max rows>}. Send one Lightning SQL statement per request, following
the supplied Lightning Command Reference, not Spark SQL or Hive SQL. Results
return as {"headers": [...], "data": [[...]]} with every value as a string.

Use read-only requests unless I ask for a change. Do not initialize Spark or
create a SparkSession.

Once connected, verify the connection by calling GET /datasource/datasources
and then running the SQL statement:

SELECT 1
```

### 6.3 Local instance

```text
Connect to the local Zetaris REST API using:

- Base URL: http://localhost:8888/api/v1.0
- Organisation ID: 1
- API key: read ZETARIS_API_KEY from .env.local (I created it in the Zetaris
  GUI; do not create or request another). Never print it, log it, or put it
  in a URL.

Use the supplied OpenAPI specification (docs.yaml) as the reference for
endpoints. Send these headers on every request:

- Authorization: Bearer <ZETARIS_API_KEY>
- X-Request-ID: a new UUID for each request
- X-Org-ID: 1

To run Lightning SQL, POST to /sql-editor/sqls/run with a JSON body of
{"queryId": "<new UUID>", "sql": "<statement>", "source": "SqlEditor",
"limit": <max rows>}. Send one Lightning SQL statement per request, following
the supplied Lightning Command Reference, not Spark SQL or Hive SQL. Results
return as {"headers": [...], "data": [[...]]} with every value as a string.

Use read-only requests unless I ask for a change. Do not call port 8889: it is
an internal login route and is not part of this connection. Do not initialize
Spark or create a SparkSession.

Once connected, verify the connection by calling GET /datasource/datasources
and then running the SQL statement:

SELECT 1
```

## 7. Verification

**JDBC.** Execute `SELECT 1`. A single result row containing `1` confirms the
driver loaded and the endpoint accepts queries.

**REST.** Two checks:

1. `GET {{REST_URL}}/datasource/datasources` returns HTTP 200 and a JSON list.
   On the local instance the list contains the `TPCH` sample datasource
   (`dataSourceId` 6, 8 tables).
2. `POST {{REST_URL}}/sql-editor/sqls/run` with `SELECT 1` returns
   `{"headers":["1"],"data":[["1"]],...}`.

Optionally, `SHOW DATASOURCES` run through either protocol lists the datasources
the account can see.

## 8. Usage rules

1. **Protocol.** For JDBC, use the URL format expected by the supplied driver:
   `jdbc:zetaris:lightning@<host>:<port>` for local instances. For REST, use
   `/api/v1.0` paths and send the three headers on every request.
2. **Lightning SQL only.** Write every statement in Zetaris Lightning SQL, on
   either protocol.
3. **No local Spark.** Do not start Spark or create a SparkSession. Processing
   takes place on the Zetaris instance.
4. **Statement syntax.** Follow the supplied *Lightning Command Reference* and
   use qualified names, for example `SELECT ... FROM <source>.<table>`.
5. **One statement per call.** Execute each Lightning command as one JDBC call
   or one REST request. Do not include a trailing semicolon.
6. **Secrets.** Keep passwords and the API key out of prompts, source files,
   logs and commits.
7. **Read first.** Start with read-only commands (`SHOW`, `DESCRIBE`, `SELECT`).
   Most commands that create, drop or grant require an administrator account.
8. **Data types.** REST returns all values as strings, and decimals can appear
   in exponent form (for example `0E-18`). Convert them before comparing.

## 9. Troubleshooting

| Symptom | Likely cause |
|---|---|
| `Unable to locate a Java Runtime` | No JDK installed. Install JDK 11 or later and point `JAVA_HOME` at it. |
| `externally-managed-environment` on `pip install` | System Python refuses global installs. Use a virtual environment. |
| JDBC `mismatched input ... expecting` | More than one statement, or a name list, sent in one call. Send one statement per call. |
| REST `401` | Key missing, wrong, or expired. Create a new key in the GUI and update `.env.local`, then check the `Authorization: Bearer` header and `.env.local`. The interactive docs page (`/redoc/index.html`) can return 401 even when the key is valid; test with `GET /datasource/datasources` instead. |
| REST `400 Not Allowed` | Wrong `X-Org-ID`. The local instance uses `1`. |
| REST `400` on a valid request | `X-Request-ID` is missing or not a UUID, or `queryId` is not a UUID. |
| Table not found | Use the qualified form `<source>.<table>`. REST relation names are upper-case, but SQL accepted lower-case in testing. |
