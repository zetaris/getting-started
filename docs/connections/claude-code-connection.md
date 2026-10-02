# Connecting Claude Code to Zetaris

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

This document describes how to connect Claude Code to a Zetaris instance at the
start of a Datathon session, using either of the two supported protocols:
**JDBC** and the **REST API**. Submit the relevant prompt from section 5 or 6 as
the first instruction of the session. After Claude Code verifies the connection, it
can execute Zetaris Lightning SQL from the supplied *Lightning Command Reference*,
and, over REST, call the endpoints described in the supplied OpenAPI
specification (`docs.yaml`).

## 2. Prerequisites

- A Zetaris user account issued by the Datathon organisers.
- The *Lightning Command Reference* ([`docs/guides/zetaris-lightning-sql-commands.md`](../guides/zetaris-lightning-sql-commands.md)).
- The *Zetaris SQL Companion* ([`docs/guides/zetaris-lightning-sql-companion.md`](../guides/zetaris-lightning-sql-companion.md)): confirmed syntax shapes, quoting rules, gotchas and platform limitations. Add it to the prompt alongside the command reference.
- Claude Code, with a local workspace that permits the agent to run code. Open the folder that holds `.env.local` and the reference so relative paths resolve. Add the reference, driver path and `docs.yaml` to the prompt with `@` file mentions, and approve the shell commands the agent asks to run.

For **JDBC**:

- The Zetaris JDBC driver JAR. The agent will ask you for its location; have the
  full path ready.
- The driver class, `com.zetaris.lightning.jdbc.LightningDriver`.
- A Java runtime (JDK 11 or later) on the machine where the agent runs code. The
  driver is a Java JAR and cannot be loaded without one. On macOS, `java` on the
  `PATH` can be a stub that reports "Unable to locate a Java Runtime" even when a
  JDK is installed. Check `/usr/libexec/java_home` and Homebrew's
  `/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`, and set
  `JAVA_HOME` to the JDK you find. If there is none, install one with
  `brew install openjdk@17`. Prefer that to the `temurin` cask, which needs
  `sudo`; an agent cannot enter your password.
- Python with the `jaydebeapi` package, or another way to load a JDBC driver.
  Install it in a virtual environment, because system Python installations
  commonly refuse global `pip install`:
  `python3 -m venv .venv && .venv/bin/pip install -r scripts/requirements.txt`.
  The repository's own scripts use that `.venv` automatically.
- The JDBC URL of the endpoint.
- Your Zetaris user ID and password. If you keep them in `.env.local` as
  `ZETARIS_USERNAME` and `ZETARIS_PASSWORD`, the agent can read them in the
  shell without them appearing in the prompt. Optionally set `ZETARIS_JDBC_JAR`
  to the driver path there too.

To check all of this at once, run `python3 scripts/preflight.py --jdbc --jar <path>`.
It is read-only, reports what is missing, and installs nothing.

For **REST**:

- The base URL of the REST API: `http://localhost:8888/api/v1.0` for a local
  instance, or the URL supplied by the organisers for Zetaris Cloud.
- A Zetaris API key (a bearer token), **which you create yourself in the Zetaris
  GUI** (see section 6.1), and the numeric organisation ID. Store the key in a
  local file that is excluded from version control, for example
  `.env.local` containing `ZETARIS_API_KEY=...`. Do not paste the key into the
  prompt.
- The OpenAPI specification, `docs.yaml`, which the agent fetches from the
  instance (section 6.4). This needs `ZETARIS_USERNAME` and `ZETARIS_PASSWORD`
  in `.env.local`, because the docs route uses Basic authentication.

Allow network access if Claude Code asks to connect to Zetaris Cloud.

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
tell me what you need to install and ask before installing it. On macOS, java
on the PATH can be a stub even when a Homebrew JDK is installed: look for one
(for example /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home)
and set JAVA_HOME before concluding Java is missing.

Use the JDBC endpoint directly and follow the supplied Lightning Command
Reference. Although the connection uses the Hive JDBC protocol, queries must be
executed using Zetaris Lightning SQL, not Spark SQL or Hive SQL. Do not
substitute a Hive or Spark driver.

