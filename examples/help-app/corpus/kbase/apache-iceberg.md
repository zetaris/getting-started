---
source: kbase
url: https://kbase.zetaris.com/knowledge/apache-iceberg
title: "Apache Iceberg"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 9ad4fe3e92199ce63cfbd573322efda3a9e6253d85fd6914b34917dc56c985be
---
# Apache Iceberg

Apache Iceberg is an open-source table format for storing large, slow-changing datasets.

Zetaris allows you to connect your Apache Iceberg tables and query against them in real-time without having to move the tables to a centralised location.

-   [Release Notes](https://kbase.zetaris.com/knowledge/zetaris-integrates-with-apache-iceberg)

### Connecting and Querying your Apache Iceberg tables

Connecting to your Apache Iceberg formatted tables (parquet, ORC or AVRO) through the SQL Editor.

**Step 1:**  Connect to your Iceberg path:

_Note: example is using AWS environment_

```
CREATE datalake mlake options (storageType 'S3',storagePath 's3a://zetaris-emr-test/qa_file/Iceberg/',AwsAccessKeyId 'ABCDEFHUJS',AwsSecretAccessKey 'z1y2x3w3v4u5t6')
```

**Step 2:** Create virtual table representation in Zetaris: 

```
CREATE TABLE mlake.tpcds.mytestUSING iceberg AS SELECT c_name FROM AZURE_MSSQL.customer LIMIT 5;
```

### How to manage your Iceberg tables in Zetaris:

#### DROP

```
DROP TABLE mlake.tpcds.mytest 
```

_Note: Only those with Administrator permissions can drop tables_

#### Alter Table (ADD, RENAME)

#### ADD

```
ALTER TABLE mlake.tpcds.mytestADD COLUMNS (   new_column string comment 'new_column docs'  )
```

**RENAME (table)**

```
ALTER TABLE mlake.tpcds.mytest RENAME TO mlake.tpcds.test
```

**RENAME (columns)**

```
ALTER TABLE mlake.tpcds.mytest RENAME COLUMN new_column docs  TO payload
```
