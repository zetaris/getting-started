# Connecting Claude Code to Zetaris

## Contents

1. [Purpose](#1-purpose)
2. [Prerequisites](#2-prerequisites)
3. [Choosing a protocol](#3-choosing-a-protocol)
4. [Connection parameters](#4-connection-parameters)
5. [JDBC starter prompt](#5-jdbc-starter-prompt)
6. [REST starter prompt](#6-rest-starter-prompt)
7. [Verification](#7-verification)
8. [Usage rules](#8-usage-rules)
9. [Troubleshooting](#9-troubleshooting)

## 1. Purpose

This document describes how to start a Claude Code session against a Zetaris
instance, using either of the two supported protocols: **JDBC** and the **REST
API**. Open this repository as the workspace and submit the starter prompt from
section 5 or 6 as the first instruction. The prompt is short on purpose: the
rules, the tools and the order of work live in `AGENTS.md` at the repository
root, so they stay in one place. Claude Code loads `AGENTS.md` through the `CLAUDE.md` at the repository root.

The agent then runs `scripts/preflight.py`, connects, confirms the connection,
and works on the goal you give it. The usual goal is to onboard data sources
and then create and activate a Unified Semantic Layer (USL) over them, using
`scripts/onboard.py` and `open_data/manifest.json`. It executes Zetaris
Lightning SQL from the *Lightning Command Reference*, and over REST it can call
the endpoints in the instance's OpenAPI specification (section 6.4).

## 2. Prerequisites

- A Zetaris user account issued by the Datathon organisers.
- The *Lightning Command Reference* ([`docs/guides/zetaris-lightning-sql-commands.md`](../guides/zetaris-lightning-sql-commands.md)).
- The *Zetaris SQL Companion* ([`docs/guides/zetaris-lightning-sql-companion.md`](../guides/zetaris-lightning-sql-companion.md)): confirmed syntax shapes, quoting rules, gotchas and platform limitations. `AGENTS.md` tells the agent to read it before writing SQL.
- Claude Code, with this repository as its workspace and permission to run code. Approve the shell commands the agent asks to run (the scripts in `scripts/`). Zetaris is reached from your machine, so allow network access if Claude Code asks.

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

The prompt does not carry connection details or secrets. The agent reads them
from `.env.local` (the only env file; copy `.env.example` to start). From a git
worktree the scripts also look in the top-level checkout, so you keep one copy.
The defaults target a local instance, so for local you only add the credentials.

| Setting | Protocol | Local default | Zetaris Cloud |
|---|---|---|---|
| `ZETARIS_JDBC_URL` | JDBC | `jdbc:zetaris:lightning@localhost:10000` | JDBC URL supplied by the organisers |
| `ZETARIS_JDBC_JAR` | JDBC | none | Full path to the Zetaris JDBC driver JAR. If unset, the agent asks you; it does not search for it. |
| `ZETARIS_USERNAME` | JDBC, spec | none | Your Zetaris user ID, normally an email address |
| `ZETARIS_PASSWORD` | JDBC, spec | none | Your Zetaris user password |
| `ZETARIS_REST_URL` | REST | `http://localhost:8888/api/v1.0` | REST base URL, ending in `/api/v1.0` |
| `ZETARIS_ORG_ID` | REST | `1` | Numeric organisation ID |
| `ZETARIS_API_KEY` | REST | none | API key you create in the Zetaris GUI (section 6.1) |
| `ZETARIS_USER_AGENT` | either | none | `"<app name> <contact email>"`, for scripts that call external APIs such as SEC EDGAR |

Do not save credentials in source files or commit them. They belong only in
`.env.local`, which is gitignored.

## 5. JDBC starter prompt

Set the JDBC settings from section 4 in `.env.local`, then submit this as the
first instruction. Replace the goal.

```text
Read AGENTS.md and follow it. Run python3 scripts/preflight.py --jdbc and show
me the result; if the driver JAR path is not set, ask me for it. Then connect
over JDBC to the instance configured in .env.local and confirm with SELECT 1
and SHOW LIGHTNING DATABASES.

Goal: <for example: onboard company_dns and the EDGAR sources, then create and
activate the sic_edgar_usl USL over them>

Dry-run before creating anything and wait for my go-ahead.
```

The goal can be anything the repository supports, for example:
- *List what is on the instance and summarise it.* Read-only.
- *Onboard `pokeapi`.* One source.
- *Onboard `edgar_profiles` and build `sic_edgar_usl`.* Dependencies run first.
- *Create and activate a USL over `<sources>`.* The agent uses the command
  reference and the SQL companion for the DDL.

What the agent will do without being told, because `AGENTS.md` says so: use
Lightning SQL only, one statement per call, never start Spark, never print
credentials, find the JDK and `JAVA_HOME` itself, and ask before installing
anything.

## 6. REST starter prompt

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

### 6.2 Starter prompt

Set the REST settings from section 4 in `.env.local` and create your API key
first (section 6.1). Then submit this as the first instruction. Replace the goal.

```text
Read AGENTS.md and follow it. Run python3 scripts/preflight.py and show me the
result. Then connect over REST to the instance configured in .env.local and
confirm with SELECT 1 and SHOW LIGHTNING DATABASES.

Goal: <for example: onboard company_dns and the EDGAR sources, then create and
activate the sic_edgar_usl USL over them>

Dry-run before creating anything and wait for my go-ahead.
```

Goal ideas are the same as in section 5. The agent sends the bearer key and the
`X-Org-ID` and `X-Request-ID` headers for you through `scripts/run_sql.py`; you
do not need to describe them. It fetches the OpenAPI specification itself when
it needs an endpoint (section 6.4).

### 6.3 Local or Zetaris Cloud

The same prompt works for both. Which instance it talks to is decided by
`ZETARIS_REST_URL`, `ZETARIS_ORG_ID` and `ZETARIS_API_KEY` in `.env.local`
(section 4). Do not call port 8889 on a local instance: it is an internal login
route and is not part of this connection.

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

The agent runs these checks for you from the starter prompt (and
`python3 scripts/preflight.py` covers most of them). To check by hand:

**JDBC.** Execute `SELECT 1`. A single result row containing `1` confirms the
driver loaded and the endpoint accepts queries.

**REST.** Two checks:

1. `GET <ZETARIS_REST_URL>/datasource/datasources` returns HTTP 200 and a JSON list.
   On the local instance the list contains the `TPCH` sample datasource
   (`dataSourceId` 6, 8 tables).
2. `POST <ZETARIS_REST_URL>/sql-editor/sqls/run` with `SELECT 1` returns
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

These mirror the rules in `AGENTS.md`, which is the source of truth for the
agent. If the two ever differ, follow `AGENTS.md` and fix this list.

1. **Protocol.** For JDBC, use the URL format expected by the driver:
   `jdbc:zetaris:lightning@<host>:<port>` for local instances. For REST, use
   `/api/v1.0` paths and send the three headers on every request.
2. **Lightning SQL only.** Write every statement in Zetaris Lightning SQL, on
   either protocol.
3. **No local Spark.** Do not start Spark or create a SparkSession. Processing
   takes place on the Zetaris instance.
4. **Statement syntax.** Follow the *Lightning Command Reference*
   (`docs/guides/zetaris-lightning-sql-commands.md`) and use qualified names,
   for example `SELECT ... FROM <source>.<table>`. Consult the *Zetaris SQL
   Companion* before writing SQL; it records limitations the command reference
   omits.
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
