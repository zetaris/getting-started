---
source: kbase
url: https://kbase.zetaris.com/knowledge/azure-delta-lakes-adls
title: "Azure Delta Lakes - ADLS"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: c14cb2de3dc4eadbc69298bdc929070b897eafb24f8165501b5e093508caf315
---
# Azure Delta Lakes - ADLS

## This article shows how we can build high quality data lakes using Delta Lake, Databricks and ADLS Gen2 and access delta lakes data through Zetaris Lightning Platform.

### Pre-Requisites

For this demo we have used following components to generate delta files on Azure Blobs.

-   Azure SQL Database - As a Data Source
    
-   Azure Data Lake Storage Gen2 - As a Storage
    
-   Azure Data Bricks - As a ETL Tool
    
-   Azure Key Vault - To Store Secrets
    

> Please note that requested access to [![](https://github.githubassets.com/favicon.ico)](https://github.com/zetaris/Azure-Databricks/) [GITHUB](https://github.com/zetaris/Azure-Databricks) links will be required in order access files.

#### Azure SQL Database

> -   This is optional, skip this step if you already have delta data in your storage
>     
> -   You can also use any other data source as required. However make sure to have changed records (New/Updated/Deleted) in source in order to populate delta lakes.
>     

-   **Setup an Azure SQL Database:** For this article we used server less SQL Database.
    
-   **SQL Scripts:**
    
    -   Sample scripts provide here on [GitHub](https://github.com/zetaris/Azure-Databricks/tree/main/Delta%20Lakes%20-%20SQL%20Scripts)
        
    -   Connect to new Azure SQL Database created and set create & load base data to the **TestDeltaLake** table using the scripts “[01\_Create\_TestDeltaLake\_Table.sql](https://github.com/zetaris/Azure-Databricks/blob/main/Delta%20Lakes%20-%20SQL%20Scripts/01_Create_TestDeltaLake_Table.sql)“ in the repo.
        
    -   To run scripts follow the instructions provided in Databricks Notebook.
        

#### Azure Storage

-   **Create a Data Lake Storage Gen 2:** ADLSgen2 will be the Data Lake storage on top of which the Delta Lake will be created. Refer this [Delta Storage](https://docs.delta.io/latest/delta-storage.html#microsoft-azure-storage) article for other storage types i.e., Blob & ADLS Gen1.
    

**Create a Data Lake Storage Gen2 Container/Zones:** Once your Data Lake Gen2 is created, also create the appropriate containers/Zones.

-   Best practice, is breaking the Data Lake up into four zones
    
     ![](https://kbase.zetaris.com/hubfs/image-png-Dec-09-2022-04-31-47-8938-AM.png)
    
    -   **Transient** – In this zone, we rest data temporarily as it moves from the source to the persisted area, think staging. Data in this zone is periodically removed, based on the file time-to-live.
        
    -   **Persisted** – Data is kept indefinitely in its raw format and is immutable to change. This zone is often referred to as persisted staging. It provides a historical representation of raw data at any given point in time.
        
    -   **Curated** – Data in this zone has been transformed, enriched and/or aggregated to meet specific requirements.
        
    -   **Experiments** – This is a dedicated zone used by analysts and data scientists for “experiments”.
        
    
-   For this article we have created “persisted“ container to store a sample source parquet file and also used for Delta Inserts, Updates and Deletes from source.![](https://kbase.zetaris.com/hubfs/image-png-Dec-09-2022-04-34-16-6502-AM.png)
    

#### Azure Key Vault 

> This is optional, skip this step if you already have delta data in your storage

Azure Key Vault will be used to store SQL Database and Azure Service Principle secrets. Setup Key Vault account and create following secrets to use in data bricks notebook variables.

![](blob:https://zetaris.atlassian.net/758d6621-0c9c-4382-8c13-0ba995dcef61#media-blob-url=true&id=d069defa-9bd1-40b9-b1fc-655aab5b159b&collection=contentId-2735964161&contextId=2735964161&height=299&width=737&alt=)![](https://kbase.zetaris.com/hubfs/image-png-Dec-09-2022-05-12-59-6945-AM.png)

#### Azure Data Bricks 

> This is optional, skip this step if you already have delta data in your storage

Azure Data Bricks will be used to perform the ELT orchestrations and also to create and manage the Delta Lakes.

1.  Setup cluster in Databricks. _Configured “**Standard\_DS3\_v2**“ cluster for trial purposes.__![](https://kbase.zetaris.com/hubfs/image-png-Dec-09-2022-05-39-04-1133-AM.png)_
2.  Setup notebook for Delta Lakes. The following is a sample notebook created to load data to ADLS Delta Lakes - Import this sample notebook into workspace: [pocDeltaLakeADLS.dbc](https://github.com/zetaris/Azure-Databricks/blob/main/Delta%20Lakes%20-%20Notebooks/pocDeltaLakeADLS.dbc)
3.  Create Secret Scope & Update variables
    
    -   [Create Secret Scope for Azure Key Vault](https://learn.microsoft.com/en-us/azure/databricks/security/secrets/secret-scopes)
        
    -   Update variable with required values under “Set notebook variables"![](https://kbase.zetaris.com/hubfs/image-png-Dec-14-2022-05-08-13-6511-AM.png)
        
4.  Attach notebook with the cluster created in Step 1. Follow the notebook instructions to run commands.
    1.  > Make sure to run last SQL Script “[03\_Change\_Baseline\_Data.sql](https://github.com/zetaris/Azure-Databricks/blob/main/Delta%20Lakes%20-%20SQL%20Scripts/03_Change_Baseline_Data.sql)” before the instruction “**Perform Insert, Update and Delete actions if required**”.
        
    2.  Once the notebook is completed running, looking at the ADLS2 “persisted“ container, we see that a delta\_log folder along with 3 snappy compressed parquet files have been created.![](https://kbase.zetaris.com/hubfs/image-png-Dec-14-2022-05-15-17-3472-AM.png)
5.  Explore delta logs. The main commit info files are generated and stored in the Insert, Update, and Delete JSON commit files. Additionally, CRC (technique for checking data integrity) files are created. ![](https://kbase.zetaris.com/hubfs/image-png-Dec-14-2022-05-20-54-7861-AM.png)

### Establishing connection to Delta Lakes

As Delta Lake data is stored in Azure blobs in parquet format, so we can use[![](https://kbase.zetaris.com/favicon.ico)Azure Blob](https://kbase.zetaris.com/knowledge/azure-blob) file source connection on Zetaris Platform.

> Make sure your Azure Blob Container has “Public Access Level“

![](https://kbase.zetaris.com/hubfs/image-png-Dec-14-2022-05-22-38-7082-AM.png)
