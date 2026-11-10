---
source: kbase
url: https://kbase.zetaris.com/knowledge/force-a-query-to-be-executed-in-the-source-environment
title: "Force a query to be executed in the source environment"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 239c633170e019b51a3ac6478eb7b59e17f1ce8ad866850194396062f8f83a68
---
# Force a query to be executed in the source environment

## In order to take advantage of the power of the source data environment (Snowflake / Oracle / Sql Server, etc.), there is an option to force the query to be executed in the source environment.

Consider the following logical data model below:

![](https://kbase.zetaris.com/hubfs/image-png-Aug-22-2022-11-59-10-88-PM.png)

If we wanted to extract the top supplier per country for any given product set, we would write an analytical query. Now let's assume that there are:

-   1 trillion Order Line items,
-   100 billion orders across
-   20 countries, servicing
-   20 million customers.

With numbers like this, it is **imperative** that we only retrieve the summary dataset and **DO NOT** join the tables inside Zetaris (on Spark). Thus when we write a query, it absolutely needs to run entirely on the source data and return just the dataset. In Zetaris, this is achieved with the "**using <DataSourceName>** " suffix operator.

### Method

Inspect the datasource for this query to be run against and determine if there is a schema. This is achieved in the Sql command editor with:

```
describe master datasource <DataSourceName> 
```

![](https://kbase.zetaris.com/hubfs/image-png-Aug-23-2022-12-12-07-08-AM.png)

Note the schema name. In the case of the example above, it is "tpch1". This schema prefix will need to be added to each table / view name from the source environment. 

![](https://kbase.zetaris.com/hubfs/image-png-Aug-23-2022-12-18-13-41-AM.png)

### Limitations

This does not work on subqueries or CTE's (Common Table Expressions), as these are usually not the last pieces of code written in a query. If the example above, you will see that the using operator is the very last thing to be specified. If any other code is found after this, it will cause the query to fail.

You cannot pass parameters to this query. So if this is a pipeline object, there is no way to dynamically filter the SQL using a dateset from a pervious operation.
