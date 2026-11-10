---
source: kbase
url: https://kbase.zetaris.com/knowledge/ocient-db
title: "Ocient"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 24b4fa881eda01766f7a7d5e649efe6649771270df872ec1b83008abc2e5cb49
---
# Ocient

## Connect and register your Ocient DB databases and tables

The Ocient connector allows you to virtually connect and register your Ocient databases, and then query on them, manage them and federate them, without having to physically move them into a central location.

[Connect Ocient via NDP Fabric Builder](#ndp_fabric_builder)

[Connect Ocient via SQL Editor](#connect_sql_editor)

  

### Connect Ocient via NDP Fabric Builder

**Step 1:** Click the **Data Fabric Builder** icon.

**Step 2:** Under Database Sources click the '+' next to Virtual Database Source to launch the wizard.

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Nov-26-2024-12-30-57-5626-AM.png)

**Step 3:** When the GUI wizard launches accept the defaults and click **Next**.

**Step 4:** Specify the following values for the connection:

-   **Datasource:** Other JDBC
-   **Data Source Name:** any\_datasource\_name
-   **JDBC Driver Class:** com.ocient.jdbc.JDBCDriver
-   **JDBC Url:** _Expressed in the following form_

```
jdbc:ocient://{host}:{port}/{database}
```

Default Port: 4050

-   **Parameters:**  
    schema: {schema name}

_**Example Ocient DB Connection**_  
![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Nov-26-2024-12-14-01-1013-AM.png)  
Click **Next**.

**Step 5:** Select from the list of tables retrieved and click **Next**.

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Nov-26-2024-12-23-03-7671-AM.png)

**Step 6:** On the summary dialogue click **Register**.

**Step 7:** The Ocient Database source should now apppear under the Virtual Database Sources on the left hand panel

### Connect Ocient via SQL Editor

The syntax to connect to Ocient via SQL Editor is shown below

```
CREATE DATASOURCE OCIENT DESCRIBE BY "OCIENT Database" OPTIONS (  jdbcdriver "com.ocient.jdbc.JDBCDriver",  jdbcurl "jdbc:ocient://{host}:{port}/{database}",  username "{username}" ,  password "{password}",  schema "{schema name}");REGISTER DATASOURCE TABLES FROM OCIENT;
```

Default Port: 4050
