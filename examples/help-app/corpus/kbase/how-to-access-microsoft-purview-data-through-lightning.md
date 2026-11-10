---
source: kbase
url: https://kbase.zetaris.com/knowledge/how-to-access-microsoft-purview-data-through-lightning
title: "Microsoft Purview"
kind: how-to
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 58521992389bb8c21feb691e6b3d9cc06a572711362400d83c36668f90d0b9b5
---
# Microsoft Purview

## This article shows how to access Microsoft Purview data through Zetaris Lightning Platform

### Pre-Requisites

#### Microsoft Purview setup

1.  Create a _purview account_ in azure. Refer [_Create an Azure Purview account in the Azure portal_](https://docs.microsoft.com/en-us/azure/purview/create-catalog-portal) article for the details on creating a purview account.
2.  Create sample collection under Microsoft Purview Data Map. Refer [![](https://learn.microsoft.com/favicon.ico)How to create and manage collections - Microsoft Purview](https://learn.microsoft.com/en-us/azure/purview/how-to-create-and-manage-collections) article for the details on creating a collection.![](https://kbase.zetaris.com/hubfs/image-png-Dec-09-2022-05-42-07-2868-AM.png)
3.  Create a s_ervice principal_ which will be used to access the API. Refer [_Create a Service Principal_](https://docs.microsoft.com/en-us/azure/purview/tutorial-using-rest-apis#create-a-service-principal-application) article for the details on creating the service principal.
4.  Grant the service principal _Data Curator_ role for the purview account you created in **Step 1**. Refer [_Grant “Purview Data Curator” Role_](https://docs.microsoft.com/en-us/azure/purview/tutorial-using-rest-apis#configure-your-catalog-to-trust-the-service-principal-application) article for details on how to grant the role.![](https://kbase.zetaris.com/hubfs/image-png-Dec-09-2022-05-43-25-2661-AM.png)
5.  Collect the following information from Service Principle and Microsoft Purview account which you will need in the next steps –

-   -   _Tenant id_
        
    -   _Service principal client id_
        
    -   _Service principal client secret_
        
    -   _Microsoft Purview account name_
        

> Microsoft Purview account setup is optional, skip this step if you already have Purview account and make sure you have required information as specified in Step 5 to connect API through Zetaris Platform.

### Establishing connection to Microsoft Purview

Once Microsoft Purview account is ready, we can connect Data Catalogs through Zetaris Lightning Platform via the REST API.

#### Connect via NDP Fabric Builder

1.  Select the NDP Fabric Builder   
    ![](https://kbase.zetaris.com/hubfs/image-png-Dec-09-2022-05-44-56-2470-AM.png)
2.  Select the ![](https://kbase.zetaris.com/hubfs/image-png-Dec-09-2022-05-46-50-5835-AM.png) **icon** next to **virtual file sources**, then create "MICROSOFT\_PURVIEW" source![](https://kbase.zetaris.com/hubfs/image-png-Dec-09-2022-05-45-57-2295-AM.png)
3.  Select the ![](https://kbase.zetaris.com/hubfs/image-png-Dec-09-2022-05-46-28-1630-AM.png) icon next to the MICROSOFT\_PURVIEW and then enter the necessary fields outlined in the below image for API OAuth Management.![](https://kbase.zetaris.com/hubfs/image-png-Dec-09-2022-05-47-17-6596-AM.png)
4.  Select the ![](https://kbase.zetaris.com/hubfs/image-png-Dec-09-2022-05-46-50-5835-AM.png) **icon** next to the **MICROSOFT\_PURVIEW** created data source and then select **"API"![](https://kbase.zetaris.com/hubfs/image-png-Dec-09-2022-05-48-12-7354-AM.png)**
5.  Enter the necessary fields as outlined in the screenshot below:![](https://kbase.zetaris.com/hubfs/image-png-Dec-09-2022-05-58-49-7769-AM.png)
6.  Finalise connection.![](https://kbase.zetaris.com/hubfs/image-png-Dec-09-2022-05-49-35-1801-AM.png)
7.  Explore data![](https://kbase.zetaris.com/hubfs/image-png-Dec-09-2022-05-50-58-8190-AM.png)

#### Connect via SQL Editor

Example connection string below with Access token authentication:

```
UPSERT AUTH purview_auth REQUEST(     endpoint "https://login.microsoftonline.com//oauth2/token",     method "post",     http_encoding "urlencoded") HEADER () BODY (      grant_type "client_credentials",      resource "https://purview.azure.net",      client_id "",      client_secret "");CREATE LIGHTNING DATABASE MICROSOFT_PURVIEW DESCRIBE BY "MP" OPTIONS ();CREATE LIGHTNING REST TABLE ASSETS FROM MICROSOFT_PURVIEW REQUEST(    endpoint "https://.catalog.purview.azure.com/api/search/query?api-version=2022-03-01-preview",    method "POST",    http_encoding "JSON",    response_type "json") HEADER (   Authorization "Bearer ${access_token}",   Content-Type "application/json") BODY (    limit "10",    offset "0"    )AUTH BY purview_auth;select a.collectionId,a.assetType,a.entityType,a.name,a.objectType,a.glossaryType,a.id,a.createBy,a.createTime,a.updateBy,a.updateTimefrom(select explode(value) a from MICROSOFT_PURVIEW.ASSETS)
```

* * *

#### References

-   [![](https://learn.microsoft.com/favicon.ico)Quickstart: Create a Microsoft Purview (formerly Azure Purview) account - Microsoft Purview](https://learn.microsoft.com/en-us/azure/purview/create-microsoft-purview-portal)
    
-   [![](https://learn.microsoft.com/favicon.ico)How to create and manage collections - Microsoft Purview](https://learn.microsoft.com/en-us/azure/purview/how-to-create-and-manage-collections)
    
-   [![](https://learn.microsoft.com/favicon.ico)How to use REST APIs for Microsoft Purview Data Planes - Microsoft Purview](https://learn.microsoft.com/en-us/azure/purview/tutorial-using-rest-apis#create-a-service-principal-application)
    
-   [![](https://learn.microsoft.com/favicon.ico)Microsoft Purview Resource Provider Rest API](https://learn.microsoft.com/en-us/rest/api/purview/)
