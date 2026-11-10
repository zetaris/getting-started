---
source: kbase
url: https://kbase.zetaris.com/knowledge/azure-databricks
title: "Azure Databricks"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: e061fb5dab71ce1804b633f35ad734933262a908eade3254563ffc308ad2de1d
---
# Azure Databricks

### **Prerequisite:**

> Please note that requested access to [![](https://github.githubassets.com/favicon.ico)](https://github.com/zetaris/Azure-Databricks) [GITHUB](https://github.com/zetaris/Azure-Databricks) links will be required in order access files.

#### JDBC Server Configuration

The JDBC Connector is installed with the JAR files required to Databricks via JDBC, _DatabricksJDBC<version>.jar_, and automatically registers these JARs.

When a JDBC server is configured for Databricks access, the JDBC driver class name must be specified, database URL, and client credentials just like configuring a client connection to an SQL database.

To access Databricks via JDBC, the following properties must be specified and values in the _jdbc-site.xml_ server configuration file must be entered:

| 
Property

 | 

Value 

 |
| --- | --- |
| 

jdbc.driver

 | 

com.databricks.client.jdbc.Driver

 |
| 

jdbc.url

 | 

jdbc:databricks://<databricks\_host>:<databricks\_port>

 |

> The latest Databricks JDBC connector can be downloaded from
> 
> [Download Databricks JDBC Driver 2.6.5](https://www.databricks.com/spark/jdbc-drivers-download)

1.  Start the container/service.
2.  Download the driver.
3.  Place it in /home/zetaris/server/latest/jdbc-lib.
4.  Stop container /service.

#### Databricks Configuration

1.  Setup cluster in Databricks. _Configured “**Standard\_DS3\_v2**“ cluster for trial purposes._  
    ![](https://kbase.zetaris.com/hubfs/image-png-Dec-07-2022-02-17-14-3469-AM.png)  
      
    
2.  Setup Notebook for Delta Tables.
    
    1.  The following is a [sample notebook](https://github.com/zetaris/Azure-Databricks/blob/main/Notebooks/FuelWatch.dbc) created to load data to Delta Tables - Import this sample notebook into workspace: [FuelWatch.dbc](https://github.com/zetaris/Azure-Databricks/blob/main/Notebooks/FuelWatch.dbc) ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Dec-07-2022-02-29-55-8651-AM.png)
        
3.  Attach & run notebook with the cluster created in Step 1. This step created “fuel“ database with delta tables in hive\_metastore.![](https://kbase.zetaris.com/hubfs/image-png-Dec-07-2022-02-34-34-8012-AM.png)
    
4.  Import the following [example notebook](https://github.com/zetaris/Azure-Databricks/blob/main/Notebooks/sample-DLT-pipeline-notebook.dbc) into workspace and start “Delta Live Table - sample-DLT-pipeline“ pipeline: [sample-DLT-pipeline-notebook.dbc](https://github.com/zetaris/Azure-Databricks/blob/main/Notebooks/sample-DLT-pipeline-notebook.dbc) **![](https://kbase.zetaris.com/hubfs/image-png-Dec-07-2022-02-52-51-5948-AM.png)**![](https://kbase.zetaris.com/hubfs/image-png-Dec-07-2022-02-51-55-1086-AM.png)
    
5.  Once pipeline execution completed successfully “dbt\_db“ database with delta live tables will be created in hive\_metastore.
    
    ![](https://kbase.zetaris.com/hubfs/image-png-Dec-07-2022-02-54-00-2523-AM.png)

> #### Get connection details for a cluster:
> 
> 1.  Log in to your Databricks workspace and go to the Data Science & Engineering or Databricks Machine Learning persona-based environment.
>     
> 2.  Click  Compute in the sidebar.
>     
> 3.  Choose a cluster to connect to.
>     
> 4.  Navigate to **Advanced Options**.
>     
> 5.  Click on the **JDBC/ODBC** tab.
>     
> 6.  Copy the connection details.
>     

* * *

### Establishing connection to Databricks

#### Connect via NDP Fabric Builder:

1.  Select the NDP Fabric Builder![](https://kbase.zetaris.com/hubfs/image-png-Dec-07-2022-02-55-44-2755-AM.png)
2.  Select the **+** icon to create a new datasource, then select **'Pull type**'.![](https://kbase.zetaris.com/hubfs/image-png-Dec-07-2022-02-56-42-8167-AM.png)
3.  Enter the necessary fields as outlined in the screenshot below:![](https://kbase.zetaris.com/hubfs/image-png-Dec-07-2022-02-57-16-9234-AM.png)
    
    1.  _**Required Fields:**_
        
        | 
        **Name**
        
        
        
         | 
        
        **Description**
        
        
        
         |
        | --- | --- |
        | 
        
        Data Source Name
        
         | Any name |
        | 
        
        JDBC Driver Class
        
         | 
        
        com.databricks.client.jdbc.Driver
        
         |
        | 
        
        JDBC URL
        
         | 
        
        Use the connection URL to supply connection information to the data store that you are accessing
        
        **Format** - jdbc:databricks://_\[Host\]_:_\[Port\]_
        
        **Note** - By default, Databricks uses port 443.
        
        
        
        
        
         |
        
        _**Required Properties/Parameters:**_ 
        
        | 
        **Name**
        
        
        
         | 
        
        **Description**
        
        
        
         |
        | --- | --- |
        | 
        
        AuthMech
        
         | 
        
        The Databricks JDBC Driver supports the following authentication mechanisms:
        
        -   User Name And Password
        -   OAuth 2.0
        
        _Sample connection uses User Name & Password mechanism and set the **AuthMech** property to **3**_
        
        
        
         |
        | 
        
        UID
        
         | 
        
        Appropriate username for accessing the Databricks server.
        
        By default, the connector authenticates the connection using the user name **token**.
        
         |
        | 
        
        PWD
        
         | 
        
        Password corresponding to the username provided.
        
        If UID is either set to token or left at the default value (which is also token), then set the PWD property to the Databricks token value that you want to use for authentication
        
         |
        | 
        
        ssl
        
         | 
        
        This property specifies whether the connector requires the name of the CA-issued SSL certificate to match the host name of the Databricks server.
        
        -   0: The connector requires the names to match.
            
        -   1: The connector allows the names to mismatch.
            
        
        _D__efault value: 0_
        
        
        
        
        
         |
        | 
        
        httpPath
        
         | 
        
        Azure Databricks compute resources URL
        
         |
        
        **Optional Properties/Parameters:**
        
        | 
        **Name**
        
        
        
         | 
        
        **Description**
        
        
        
         |
        | --- | --- |
        | 
        
        Schema
        
         | 
        
        By default, the connector uses the schema named default
        
         |
        | 
        
        UseNativeQuery
        
         | 
        
        This property specifies whether the connector transforms the queries emitted by applications.
        
        -   0: The connector transforms the queries emitted by applications and converts them into an equivalent form in HiveQL.
            
        -   1: The connector does not transform the queries emitted by applications, so the native query is used.
            
        -   2: The connector automatically sets this property to either 0 or 1, depending on the server capabilities.
            
        
        _Default value: 2_
        
        
        
        
        
         |
        | 
        
        transportMode
        
         | 
        
        The transport protocol to use in the Thrift layer
        
        _Default value: http_
        
        
        
        
        
         |
        
        -   Properties are case-sensitive.
            
        -   Do not duplicate properties in the connection.
        
        Refer to the [Databricks JDBC Driver Install and Configuration Guide](https://github.com/zetaris/Azure-Databricks/blob/main/Documents/Databricks%20JDBC%20Driver%20Install%20and%20Configuration%20Guide.pdf) for more properties & respective values.
        
4.  Select the tables you want or select all![](https://kbase.zetaris.com/hubfs/image-png-Dec-07-2022-04-22-30-0896-AM.png)
5.   Finalise connection.![](https://kbase.zetaris.com/hubfs/image-png-Dec-07-2022-05-03-36-8182-AM.png)![](https://kbase.zetaris.com/hubfs/image-png-Dec-07-2022-05-04-02-7709-AM.png)

#### Connect via SQL Editor:

Example connection string below with Access token authentication:

```
CREATE DATASOURCE AZURE_DATABRICKS_FW DESCRIBE BY "db" OPTIONS (    jdbcdriver "com.databricks.client.jdbc.Driver",    jdbcurl "jdbc:databricks://host:port",    username "token" ,    password "<DATABRICKS_TOKEN>",    transportMode "http",    ssl "1",    httpPath "sql/protocolv1/o/2235045490554067/1129-043453-c2r2eet6",    AuthMech "3",    UseNativeQuery "0",    Schema "fuel");REGISTER DATASOURCE TABLES FROM AZURE_DATABRICKS_FW;
```

* * *

> ### References
> 
> -   [![](https://learn.microsoft.com/favicon.ico)Configure the Databricks ODBC and JDBC drivers - Azure Databricks](https://learn.microsoft.com/en-us/azure/databricks/integrations/jdbc-odbc-bi?source=recommendations#--jdbc-driver)
>     
> -   -   Latest configuration Guide available with Databricks JDBC Connector Download
>         
>         [](https://learn.microsoft.com/en-us/azure/databricks/integrations/jdbc-odbc-bi?source=recommendations#--jdbc-driver)[Databricks JDBC Driver Install and Configuration Guide](https://github.com/zetaris/Azure-Databricks/blob/main/Documents/Databricks%20JDBC%20Driver%20Install%20and%20Configuration%20Guide.pdf)
>
