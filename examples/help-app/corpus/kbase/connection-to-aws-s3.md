---
source: kbase
url: https://kbase.zetaris.com/knowledge/connection-to-aws-s3
title: "AWS S3"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: cce2812b7d2a131a964dbc3aaa36272540c37ed422c89c60d8b9a919405878a3
---
# AWS S3

## This article covers how to connect Zetaris to AWS S3

1.  Login to the Zetaris platform
2.  Click on **NDP fabric builder** icon in the navigation located at the top left side of the screen  
    ![](https://kbase.zetaris.com/hubfs/image-png-Nov-03-2022-11-06-09-6548-PM.png)
3.  Click ![](https://kbase.zetaris.com/hubfs/image-png-Nov-02-2022-03-42-50-6541-AM.png) next to **Virtual File Sources** to launch the connection dialog.  
    
    ![](blob:https://zetaris.atlassian.net/0d24e5e2-576d-49f2-aa7d-e8fec74186f7#media-blob-url=true&id=8f179ff8-b859-4024-b810-3917d6df37f1&collection=contentId-2614591497&contextId=2614591497&mimeType=image%2Fpng&name=image-20220329-234225.png&size=56107&height=216&width=1743&alt=)![](https://kbase.zetaris.com/hubfs/image-png-Nov-03-2022-11-05-48-4959-PM.png)
    
4.  A pop-up window will appear. Please specify the following values then select **Create**: 
    1.  Database Name
    2.  Description
    3.  Parameters   
        ![](https://kbase.zetaris.com/hubfs/image-png-Nov-03-2022-11-07-01-1623-PM.png)
5.  Your new database virtual file source created in step 4 will appear under the **virtual file source**. ![](https://kbase.zetaris.com/hubfs/image-png-Nov-03-2022-11-07-18-5068-PM.png)
6.  Click ![](https://kbase.zetaris.com/hubfs/image-png-Nov-02-2022-03-42-50-6541-AM.png) next to the new database file source created in the previous step.  
    
7.  A pop-up will appear. **On Step 1**, Choose **File store** option and then select **next**.  
    
    ![](blob:https://zetaris.atlassian.net/b778f1f6-3b07-46ce-bd38-ec97ecb3e37a#media-blob-url=true&id=adefcb30-42cd-4608-96ae-1d688543c2a8&collection=contentId-2614591497&contextId=2614591497&mimeType=image%2Fpng&name=image-20220330-011913.png&size=27868&height=434&width=1199&alt=)![](https://kbase.zetaris.com/hubfs/image-png-Nov-03-2022-11-09-54-2289-PM.png)
    
8.  **Upon Step 2** Please provide the following connection details below:  
    1.  **File source:** Choose your **File Source Type**
    2.  **Storage:** Choose Amazon S3 
    3.  **Table name:** Provide any name (without spaces - use underscore)
    4.  **File path:** Provide your s3 path (eg. s3a://zetaris-lightning-test/csv-data/tpc-h/customer.csv)
    5.  **Access key:** Provide your access key
    6.  **Security key:** Provide your security key
    7.  **Delimiter:** “,” ( the delimiter in CSV)
    8.  **Parameters**
        1.  header - true
        2.  inferSchema - true (Optional)![](https://kbase.zetaris.com/hubfs/image-png-Nov-03-2022-11-10-17-8967-PM.png)
9.  Once all the details are filled click **next** to proceed.
10.  **Step 3** will provide a table preview of your data. Once satisfied, select **Create.**  
    
    ![](blob:https://zetaris.atlassian.net/ecb1a7f3-23f5-4d68-87a6-852c04e4227f#media-blob-url=true&id=d8471b58-f109-4227-bfcb-588a46d39fe1&collection=contentId-2614591497&contextId=2614591497&mimeType=image%2Fpng&name=image-20220330-003000.png&size=39098&height=542&width=696&alt=)![](https://kbase.zetaris.com/hubfs/image-png-Nov-03-2022-11-11-00-7663-PM.png)
    
11.  The newly created table will appear under your file source database.  
    ![Capture1](https://kbase.zetaris.com/hs-fs/hubfs/Capture1.png)
12.  To view the contents of your table click on the preview button ![preview](https://kbase.zetaris.com/hs-fs/hubfs/preview.png)  
    ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Nov-03-2022-11-11-25-7668-PM.png)
