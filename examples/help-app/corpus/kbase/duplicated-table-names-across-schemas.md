---
source: kbase
url: https://kbase.zetaris.com/knowledge/duplicated-table-names-across-schemas
title: "How to handle duplicated table names across schemas"
kind: how-to
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: f2267dbaf8e783c9b35cb954c08932b44f259fe17130cf7835d303c9c0f81b03
---
# How to handle duplicated table names across schemas

Often when we connect to different schemas in a database, we will have tables, for numerous reasons, with the same name sitting in different schemas.

When we register a data source, by default, we name the table only, so if you have not specified a schema in the database connection statement, at face value it would appear that duplicated tables are showing.

To address this, we add the following detail either in the datasource connection wizard or the datasource connection sql statement

```
schema_prepended_table "true"
```

This will add the schema name, to the table name. In the below screen shot example, tpch and tpch1 are the schemas captured, and have been prepended to the table name.

![](https://kbase.zetaris.com/hubfs/image-png-Aug-18-2022-01-59-15-49-AM.png)
