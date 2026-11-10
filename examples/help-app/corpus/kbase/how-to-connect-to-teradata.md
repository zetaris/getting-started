---
source: kbase
url: https://kbase.zetaris.com/knowledge/how-to-connect-to-teradata
title: "How to connect to Teradata"
kind: how-to
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 43b54249b5ed1925337c9895f0720b34fb5c0db1af8806479dad106d4710dfe4
---
# How to connect to Teradata

## This article explains the steps to be followed to connect to a Teradata DB from Zetaris

1\. Login to Zetaris and on the left hand side pane, under Virtual Database Sources click '+' to create a new file source

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Jul-21-2025-08-34-40-5340-AM.png)

2\. Select Next and you will see the Create Data Source modal on the screen. Select 'TERADATA' from the dropdown and fill in the details and select Next

Data Source Name (mandatory): The name you want to give to this data source  
Description (optional): A brief description of the data source

JDBC Driver Class: com.ncr.teradata.TeraDriver

JDBC URL: Enter your Teradata JDBC URL in the following format -jdbc:teradata://<hostname>:<port>/databaseinstance

Username (optional): Username required to connect to teradata

Password(optional): Username required to connect to teradata

Fetch Size (mandatory): leave it to default at 3000 or change as necessary

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Jul-21-2025-08-40-25-2729-AM.png)

3\. If your connection details are correct, you will now be able to see the list of tables. Select the required tables for this connection and select Next.

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Jul-21-2025-08-42-33-8744-AM.png)

4\. Review the tables and select Register to complete the Teradata connectivity from Zetaris.

Once registered, refresh the Virtual Database Sources and you will be able to see the teradata data source under the registered name. 

**Data Source Registration via Command  
**

CREATE DATASOURCE TERADATA\_3 DESCRIBE BY "TERADATA\_ADMIN" OPTIONS (

jdbcdriver "com.teradata.jdbc.TeraDriver",

jdbcurl "jdbc:teradata://teradata-zetaris.australiacentral.cloudapp.azure.com/DATABASE=TPCDS\_DB,DBS\_PORT=1025",

username "<user\_name>" ,

password "XXX"

);

REGISTER DATASOURCE TABLES FROM TERADATA\_3;
