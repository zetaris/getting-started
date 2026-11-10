---
source: kbase
url: https://kbase.zetaris.com/knowledge/how-to-connect-to-minio-s3
title: "How to connect to MinIO S3"
kind: how-to
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 7186f32b45813445353dfc8ec1fa4b367db231eb6350a930ee3da3fa0237ee0b
---
# How to connect to MinIO S3

## This article explains the steps to be followed to connect to a MinIO S3 from Zetaris

1\. Login to Zetaris and on the left hand side pane, under Virtual File Sources click '+' to create a new file source

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Jul-10-2025-05-20-48-2904-AM.png)

2\. Provide a name that uniquely identifies the file source (e.g. format: minios3\_data) along with description and any optional connectivity parameters.

![image-20250625-011331.png](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Jul-10-2025-05-19-41-6767-AM.png)

3\. You will now be able to see the created file source under Virtual File Sources. To add a table to this, click on '..." next to the file source and select Create Table

![image-20250625-011447.png](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Jul-10-2025-05-19-24-2100-AM.png)

4\. Select the Source Type as File Store and proceed to Step 2

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Jul-10-2025-05-19-07-5761-AM.png)

5\. Provide all the required details to successfully establish a connection to the MinIO S3 source:

-   **Filesource** : Choose the relevant data source from the list of  available options
    
-   **Storage** : This will be Amazon S3
    
-   **table Name** : Provide the name of the table to be created
    
-   **file path** : Specify the path where the file is currently  located in MinIO
    
-   **endpoint** : Provide the api endpoint to  connect to the MinIO source
    
-   **access** **key** : Your MinIO username
    
-   **security** **key** : Your MinIO password
    
-   **delimiter** : This will be ',' by default
    

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Jul-10-2025-05-18-29-4030-AM.png)

6\. In the Parameters section, it is important to add the below parameter for successful MinIO connectivity :

-   Add **useS3PathStyleAccess** and set it to **true**
    
-   You may optionally add other required parameters such has whether your data contains header, etc as per the data source  
    ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Jul-10-2025-05-17-24-5070-AM.png)

7\. Once all the details have been provided and when you click Next, the details are validated and if the connection is successful, you should be able to see a preview of the records from the provided MinIO source.

![image-20250625-012318.png](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Jul-10-2025-05-16-05-5027-AM.png)

8\. Click Create to register your MinIO source table and you will now be able to view the created table under the MinIO S3 file source. 

**Ðata Source Registration via Command**

CREATE LIGHTNING FILESTORE TABLE web\_site FROM TPCDS\_MINIO FORMAT PARQUET OPTIONS (

    PATH "s3a://api-bucket/TPCDS\_DB/web\_site/",

   s3Endpoint [https://minio-api.cluster-us-south-1-gx3-16-5d5bdf2a4007deba9518ed06620558de-0000.us-south.containers.appdomain.cloud](https://minio-api.cluster-us-south-1-gx3-16-5d5bdf2a4007deba9518ed06620558de-0000.us-south.containers.appdomain.cloud) ,

   inferSchema "true",

    header "true",

    useS3PathStyleAccess "true",

    AWSACCESSKEYID "admin",

    AWSSECRETACCESSKEY "admin"

);
