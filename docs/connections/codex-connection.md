# Connecting Codex to Zetaris

## Contents

1. [Purpose](#1-purpose)
2. [Prerequisites](#2-prerequisites)
3. [Connection parameters](#3-connection-parameters)
4. [Connection prompts](#4-connection-prompts)
5. [Verification](#5-verification)
6. [Usage rules](#6-usage-rules)

## 1. Purpose

This document describes how to connect Codex to a Zetaris instance over JDBC
at the start of a Datathon session. Submit the relevant prompt in section 4 as
the first instruction. After Codex verifies the connection, it can execute
Zetaris Lightning SQL from the supplied *Lightning Command Reference*.

## 2. Prerequisites

- A Zetaris user account issued by the Datathon organisers.
- The JDBC URL of the Zetaris Cloud endpoint, or a local instance.
- The Zetaris JDBC driver JAR and *Lightning Command Reference*.
- Codex, with a local workspace that permits the agent to run code.

For the local instance, `zetaris-platform` includes the driver at
`jdbc/ndp-jdbc-driver-2.4.3.1-7eff043-driver.jar`. Open the `zetaris-platform`
folder in Codex so the relative JAR path in the local prompt resolves correctly.
The driver class is `com.zetaris.lightning.jdbc.LightningDriver`.

Add the driver and reference to the Codex prompt with `@` file mentions. Allow
network access if Codex asks to connect to Zetaris Cloud.

## 3. Connection parameters

| Placeholder | Description |
|---|---|
| `{{JDBC_URL}}` | Zetaris Cloud JDBC URL supplied by the organisers. |
| `{{USER_ID}}` | Zetaris user ID, normally an email address. |
| `{{PASSWORD}}` | Zetaris user password. |

Replace each placeholder before submitting the prompt. Do not save credentials
in source files or commit them to a repository.

## 4. Connection prompts

Use the prompt for the target instance.

### 4.1 Zetaris Cloud

```text
Establish a JDBC connection to Zetaris Cloud using:

JDBC URL: {{JDBC_URL}}

Credentials:
- User ID: {{USER_ID}}
- Password: {{PASSWORD}}

Use the supplied JDBC driver and command reference. Use the JDBC endpoint
directly. Although the connection uses the Hive JDBC protocol, queries must be
executed using Zetaris Lightning SQL, not Spark SQL or Hive SQL.

Do not initialize Spark or create a SparkSession.

Once connected, verify the connection by executing:

SELECT 1;
```

### 4.2 Local instance

```text
Establish a JDBC connection to the local Zetaris instance using:

- Driver JAR: jdbc/ndp-jdbc-driver-2.4.3.1-7eff043-driver.jar
- Driver class: com.zetaris.lightning.jdbc.LightningDriver
- JDBC URL: jdbc:zetaris:lightning@localhost:10000

Credentials:
- User ID: {{USER_ID}}
- Password: {{PASSWORD}}

Use this JAR directly (for example, via JayDeBeApi) and load the specified
driver class. Use the JDBC endpoint directly and follow the supplied Lightning
Command Reference. Do not substitute a Hive or Spark driver.

Write Zetaris Lightning SQL, one statement per JDBC call.

Do not initialize Spark or create a SparkSession.

Once connected, verify the connection by executing:

SELECT 1;
```

## 5. Verification

The connection is verified by executing:

```sql
SELECT 1;
```

A result row containing `1` confirms the JDBC connection can execute a query.
If the query fails, confirm the JDBC URL, credentials, driver, and account
access.

## 6. Usage rules

1. **Protocol.** Use the URL format expected by the supplied Zetaris driver.
   The driver included with `zetaris-platform` uses
   `jdbc:zetaris:lightning@<host>:<port>` for local instances.
   Write every statement in Zetaris Lightning SQL.
2. **No local Spark.** Do not start Spark or create a SparkSession. Processing
   takes place on the Zetaris instance.
3. **Statement syntax.** Follow the supplied *Lightning Command Reference* and
   use qualified names, for example `SELECT ... FROM <source>.<table>`.
4. **One statement per call.** Execute each Lightning command as one JDBC call.
