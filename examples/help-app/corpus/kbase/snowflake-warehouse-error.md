---
source: kbase
url: https://kbase.zetaris.com/knowledge/snowflake-warehouse-error
title: "Snowflake query error: No active warehouse selected in the current session. Select an active warehouse with the 'use warehouse' command."
kind: sql-reference
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: a17a72e7d6dd366459afcea6d609a3c9b02ad59af8f9e2d2c8dc80181a46c31d
---
# Snowflake query error: No active warehouse selected in the current session. Select an active warehouse with the 'use warehouse' command.

## In order to run a query against Snowflake, a warehouse must be employed. If quering anything other than the default demo data, the user will no doubt be given a login and particular role, to protect the source data from security violations

Let's assume that the datasource connection already exists. 

![](https://kbase.zetaris.com/hubfs/image-png-3.png)

And we now want to see the metadata of the connection. In this case, we are looking at the table **TEST01** in the database **ZETARIS01**, schema **PIPELINE .** Click the table name to expand the metadata high level contents.

![](https://kbase.zetaris.com/hubfs/image-png-4.png)

However, we land up with this result. 

![](https://kbase.zetaris.com/hubfs/image-png-Jun-06-2022-07-16-05-68-AM.png)

Upon inspection, we find that the connection is complaining about not being assigned a warehouse, even though the datasource connection explicitly states a warehouse and there is a default warehouse to be used for the particular user in Snowflake.

![](https://kbase.zetaris.com/hubfs/image-png-Jun-06-2022-07-17-17-84-AM.png)

![](https://kbase.zetaris.com/hubfs/image-png-Jun-06-2022-07-17-25-86-AM.png)

Let's go take a look at Snowflake to see what the problem could be.

![](https://kbase.zetaris.com/hubfs/image-png-Jun-06-2022-07-17-59-01-AM.png)

So far this looks fine. The user **ZDEMO** has been specified in the datasource connection. This user has the default role **SALES** and the deault warehouse **WH\_XSMALL** assigned to it. What could the matter be?

![](https://kbase.zetaris.com/hubfs/image-png-Jun-06-2022-07-19-13-15-AM.png)

Could it be the warehouse name? 

Nope! All good on this front.

![](https://kbase.zetaris.com/hubfs/image-png-Jun-06-2022-07-19-46-92-AM.png)

What is required is for the role that the user connects with to be able to actually use the warehouse. This is not obvious, but it a step that if missing will trip you up. The warehouse was created by the **SYSADMIN** role so the useage of the warehouse needs to be granted by that role or a superior role (in Snowflake, **ACCOUNTADMIN role** is the most senior role and is used to create accounts). So what happens once the usage privilege on the warehouse is granted?

![](https://kbase.zetaris.com/hubfs/image-png-Jun-06-2022-07-22-47-67-AM.png)

Everything works as expected.
