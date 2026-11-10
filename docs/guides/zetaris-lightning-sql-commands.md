# Lightning Command Reference

## Start with the supplied samples

Start with [your first SQL commands](../connections/lightning-recipe-reference.md), using the supplied `NY_TAXI` and `TPCDS_DB` samples.

| Stage | Commands to learn | Prerequisites |
|---|---|---|
| Check execution | `SELECT 1`, `SHOW SERVER VERSION` | Login and query permission |
| Discover sources | `SHOW LIGHTNING DATABASES`, `SHOW DATASOURCES` | Login; results are limited to your access |
| Inspect sample tables | `SHOW LIGHTNING TABLES`, `DESCRIBE DATASOURCE TABLE` | Access to the supplied NY Taxi or TPCDS tables |
| Read sample data | `SELECT ... LIMIT 5` | Query permission on an existing table |
| Create views and connect more data | SchemaStore, file, REST and datasource commands | Creation permission, your own object names and the source-specific setup below |
| Build models and pipelines | USL, DQ, pipeline and data-mart commands | Accessible source data and the required namespaces or containers |
| Manage storage, access and cleanup | Export, cache, grant, revoke and drop commands | Writable storage or management permission, with a confirmed scope |

Empty discovery lists are valid. Use `SHOW DATASOURCES` for external database connections and `SHOW LIGHTNING DATABASES` for file/REST sources.

Read each group's prerequisites and each command's privileges. The sections group commands by topic, not execution order.

## Contents

