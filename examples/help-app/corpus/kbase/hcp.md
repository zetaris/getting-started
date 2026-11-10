---
source: kbase
url: https://kbase.zetaris.com/knowledge/hcp
title: "Hitachi Content Platform (HCP) on S3"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 36c09be48661d5981f61b22bb9a328d822b67d1e2c9c21acba4c3d666d7438ad
---
# Hitachi Content Platform (HCP) on S3

Our HCP connection allows you to connect directly to your HCP S3 object store, allowing you to query over it using SQL or Spark, with external connection possibilities too.

[Create a standard file connection](#standard_file_connect)

[Create a lakehouse connection](#lakehouse_connect)

#### Standard file connection

**Step 1:** Click the **NDP Fabric Builder** icon.

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-May-16-2024-12-13-08-0873-PM.png)

**Step 2:** Click the **'+'** next to **Virtual File Sources** to launch the wizard

**Step 3:** Name your data source e.g. HCP\_FILES

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-May-16-2024-03-13-00-5765-PM.png)

**Step 4:** Click **Create**

**Step 5:** Click the **'+'** next to the newly created Virtual File Source container

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-May-16-2024-03-12-12-5609-PM.png)

**Step 6:** Select **'File Store'** and click **Next**

**Step 7: Complete the form**

1.  **File source:** Choose your **File Source Type**
2.  **Storage:** Choose Amazon S3 
3.  **Table name:** Provide any name (without spaces - use underscore)
4.  **File path:** Provide your s3 path (eg. s3a://zetaris-lightning-test/csv-data/tpc-h/customer.csv)
5.  **Endpoint:** <accountname>.hitachivantara.com
6.  **Access key:** <awsAccessKeyId>
7.  **Security key:** <awsSecretAccessKey>
8.  **Delimiter:** (only or CSV file types)
9.  **Parameters**
    1.  header - true
    2.  inferSchema - true (Optional)

**Step 8**: Click **Next**

**![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-May-16-2024-03-23-34-6269-PM.png)**

**Step 9:** Click **Create**

#### Lakehouse connection

**Step 1:** Click the **NDP Fabric Builder** icon.

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-May-16-2024-12-13-08-0873-PM.png)

**Step 2:** Click the **'+'** next to **Data Lake Warehouse** Source to launch the wizard.

**Step 3:** Complete the necessary fields as shown below

**Name:** <AnyName> (all one word)

**Storage:** Select **AWS S3**

**Storage Path:** s3a://path/to/lakehouse

**NOTE:** For Storage Path, a directory/folder must be created inside the HCP bucket, and called in the string

**awsAccessKeyId:** <awsAccessKeyId>

**awsSecretAccessKey:** <awsSecretAccessKey>

**s3Endpoint:** <accountname>.hitachivantara.com

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-May-16-2024-12-07-09-2565-PM.png)

**Step 4:** Click **Create**
