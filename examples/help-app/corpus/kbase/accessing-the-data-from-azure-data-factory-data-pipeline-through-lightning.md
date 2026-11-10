---
source: kbase
url: https://kbase.zetaris.com/knowledge/accessing-the-data-from-azure-data-factory-data-pipeline-through-lightning
title: "Azure Data Factory"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 4691adb8f3cea9ec15e7a28e62d4bff0d95d2a4fe827bbbc3478cbed7bad6876
---
# Azure Data Factory

This article articulates the access to the data in Lightning transformed using ETL Pipeline created in Azure Data Factory. As an example, an ETL pipeline is created in Azure Data factory that performs the delta operation for the customers that belong to the nation ‘Japan’ into the target table within the Raw Data Store. This data, in turn, will be accessed virtually within the Lightning platform.

### **Implementing an Azure Data factory & delta load pipeline**

‘**POCDataFactory01**’ ADF consists of a delta load pipeline. The ‘**Delta\_Load\_Pipeline**’ connects to a customer table from the ‘**Azure MSSQL**’ database & filters out the customers that belong to the nation ‘**Japan**’ & loads the data into the RDS Table ‘**customer\_japan**’ via delta load operation. If there is any new customer that belongs to Japan is entered into the source table then it will automatically get loaded into the target ‘**customer\_japan**' table.

![](https://kbase.zetaris.com/hubfs/image-png-Dec-08-2022-06-28-47-4600-AM.png)

This target ‘**customer\_japan**' table is connected to the Lightning environment virtually & can be used for further analysis/operations. The updated data will automatically get refreshed & the object doesn’t need to be refreshed manually.

![](https://kbase.zetaris.com/hubfs/image-png-Dec-08-2022-06-29-14-4062-AM.png)