Write Zetaris Lightning SQL, one statement per JDBC call, without a trailing
semicolon. Do not print my credentials back to me.

Do not initialize Spark or create a SparkSession.

Once connected, verify the connection by executing these statements, one per
call:

SELECT 1
SHOW LIGHTNING DATABASES

SHOW DATASOURCES does not list the REST and file sources registered with
CREATE LIGHTNING DATABASE, so use SHOW LIGHTNING DATABASES to see those. An
empty result is normal on a clean instance.
```

### 5.2 Local instance

```text
Establish a JDBC connection to the local Zetaris instance using:

- JDBC URL: jdbc:zetaris:lightning@localhost:10000
- Driver class: com.zetaris.lightning.jdbc.LightningDriver

Credentials:
- User ID: {{USER_ID}}
- Password: {{PASSWORD}}

Ask me for the full path of the Zetaris JDBC driver JAR before connecting.
Use this JAR directly (for example, via JayDeBeApi) and load the specified
driver class. If Java or JayDeBeApi is missing, tell me what you need to
install and ask before installing it. On macOS, java on the PATH can be a stub
even when a Homebrew JDK is installed: look for one (for example
/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home) and set
JAVA_HOME before concluding Java is missing. Use a virtual environment for
Python packages.

Use the JDBC endpoint directly and follow the supplied Lightning Command
Reference. Do not substitute a Hive or Spark driver.

Write Zetaris Lightning SQL, one statement per JDBC call, without a trailing
semicolon. Do not print my credentials back to me.

Do not initialize Spark or create a SparkSession.

Once connected, verify the connection by executing these statements, one per
call:

SELECT 1
SHOW LIGHTNING DATABASES

SHOW DATASOURCES does not list the REST and file sources registered with
CREATE LIGHTNING DATABASE, so use SHOW LIGHTNING DATABASES to see those. An
empty result is normal on a clean instance.
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

Use the OpenAPI specification as the reference for endpoints. Fetch it fresh
with Basic auth from /redoc/docs.yaml, using ZETARIS_USERNAME and
ZETARIS_PASSWORD from .env.local (never print them); see section 6.4.
Send these headers on every request:

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
and then running these SQL statements, one per request:

SELECT 1
SHOW LIGHTNING DATABASES

GET /datasource/datasources and SHOW DATASOURCES do not list the REST and file
sources registered with CREATE LIGHTNING DATABASE, so use SHOW LIGHTNING
DATABASES to see those. An empty result is normal on a clean instance.
```

### 6.3 Local instance

```text
Connect to the local Zetaris REST API using:

- Base URL: http://localhost:8888/api/v1.0
- Organisation ID: 1
- API key: read ZETARIS_API_KEY from .env.local (I created it in the Zetaris
  GUI; do not create or request another). Never print it, log it, or put it
  in a URL.

Use the OpenAPI specification as the reference for endpoints. Fetch it fresh
with Basic auth from /redoc/docs.yaml, using ZETARIS_USERNAME and
ZETARIS_PASSWORD from .env.local (never print them); see section 6.4.
Send these headers on every request:

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
and then running these SQL statements, one per request:

SELECT 1
SHOW LIGHTNING DATABASES

GET /datasource/datasources and SHOW DATASOURCES do not list the REST and file
sources registered with CREATE LIGHTNING DATABASE, so use SHOW LIGHTNING
DATABASES to see those. An empty result is normal on a clean instance.
```

### 6.4 Fetch the OpenAPI specification

The spec is served by the instance itself, so fetch it at the start of a REST
session rather than relying on a saved copy that may be out of date. The docs
route does not accept the bearer API key. It uses HTTP Basic authentication
with your Zetaris user ID and password, so add both to `.env.local` yourself:

```text
ZETARIS_USERNAME=<your user id>
ZETARIS_PASSWORD=<your password>
```

The docs page, `http://localhost:8888/redoc/index.html`,
names the spec in its `spec-url` attribute, which is `./docs.yaml`. That attribute
is in the page source, not visible in a browser, and the browser cannot send
the Basic credentials for you. Fetch the spec with:

```bash
set -a; . ./.env.local; set +a
curl -s -u "$ZETARIS_USERNAME:$ZETARIS_PASSWORD" \
  http://localhost:8888/redoc/docs.yaml -o docs.yaml
```