[Start with the supplied samples](#start-with-the-supplied-samples)

1. [Introduction](#1-introduction)
2. [Conventions](#2-conventions)
3. [General Rules](#3-general-rules)
4. [Data Sources](#4-data-sources)
5. [File Sources](#5-file-sources)
6. [REST Sources and Authentication](#6-rest-sources-and-authentication)
7. [Streaming](#7-streaming)
8. [Data Lakes](#8-data-lakes)
9. [External Catalogs](#9-external-catalogs)
10. [Hive Metastore](#10-hive-metastore)
11. [AWS Glue Metastore](#11-aws-glue-metastore)
12. [Schema Store Views](#12-schema-store-views)
13. [Unified Semantic Layer](#13-unified-semantic-layer)
14. [Data Quality](#14-data-quality)
15. [Export and Materialization](#15-export-and-materialization)
16. [Data Pipelines](#16-data-pipelines)
17. [Virtual Data Marts](#17-virtual-data-marts)
18. [Query Plans](#18-query-plans)
19. [Caching](#19-caching)
20. [Users and Roles](#20-users-and-roles)
21. [Access Control](#21-access-control)
22. [Data Warehouses](#22-data-warehouses)
23. [Server Information](#23-server-information)

## 1. Introduction

Lightning commands connect sources, build models, check data quality and manage access.

Use the platform UI or run these commands in SQL Workspace alongside ordinary SQL queries.

This reference contains 144 Lightning commands.

## 2. Conventions

### 2.1 Syntax notation


| Notation           | Meaning                                                                   |
| ------------------ | ------------------------------------------------------------------------- |
| `KEYWORD`          | A keyword, entered as shown. Keywords are not case-sensitive.             |
| `<name>`           | A value supplied by the user.                                             |
| `'<text>'`         | A value supplied as a quoted string. Single or double quotes may be used. |
| `[ … ]`            | An optional element.                                                      |
| `{ A \| B }` | Choose one alternative. |
| `…`                | The preceding element may be repeated.                                    |
| `(key 'value', …)` | An option list of key and quoted value pairs, separated by commas.        |


### 2.2 Entry format

Each entry gives syntax, a description, privileges, any limitations or notes, and an example.

### 2.3 Example objects

Examples use the objects below. Create the required objects and replace names with your team names. Hosts, credentials and incomplete JSON are placeholders. The starter guide uses already-registered `NY_TAXI` and `TPCDS_DB` samples.


| Object                         | Description                                                                                    |
| ------------------------------ | ---------------------------------------------------------------------------------------------- |
| `crm_pg`                       | A PostgreSQL datasource with the tables `customers` and `orders`                               |
| `sales_files`                  | A file source containing the table `transactions`                                              |
| `weather_api`                  | A REST source containing the table `daily_weather`; `weather_oauth` is its saved token request |
| `clickstream`                  | A Kafka streaming source                                                                       |
| `analysis`                     | A schema store container                                                                       |
| `lightning.metastore.datathon` | The namespace of the USL `retail`                                                              |
| `etl`                          | A pipeline container                                                                           |
| `sales_mart`                   | A virtual data mart                                                                            |
| `alice@example.com`, `analyst` | A user and a role                                                                              |


## 3. General Rules

1. **One statement per execution.** The SQL Workspace splits editor text on semicolons. Submit each command separately.
2. **Qualified table names.** Commands that operate on a table require the form `<source>.<table>`.
3. **Identifiers and values.** Object names are written without quotes; names containing special characters are enclosed in backquotes. Text values are enclosed in single or double quotes.
4. **Privileges.** Commands marked *Administrators only* are refused for other users. Other commands require the permission stated in the entry, and return only the objects assigned to the user.
5. **Standard SQL.** Registered tables are queried with standard Spark SQL, for example `SELECT … FROM crm_pg.customers`, and may be joined across sources.

## 4. Data Sources

A datasource is a registered connection to an external database. Registering a datasource stores the connection only; its tables become available after they are imported.

**Prerequisites**

Creating or inspecting an unregistered datasource needs a reachable database, driver and source credentials. Import, preview and metadata changes need a registered datasource. The client JDBC connection to Zetaris is separate. `SHOW DATASOURCES` needs no registration.

### 4.1 CREATE DATASOURCE

**Syntax**

```sql
CREATE DATASOURCE <name> [DESCRIBE BY '<desc>'] OPTIONS (key 'value', …)
```

Registers an external source (JDBC, Cassandra, MongoDB or DynamoDB, detected from the options) after testing the connection.

**Privileges:** Administrators only.

**Example**

```sql
CREATE DATASOURCE crm_pg DESCRIBE BY "PostgreSQL" OPTIONS (
  jdbcdriver "org.postgresql.Driver",
  jdbcurl "jdbc:postgresql://crm-db.example.com:5432/crm",
  username "datathon",
  password "changeme",
  fetchsize "1000"
)
```

### 4.2 REGISTER DATASOURCE TABLE

**Syntax**

```sql
REGISTER DATASOURCE TABLE '<table>' FROM <datasource>
```

Imports one source table's metadata into a datasource.

**Privileges:** Administrators only.

**Example**

```sql
REGISTER DATASOURCE TABLE "customers" FROM crm_pg
```

### 4.3 REGISTER DATASOURCE TABLES

**Syntax**

```sql
REGISTER DATASOURCE TABLES [('<table>', …)] FROM <datasource>
```

Imports the listed source tables, or every table when no list is given.

**Privileges:** Administrators only.

**Example**

```sql
REGISTER DATASOURCE TABLES FROM crm_pg
```

### 4.4 CREATE DATASOURCE VIEW

**Syntax**

```sql
CREATE DATASOURCE VIEW <view> FROM <datasource> AS <SELECT query …>
```

Creates or replaces a datasource view from native SQL that runs on the source.

**Privileges:** Administrators or Query Builder Write users.

**Example**

```sql
CREATE DATASOURCE VIEW au_customers FROM crm_pg AS SELECT * FROM customers WHERE country = 'AU'
```

### 4.5 SHOW DATASOURCES

**Syntax**

```sql
SHOW DATASOURCES
```

Lists accessible datasources: name, description and id.

**Privileges:** Signed-in users; assigned objects only.

**Example**

```sql
SHOW DATASOURCES
```

### 4.6 SHOW DATASOURCE TABLES

**Syntax**

```sql
SHOW DATASOURCE TABLES [<datasource>]
SHOW DATASOURCE TABLES <datasource> WITH STATISTICS
```

Lists a datasource's tables and views; WITH STATISTICS adds row counts, size and tags.

**Privileges:** Depends on the form: any user; Data Catalog Read, Data Catalog Write.

**Limitations**

- WITH STATISTICS requires a datasource name.

**Remarks**

- WITH STATISTICS adds row counts, size and tags.

**Example**

```sql
SHOW DATASOURCE TABLES crm_pg
```

### 4.7 PREVIEW DATASOURCE SQL

**Syntax**

```sql
PREVIEW DATASOURCE SQL <datasource> AS <SELECT query …>
```

Runs native SQL on a datasource and returns up to 10 rows.

**Privileges:** Administrators only.

**Example**

```sql
PREVIEW DATASOURCE SQL crm_pg AS SELECT id, full_name FROM customers WHERE country = 'AU'
```

### 4.8 LIST DATABASE TABLES

**Syntax**

```sql
LIST DATABASE TABLES OPTIONS (key 'value', …)
```

Connects with inline options and lists an unregistered source's tables, columns, types and keys.

**Privileges:** Administrators only.

**Limitations**

- Only JDBC sources are supported.

**Example**

```sql
LIST DATABASE TABLES OPTIONS (
  jdbcdriver "org.postgresql.Driver",
  jdbcurl "jdbc:postgresql://crm-db.example.com:5432/crm",
  username "datathon",
  password "changeme"
)
```

### 4.9 DESCRIBE DATASOURCE TABLE

**Syntax**

```sql
DESCRIBE DATASOURCE TABLE <datasource>.<table>
```

Describes a table's columns with type, comment, description and tags (datasource, file, REST, Hive or Glue).

**Privileges:** Signed-in users; assigned objects only.

**Limitations**

- The table must be qualified with its datasource name.

**Example**

```sql
DESCRIBE DATASOURCE TABLE crm_pg.customers
```

### 4.10 REFRESH DATASOURCE TABLES

**Syntax**

```sql
REFRESH DATASOURCE TABLES FROM <datasource>
```

Re-imports metadata for a datasource's registered tables.

**Privileges:** Administrators or Data Catalog Write users.

**Example**

```sql
REFRESH DATASOURCE TABLES FROM crm_pg
```

### 4.11 UNCACHE DATASOURCE

**Syntax**

```sql
UNCACHE DATASOURCE <name>
```

Clears a datasource's cached table metadata and statistics, then reloads Presto catalogs.

**Privileges:** Administrators only.

**Example**

```sql
UNCACHE DATASOURCE crm_pg
```

### 4.12 UPDATE DATASOURCE SCHEMA

**Syntax**

```sql
UPDATE DATASOURCE SCHEMA [<datasource>]
```

Re-imports table metadata for one datasource, or for every datasource you can access.

**Privileges:** Administrators only.

**Example**

```sql
UPDATE DATASOURCE SCHEMA crm_pg
```

### 4.13 DROP DATASOURCE VIEW

**Syntax**

```sql
DROP DATASOURCE VIEW <view> FROM <datasource>
```

Deletes a datasource view.

**Privileges:** Administrators only.

**Example**

```sql
DROP DATASOURCE VIEW au_customers FROM crm_pg
```

### 4.14 DROP DATASOURCE

**Syntax**

```sql
DROP DATASOURCE <name>
```

Deregisters a datasource with its tables, cache, search-index entries and privileges.

**Privileges:** Administrators only.

**Example**

```sql
DROP DATASOURCE crm_pg
```

## 5. File Sources

A file source is a Lightning database whose tables are defined over files in S3, Azure Blob Storage, Google Cloud Storage, HDFS or platform storage.

**Prerequisites**

Query the supplied samples with source access. New file tables need creation permission, a readable path and any storage credentials; persistent tables also need a Lightning database. Update, uncache and drop need an existing object.

### 5.1 CREATE FILESTORE SESSION TABLE

**Syntax**

```sql
CREATE FILESTORE SESSION TABLE <table> FORMAT <format> OPTIONS (key 'value', …)
```

Defines a temporary file-backed table, readable as `session.<table>` until restart or DROP TABLE.

**Privileges:** Administrators only.

**Remarks**

- Session tables are visible within the organisation until they are dropped.
- Read the table as `session.<table>` and remove it with `DROP TABLE session.<table>`.

**Example**

```sql
CREATE FILESTORE SESSION TABLE tx_preview FORMAT CSV OPTIONS (
  path "s3a://datathon-bucket/sales/transactions.csv",
  awsAccessKeyId "AKIAEXAMPLE",
  awsSecretAccessKey "example-secret",
  header "true",
  delimiter ","
)
SELECT * FROM session.tx_preview LIMIT 20
```

### 5.2 CREATE LIGHTNING DATABASE

**Syntax**

```sql
CREATE LIGHTNING DATABASE <name> [DESCRIBE BY '<desc>'] [OPTIONS (key 'value', …)]
```

Creates a Lightning database, the container for file-store and REST tables.

**Privileges:** Administrators only.

**Remarks**

- The name must be unique within the organisation.

**Example**

```sql
CREATE LIGHTNING DATABASE sales_files DESCRIBE BY "Sales files"
```

### 5.3 CREATE LIGHTNING FILESTORE TABLE

**Syntax**

```sql
CREATE LIGHTNING FILESTORE TABLE <table> FROM <database> FORMAT <format> OPTIONS (key 'value', …)
```

Registers a file table (CSV, Parquet, JSON, Delta, PDF, images and more) with the schema inferred from the path.

**Privileges:** Administrators only.

**Remarks**

- Option `sourceTable` also writes that table's data to the path.
- Query the table as `<database>.<table>`. Supported formats: CSV, JSON, PARQUET, ORC, DELTA, XML, AVRO, PDF, IMAGE, VIDEO, AUDIO, DOC, TEXT, MARKDOWN, RTF.

**Example**

```sql
CREATE LIGHTNING FILESTORE TABLE transactions FROM sales_files FORMAT CSV OPTIONS (
  path "s3a://datathon-bucket/sales/transactions.csv",
  awsAccessKeyId "AKIAEXAMPLE",
  awsSecretAccessKey "example-secret",
  header "true",
  delimiter ","
)
SELECT * FROM sales_files.transactions LIMIT 20
```

### 5.4 SHOW LIGHTNING DATABASES

**Syntax**

```sql
SHOW LIGHTNING DATABASES
```

Lists accessible Lightning databases: name, description and id.

**Privileges:** Signed-in users; assigned objects only.

**Example**

```sql
SHOW LIGHTNING DATABASES
```

### 5.5 SHOW LIGHTNING TABLES

**Syntax**

```sql
SHOW LIGHTNING TABLES <database>
```

Lists a Lightning database's tables with type, path or endpoint, format and id.

**Privileges:** Signed-in users; assigned objects only.

**Limitations**

- Only a single database name is accepted.

**Example**

```sql
SHOW LIGHTNING TABLES sales_files
```

### 5.6 LIST HDFS FILES

**Syntax**

```sql
LIST HDFS FILES '<dir>' OPTIONS (key 'value', …)
```

Lists files and folders under an HDFS, S3, Azure or local path, using the credentials you pass.

**Privileges:** Administrators only.

**Example**

```sql
LIST HDFS FILES "s3a://datathon-bucket/sales/" OPTIONS (
  awsAccessKeyId "AKIAEXAMPLE",
  awsSecretAccessKey "example-secret",
  isS3BucketPublic "false"
)
```

### 5.7 UNCACHE LIGHTNING FILESTORE TABLE

**Syntax**

```sql
UNCACHE LIGHTNING FILESTORE TABLE <table> FROM <database>
```

Clears a file-store table's cached metadata and dependent caches, then reloads Presto catalogs.

**Privileges:** Signed-in users; assigned objects only.

**Example**

```sql
UNCACHE LIGHTNING FILESTORE TABLE transactions FROM sales_files
```

### 5.8 UPDATE LIGHTNING FILESTORE TABLE

**Syntax**

```sql
UPDATE LIGHTNING FILESTORE TABLE <table> FROM <database> OPTIONS (key 'value', …)
```

Updates a file-store table's stored options; changing the path is rejected. Include the original `path` in OPTIONS even when updating other settings. On Zetaris 2.4.3.1, an update without it returned `Path is not provided` in the 12 October 2026 live check.

**Privileges:** Administrators only.

**Example**

```sql
UPDATE LIGHTNING FILESTORE TABLE transactions FROM sales_files OPTIONS (
  path "s3a://datathon-bucket/sales/transactions.csv",
  header "true",
  delimiter ";"
)
```

### 5.9 DROP LIGHTNING DATABASE TABLE

**Syntax**

```sql
DROP LIGHTNING DATABASE TABLE <database>.<table>
```

Removes a file-store or REST table from a Lightning database.

**Privileges:** Administrators only.

**Limitations**

- The table must be qualified with its database name.

**Example**

```sql
DROP LIGHTNING DATABASE TABLE sales_files.transactions
```

### 5.10 DROP LIGHTNING DATABASE

**Syntax**

```sql
DROP LIGHTNING DATABASE <database>
```

Deletes a Lightning database with its tables and privileges.

**Privileges:** Administrators only.

**Example**

```sql
DROP LIGHTNING DATABASE sales_files
```

## 6. REST Sources and Authentication

A REST table exposes the JSON response of an HTTP endpoint as a table. Saved token requests (auth definitions) supply access tokens to REST tables.

**Prerequisites**

REST requests need an endpoint reachable from Zetaris and any required authentication. Persistent tables need a Lightning database and creation permission. Saved AUTH operations need a definition; token requests need the token endpoint and credentials. `LIST AUTH` may be empty.

### 6.1 CREATE REST SESSION TABLE

**Syntax**

```sql
CREATE REST SESSION TABLE <table> REQUEST (key 'value', …) HEADER (key 'value', …) BODY (key 'value', …) [AUTH BY <auth>[, …]]
```

Calls a REST endpoint and holds the result as temporary table `session.<table>`.

**Privileges:** Administrators only.

**Remarks**

- Session tables are visible within the organisation until they are dropped.
- Read the table as `session.<table>` and remove it with `DROP TABLE session.<table>`.

**Example**

```sql
CREATE REST SESSION TABLE weather_preview REQUEST (
  endpoint "https://api.example.com/v1/weather/daily",
  method "GET",
  http_encoding "URLENCODED",
  response_type "JSON",
  insecure_ssl "false"
) HEADER () BODY () AUTH BY weather_oauth
SELECT * FROM session.weather_preview
```

### 6.2 CREATE LIGHTNING REST TABLE

**Syntax**

```sql
CREATE LIGHTNING REST TABLE <table> FROM <database> REQUEST (key 'value', …) HEADER (key 'value', …) BODY (key 'value', …) [AUTH BY <auth>[, …]]
```

Registers a REST table by calling its endpoint and inferring the JSON schema. AUTH BY is optional.

**Privileges:** Administrators only.

**Remarks**

- Query the table as `<database>.<table>`.

**Example**

```sql
CREATE LIGHTNING REST TABLE daily_weather FROM weather_api REQUEST (
  endpoint "https://api.example.com/v1/weather/daily",
  method "GET",
  http_encoding "URLENCODED",
  response_type "JSON",
  insecure_ssl "false"
) HEADER () BODY () AUTH BY weather_oauth
```

### 6.3 UPSERT AUTH

**Syntax**

```sql
UPSERT AUTH <auth> REQUEST (key 'value', …) HEADER (key 'value', …) BODY (key 'value', …)
```

Creates or updates a named token-request definition: endpoint, method, headers and body.

**Privileges:** Administrators only.

**Example**

```sql
UPSERT AUTH weather_oauth REQUEST (
  endpoint "https://auth.example.com/oauth/token",
  method "POST",
  http_encoding "URLENCODED",
  insecure_ssl "false"
) HEADER () BODY (
  grant_type "client_credentials",
  client_id "datathon-app",
  client_secret "example-secret"
)
```

### 6.4 TEST AUTH REQUEST

**Syntax**

```sql
TEST AUTH REQUEST (key 'value', …) HEADER (key 'value', …) BODY (key 'value', …)
```

Runs an ad-hoc token request and returns the response fields.

**Privileges:** Administrators only.

**Example**

```sql
TEST AUTH REQUEST (
  endpoint "https://auth.example.com/oauth/token",
  method "POST",
  http_encoding "URLENCODED",
  insecure_ssl "false"
) HEADER () BODY (
  grant_type "client_credentials",
  client_id "datathon-app",
  client_secret "example-secret"
)
```

### 6.5 TEST AUTH

**Syntax**

```sql
TEST AUTH <auth>
```

Runs a saved token-request definition and returns the response fields.

**Privileges:** Administrators only.

**Example**

```sql
TEST AUTH weather_oauth
```

### 6.6 TEST REST REQUEST

**Syntax**

```sql
TEST REST REQUEST (key 'value', …) HEADER (key 'value', …) BODY (key 'value', …) [AUTH BY <auth>[, …]]
```

Runs a REST request, optionally authorised by saved AUTH definitions, and returns the rows.

**Privileges:** Administrators only.

**Example**

```sql
TEST REST REQUEST (
  endpoint "https://api.example.com/v1/weather/daily",
  method "GET",
  http_encoding "URLENCODED",
  response_type "JSON",
  insecure_ssl "false"
) HEADER () BODY () AUTH BY weather_oauth
```

### 6.7 SHOW AUTH

**Syntax**

```sql
SHOW AUTH <auth>
```

Shows a saved token-request definition, including its header and body values.

**Privileges:** Administrators only.

**Example**

```sql
SHOW AUTH weather_oauth
```

### 6.8 LIST AUTH

**Syntax**

```sql
LIST AUTH
```

Lists saved token-request definitions: name, endpoint, method, encoding, content type.

**Privileges:** Administrators only.

**Example**

```sql
LIST AUTH
```

### 6.9 DROP AUTH

**Syntax**

```sql
DROP AUTH <auth>
```

Deletes a saved token-request definition.

**Privileges:** Administrators only.

**Example**

```sql
DROP AUTH weather_oauth
```

## 7. Streaming

Streaming sources read JSON messages from a Kafka topic. Aggregation tables run a continuous query over a streaming source and write the result to storage.

**Prerequisites**

Registering a stream needs Kafka broker/topic access, a sample JSON message and creation permission. An aggregation also needs writable output storage. Aggregation listing/removal needs its registered source.

### 7.1 REGISTER STREAMING DATASOURCE

**Syntax**

```sql
REGISTER STREAMING DATASOURCE <name>
INPUT_SOURCE KAFKA
INPUT_FORMAT JSON
INPUT_OPTIONS (key 'value', …)
INPUT_SAMPLE <sample message>
```

Registers a Kafka topic as a streaming source; the schema comes from INPUT_SAMPLE.

**Privileges:** Administrators only.

**Limitations**

- Only Kafka input sources and JSON messages are supported.

**Remarks**

- The Kafka broker must be reachable from the Lightning platform. A broker addressed as `localhost` on a participant's computer is not reachable.
- The schema is derived from INPUT_SAMPLE; supply one representative message.
- Requires an external service: Kafka.

**Example**

```sql
REGISTER STREAMING DATASOURCE clickstream
INPUT_SOURCE KAFKA
INPUT_FORMAT JSON
INPUT_OPTIONS(
  inferSchema "false",
  kafka.bootstrap.servers "kafka.example.com:9092",
  kafka.topic "clicks",
  security.protocol "PLAINTEXT"
)
INPUT_SAMPLE
{"user_id": 42, "page": "/pricing", "ts": 1727222400}
```

### 7.2 REGISTER STREAMING AGGREGATION

**Syntax**

```sql
REGISTER STREAMING AGGREGATION <table> FROM <source>
OUTPUT_MODE {APPEND | COMPLETE | UPDATE}
OUTPUT_FORMAT {PARQUET | ORC | CSV | JDBC}
OUTPUT_OPTIONS (key 'value', …)
AS <SELECT query>
```

Starts a streaming query over a source and writes the result to Parquet, ORC, CSV or JDBC.

**Privileges:** Administrators only.

**Limitations**

- Supported output formats are PARQUET, ORC, CSV and JDBC.

**Remarks**

- Requires an external service: Kafka.

**Example**

```sql
REGISTER STREAMING AGGREGATION pricing_clicks FROM clickstream
OUTPUT_MODE APPEND
OUTPUT_FORMAT PARQUET
OUTPUT_OPTIONS(path "s3a://datathon-bucket/streams/pricing_clicks")
AS SELECT user_id, page, from_unixtime(ts) AS clicked_at FROM clickstream WHERE page LIKE '/pricing%'
```

### 7.3 SHOW STREAMING DATASOURCE

**Syntax**

```sql
SHOW STREAMING DATASOURCE
```

Lists the streaming sources you can see: name, input, format, schema.

**Privileges:** Signed-in users; assigned objects only.

**Example**

```sql
SHOW STREAMING DATASOURCE
```

### 7.4 SHOW STREAMING AGGREGATION TABLES

**Syntax**

```sql
SHOW STREAMING AGGREGATION TABLES <source>
```

Lists a streaming source's aggregation tables: output mode, format, schema, query.

**Privileges:** Signed-in users; assigned objects only.

**Example**

```sql
SHOW STREAMING AGGREGATION TABLES clickstream
```

### 7.5 DROP STREAMING DATASOURCE

**Syntax**

```sql
DROP STREAMING DATASOURCE <source>
```

Stops and deletes a streaming source, and revokes its privileges.

**Privileges:** Administrators only.

**Example**

```sql
DROP STREAMING DATASOURCE clickstream
```

### 7.6 DROP STREAMING AGGREGATION TABLE

**Syntax**

```sql
DROP STREAMING AGGREGATION TABLE <source>.<table>
```

Stops and deletes aggregation table `<source>.<table>`.

**Privileges:** Administrators only.

**Example**

```sql
DROP STREAMING AGGREGATION TABLE clickstream.pricing_clicks
```

## 8. Data Lakes

A data lake is an Iceberg lakehouse registered on object or file storage.

**Prerequisites**

Creation needs accessible Iceberg storage, connection settings and creation permission. Table listing needs a registered lake. `RELOAD DATALAKE` affects all engine catalogs; confirm that scope first.

### 8.1 CREATE DATALAKE

**Syntax**

```sql
CREATE DATALAKE <name> OPTIONS (key 'value', …)
```

Registers an Iceberg data lake on S3, Azure, GCS, HDFS or local storage after checking the path.

**Privileges:** Administrators only.

**Example**

```sql
CREATE DATALAKE datathon_lake OPTIONS (
  storageType "S3",
  storagePath "s3a://datathon-bucket/lake/",
  awsAccessKeyId "AKIAEXAMPLE",
  awsSecretAccessKey "example-secret"
)
```

### 8.2 SHOW DATALAKES

**Syntax**

```sql
SHOW DATALAKES
```

Lists accessible data lakes.

**Privileges:** Signed-in users; assigned objects only.

**Example**

```sql
SHOW DATALAKES
```

### 8.3 SHOW DATALAKE TABLES

**Syntax**

```sql
SHOW DATALAKE TABLES <database>
```

Lists a data lake's Iceberg tables.

**Privileges:** Signed-in users; assigned objects only.

**Remarks**

- Reads the lake storage directly; the command can take several minutes on a large lake.

**Example**

```sql
SHOW DATALAKE TABLES datathon_lake
```

### 8.4 RELOAD DATALAKE

**Syntax**

```sql
RELOAD DATALAKE
```

Tells every Presto engine to reload its catalogs and drops cached Spark catalogs.

**Privileges:** Administrators only.

**Remarks**

- Requires an external service: Presto.

**Example**

```sql
RELOAD DATALAKE
```

## 9. External Catalogs

External catalogs connect a Unity Catalog server under a local alias.

**Prerequisites**

Registration needs Unity Catalog server access, authentication, an existing catalog and creation permission. Namespace/table commands need an accessible registered catalog. `SHOW UNITY CATALOG` needs no registration.

### 9.1 REGISTER UNITY CATALOG

**Syntax**

```sql
REGISTER UNITY CATALOG <alias> NAME <catalog> OPTIONS (key 'value', …)
```

Registers a Unity Catalog under an alias after checking the catalog exists on the server.

**Privileges:** Administrators only.

**Remarks**

- The option `unityCatalogUri` is required.
- Requires an external service: Unity Catalog server.

**Example**

```sql
REGISTER UNITY CATALOG uc_demo NAME main OPTIONS (
  useCatalogTemporaryCredentials "true",
  unityCatalogUri "https://uc.example.com",
  unityCatalogToken "dapi-example-token"
)
```

### 9.2 SHOW UNITY CATALOG

**Syntax**

```sql
SHOW UNITY CATALOG
```

Lists registered Unity Catalogs: alias, name, masked options, schema count.

**Privileges:** Signed-in users; assigned objects only.

**Example**

```sql
SHOW UNITY CATALOG
```

### 9.3 SHOW UC NAMESPACES

**Syntax**

```sql
SHOW UC NAMESPACES IN <alias>[.<namespace> …]
```

Lists a Unity Catalog's schemas with child counts, filtered to what you can access.

**Privileges:** Signed-in users; assigned objects only.

**Remarks**

- Requires an external service: Unity Catalog server.

**Example**

```sql
SHOW UC NAMESPACES IN uc_demo
```

### 9.4 SHOW UC TABLES

**Syntax**

```sql
SHOW UC TABLES IN <alias>.<namespace>[.<namespace> …]
```

Lists the tables in a Unity Catalog schema.

**Privileges:** Signed-in users; assigned objects only.

**Remarks**

- Users other than administrators require an assignment on the schema.
- Requires an external service: Unity Catalog server.

**Example**

```sql
SHOW UC TABLES IN uc_demo.default
```

### 9.5 UNCACHE UNITY CATALOG

**Syntax**

```sql
UNCACHE UNITY CATALOG <name>
```

Evicts a Unity Catalog connection from the driver cache so it reloads.

**Privileges:** Administrators only.

**Example**

```sql
UNCACHE UNITY CATALOG uc_demo
```

### 9.6 DROP UNITY CATALOG

**Syntax**

```sql
DROP UNITY CATALOG <alias>
```

Removes a Unity Catalog registration and unloads it.

**Privileges:** Administrators only.

**Example**

```sql
DROP UNITY CATALOG uc_demo
```

## 10. Hive Metastore

A Hive metastore registration synchronises database and table metadata from an existing Hive metastore database.

**Prerequisites**

Registration/remote listing needs Hive metastore access, its JDBC driver and credentials. Named listing/removal needs a registered metastore or synced database. `LIST HIVE METASTORES` may be empty.

### 10.1 REGISTER HIVE METASTORE

**Syntax**

```sql
REGISTER HIVE METASTORE <name> OPTIONS (key 'value', …)
```

Registers a Hive metastore (JDBC to its database) and syncs the listed databases.

**Privileges:** Administrators only.

**Remarks**

- Requires an external service: Hive metastore.

**Example**

```sql
REGISTER HIVE METASTORE hive_prod OPTIONS (
  hive_meta_jdbc_url "jdbc:mysql://hive-db.example.com:3306/metastore",
  hive_meta_user_name "hive",
  hive_meta_password "changeme",
  hive_meta_jdbc_driver "com.mysql.cj.jdbc.Driver",
  databases "sales"
)
```

### 10.2 LIST HIVE METASTORES

**Syntax**

```sql
LIST HIVE METASTORES
```

Lists accessible Hive metastores.

**Privileges:** Signed-in users; assigned objects only.

**Example**

```sql
LIST HIVE METASTORES
```

### 10.3 LIST HIVE METASTORE TABLES REMOTE

**Syntax**

```sql
LIST HIVE METASTORE TABLES REMOTE OPTIONS (key 'value', …)
```

Lists live tables for the databases named in OPTIONS, over an inline connection.

**Privileges:** Administrators only.

**Remarks**

- The `databases` key is case-sensitive.
- Requires an external service: Hive metastore.

**Example**

```sql
LIST HIVE METASTORE TABLES REMOTE OPTIONS (
  hive_meta_jdbc_url "jdbc:mysql://hive-db.example.com:3306/metastore",
  hive_meta_user_name "hive",
  hive_meta_password "changeme",
  hive_meta_jdbc_driver "com.mysql.cj.jdbc.Driver",
  databases "sales"
)
```

### 10.4 LIST HIVE METASTORE DATABASES

**Syntax**

```sql
LIST HIVE METASTORE DATABASES <metastore>
```

Lists the synced databases of a Hive metastore.

**Privileges:** Signed-in users; assigned objects only.

**Example**

```sql
LIST HIVE METASTORE DATABASES hive_prod
```

### 10.5 SHOW HIVE METASTORE DATABASES

**Syntax**

```sql
SHOW HIVE METASTORE DATABASES OPTIONS (key 'value', …)
```

Lists live Hive databases from inline connection options.

**Privileges:** Administrators only.

**Remarks**

- Requires an external service: Hive metastore.

**Example**

```sql
SHOW HIVE METASTORE DATABASES OPTIONS (
  hive_meta_jdbc_url "jdbc:mysql://hive-db.example.com:3306/metastore",
  hive_meta_user_name "hive",
  hive_meta_password "changeme",
  hive_meta_jdbc_driver "com.mysql.cj.jdbc.Driver"
)
```

### 10.6 LIST HIVE METASTORE TABLES

**Syntax**

```sql
LIST HIVE METASTORE TABLES <source>.<table> [OPTIONS (key 'value', …)]
```

Lists synced tables of `<metastore>.<db>`; with OPTIONS it lists live tables instead.

**Privileges:** Depends on the form: any user; admins only.

**Example**

For a registered metastore:

```sql
LIST HIVE METASTORE TABLES hive_prod.sales
```

For a remote connection with inline options:

```sql
LIST HIVE METASTORE TABLES REMOTE OPTIONS (
  hive_meta_jdbc_url "jdbc:mysql://hive-db.example.com:3306/metastore",
  hive_meta_user_name "hive",
  hive_meta_password "changeme",
  hive_meta_jdbc_driver "com.mysql.cj.jdbc.Driver",
  databases "sales"
)
```

### 10.7 DROP HIVE METASTORE

**Syntax**

```sql
DROP HIVE METASTORE <source>.<table>
```

Deletes a registered Hive metastore (`<metastore>`) or one synced database (`<metastore>.<db>`).

**Privileges:** Administrators only.

**Example**

```sql
DROP HIVE METASTORE hive_prod
```

## 11. AWS Glue Metastore

An AWS Glue metastore registration synchronises database and table metadata from AWS Glue.

**Prerequisites**

Registration/remote listing needs a region, Glue catalog/database and authorised AWS authentication. Named listing/removal needs a registered metastore or synced database. `LIST AWS GLUE METASTORES` may be empty.

### 11.1 REGISTER AWS GLUE METASTORE

**Syntax**

```sql
REGISTER AWS GLUE METASTORE <name> OPTIONS (key 'value', …)
```

Registers an AWS Glue catalog (region, databases, optional keys and prefix) and syncs its metadata.

**Privileges:** Administrators only.

**Remarks**

- Requires an external service: AWS Glue.

**Example**

```sql
REGISTER AWS GLUE METASTORE glue_prod OPTIONS (
  region "ap-southeast-2",
  databases "analytics",
  awsAccessKeyId "AKIAEXAMPLE",
  awsSecretAccessKey "example-secret"
)
```

### 11.2 LIST AWS GLUE METASTORES

**Syntax**

```sql
LIST AWS GLUE METASTORES
```

Lists accessible Glue metastores.

**Privileges:** Signed-in users; assigned objects only.

**Example**

```sql
LIST AWS GLUE METASTORES
```

### 11.3 LIST AWS GLUE METASTORE DATABASES REMOTE

**Syntax**

```sql
LIST AWS GLUE METASTORE DATABASES REMOTE OPTIONS (key 'value', …)
```

Lists live Glue databases from inline options.

**Privileges:** Administrators only.

**Remarks**

- Requires an external service: AWS Glue.

**Example**

```sql
LIST AWS GLUE METASTORE DATABASES REMOTE OPTIONS (
  name "glue_prod",
  region "ap-southeast-2",
  awsAccessKeyId "AKIAEXAMPLE",
  awsSecretAccessKey "example-secret"
)
```

### 11.4 LIST AWS GLUE METASTORE DATABASES

**Syntax**

```sql
LIST AWS GLUE METASTORE DATABASES {OPTIONS (key 'value', …) | <metastore>}
```

With a name, lists synced databases; with OPTIONS, lists live ones.

**Privileges:** Depends on the form: admins only; any user.

**Example**

For a registered metastore:

```sql
LIST AWS GLUE METASTORE DATABASES glue_prod
```

For a remote connection with inline options:

```sql
LIST AWS GLUE METASTORE DATABASES REMOTE OPTIONS (
  name "glue_prod",
  region "ap-southeast-2",
  awsAccessKeyId "AKIAEXAMPLE",
  awsSecretAccessKey "example-secret"
)
```

### 11.5 LIST AWS GLUE METASTORE TABLES REMOTE

**Syntax**

```sql
LIST AWS GLUE METASTORE TABLES REMOTE OPTIONS (key 'value', …)
```

Lists live tables for the databases in OPTIONS `original_names`, over an inline connection.

**Privileges:** Administrators only.

**Remarks**

- `original_names` is read case-sensitively.
- Requires an external service: AWS Glue.

**Example**

```sql
LIST AWS GLUE METASTORE TABLES REMOTE OPTIONS (
  name "glue_prod",
  region "ap-southeast-2",
  original_names "analytics",
  awsAccessKeyId "AKIAEXAMPLE",
  awsSecretAccessKey "example-secret"
)
```

### 11.6 LIST AWS GLUE METASTORE TABLES

**Syntax**

```sql
LIST AWS GLUE METASTORE TABLES <source>.<table> [OPTIONS (key 'value', …)]
```

Lists synced tables of `<metastore>.<db>`; with OPTIONS it lists live tables instead.

**Privileges:** Depends on the form: any user; admins only.

**Example**

For a registered metastore:

```sql
LIST AWS GLUE METASTORE TABLES glue_prod.analytics
```

For a remote connection with inline options:

```sql
LIST AWS GLUE METASTORE TABLES REMOTE OPTIONS (
  name "glue_prod",
  region "ap-southeast-2",
  original_names "analytics",
  awsAccessKeyId "AKIAEXAMPLE",
  awsSecretAccessKey "example-secret"
)
```

### 11.7 DROP AWS GLUE METASTORE

**Syntax**

```sql
DROP AWS GLUE METASTORE <source>.<table>
```

Deletes a registered Glue metastore (`<metastore>`) or one synced database (`<metastore>.<db>`).

**Privileges:** Administrators only.

**Example**

```sql
DROP AWS GLUE METASTORE glue_prod
```

## 12. Schema Store Views

A schema store view is a stored Spark SQL view held in a container. Query Builder views are stored the same way.

**Prerequisites**

Views need an accessible source, an existing container and creation permission. First [create your own container](#122-create-schemastore-container). Preview can use `SELECT 1` without a container. Rename/removal needs an existing view.

### 12.1 CREATE [OR REPLACE] SCHEMASTORE VIEW

**Syntax**

```sql
CREATE [OR REPLACE] SCHEMASTORE VIEW <view> WITH CONTAINER <container> AS <SELECT query …>
```

Creates a Spark SQL view in a container; OR REPLACE overwrites an existing view.

**Privileges:** Administrators or Query Builder Write users.

**Remarks**

- Query a view as `<container>.<view>`.

**Example**

```sql
CREATE SCHEMASTORE VIEW reasons WITH CONTAINER analysis AS
SELECT r_reason_sk, r_reason_desc FROM TPCDS_DB.reason
```

### 12.2 CREATE SCHEMASTORE CONTAINER

**Syntax**

```sql
CREATE SCHEMASTORE CONTAINER <name>
```

Creates a schema-store view container, the folder Query Builder views live in.

**Privileges:** Administrators only.

**Example**

```sql
CREATE SCHEMASTORE CONTAINER analysis
```

### 12.3 PREVIEW SCHEMASTORE SQL

**Syntax**

```sql
PREVIEW SCHEMASTORE SQL AS <SELECT query …>
```

Runs a Spark SQL query and returns up to 10 rows.

**Privileges:** Administrators only.

**Remarks**

- Begin the statement with `PREVIEW SCHEMASTORE SQL AS`.

**Example**

```sql
PREVIEW SCHEMASTORE SQL AS SELECT country, COUNT(*) AS customers FROM crm_pg.customers GROUP BY country
```

### 12.4 SHOW DATASOURCE VIEWS

**Syntax**

```sql
SHOW DATASOURCE VIEWS
```

Lists accessible schema-store views: name, generator and cached table.

**Privileges:** Signed-in users; assigned objects only.

**Example**

```sql
SHOW DATASOURCE VIEWS
```

### 12.5 UPDATE SCHEMASTORE VIEW

**Syntax**

```sql
UPDATE SCHEMASTORE VIEW <source>.<table> SET NAME <new_name>
```

Renames a schema-store view and updates its grants and data-mart references.

**Privileges:** Administrators or Query Builder Write users.

**Remarks**

- Pipelines that refer to the view by its previous name must be updated separately.
- Needs `<container>.<view>`.

**Example**

```sql
UPDATE SCHEMASTORE VIEW analysis.top_customers SET NAME best_customers
```

### 12.6 DROP SCHEMASTORE VIEW

**Syntax**

```sql
DROP SCHEMASTORE VIEW <view> FROM <container>
```

Deletes a schema-store view unless a data mart uses it, and revokes its privileges.

**Privileges:** Administrators only.

**Example**

```sql
DROP SCHEMASTORE VIEW best_customers FROM analysis
```

## 13. Unified Semantic Layer

A Unified Semantic Layer (USL) is a semantic model of tables, keys and relationships. Each table is compiled from DDL, deployed to a namespace under `lightning.metastore`, and activated with a query over source data. An activated table is queried as `lightning.metastore.<namespace>.<usl>.<table>`.

**Prerequisites**

Deployment needs creation permission and a namespace under `lightning.metastore`. Activation needs an accessible SELECT matching the table schema. Load/update needs an existing USL. Compile without DEPLOY returns a model without saving it.

### 13.1 COMPILE USL

**Syntax**

```sql
COMPILE USL <usl> [DEPLOY] NAMESPACE <namespace> DDL
<CREATE TABLE statement>;
[<CREATE TABLE statement>; …]
```

Compiles USL table DDL into a semantic model; with DEPLOY it saves the model under the namespace.

**Privileges:** Administrators only.

**Limitations**

- Columns must use scalar data types. ARRAY, MAP and STRUCT types are not supported.
- Each CREATE TABLE statement must begin on a new line.

**Remarks**

- Separate CREATE TABLE definitions with `;`. SQL Workspace splits editor text at those separators. For multiple tables, use Unified Semantic Layer → New USL, or send the whole COMPILE statement over JDBC/HTTP with a runner that keeps it intact. Do not send each definition separately.
- Without DEPLOY, the command returns the model definition as JSON and stores nothing.
- The namespace must exist; create it with `CREATE NAMESPACE IF NOT EXISTS lightning.metastore.<name>`.

**Example**

```sql
COMPILE USL retail DEPLOY NAMESPACE lightning.metastore.datathon DDL
CREATE TABLE customer (
  id int NOT NULL PRIMARY KEY,
  full_name varchar(200),
  email varchar(200),
  country varchar(50)
);
CREATE TABLE orders (
  id int NOT NULL PRIMARY KEY,
  customer_id int FOREIGN KEY REFERENCES customer(id),
  amount decimal(10,2),
  status varchar(20)
)
```

### 13.2 LOAD USL

**Syntax**

```sql
LOAD USL <usl> NAMESPACE <namespace>
```

Returns a USL as JSON: tables, ordered columns, keys and materialization info.

**Privileges:** Signed-in users; assigned objects only.

**Example**

```sql
LOAD USL retail NAMESPACE lightning.metastore.datathon
```

### 13.3 SHOW NAMESPACES OR TABLES

**Syntax**

```sql
SHOW NAMESPACES OR TABLES IN <namespace>
```

Lists the namespaces, USLs and tables (with activation flag) under a namespace, filtered by access.

**Privileges:** Signed-in users; assigned objects only.

**Remarks**

- Use this command in place of `SHOW NAMESPACES` and `SHOW TABLES`.

**Example**

```sql
SHOW NAMESPACES OR TABLES IN lightning.metastore
```

### 13.4 ACTIVATE USL TABLE

**Syntax**

```sql
ACTIVATE USL TABLE <namespace.usl.table> AS <SELECT query …>
```

Binds a USL table to a SELECT query after checking the query matches the declared schema.

**Privileges:** Administrators only.

**Remarks**

- Any ANSI SQL or Spark built-in function can shape the columns; a query column may not be downcast to the declared type.
- The query must return the declared columns with compatible types. A column declared NOT NULL requires a non-null expression, for example `COALESCE(id, 0)`.

**Example**

```sql
ACTIVATE USL TABLE lightning.metastore.datathon.retail.customer AS
SELECT COALESCE(id, 0) AS id, full_name, email, country
FROM crm_pg.customers
```

### 13.5 UPDATE USL … AS (replace model)

**Syntax**

```sql
UPDATE USL <usl> NAMESPACE <namespace> AS <USL JSON …>
```

Replaces a whole USL from its JSON form.

**Privileges:** Administrators only.

**Remarks**

- Start from the JSON returned by LOAD USL. The command replaces the entire model.
- Re-run `ACTIVATE USL TABLE` after replacement before querying the table. On Zetaris 2.4.3.1, the 12 October 2026 live check accepted JSON containing `activateQuery` but the next SELECT returned `table(...) is not activated`. Reactivation restored query access.

**Example**

```sql
UPDATE USL retail NAMESPACE lightning.metastore.datathon AS {"namespace": ["metastore", "datathon"], "name": "retail", "tables": […]}
```

### 13.6 UPDATE USL … SET DESCRIPTION

**Syntax**

```sql
UPDATE USL <namespace.usl.table[.column]> SET [TABLE | COLUMN] DESCRIPTION <text …>
```

Sets the description of a USL, one of its tables, or one column.

**Privileges:** Administrators only.

**Example**

```sql
UPDATE USL lightning.metastore.datathon.retail.customer SET TABLE DESCRIPTION One row per customer
```

### 13.7 UPDATE USL … SET COLUMN ORDER

**Syntax**

```sql
UPDATE USL <namespace.usl.table> SET COLUMN ORDER <col1, col2, …>
```

Saves a table's column display order; list every column, comma-separated.

**Privileges:** Administrators only.

**Example**

```sql
UPDATE USL lightning.metastore.datathon.retail.customer SET COLUMN ORDER id, full_name, country, email
```

### 13.8 REMOVE USL

**Syntax**

```sql
REMOVE USL <usl> NAMESPACE <namespace>
```

Deletes a USL.

**Privileges:** Administrators only.

**Example**

```sql
REMOVE USL retail NAMESPACE lightning.metastore.datathon
```

## 14. Data Quality

Data-quality rules are boolean expressions evaluated against activated USL tables.

**Prerequisites**

Rules and record inspection need an activated USL table. Registering a rule needs model-change permission. Named operations need an existing rule; check names with `LIST DQ USL`.

### 14.1 REGISTER DQ

**Syntax**

```sql
REGISTER DQ <rule> TABLE <namespace.usl.table> AS <boolean expression …>
```

Adds a named data-quality rule, a boolean expression, to an activated USL table.

**Privileges:** Administrators only.

**Example**

```sql
REGISTER DQ valid_email TABLE lightning.metastore.datathon.retail.customer AS
email IS NOT NULL AND email LIKE '%@%'
```

### 14.2 LIST DQ USL

**Syntax**

```sql
LIST DQ USL <namespace.usl>
```

Lists the key constraints and data-quality rules for every table in a USL.

**Privileges:** Signed-in users; assigned objects only.

**Example**

```sql
LIST DQ USL lightning.metastore.datathon.retail
```

### 14.3 SHOW DQ VALID / INVALID RECORD

**Syntax**

```sql
SHOW DQ {VALID | INVALID} RECORD <rule> TABLE <namespace.usl.table>
```

Returns the records that pass (VALID) or fail (INVALID) one rule.

**Privileges:** Signed-in users; assigned objects only.

**Remarks**

- Results are streamed.

**Example**

```sql
SHOW DQ INVALID RECORD valid_email TABLE lightning.metastore.datathon.retail.customer
```

### 14.4 SHOW DQ ALL VALID / INVALID

**Syntax**

```sql
SHOW DQ ALL {VALID | INVALID} TABLE <namespace.usl.table>
```

Returns the records that pass every rule, or fail any rule.

**Privileges:** Administrators only.

**Example**

```sql
SHOW DQ ALL INVALID TABLE lightning.metastore.datathon.retail.customer
```

### 14.5 UPDATE DQ

**Syntax**

```sql
UPDATE DQ <rule> TABLE <namespace.usl.table> SET NAME = <new_rule>, EXPRESSION = <boolean expression …>
```

Renames a data-quality rule and/or changes its expression.

**Privileges:** Administrators only.

**Example**

```sql
UPDATE DQ valid_email TABLE lightning.metastore.datathon.retail.customer
SET NAME = valid_email_v2, EXPRESSION = email LIKE '%@%.%'
```

### 14.6 RUN DQ

**Syntax**

```sql
RUN DQ <rule> TABLE <namespace>.<usl>.<table>
```

Runs one rule, or all rules and key constraints, and returns total, valid and invalid counts.

**Privileges:** Signed-in users; assigned objects only.

**Limitations**

- A rule name must be specified.

**Remarks**

- For a composite key, enclose the column list in backquotes, for example `RUN DQ` id,name `TABLE …`.

**Example**

```sql
RUN DQ valid_email TABLE lightning.metastore.datathon.retail.customer
```

### 14.7 REMOVE DQ

**Syntax**

```sql
REMOVE DQ <rule> TABLE <namespace.usl.table>
```

Deletes a data-quality rule.

**Privileges:** Administrators only.

**Remarks**

- The rule is removed from every table in the USL.

**Example**

```sql
REMOVE DQ valid_email_v2 TABLE lightning.metastore.datathon.retail.customer
```

## 15. Export and Materialization

These commands write a query result or a USL table to storage.

**Prerequisites**

Export needs a writable destination, storage settings/credentials and query access. USL materialisation also needs an activated table. Confirm the path and overwrite/append behaviour before writing.

### 15.1 RUN EXPORT TO STORAGE

**Syntax**

```sql
RUN EXPORT TO STORAGE (key 'value', …)
```

Writes query results to cloud storage or an Iceberg table.

**Privileges:** Signed-in users; assigned objects only.

**Remarks**

- `optionsBase64` is a base64-encoded JSON object of write and storage options; the example encodes `{"header":"true"}`.
- `format` is csv, json, parquet, orc or delta; `saveMode` is overwrite, append, ignore or errorifexists.
- The Export action in the SQL Workspace builds this command, including the storage credentials.

**Example**

```sql
RUN EXPORT TO STORAGE (
  query = 'SELECT * FROM crm_pg.customers WHERE country = ''AU''',
  path = 's3a://datathon-bucket/exports/au_customers',
  format = 'csv',
  saveMode = 'overwrite',
  optionsBase64 = 'eyJoZWFkZXIiOiJ0cnVlIn0='
)
```

### 15.2 MATERIALIZE USL TABLE

**Syntax**

```sql
MATERIALIZE USL TABLE <namespace.usl.table> TO STORAGE (key 'value', …)
```

Runs a USL table's activation query and writes the result to storage.

**Privileges:** Administrators only.

**Remarks**

- `recordType` is `all` or `valid`; `valid` writes only rows that pass the data-quality rules.
- The Materialize action on a USL table builds this command, including the storage setting and credentials.

**Example**

```sql
MATERIALIZE USL TABLE lightning.metastore.datathon.retail.customer TO STORAGE (
  recordType = 'all',
  path = 's3a://datathon-bucket/usl/retail/customer',
  format = 'parquet',
  storageSettingId = '<storage setting id>',
  optionsBase64 = 'eyJoZWFkZXIiOiJ0cnVlIn0='
)
```

## 16. Data Pipelines

Pipelines are built in the Data Pipeline designer and stored in pipeline containers. Several commands in this chapter take the pipeline specification in JSON form.

**Prerequisites**

Saving needs your own container, write permission and a complete specification with accessible sources. Infer/verify needs a valid query or specification. Named describe/update/drop needs a saved relation.

### 16.1 CREATE PIPELINE CONTAINER

**Syntax**

```sql
CREATE PIPELINE CONTAINER <name> [DESCRIPTION '<desc>']
```

Creates a pipeline container.

**Privileges:** Administrators or Data Pipeline Write users.

**Example**

```sql
CREATE PIPELINE CONTAINER etl DESCRIPTION 'Daily ETL'
```

### 16.2 REGISTER PIPELINE RELATION CONTAINER

**Syntax**

```sql
REGISTER PIPELINE RELATION CONTAINER <container> SPEC <pipeline JSON …>
```

Saves a pipeline into a container.

**Privileges:** Administrators or Data Pipeline Write users.

**Remarks**

- The specification is the JSON returned by DESCRIBE PIPELINE RELATION. Pipelines are normally built in the Data Pipeline designer.

**Example**

```sql
REGISTER PIPELINE RELATION CONTAINER etl SPEC
{"name": "daily_orders", "nodes": [
  {"nodeType": "DataSource", "name": "orders_source",
   "columns": [{"name": "customer_id", "dataType": "int"}, {"name": "amount", "dataType": "decimal(10,2)"}],
   "properties": [], "sources": ["crm_pg.orders"]},
  {"nodeType": "Projection", "name": "orders_projection",
   "columns": [{"name": "customer_id", "dataType": "int"}, {"name": "amount", "dataType": "decimal(10,2)"}],
   "properties": [], "sources": ["orders_source"]}
]}
```

### 16.3 LIST PIPELINE CONTAINER

**Syntax**

```sql
LIST PIPELINE CONTAINER
```

Lists accessible pipeline containers.

**Privileges:** Signed-in users; assigned objects only.

**Example**

```sql
LIST PIPELINE CONTAINER
```

### 16.4 LIST PIPELINE RELATION

**Syntax**

```sql
LIST PIPELINE RELATION <container>
```

Lists the pipelines in a container.

**Privileges:** Signed-in users; assigned objects only.

**Example**

```sql
LIST PIPELINE RELATION etl
```

### 16.5 DESCRIBE PIPELINE RELATION

**Syntax**

```sql
DESCRIBE PIPELINE RELATION <container>.<pipeline>
```

Returns a saved pipeline's JSON.

**Privileges:** Administrators or Data Pipeline Read or Write users.

**Limitations**

- The pipeline must be qualified with its container name.

**Remarks**

- Returns the pipeline specification in JSON form.

**Example**

```sql
DESCRIBE PIPELINE RELATION etl.daily_orders
```

### 16.6 VERIFY PIPELINE

**Syntax**

```sql
VERIFY PIPELINE SPEC <pipeline JSON …>
```

Validates a whole pipeline spec, source access included; returns validity, schema and error.

**Privileges:** Administrators or Data Pipeline Write users.

**Remarks**

- Returns the validity, the output schema and any error.

**Example**

```sql
VERIFY PIPELINE SPEC {"name": "daily_orders", "nodes": […]}
```

### 16.7 INFER SQLTABLE SOURCES

**Syntax**

```sql
INFER SQLTABLE SOURCES SPEC <SQL query …>
```

Returns the source tables and aliases that a SQL query reads.

**Privileges:** Administrators or Data Pipeline Write users.

**Example**

```sql
INFER SQLTABLE SOURCES SPEC SELECT c.id, o.amount FROM crm_pg.customers c JOIN crm_pg.orders o ON o.customer_id = c.id
```

### 16.8 INFER SQLTABLE COLUMNS

**Syntax**

```sql
INFER SQLTABLE COLUMNS SPEC <SQL query …>
```

Returns a SQL query's output columns with their source table.column and type.

**Privileges:** Administrators or Data Pipeline Write users.

**Example**

```sql
INFER SQLTABLE COLUMNS SPEC SELECT c.id, o.amount FROM crm_pg.customers c JOIN crm_pg.orders o ON o.customer_id = c.id
```

### 16.9 UPDATE PIPELINE RELATION

**Syntax**

```sql
UPDATE PIPELINE RELATION <container>.<pipeline> SPEC <pipeline JSON>
```

Replaces a saved pipeline's JSON.

**Privileges:** Administrators or Data Pipeline Write users.

**Limitations**

- The pipeline must be qualified with its container name.

**Remarks**

- The specification is the JSON returned by DESCRIBE PIPELINE RELATION.

**Example**

```sql
UPDATE PIPELINE RELATION etl.daily_orders SPEC {"name": "daily_orders", "nodes": […]}
```

### 16.10 RUN PIPELINE

**Syntax**

```sql
RUN PIPELINE ON '<node>' [LIMIT <n>] SPEC <pipeline JSON …>
```

Runs an unsaved pipeline up to the named node and returns its rows.

**Privileges:** Administrators or Data Pipeline Read or Write users.

**Remarks**

- Runs the unsaved specification up to the named node and returns its rows.

**Example**

```sql
RUN PIPELINE ON 'orders_projection' LIMIT 100 SPEC {"name": "daily_orders", "nodes": […]}
```

### 16.11 DROP PIPELINE CONTAINER

**Syntax**

```sql
DROP PIPELINE CONTAINER <name>
```

Deletes a pipeline container with its dependent views and privileges.

**Privileges:** Administrators or Data Pipeline Write users.

**Example**

```sql
DROP PIPELINE CONTAINER etl
```

### 16.12 DROP PIPELINE RELATION

**Syntax**

```sql
DROP PIPELINE RELATION <container>.<pipeline>
```

Deletes a saved pipeline.

**Privileges:** Administrators or Data Pipeline Write users.

**Limitations**

- The pipeline must be qualified with its container name.

**Example**

```sql
DROP PIPELINE RELATION etl.daily_orders
```

## 17. Virtual Data Marts

A virtual data mart presents source tables under new table and column names without copying data.

**Prerequisites**

Creation needs write permission. Adding a table needs an existing mart and source access; map every source column. Other operations need the existing mart or table.

### 17.1 CREATE DATAMART

**Syntax**

```sql
CREATE DATAMART <name> [DESCRIBE BY '<description>']
```

Creates a virtual data mart.

**Privileges:** Administrators or Virtual Data Mart Write users.

**Example**

```sql
CREATE DATAMART sales_mart DESCRIBE BY 'Sales mart'
```

### 17.2 ADD DATAMART TABLE

**Syntax**

```sql
ADD DATAMART TABLE <table> INTO <datamart> FROM <source.path> VSCHEMA (<column> <virtual_name>, …)
```

Adds a virtual table over a source table; every source column must be given a virtual name.

**Privileges:** Administrators or Virtual Data Mart Write users.

**Remarks**

- Query a data-mart table as `<datamart>.<table>`.
- The source can also be an activated USL table (`<usl table>`) or a saved pipeline relation (`<container>.<relation>`). `VSCHEMA` must still list every source column: a partial list failed with "Data mart table schemas do not match source table's". Tested on 2.4.3.1; see the [companion guide, section 7](zetaris-lightning-sql-companion.md#7-virtual-data-marts-vdm--the-sql-free-consumption-layer-and-where-usl-changes-this).

**Example**

```sql
ADD DATAMART TABLE customer_v INTO sales_mart FROM crm_pg.customers
VSCHEMA (id customer_id, full_name name, email email, country country, created_at signup_date)
```

### 17.3 SHOW DATAMARTS

**Syntax**

```sql
SHOW DATAMARTS
```

Lists accessible data marts.

**Privileges:** Signed-in users; assigned objects only.

**Example**

```sql
SHOW DATAMARTS
```

### 17.4 SHOW DATAMART TABLES

**Syntax**

```sql
SHOW DATAMART TABLES <datamart>
```

Lists a data mart's tables with their sources.

**Privileges:** Signed-in users; assigned objects only.

**Example**

```sql
SHOW DATAMART TABLES sales_mart
```

### 17.5 DESCRIBE DATAMART TABLE

**Syntax**

```sql
DESCRIBE DATAMART TABLE <source>.<table>
```

Returns a data-mart table's real-to-virtual column mapping.

**Privileges:** Administrators or Virtual Data Mart Read or Write users.

**Example**

```sql
DESCRIBE DATAMART TABLE sales_mart.customer_v
```

### 17.6 UPDATE DATAMART

**Syntax**

```sql
UPDATE DATAMART <name> OPTIONS (key 'value', …)
```

Renames a data mart and/or sets its description.

**Privileges:** Administrators or Virtual Data Mart Write users.

**Remarks**

- Change the name and the description in separate statements.

**Example**

```sql
UPDATE DATAMART sales_mart OPTIONS (DESCRIPTION "Sales mart for the datathon")
```

### 17.7 UPDATE DATAMART TABLE … SET VSCHEMA

**Syntax**

```sql
UPDATE DATAMART TABLE <source>.<table> SET VSCHEMA (<column> <virtual_name>,…)
```

Rewrites a data-mart table's virtual column names.

**Privileges:** Administrators or Virtual Data Mart Write users.

**Example**

```sql
UPDATE DATAMART TABLE sales_mart.customer_v SET VSCHEMA (id customer_id, full_name customer_name, email email, country country, created_at signup_date)
```

### 17.8 UPDATE DATAMART TABLE … SET NAME

**Syntax**

```sql
UPDATE DATAMART TABLE <source>.<table> SET NAME <new_name>
```

Renames a data-mart table.

**Privileges:** Administrators or Virtual Data Mart Write users.

**Example**

```sql
UPDATE DATAMART TABLE sales_mart.customer_v SET NAME customers
```

### 17.9 DROP DATAMART

**Syntax**

```sql
DROP DATAMART <name>
```

Deletes a data mart with its dependent views and privileges.

**Privileges:** Administrators or Virtual Data Mart Write users.

**Example**

```sql
DROP DATAMART sales_mart
```

### 17.10 DROP DATAMART TABLE

**Syntax**

```sql
DROP DATAMART TABLE <source>.<table>
```

Deletes data-mart table `<datamart>.<table>`.

**Privileges:** Administrators or Virtual Data Mart Write users.

**Example**

```sql
DROP DATAMART TABLE sales_mart.customers
```

## 18. Query Plans

This chapter describes the query-plan command.

**Prerequisites**

Administrator permission and an accessible SELECT query. `EXPLAIN QUERY AS SELECT 1` needs no source table.

### 18.1 EXPLAIN QUERY

**Syntax**

```sql
EXPLAIN QUERY AS <SELECT query>
```

Returns the query plan for a statement.

**Privileges:** Administrators only.

**Limitations**

- Only SELECT statements are supported.

**Remarks**

- Use this command only with SELECT statements.

**Example**

```sql
EXPLAIN QUERY AS SELECT country, COUNT(*) FROM crm_pg.customers GROUP BY country
```

## 19. Caching

Off-site caching stores a copy of a table in memory or in file storage to accelerate queries.

**Prerequisites**

Caching needs a table, source access and cache-management permission. Update/uncache needs an active cache. Policy/history lists may be empty. `INVALIDATE CACHE` affects every organisation; confirm that scope first.

### 19.1 SHOW CACHE TABLES

**Syntax**

```sql
SHOW CACHE TABLES
```

Lists cached tables with storage, size, partitions and hit counts.

**Privileges:** Administrators only.

**Example**

```sql
SHOW CACHE TABLES
```

### 19.2 SHOW CACHE POLICY

**Syntax**

```sql
SHOW CACHE POLICY
```

Lists stored organisation cache policies.

**Privileges:** Administrators only.

**Example**

```sql
SHOW CACHE POLICY
```

### 19.3 SHOW CACHE TABLE POLICY

**Syntax**

```sql
SHOW CACHE TABLE POLICY [<datasource>]
```

Lists per-table cache policies, optionally for one datasource.

**Privileges:** Administrators only.

**Example**

```sql
SHOW CACHE TABLE POLICY crm_pg
```

### 19.4 OFFSITE CACHE TABLE

**Syntax**

```sql
OFFSITE CACHE TABLE <source>.<table> TO {ONSITEMEMORY | MEMORY | FILE} WITH (key 'value', …)
```

Caches a table in Spark memory or a file cache, with expiry and partition options.

**Privileges:** Administrators only.

**Remarks**

- `expireInSec` is `-1` for no expiry or a number of seconds; `partcount` sets the number of partitions.
- Storage is `MEMORY` or `FILE`.

**Example**

```sql
OFFSITE CACHE TABLE crm_pg.customers TO MEMORY WITH (expireInSec "-1", partcount "4")
```

### 19.5 OFFSITE UNCACHE TABLE

**Syntax**

```sql
OFFSITE UNCACHE TABLE <source>.<table>
```

Drops a table's cache and its refresh schedule.

**Privileges:** Administrators only.

**Example**

```sql
OFFSITE UNCACHE TABLE crm_pg.customers
```

### 19.6 UPDATE OFFSITE CACHE TABLE

**Syntax**

```sql
UPDATE OFFSITE CACHE TABLE <source>.<table> WITH (key 'value', …)
```

Changes a cached table's refresh schedule.

**Privileges:** Administrators only.

**Example**

```sql
UPDATE OFFSITE CACHE TABLE crm_pg.customers WITH (expireInSec "600")
```

### 19.7 OFFSITE CACHE TABLE DETAILS

**Syntax**

```sql
OFFSITE CACHE TABLE DETAILS <source>.<table>
```

Returns a table's cache settings; empty when the table isn't cached.

**Privileges:** Administrators only.

**Example**

```sql
OFFSITE CACHE TABLE DETAILS crm_pg.customers
```

### 19.8 OFFSITE CACHE HISTORY

**Syntax**

```sql
OFFSITE CACHE HISTORY <source>.<table>
```

Lists a table's cache and uncache history.

**Privileges:** Administrators only.

**Example**

```sql
OFFSITE CACHE HISTORY crm_pg.customers
```

### 19.9 INVALIDATE CACHE

**Syntax**

```sql
INVALIDATE CACHE
```

Flushes the driver's metadata caches for every organisation; table caches are kept.

**Privileges:** Signed-in users; assigned objects only.

**Example**

```sql
INVALIDATE CACHE
```

## 20. Users and Roles

User and role names are stored in upper case and matched case-insensitively.

**Prerequisites**

Check each command's user-management privileges. Assignment/revocation needs existing users and roles. Deletion examples require a disposable test user, not a participant account.

### 20.1 CREATE ROLE

**Syntax**

```sql
CREATE ROLE '<role>' [DESCRIBE BY '<desc>']
```

Creates a role; admin, none, all and default are reserved names.

**Privileges:** Administrators or User Management Write users.

**Example**

```sql
CREATE ROLE 'analyst' DESCRIBE BY 'Datathon analysts'
```

### 20.2 SHOW USERS

**Syntax**

```sql
SHOW USERS
```

Lists your organisation's users: email, name, level, organisation, LDAP flag.

**Privileges:** Administrators or User Management Read or Write users.

**Example**

```sql
SHOW USERS
```

### 20.3 SHOW ROLES

**Syntax**

```sql
SHOW ROLES
```

Lists roles: name, creator, created time, description, LDAP flag.

**Privileges:** Administrators or User Management Read or Write users.

**Example**

```sql
SHOW ROLES
```

### 20.4 SHOW ROLE ASSIGNED TO USER

**Syntax**

```sql
SHOW ROLE ASSIGNED TO USER '<user>'
```

Lists a user's roles with who assigned them and when.

**Privileges:** Administrators or User Management Read or Write users.

**Example**

```sql
SHOW ROLE ASSIGNED TO USER 'alice@example.com'
```

### 20.5 SHOW USER ASSIGNED TO ROLE

**Syntax**

```sql
SHOW USER ASSIGNED TO ROLE '<role>'
```

Lists a role's users with who assigned them and when.

**Privileges:** Administrators or User Management Read or Write users.

**Example**

```sql
SHOW USER ASSIGNED TO ROLE 'analyst'
```

### 20.6 DESCRIBE USER

**Syntax**

```sql
DESCRIBE USER '<user>'
```

Returns a user's name, email, level, organisation and LDAP flag.

**Privileges:** Signed-in users; assigned objects only.

**Example**

```sql
DESCRIBE USER 'alice@example.com'
```

### 20.7 ASSIGN USER … TO ROLE

**Syntax**

```sql
ASSIGN USER '<user>'[, …] TO ROLE '<role>'
```

Adds users to a role; LDAP-sourced roles are refused.

**Privileges:** Administrators or User Management Write users.

**Example**

```sql
ASSIGN USER 'alice@example.com', 'bob@example.com' TO ROLE 'analyst'
```

### 20.8 DROP USER

**Syntax**

```sql
DROP USER '<user>'
```

Deletes a user; you can't delete yourself.

**Privileges:** Administrators or User Management Write users.

**Example**

```sql
DROP USER 'bob@example.com'
```

### 20.9 DROP ROLE

**Syntax**

```sql
DROP ROLE '<role>'
```

Deletes a role and its user assignments.

**Privileges:** Administrators or User Management Write users.

**Example**

```sql
DROP ROLE 'analyst'
```

### 20.10 REVOKE USER … FROM ROLE

**Syntax**

```sql
REVOKE USER '<user>'[, …] FROM ROLE '<role>'
```

Removes users from a role; LDAP-sourced roles are refused.

**Privileges:** Administrators or User Management Write users.

**Example**

```sql
REVOKE USER 'bob@example.com' FROM ROLE 'analyst'
```

## 21. Access Control

Access is controlled at two levels. An assignment attaches a user or role to an object; a grant gives a privilege (SELECT or INSERT) on a table or namespace. Schema store views are protected by grants; view assignments are made per container in the platform interface.

**Prerequisites**

Assignments/grants need existing objects/principals and access-control permission. Metastore forms need a registered Hive or Glue database. Confirm the recipient, object and privilege before access changes.

### 21.1 SHOW GRANT … ON ALL

**Syntax**

```sql
SHOW GRANT [{ROLE '<role>' | USER '<user>'}[, …]] ON ALL
```

Lists the grants held by users or roles; with no principal, every grant in your organisation.

**Privileges:** Administrators or Access Control Read or Write users.

**Example**

```sql
SHOW GRANT USER 'alice@example.com' ON ALL
```

### 21.2 LIST USERS / LIST ROLES FOR object

**Syntax**

```sql
LIST {USERS | ROLES} FOR {DATASOURCE | DATAMART | [LIGHTNING] DATABASE | PIPELINE | STREAMING DATASOURCE} <name>
```

Lists the users or roles assigned to an object.

**Privileges:** Administrators or Access Control Read or Write users.

**Limitations**

- Schema store views are not supported. Access to views is controlled with GRANT … ON VIEW.

**Example**

```sql
LIST USERS FOR DATASOURCE crm_pg
```

### 21.3 LIST USERS / LIST ROLES FOR metastore database

**Syntax**

```sql
LIST {USERS | ROLES} FOR {HIVE METASTORE DATABASE|AWS GLUE METASTORE DATABASE} <metastore.db>
```

Lists the users or roles assigned to a Hive or Glue metastore database.

**Privileges:** Administrators or Access Control Read or Write users.

**Example**

```sql
LIST ROLES FOR HIVE METASTORE DATABASE hive_prod.sales
```

### 21.4 GRANT privilege

**Syntax**

```sql
GRANT {SELECT | INSERT | CACHE} ON {ALL [<object_type>] | USL {NAMESPACE | TABLE} <name> | <object_type> {NAMESPACE | TABLE} <name>} TO {ROLE '<role>' | USER '<user>'}[, …] [WITH GRANT OPTION]
```

Grants SELECT, INSERT or CACHE on everything, one object type, or a namespace or table.

**Privileges:** Administrators, or users granted the Access Control Write; holders of the privilege WITH GRANT OPTION can also grant it permission.

**Remarks**

- Holders of a privilege WITH GRANT OPTION can pass it on.
- Object types: DATASOURCE, LIGHTNING DATABASE, DATAMART, PIPELINE, VIEW, DATALAKE, STREAMING DATASOURCE, HIVE, AWS GLUE, UNITY CATALOG, USL.
- Grants on views take the form `VIEW TABLE <container>.<view>` or `VIEW NAMESPACE <container>`.

**Example**

```sql
GRANT SELECT ON DATASOURCE TABLE crm_pg.customers TO USER 'alice@example.com'
```

### 21.5 ASSIGN object TO ROLE

**Syntax**

```sql
ASSIGN {DATASOURCE | DATAMART | [LIGHTNING] DATABASE | PIPELINE | STREAMING DATASOURCE} <object>[, …] TO ROLE '<role>'[, …]
```

Assigns datasources, data marts, Lightning databases, pipelines or streaming sources to roles.

**Privileges:** Administrators or Access Control Write users.

**Limitations**

- Schema store views cannot be assigned. Access to views is controlled with GRANT … ON VIEW.

**Example**

```sql
ASSIGN DATASOURCE crm_pg TO ROLE 'analyst'
```

### 21.6 ASSIGN metastore database TO ROLE

**Syntax**

```sql
ASSIGN {HIVE METASTORE DATABASE|AWS GLUE METASTORE DATABASE} <metastore.db>[, …] TO ROLE '<role>'[, …]
```

Assigns Hive or AWS Glue metastore databases to roles.

**Privileges:** Administrators or Access Control Write users.

**Example**

```sql
ASSIGN HIVE METASTORE DATABASE hive_prod.sales TO ROLE 'analyst'
```

### 21.7 ASSIGN object TO USER

**Syntax**

```sql
ASSIGN {DATASOURCE | DATAMART | [LIGHTNING] DATABASE | PIPELINE | STREAMING DATASOURCE} <object>[, …] TO USER '<user>'[, …]
```

Assigns datasources, data marts, Lightning databases, pipelines or streaming sources to users.

**Privileges:** Administrators or Access Control Write users.

**Limitations**

- Schema store views cannot be assigned. Access to views is controlled with GRANT … ON VIEW.

**Example**

```sql
ASSIGN DATAMART sales_mart TO USER 'alice@example.com'
```

### 21.8 ASSIGN metastore database TO USER

**Syntax**

```sql
ASSIGN {HIVE METASTORE DATABASE|AWS GLUE METASTORE DATABASE} <metastore.db>[, …] TO USER '<user>'[, …]
```

Assigns Hive or AWS Glue metastore databases to users.

**Privileges:** Administrators or Access Control Write users.

**Example**

```sql
ASSIGN AWS GLUE METASTORE DATABASE glue_prod.analytics TO USER 'alice@example.com'
```

### 21.9 REVOKE privilege

**Syntax**

```sql
REVOKE {SELECT | INSERT | CACHE} ON {ALL [<object_type>] | USL {NAMESPACE | TABLE} <name> | <object_type> {NAMESPACE | TABLE} <name>} FROM {ROLE '<role>' | USER '<user>'}[, …]
```

Revokes a SELECT, INSERT or CACHE grant.

**Privileges:** Administrators, or users granted the Access Control Write; holders of the privilege WITH GRANT OPTION can also grant it permission.

**Example**

```sql
REVOKE SELECT ON DATASOURCE TABLE crm_pg.customers FROM USER 'alice@example.com'
```

### 21.10 REVOKE object FROM ROLE

**Syntax**

```sql
REVOKE {DATASOURCE | DATAMART | [LIGHTNING] DATABASE | PIPELINE | STREAMING DATASOURCE} <object>[, …] FROM ROLE '<role>'
```

Removes object assignments from a role.

**Privileges:** Administrators or Access Control Write users.

**Limitations**

- Schema store views are not supported.

**Remarks**

- There is no FROM USER form; use `REVOKE USERS … FROM <object>`.

**Example**

```sql
REVOKE DATASOURCE crm_pg FROM ROLE 'analyst'
```

### 21.11 REVOKE metastore database FROM ROLE

**Syntax**

```sql
REVOKE {HIVE METASTORE DATABASE|AWS GLUE METASTORE DATABASE} <metastore.db>[, …] FROM ROLE '<role>'
```

Removes metastore database assignments from a role.

**Privileges:** Administrators or Access Control Write users.

**Example**

```sql
REVOKE HIVE METASTORE DATABASE hive_prod.sales FROM ROLE 'analyst'
```

### 21.12 REVOKE USERS / ROLES FROM object

**Syntax**

```sql
REVOKE {USERS '<user>'[, …] | ROLES '<role>'[, …]} FROM {DATASOURCE | DATAMART | [LIGHTNING] DATABASE | PIPELINE | STREAMING DATASOURCE} <name>
```

Removes the named users' or roles' assignment to an object, with their privileges on it.

**Privileges:** Administrators or Access Control Write users.

**Limitations**

- Schema store views are not supported.

**Example**

```sql
REVOKE USERS 'alice@example.com' FROM DATAMART sales_mart
```

### 21.13 REVOKE USERS / ROLES FROM metastore database

**Syntax**

```sql
REVOKE {USERS '<user>'[, …] | ROLES '<role>'[, …]} FROM {HIVE METASTORE DATABASE|AWS GLUE METASTORE DATABASE} <metastore.db>
```

Removes users' or roles' assignment to a Hive or Glue metastore database.

**Privileges:** Administrators or Access Control Write users.

**Example**

```sql
REVOKE ROLES 'analyst' FROM AWS GLUE METASTORE DATABASE glue_prod.analytics
```

## 22. Data Warehouses

Commands for the virtual data warehouse feature.

**Prerequisites**

Administrator permission. Virtual data warehouses are unused here, so the list is normally empty.

### 22.1 LIST DATAWAREHOUSE

**Syntax**

```sql
LIST DATAWAREHOUSE
```

Lists warehouses with their status and endpoints.

**Privileges:** Administrators only.

**Remarks**

- Virtual data warehouses are not used on this platform; the list is normally empty.

**Example**

```sql
LIST DATAWAREHOUSE
```

## 23. Server Information

Commands that report on the platform.

**Prerequisites**

A signed-in account. No datasource or dataset setup is needed; results reflect your access.

### 23.1 SHOW SCHEMA

**Syntax**

```sql
SHOW SCHEMA
```

Lists accessible databases, datasources, streams, pipelines and data marts.

**Privileges:** Signed-in users; assigned objects only.

**Example**

```sql
SHOW SCHEMA
```

### 23.2 SHOW SERVER VERSION

**Syntax**

```sql
SHOW SERVER VERSION
```

Returns the driver's version, build time, tag and commit.

**Privileges:** Signed-in users; assigned objects only.

**Example**

```sql
SHOW SERVER VERSION
```
