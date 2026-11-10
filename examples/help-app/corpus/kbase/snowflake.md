---
source: kbase
url: https://kbase.zetaris.com/knowledge/snowflake
title: "Snowflake"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 642f97308fc93a7ada3e8fe03378e1121e293418367085cff6b9e15f9c25edd3
---
# Snowflake

Our Snowflake connection allows you to virtually connect to external Snowflake tables, and query on them, without having to physically move them into Zetaris.

[Connect via NDP Fabric Builder](#ndp_fabric_builder)

[Connect via SQL Editor](#connect_sql_editor)

[Query Pushdown](#query_pushdown)

[Connection Troubleshooting](#troubleshooting)

### Connect via NDP Fabric Builder

**Step 1:** Click the **Data Fabric Builder** icon.

**Step 2:** Under Database Sources click the '+' next to Virtual Database Source to launch the wizard.

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Nov-17-2022-05-18-30-9322-AM.png)

**Step 3:** When the GUI wizard launches accept the defaults and click **Next**.

**Step 4:** Specify the following values for the connection:

-   **Datasource:** Snowflake
-   **Data Source Name:** your database
-   **JDBC Driver Class:** leave default
-   **JDBC Url:** Expressed in the following form

```
jdbc:snowflake://{host}/?db={database}?schema={schema_name}
```

**Parameters:**  
schema: schema name  
  
![Screen Shot 2022-07-04 at 7.26.08 pm](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/Screen%20Shot%202022-07-04%20at%207.26.08%20pm.png)  
  
Click **Next**.

  

**Step 5:** Select from the list of tables retrieved and click **Next**.

**Step 6:** On the summary dialogue click **Register**.

**Step 7:** The Snowflake data source should now appear under   
  
![Screen Shot 2022-07-04 at 7.31.43 pm](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/Screen%20Shot%202022-07-04%20at%207.31.43%20pm.png)

### Connect via SQL Editor

The syntax to connect to Snowflake via SQL Editor is shown below

```
CREATE DATASOURCE SNOWFLAKE DESCRIBE BY "SNOWFLAKE" OPTIONS (  jdbcdriver "com.snowflake.client.jdbc.SnowflakeDriver",  jdbcurl "jdbc:snowflake://{host}",  username "username" ,  password "password",  db "{database}",  schema "{schema_name}");REGISTER DATASOURCE TABLES FROM SNOWFLAKE;
```

### Query Pushdown

Zetaris is able to pushdown the query to the Snowflake environment wherever it can by leverage the USING clause, in a SQL statement.

When writing the SQL statement, in the SQL Editor, you will need to reference the actual Schema name that table or tables resides inside of Snowflake. Check the below images for an example.

Image 1: Snowflake Database, Schema and Tables

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-May-17-2024-04-54-56-8879-AM.png)

Image 2: Zetaris SQL Editor referencing the Snowflake Schema and Tables, with USING statement to enable pushdown query.

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-May-17-2024-11-00-45-6322-AM.png)

In this example, since all tables in the query are refencing Snowflake, the entire query is pushed down to Snowflake, and only the result set is returned. Check the Snowflake monitoring console to check what query was run inside of Snowflake. It should be almost identical to the query mentioned in Zetaris.

### Connection Troubleshooting

Snowflake query error:

**_\- No active warehouse selected in the current session. Select an active warehouse with the 'use warehouse'_** 

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

Everything works as expected.[](https://kbase.zetaris.com/knowledge/snowflake-warehouse-error)
