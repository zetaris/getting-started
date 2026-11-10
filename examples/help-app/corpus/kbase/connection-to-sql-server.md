---
source: kbase
url: https://kbase.zetaris.com/knowledge/connection-to-sql-server
title: "Microsoft SQL Server"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 13ed7e74bbd3a73139c79bd18e552713b32b8b293a1a7b2faca303345d263494
---
# Microsoft SQL Server

## Steps to connect to Microsoft SQL Server

1.  Steps to make connection to MSSQL Database:
2.  Login to the Zetaris platform
3.  Click on **NDP Fabric Builder**.  
      
    ![](https://kbase.zetaris.com/hubfs/image-png-Nov-02-2022-03-44-06-4810-AM.png)
4.  Click ![](https://kbase.zetaris.com/hubfs/image-png-Nov-02-2022-03-43-39-2910-AM.png) next to Virtual Database Sources to launch the connection dialog.  
      
    ![](https://kbase.zetaris.com/hubfs/image-png-Nov-02-2022-03-43-55-1843-AM.png)
5.  On **step 1** click **Next**.  
      
    ![](https://kbase.zetaris.com/hubfs/image-png-Nov-02-2022-03-44-25-7643-AM.png)  
      
    
6.  Upon reaching **Step 2** Please provide the following connection details below:  
    1.  **Datasource:** MS SQL
    2.  **Data source name:** _Provide a name_
    3.  **Description:** _Provide a description_
    4.  **JDBC server class:** com.microsoft.sqlserver.jdbc.SQLServerDriver
    5.  **JDBC URL:** jdbc:sqlserver://hostname:portname/databaseinstance
    6.  **Username:** _Your MS SQLconnection username_
    7.  **Password:<REDACTED> _Your MS SQLconnection password_
    8.  **Parameters:** if you have a specific schema to connect to
        1.  eg. schema \[your schema name\] ![](https://kbase.zetaris.com/hubfs/image-png-Nov-03-2022-11-12-23-8861-PM.png)
7.  Once all the details are filled select **next** to proceed.
8.  You will see a list of tables associated with the database and schema as part of **Step 3**.
9.  Select all the tables you want to pull in and then select **next**.  
    
    ![](https://kbase.zetaris.com/hubfs/image-png-Nov-03-2022-11-12-35-3097-PM.png)![](blob:https://zetaris.atlassian.net/7e80a859-556a-4b5c-b696-c5c2f09195af#media-blob-url=true&id=1212ef71-6e53-4a54-a075-855bc97ede37&collection=contentId-2614755344&contextId=2614755344&mimeType=image%2Fpng&name=image-20220330-010142.png&size=25863&height=544&width=605&alt=)
    
10.  A summary of the data source to be crated will be provided as part of **Step 4.** Once satisfied with the summary select **Register.**  
    
    ![](https://kbase.zetaris.com/hubfs/image-png-Nov-03-2022-11-13-04-4401-PM.png)![](blob:https://zetaris.atlassian.net/1090a514-0975-438c-95a0-8354c861a1bf#media-blob-url=true&id=96bbfbd9-b377-476c-ad25-f3660ab5c2e8&collection=contentId-2614755344&contextId=2614755344&mimeType=image%2Fpng&name=image-20220330-010438.png&size=35025&height=617&width=601&alt=)
    
11.  Your newly created virtual database source will appear under **virtual database sources.**![Capture-3](https://kbase.zetaris.com/hs-fs/hubfs/Capture-3.png)
12.  To view the contents of your table click on the preview button ![preview](https://kbase.zetaris.com/hs-fs/hubfs/preview.png)  
    
    ![](blob:https://zetaris.atlassian.net/9f07ec90-d8d5-4b40-a7bf-61318ebed9ac#media-blob-url=true&id=63649252-1705-4c41-b493-d07fc4e46260&collection=contentId-2614755344&contextId=2614755344&mimeType=image%2Fpng&name=image-20220330-010553.png&size=179770&height=632&width=1901&alt=)
