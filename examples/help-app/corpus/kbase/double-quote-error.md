---
source: kbase
url: https://kbase.zetaris.com/knowledge/double-quote-error
title: "SOLVED : SELECT * FROM \"table_name\" in double quotes results in error"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 2185f443af2575283f43f855a11056d5573ac13126da9329e3f7ab26fffe6497
---
# SOLVED : SELECT * FROM "table_name" in double quotes results in error

Referencing table names in Zetaris can be done in a number of ways, see the below examples:

[Method 1 - Replace double quotes with backticks ( ' )](#method_1)

[Method 2 - Append suffix "using Virtual Data Source Name"](#method_2)

### Why error?

Zetaris' SQL dialect is reflective of what Spark SQL is capable of, which is akin to ANSI SQL. Some ANSI dialect features may not be from the ANSI SQL standard directly, but their behaviours align with ANSI SQL’s style, such as how Spark SQL uses back-ticks for identifiers and not double-quotes, as would be expected for complete ANSI SQL compliance.

-   [Spark SQL reference](https://spark.apache.org/docs/latest/sql-ref.html)

![](https://kbase.zetaris.com/hubfs/image-png-Jul-20-2022-06-04-46-59-AM.png)

### Method 1 - Replace double quotes with backticks ( \` )

![](https://kbase.zetaris.com/hubfs/image-png-Jul-20-2022-06-06-09-92-AM.png)

As can be seen, the backticks are treated as escape characters and the table name (it could be a table name with non-alpha / space characters) in it.

### Method 2 - Append suffix "using Virtual Data Source Name"

#### Step 1: Find the schema prefix

To start, you will need to prefix this with the schema name. Let's find the schema by describing the datasource. We do this with the command 

_**describe MASTER DATASOURCE <DataSourceName>**_ (see below) 

![](https://kbase.zetaris.com/hubfs/image-png-Jul-20-2022-06-18-30-66-AM.png)

The screenshot above shows that the schema name is tpch1. This will now be used in the query, as shown below:

#### Step 2: Append suffix USING

![](https://kbase.zetaris.com/hubfs/image-png-Jul-20-2022-06-20-21-03-AM.png)

So what we see is that if you use the suffix "using DatasourceName", it has the effect of passing the query exactly as it is to the source system to be executed. This would mean that if there is a schema prefix (anything other than "dbo" in Sql Server), regardless of the fact that the schema is already registered in the Zetaris metadata catalog, it will have to be explicitly stated again.

This is particularly useful if the source data table / view contains a space or some other character which is not best practice when it comes to data management standards.
