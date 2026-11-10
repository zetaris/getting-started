---
source: kbase
url: https://kbase.zetaris.com/knowledge/zetaris-integrates-with-apache-iceberg
title: "Zetaris integrates with Apache Iceberg"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 95b220a76f825d9caeed9f8280b383e070188568a2b64d6db95930e1950ddb02
---
# Zetaris integrates with Apache Iceberg

## Zetaris now integrates with Apache Iceberg providing a powerful combination of data management and processing capabilities, enabling efficient and flexible management of large and complex datasets.

Apache Iceberg is an open-source table format for storing large, slow-changing datasets. It was developed to address some of the limitations of other table formats, such as Apache Parquet and Apache ORC, which struggle to efficiently manage schema evolution and data versioning. Apache Iceberg achieves this by separating the data storage format from the table schema definition, allowing for more flexibility in managing changes over time.

**Reference links for Apache Iceberg**

https://iceberg.apache.org/docs/latest/spark-ddl/  
https://iceberg.apache.org/docs/latest/spark-queries/  
https://iceberg.apache.org/docs/latest/spark-writes/

**When to use Apache Iceberg:**  
\- When you have large, slow-changing datasets that require efficient management of schema evolution and data versioning  
\- When you need to store historical versions of your data without duplicating large amounts of data  
\- When you require ACID transaction support for your data modifications  
\- When you need to support both batch and streaming data ingestion  
\- When you require strong table metadata management and search capabilities  
  
**When not to use Apache Iceberg:**  
\- When you have small, frequently-changing datasets that do not require schema evolution or data versioning management  
\- When you do not require ACID transaction support for your data modifications  
\- When you only require batch data ingestion and do not need to support streaming data  
\- When you do not require extensive table metadata management and search capabilities  
\- When you need to optimize for read performance over write performance.
