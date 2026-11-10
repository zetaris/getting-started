---
source: kbase
url: https://kbase.zetaris.com/knowledge/amazon-s3-storage
title: "How to connect to Amazon S3 (with session token)"
kind: how-to
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: db9433d1e582c019a551b9ed5de18161f13a63554e50b1c512e3f9c379b3ec77
---
# How to connect to Amazon S3 (with session token)

## This article explains the steps to be followed to connect to a Amazon S3 storage from Zetaris

1\. Login to Zetaris and on the left hand side pane, under Data Lake Warehouses click '+' to create a new file source

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Jul-21-2025-09-53-01-2192-AM.png)

2\. Provide a name that uniquely identifies the file source (e.g. format: AmazonS3\_data) and enter the required S3 storage parameters .

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Jul-21-2025-09-57-29-1213-AM.png)

3\. Once you click Create, if the entered details are correct, you will be able to successfully connect to the S3 storage bucket.

4\. When you refresh the newly created data lake warehouse, you will now be able to see all the objects form the storage.

**Datasource Registration via Command  
**

CREATE LIGHTNING FILESTORE TABLE store\_sales FROM TPCDS\_S3 FORMAT PARQUET OPTIONS (

    PATH "s3a://zetaris-emr-test/tpcds\_db/store\_sales/",

    inferSchema "true",

    header "true",

    AWSACCESSKEYID "XXX",

    AWSSECRETACCESSKEY "<AWS_SECRET_ACCESS_KEY>",

    awsSessionToken "XXX"

);