Save it outside version control or somewhere disposable, and fetch it again if
the instance is upgraded. The agent must read the credentials from the
environment and never print, log or echo them. Local verification: HTTP 200,
OpenAPI 3.1.0, about 280 paths, with both `bearer` and `basic` security schemes.

## 7. Verification

**JDBC.** Execute `SELECT 1`. A single result row containing `1` confirms the
driver loaded and the endpoint accepts queries.

**REST.** Two checks:

1. `GET {{REST_URL}}/datasource/datasources` returns HTTP 200 and a JSON list.
   On the local instance the list contains the `TPCH` sample datasource
   (`dataSourceId` 6, 8 tables).
2. `POST {{REST_URL}}/sql-editor/sqls/run` with `SELECT 1` returns
   `{"headers":["1"],"data":[["1"]],...}`.

**What is on the instance.** `SHOW DATASOURCES` lists only the datasources
registered with `CREATE DATASOURCE`, such as the `TPCH` sample or a JDBC source.
It does **not** list sources registered with `CREATE LIGHTNING DATABASE`, which is
how every REST and file source in this repository is onboarded, so it can look
empty after a successful onboarding. Check these through either protocol:

| Statement | Lists |
|---|---|
| `SHOW DATASOURCES` | Datasources, for example `TPCH` |
| `SHOW LIGHTNING DATABASES` | Lightning databases: the REST and file sources you onboarded, for example `COMPANY_DNS` and `SEC_DATA` |
| `SHOW NAMESPACES OR TABLES IN lightning.metastore` | USL namespaces and USLs (`SHOW NAMESPACES` alone is disabled) |

An empty list is normal on a clean instance. To confirm a source loaded, query a
row count from its view, as that source's `_select.sql` does.

## 8. Usage rules

1. **Protocol.** For JDBC, use the URL format expected by the supplied driver:
   `jdbc:zetaris:lightning@<host>:<port>` for local instances. For REST, use
   `/api/v1.0` paths and send the three headers on every request.
2. **Lightning SQL only.** Write every statement in Zetaris Lightning SQL, on
   either protocol.
3. **No local Spark.** Do not start Spark or create a SparkSession. Processing
   takes place on the Zetaris instance.
4. **Statement syntax.** Follow the supplied *Lightning Command Reference* and
   use qualified names, for example `SELECT ... FROM <source>.<table>`. Consult the *Zetaris SQL Companion*
   before writing SQL; it records limitations the command reference omits.
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
| `Unable to locate a Java Runtime` | No JDK is visible. On macOS `java` on the `PATH` can be a stub even when a Homebrew JDK exists: find it (`/usr/libexec/java_home`, or `/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`) and set `JAVA_HOME`. Otherwise install JDK 11 or later with `brew install openjdk@17`; the `temurin` cask needs `sudo`. |
| `SHOW DATASOURCES` does not list a source I just onboarded | It omits Lightning-registered (REST and file) sources. Use `SHOW LIGHTNING DATABASES`, and query a row count to confirm the data. |
| Driver JAR not found, or `ClassNotFoundException` for `LightningDriver` | The JAR path is wrong or the file is not the Zetaris driver. Ask for the full path; do not guess a location. |
| `externally-managed-environment` on `pip install` | System Python refuses global installs. Use a virtual environment. |
| JDBC `mismatched input ... expecting` | More than one statement, or a name list, sent in one call. Send one statement per call. |
| REST `401` | Key missing, wrong, or expired. Create a new key in the GUI and update `.env.local`, then check the `Authorization: Bearer` header and `.env.local`. The docs page (`/redoc/index.html`) and `/redoc/docs.yaml` return 401 for a bearer key because they use Basic authentication (see section 6.4); test the key with `GET /datasource/datasources` instead. |
| REST `400 Not Allowed` | Wrong `X-Org-ID`. The local instance uses `1`. |
| REST `400` on a valid request | `X-Request-ID` is missing or not a UUID, or `queryId` is not a UUID. |
| Table not found | Use the qualified form `<source>.<table>`. REST relation names are upper-case, but SQL accepted lower-case in testing. |
