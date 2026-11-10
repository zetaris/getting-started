---
source: kbase
url: https://kbase.zetaris.com/knowledge/teradata
title: "Teradata"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 17233745595f239cc1b1892489705cd156b0755647d0063b9724c68e447da854
---
# Teradata

Our Teradata connection allows you to virtually connect to your on-premise or cloud Teradata platform, and live query its tables.

[Connect via NDP Fabric Builder](#ndp_fabric_builder)

[Connect via SQL Editor](#connect_sql_editor)

[Connection Troubleshooting](#troubleshooting)

### Connect via NDP Fabric Builder

**Step 1:** Click the **Data Fabric Builder** icon.

**Step 2:** Under Database Sources click the '+' next to Virtual Database Source to launch the wizard.

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Nov-17-2022-05-18-30-9322-AM.png)

**Step 3:** When the GUI wizard launches accept the defaults and click **Next**.

**Step 4:** Specify the following values for the connection:

-   **Datasource:** Teradata
-   **Data Source Name:** your database
-   **JDBC Driver Class:** leave default
-   **JDBC Url:** Expressed in the following form

```
jdbc:teradata://{host}/DATABASE={database},DBS_PORT={port_number}
```

Default Teradata port is 1025

**Required Parameters:**  
DATABASE: {database\_name}

DBS\_PORT: {port\_number}

  
  
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

Everything works as expected.
