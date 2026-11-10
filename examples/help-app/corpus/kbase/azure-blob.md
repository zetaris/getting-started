---
source: kbase
url: https://kbase.zetaris.com/knowledge/azure-blob
title: "Azure Blob"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: bda788e14077af3e1f8e42810bd40e6018e1bf4d9474647f5b6e2fc062a5ca23
---
# Azure Blob

## Connecting to your Azure Blob data

Azure Blob is an object storage service, used for storing data of many different types.

Through Zetaris, you are able to your data stored in Azure Blob container. These types of files we can connect are  CSV, Excel, XML, JSON, Parquet, ORC, Delta and Avro.

### How to connect to Azure Blob container

#### Using NDP Fabric Builder

Step 1: Login to the Zetaris Platform.

Step 2: Click on **NDP Fabric Builder** from the top widgets.

Step 3: Click on the **plus button** next to 'Virtual File Source'.

![click_plus_s3](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_connections/amazon_s3/click_plus_s3.png)Step 4: After clicking on plus button a pop-up will appear. Give any database name and description, then click on **'Create'**.

![create_db_blob](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_connections/azure_blob/create_db_blob.png)Step 5: The database created should now appear under the 'Virtual File Sources'. Click on the **plus button** next to the database created.

![saved_file_source_s3](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_connections/amazon_s3/saved_file_source_s3.png)

Step 6: Choose **'File Store'** and click **'Next'.**

![steps_table_s3](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_connections/amazon_s3/steps_table_s3.png)

Step 7: Provide all the connection detail as shown below, then click **'Next'.**

> NOTE: depending on what 'File Source' you select, the Meta Info that you can input will slightly differ. Below is an example of connecting to a Parquet file, and its associated parameters.

![connection_pane_blob](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_connections/azure_blob/connection_pane_blob.png)

<table style="border-collapse: collapse; table-layout: fixed; margin-left: auto; margin-right: auto; border: 1px solid #99acc2; width: 127.18%; height: 367px;"><tbody><tr style="height: 29px;"><td style="width: 19.6358%; height: 29px;"><strong>Meta Info</strong></td><td style="width: 80.3642%; height: 29px;"><strong>Value</strong></td></tr><tr style="height: 55px;"><td style="width: 19.6358%; height: 55px;">File Source</td><td style="width: 80.3642%; height: 55px;">Select desired file to connect to from CSV, Excel, XML, JSON, Parquet, ORC, Delta or Avro.</td></tr><tr style="height: 29px;"><td style="width: 19.6358%; height: 29px;">Storage</td><td style="width: 80.3642%; height: 29px;">Select&nbsp;<strong>Azure Blob File System</strong></td></tr><tr style="height: 29px;"><td style="width: 19.6358%; height: 29px;">table name</td><td style="width: 80.3642%; height: 29px;">Any name without space</td></tr><tr style="height: 81px;"><td style="width: 19.6358%; height: 81px;">file path</td><td style="width: 80.3642%; height: 81px;"><p>Example:</p><p>"wasbs://[your_container_name]@[your_azure_storage_name].blob.core.windows.net/[complete_path_to_file]/"</p><p>To get file path:</p><p><img class="hs-image-align-none" src="https://kbase.zetaris.com/hubfs/image-png-Oct-24-2023-12-31-40-2470-AM.png" loading="lazy"></p><p><img class="hs-image-align-none" src="https://kbase.zetaris.com/hubfs/image-png-Oct-24-2023-12-25-53-2840-AM.png" loading="lazy"></p></td></tr><tr style="height: 39px;"><td style="width: 19.6358%; height: 39px;"><p>access key name</p></td><td style="width: 80.3642%; height: 39px;"><p>Example:</p><p><a href="http://fs.azure.account.key.saastraning2storage.blob.core.windows.net/" data-renderer-mark="true">fs.azure.account.key.</a>[your_azure_storage_name]<a href="http://fs.azure.account.key.saastraning2storage.blob.core.windows.net/" data-renderer-mark="true">.blob.core.windows.net</a></p></td></tr><tr style="height: 75px;"><td style="width: 19.6358%; height: 75px;">parameters</td><td style="width: 80.3642%; height: 75px;"><p>inferSchema: true</p></td></tr></tbody></table>

> **Discover tables in path**: If you are unsure of which table to connect to, select the **cloud icon** next to 'file path', to discover and view all the select file types in that path.

Step 8: You are provided with a preview of the selected table/s, select **'Create'** to register.

![preview_blob](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_connections/azure_blob/preview_blob.png)

Step 9: Table appears under 'Virtual File Sources'. The nesting should be: Virtual File Source → Database → Table.

Step 10: You can click on preview button to see your data.
