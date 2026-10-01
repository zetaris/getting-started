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
Zetaris Lightning SQL using the included [recipe command reference](lightning-recipe-reference.md). For advanced commands, obtain a version-compatible platform reference or follow the linked model guide.

## 2. Prerequisites

- A confirmed Zetaris user account with the required permissions. This repo does not issue one.
- The JDBC URL of the Zetaris Cloud endpoint, or a local instance.
- The matching Zetaris JDBC driver JAR, obtained separately. The [recipe command reference](lightning-recipe-reference.md) is included for starter commands.
- Codex, with an execution environment that can run a Java-compatible JDBC client and reach the actual endpoint. Confirm these prerequisites before installing anything.

For the separate local distribution described in the installation guide, the documented driver path is
`jdbc/ndp-jdbc-driver-2.4.3.1-7eff043-driver.jar`. This repo does not contain that JAR. Obtain it and use its actual absolute path in the prompt; do not assume another workspace is present.
The driver class is `com.zetaris.lightning.jdbc.LightningDriver`.

Add the actual driver and repository recipe reference to the Codex prompt with file context. Allow
network access if Codex asks to connect to Zetaris Cloud.

## 3. Connection parameters

| Placeholder | Description |
|---|---|
| `{{JDBC_URL}}` | Zetaris Cloud JDBC URL supplied by the organisers. |
| `{{ABSOLUTE_DRIVER_PATH}}` | Absolute path of the matching driver you actually obtained. |
| Local credential configuration | Your issued account credentials, supplied to the client privately; variable names depend on the client. |

Replace the endpoint/driver placeholders before submitting the prompt. Supply credentials through a local execution environment rather than saving them in this prompt, source files, or reports. The event instance is shared: confirm your assigned team prefix and object permissions before creating anything. The included [Cursor prompt](cursor-connection.md) expresses these same execution and ownership rules in one reusable prompt.

## 4. Connection prompts

Use the prompt for the target instance. The local endpoint below is an example for your own installation, not the shared instance. localhost means the machine executing the client.

### 4.1 Zetaris Cloud

```text
Establish a JDBC connection to Zetaris Cloud using:

JDBC URL: {{JDBC_URL}}

Use credentials configured in my local execution environment. Stop if they are unavailable; do not print them.

Use the matching JDBC driver at {{ABSOLUTE_DRIVER_PATH}} and docs/connections/lightning-recipe-reference.md from this repo. Use the JDBC endpoint
directly. Although the connection uses the Hive JDBC protocol, queries must be
executed using Zetaris Lightning SQL, not Spark SQL or Hive SQL.

Do not initialize Spark or create a SparkSession.

Once connected, verify the connection by executing:

SELECT 1;
```

### 4.2 Local instance

```text
Establish a JDBC connection to the local Zetaris instance using:

- Driver JAR: {{ABSOLUTE_DRIVER_PATH}}
- Driver class: com.zetaris.lightning.jdbc.LightningDriver
- JDBC URL: jdbc:zetaris:lightning@localhost:10000

Use credentials configured in my local execution environment. Stop if they are unavailable; do not print them.

Use this JAR directly (for example, via JayDeBeApi) and load the specified
driver class. Use the JDBC endpoint directly and follow this repository's docs/connections/lightning-recipe-reference.md. Do not substitute a Hive or Spark driver.

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

1. **Protocol.** Use the URL format expected by the matching Zetaris driver.
   The driver included with `zetaris-platform` uses
   `jdbc:zetaris:lightning@<host>:<port>` for local instances.
   Write every statement in Zetaris Lightning SQL.
2. **No local Spark.** Do not start Spark or create a SparkSession. Processing
   takes place on the Zetaris instance.
3. **Statement syntax.** Follow the included [recipe reference](lightning-recipe-reference.md) for starter commands and
   use qualified names, for example `SELECT ... FROM <source>.<table>`.
4. **One statement per call.** Execute each Lightning command as one JDBC call.

After connection succeeds, follow [your first dataset](../guides/first-dataset.md). A connection check alone does not verify external data.
