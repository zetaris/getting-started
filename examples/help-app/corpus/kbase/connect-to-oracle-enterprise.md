---
source: kbase
url: https://kbase.zetaris.com/knowledge/connect-to-oracle-enterprise
title: "Oracle Enterprise"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 9e8412db9f6d71ed995e868401b53dd753ff083bbede62a288ae973fdbd42973
---
# Oracle Enterprise

This guide will aide in establishing a connection to Oracle Enterprise both on-prem and in a managed service, such as Amazon RDS.

[Connect via NDP Fabric Builder](#oracle_wizard)

[Connect via SQL Editor](#oracle_sql)

### Connect via NDP Fabric Builder

**Step 1:** Select the NDP Fabric Builder

**Step 2:** Select the "+", for Create Datasource, then select "Pull"

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Oct-20-2022-10-36-12-72-PM.png)

**Step 3:** Enter the necessary fields as outlined in the image below:

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Oct-20-2022-10-37-43-47-PM.png)

**Required Fields:**

\- Data Source Name

\- JDBC Driver Class

\- JDBC URL

\- Username

\- Password

**Optional Fields:**

\- Schema

#### JDBC URL Format:

```
jdbc:oracle:thin:@//{hostname}:{port}/{SID}
```

**Step 4:** Select the tables you want or select all. Finalise connection

### Connect via SQL Editor

Example connection string below

```
CREATE DATASOURCE ORACLE OPTIONS (  jdbcdriver "oracle.jdbc.OracleDriver",  jdbcurl "jdbc:oracle:thin:@//database-1.ckh4ncwbhsty.ap-southeast-2.rds.amazonaws.com:1521/ORCL",  username "admin",  password "password",  schema "ADMIN");REGISTER DATASOURCE TABLES FROM ORACLE;
```
