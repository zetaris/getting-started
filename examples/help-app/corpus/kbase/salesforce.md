---
source: kbase
url: https://kbase.zetaris.com/knowledge/salesforce
title: "Salesforce"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 4564450c93c0361bbd0da8e1d378825a36e0a29c8185054539e00ec06f558c78
---
# Salesforce

Connecting to your Salesforce environment through Zetaris will allow you to directly query on your Salesforce objects and fields.

[Salesforce Prerequisites](#salesforce-pre)

[Connect via NDP Fabric Builder](#connect_ndp)

[Connect via SQL Editor](#connect_sql)

### Salesforce Prerequisites

To connect to Salesforce, we need to establish our OAuth connection against the objects we are trying to retrieve, so with that we break the connection down into two parts

1\. Salesforce Authorisation

-   -   Once you have created your Salesforce Authorisation, you can associate it with any number of Salesforce Object Connections.

2\. Salesforce Object Connection

### Connect via NDP Fabric Builder

**Step 1:** Click the **Data Fabric Builder** icon.

**Step 2:** Under File Sources click the '+' next to Virtual File Source to launch the wizard.

![](https://kbase.zetaris.com/hubfs/image-png-Jan-31-2023-11-12-04-6014-PM.png)

**Step 3:** Enter a database name for the connection and select **'Create'**

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Jan-31-2023-11-17-50-4306-PM.png)

#### **Create the Salesforce Authorisation connection**

**Step 4:** Select the ![](https://kbase.zetaris.com/hubfs/image-png-Dec-09-2022-05-46-28-1630-AM.png) next to the newly created salesforce connection

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Jan-31-2023-11-22-54-7556-PM.png)

**Step 5:** Enter the necessary fields, as outlined in the image below, and press **'Save'.**

![](https://kbase.zetaris.com/hubfs/image-png-Jan-31-2023-11-27-43-4538-PM.png)

#### **Create the Salesforce Object Connection**

**Step 6:** Select the **'+'** icon next to your Salesforce connection, then select **'API'**.

![](https://kbase.zetaris.com/hubfs/image-png-Jan-31-2023-11-31-49-6336-PM.png)

**Step 7:** Enter the necessary fields as outlined in the screenshot below, and select **'Next'**:

_In this screenshot example below we are taking querying the 'Accounts' object in Salesforce_

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Jan-31-2023-11-40-26-8700-PM.png)

**Step 8:** Finalise connection and select **'Create'.**

The return from Salesforce is a JSON packet, which we can explode and work with further.

![](https://kbase.zetaris.com/hubfs/image-png-Jan-31-2023-11-42-58-2914-PM.png)

**Step 9:** Isolate records of interest by running a SQL command (shown below), and create a permanent view for easier access.

![](https://kbase.zetaris.com/hubfs/image-png-Jan-31-2023-11-48-07-7490-PM.png)

### Connect via SQL Editor

The syntax to connect to Salesforce purely via the SQL Editor is also shown below:

Create the Salesforce Authorisation connection:

```
UPSERT AUTH salesforce_auth REQUEST(     endpoint "https://login.salesforce.com/services/oauth2/token",     method "post",     http_encoding "urlencoded") HEADER () BODY (      grant_type "password",      username "fill with username",      password "fill with password",      client_id "fill with client_id",      client_secret "fill with client_secret");CREATE LIGHTNING DATABASE SALESFORCE DESCRIBE BY "salesforce" OPTIONS ();
```

Create the Salesforce Object connection:

```
CREATE LIGHTNING REST TABLE ACCOUNT FROM SALESFORCE REQUEST(    endpoint "https://zetaris3-dev-ed.my.salesforce.com/services/data/v52.0/query/?q=SELECT+FIELDS(ALL)+from+Account+LIMIT+200",    method "get",    response_type "json",    http_encoding "URLENCODED") HEADER (   Authorization "Bearer ${access_token}") BODY ()AUTH BY salesforce_auth;
```

Query the object

```
select a.* from(select explode(records) a from SALESFORCE.ACCOUNT)
```
