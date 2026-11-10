---
source: kbase
url: https://kbase.zetaris.com/knowledge/aws-glue
title: "AWS Glue metastore"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 7a1e5973f8169724c5b239c1ba3c731e426aa995aa5435d62f9198612bd02ea6
---
# AWS Glue metastore

## This article takes you through connecting Zetaris to AWS Glue.

**Assumptions:**

1.  Your application is already running in AWS Kubernetes
2.  The Primary AWS role has already been created and attached to service account.

**Steps for connecting to Primary AWS GLUE:**

1.  Login to the Zetaris platform.
    
2.  Select the **NDP fabric Builder** at the top of the screen.
    
3.  Select the plus icon button next to **“AWS Glue”** section of the data source panel on the left side of the screen.
    
    ![](https://kbase.zetaris.com/hubfs/image-png-Oct-07-2022-01-26-45-29-AM.png)
4.  You will now see the following window to create a new **AWS Glue Source**.  
    ![](https://kbase.zetaris.com/hubfs/image-png-Oct-07-2022-01-30-23-50-AM.png)  
    1.  **AWS Glue Name:** Any name can be given for primary Glue source.
    2.  **AWS Region:** Choose the region where glue database is located.
    3.  **Prefix:** Give any prefix.
    4.  **Parameters:** Provide any required parameters for Glue source.
5.  Proceed by selecting **Next**
6.  Select all the databases you wish to be pulled from the glue metastore.  
    ![](https://kbase.zetaris.com/hubfs/image-png-Oct-07-2022-01-32-38-27-AM.png)
7.  Please wait for all the tables to be fetched, once completed please click the **'register'** button.  
    ![](https://kbase.zetaris.com/hubfs/image-png-Oct-07-2022-01-33-46-60-AM.png)
8.  You have now successfully registered a Primary Glue metastore  
    ![](https://kbase.zetaris.com/hubfs/image-png-Oct-12-2022-09-55-17-90-PM.png)  
    ![](https://kbase.zetaris.com/hubfs/image-png-Oct-12-2022-09-56-31-81-PM.png)

**Steps for connecting to a secondary AWS GLUE(If you dont have a secondary glue below part is optional):**

1.  Log into the AWS console
2.  Ensure that Primary AWS role contains the permissions policies below:
    
    1.  **AWSGlueServiceRole**
    2.  **AmazonS3ReadOnlyAccess**
    
      
    ![](https://kbase.zetaris.com/hubfs/image-png-Oct-10-2022-01-55-08-38-AM.png)
3.  Open a new tab and log in to the AWS console and log in using the **Secondary AWS account ID**
4.  Open IAM dashboard>Roles
5.  Select ‘Create role’  
    ![](https://kbase.zetaris.com/hubfs/image-png-Oct-10-2022-01-55-31-47-AM.png)
    1.  Select trusted entity type as: **AWS account**
    2.  Select **‘Another AWS Account’** and input account id of the **Primary AWS account**
    3.  Select **next**
6.  Give a role name and select the permissions policies below:
    
    1.  **AWSGlueServiceRole**
    2.  **AmazonS3ReadOnlyAccess**
    
      
    **![](https://kbase.zetaris.com/hubfs/image-png-Oct-10-2022-01-56-16-87-AM.png)**
7.  Then click **create role**.
8.  Once role is created open the role and select the **trust relationships** tab
9.  Click on edit trust policy
10.  The section should become editable and update the ARN of the role copied from the **primary AWS account** to the trust relation of this secondary account role and save. As shown below:  
    ![](https://kbase.zetaris.com/hubfs/image-png-Oct-10-2022-01-57-47-52-AM.png)
11.  On the Primary AWS account, go to **IAM dashboard>Polices** then **create policy**  
    ![](https://kbase.zetaris.com/hubfs/image-png-Oct-10-2022-01-58-08-44-AM.png)
12.  Select the **Visual editor** tab  
    ![](https://kbase.zetaris.com/hubfs/image-png-Oct-10-2022-01-58-19-16-AM.png)
    
    1.  Service: **STS**
    2.  Actions: **Write>Assume Role**
    3.  Resources: Add ARN of role from **secondary AWS account**
    4.  Give the policy a name, then create Policy
    
      
      
    
13.  On the primary AWS account add the newly created policy created in the previous step  
    ![](https://kbase.zetaris.com/hubfs/image-png-Oct-10-2022-01-58-41-58-AM.png)
14.  Open the VM where EFS is mounted.
15.  Go to path **mount/server**
16.  Edit file  **aws\_glue\_conf.****properties.** if the file is not there create one with same name.
17.  Add the secondary account role ARN or Catalog ID.
    1.  Adding ARN:
        1.  <secondary\_glue\_name.arn>=arn:aws:iam::<your aws id>:role/<your glue s3 role>
        2.  For example :  abc\_account.arn=arn:aws:iam::6720978xxxxxx:role/glue\_s3\_role
    2.  Adding Catalog ID
        1.  <secondary\_glue\_name.catalogid>=<your catalogid>
        2.  For example : abc\_account.catalogid=6720978xxxxxx
18.  Save the file and exit
19.  Now follow the same step used in "**Steps for connecting to Primary AWS Glue"** used to connect to secondary glue. Only important point to note here is same name has to be given for secondary glue in aws\_glue\_conf.properties.
