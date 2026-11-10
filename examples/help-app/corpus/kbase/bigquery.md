---
source: kbase
url: https://kbase.zetaris.com/knowledge/bigquery
title: "Google BigQuery"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: c27d83b0d39b309b976c9c54d1d3ef09031c61bf59e3054aae09f26a8ea504ab
---
# Google BigQuery

Our Google BigQuery connection allows you to connect to your Google BigQuery tables, and query on them, without having to physically move them into Zetaris.

The Google BigQuery connection requires a connection to be established over OAuth.

[Connect via NDP Fabric Builder](#ndp_fabric_builder)

[Connect via SQL Editor](#connect_sql_editor)[](#troubleshooting)

[Google Details](#google_details)

### Connect via NDP Fabric Builder

  
**Step 1:** Click the **Data Fabric Builder** icon.

**Step 2:** Under Database Sources click the '+' next to Virtual Database Source to launch the wizard.

![instructions_new](https://kbase.zetaris.com/hs-fs/hubfs/kbaseupdationImages/instructions_new.png)

**Step 3:** When the GUI wizard launches accept the defaults and click **Next**.

**Step 4:** Specify the following values for the connection:

<table style="width: 100%; border-collapse: collapse; table-layout: fixed; border: 1px solid #99acc2; height: 222px;"><tbody><tr style="height: 35px;"><td style="width: 29.3983%; padding: 4px; height: 35px; border-style: solid;"><strong>Parameter</strong></td><td style="width: 70.6017%; padding: 4px; height: 35px; border-style: solid;"><strong>Value</strong></td></tr><tr style="height: 35px;"><td style="width: 29.3983%; padding: 4px; height: 35px; border-style: solid;">Datasource</td><td style="width: 70.6017%; padding: 4px; height: 35px; border-style: solid;">Other JDBC</td></tr><tr style="height: 81px;"><td style="width: 29.3983%; padding: 4px; height: 81px; border-style: solid;">Data Source Name</td><td style="width: 70.6017%; padding: 4px; height: 81px; border-style: solid;"><p>{database_name}</p><p>NOTE: name cannot contain spaces</p></td></tr><tr style="height: 35px;"><td style="width: 29.3983%; padding: 4px; height: 35px; border-style: solid;">JDBC Driver Class</td><td style="width: 70.6017%; padding: 4px; height: 35px; border-style: solid;">com.simba.googlebigquery.jdbc.Driver</td></tr><tr style="height: 35px;"><td style="width: 29.3983%; padding: 4px; height: 35px; border-style: solid;">JDBC URL</td><td style="width: 70.6017%; padding: 4px; height: 35px; border-style: solid;">jdbc:bigquery://https://www.googleapis.com/bigquery/v2:443</td></tr></tbody></table>

**Additional Parameters**

<table style="width: 100%; margin-left: auto; margin-right: auto; border-collapse: collapse; table-layout: fixed; border: 1px solid #99acc2; height: 592.401px;" class=" hs-table-align-center"><tbody><tr style="height: 35.0667px;"><td style="width: 37.3458%; padding: 4px; height: 35.0667px; border-style: solid;">ProjectID</td><td style="width: 62.5286%; padding: 4px; height: 35.0667px; border-style: solid;">{bigquery_projectID}</td></tr><tr style="height: 35.0667px;"><td style="width: 37.3458%; padding: 4px; border-style: solid; height: 35.0667px;">DefaultDataset (optional)</td><td style="width: 62.5286%; padding: 4px; border-style: solid; height: 35.0667px;">{dataset_name}</td></tr><tr style="height: 139.067px;"><td style="width: 37.3458%; padding: 4px; border-style: solid; height: 139.067px;">FilterTablesOnDefaultDataset (optional if you want to only read tables from the defaultdataset, defined in DefaultDataset)</td><td style="width: 62.5286%; padding: 4px; border-style: solid; height: 139.067px;">1</td></tr><tr style="height: 35.0667px;"><td style="width: 37.3458%; padding: 4px; height: 35.0667px; border-style: solid;">OAuthType</td><td style="width: 62.5286%; padding: 4px; height: 35.0667px; border-style: solid;">0</td></tr><tr style="height: 143.067px;"><td style="width: 37.3458%; padding: 4px; height: 143.067px; border-style: solid;">OAuthServiceAcctEmail</td><td style="width: 62.5286%; padding: 4px; height: 143.067px; border-style: solid;"><p>{service_account_email}</p><p>Help:</p><p><a href="https://kbase.zetaris.com/knowledge/bigquery#google_sa" rel="noopener">Where is your Google Cloud Service Account Email</a></p></td></tr><tr style="height: 205.067px;"><td style="width: 37.3458%; padding: 4px; height: 205.067px; border-style: solid;">OAuthPvtKeyPath</td><td style="width: 62.5286%; padding: 4px; height: 205.067px; border-style: solid;"><p>{path/to/key}</p><p>Help:</p><p><a href="https://kbase.zetaris.com/knowledge/bigquery#download_sa_key" rel="noopener">How to download your OAuthPvtKey from Google Cloud</a></p><p><a href="https://kbase.zetaris.com/knowledge/bigquery#upload_sa_key" rel="noopener">Where to store and access your OAuthPvtKey in Zetaris</a></p></td></tr></tbody></table>

<table style="border-collapse: collapse; table-layout: fixed; margin-left: auto; margin-right: auto; border: 1px solid #99acc2; width: 100%; height: 116px;" class="hs-table-align-center"><tbody><tr><td style="width: 37.5171%; border-style: solid;"><p>Required IAM Roles for BigQuery Service Account Access</p></td><td style="width: 62.5286%; border-style: solid;"><p>&nbsp;</p><p>1.&nbsp; BigQuery Data Owner<br>Usage:<br>Grants full access to datasets. Optional if only read access is needed.</p><p><strong>Shown Example</strong>:</p><p><img alt="IAM_POLICY_BQ_new" class="hs-image-align-none" height="198" style="height: auto; width: 301px;" src="https://kbase.zetaris.com/hs-fs/hubfs/kbaseupdationImages/IAM_POLICY_BQ_new.png?width=301&amp;height=198&amp;name=IAM_POLICY_BQ_new.png" width="301" loading="lazy" srcset="https://kbase.zetaris.com/hs-fs/hubfs/kbaseupdationImages/IAM_POLICY_BQ_new.png?width=151&amp;height=99&amp;name=IAM_POLICY_BQ_new.png 151w, https://kbase.zetaris.com/hs-fs/hubfs/kbaseupdationImages/IAM_POLICY_BQ_new.png?width=301&amp;height=198&amp;name=IAM_POLICY_BQ_new.png 301w, https://kbase.zetaris.com/hs-fs/hubfs/kbaseupdationImages/IAM_POLICY_BQ_new.png?width=452&amp;height=297&amp;name=IAM_POLICY_BQ_new.png 452w, https://kbase.zetaris.com/hs-fs/hubfs/kbaseupdationImages/IAM_POLICY_BQ_new.png?width=602&amp;height=396&amp;name=IAM_POLICY_BQ_new.png 602w, https://kbase.zetaris.com/hs-fs/hubfs/kbaseupdationImages/IAM_POLICY_BQ_new.png?width=753&amp;height=495&amp;name=IAM_POLICY_BQ_new.png 753w, https://kbase.zetaris.com/hs-fs/hubfs/kbaseupdationImages/IAM_POLICY_BQ_new.png?width=903&amp;height=594&amp;name=IAM_POLICY_BQ_new.png 903w" sizes="(max-width: 301px) 100vw, 301px"></p><p><br>2.&nbsp; BigQuery Data Viewer<br>Usage:<br>Grants read-only access to tables and metadata.<br><br>3.&nbsp; BigQuery Job User<br>Usage:<br>Required to execute SQL queries and create query jobs.</p></td></tr></tbody></table>

![](https://kbase.zetaris.com/hs-fs/hubfs/Screen%20Shot%202023-11-17%20at%203-31-59%20pm-png.png)

   **Step 5:** Select from the list of tables retrieved and click **Next**

_![1_choose table](https://kbase.zetaris.com/hs-fs/hubfs/kbaseupdationImages/1_choose%20table.png)_

  **Step 6**:  On the summary dialogue click Register.                  

                           _**![2_ Preview connections ](https://kbase.zetaris.com/hs-fs/hubfs/kbaseupdationImages/2_%20Preview%20connections%20.png)**_

**Step 7:** The BigQuery data source should now appear under:                

   .

                    ![3_FINAL_Sucessfull_connections](https://kbase.zetaris.com/hs-fs/hubfs/kbaseupdationImages/3_FINAL_Sucessfull_connections.png) 

### Connect via SQL Editor

The syntax to connect to BigQuery via SQL Editor is shown below

To include all table in ProjectID, do not include **DefaultDataset** or **FilterTablesOnDefaultDataset** parameters

```
CREATE DATASOURCE GOOGLE_BIGQUERY OPTIONS (  jdbcdriver "com.simba.googlebigquery.jdbc.Driver",  jdbcurl "jdbc:bigquery://https://www.googleapis.com/bigquery/v2:443",  ProjectID "<projectID>",  DefaultDataset "<dataset>",  FilterTablesOnDefaultDataset "1",  OAuthType "<oauthType>",  OAuthServiceAcctEmail "<oauthServiceAccountEmail>",  OAuthPvtKeyPath "<oauthPrivateKeyPath>");REGISTER DATASOURCE TABLES FROM GOOGLE_BIGQUERY;
```

Example connection string:

```
CREATE DATASOURCE BIG_QUERY_HOSPITAL OPTIONS (  jdbcdriver "com.simba.googlebigquery.jdbc.Driver",  jdbcurl "jdbc:bigquery://https://www.googleapis.com/bigquery/v2:443",  ProjectID "hospital-405300",  DefaultDataset "warehouse",  FilterTablesOnDefaultDataset "1",  OAuthType "0",  OAuthServiceAcctEmail "<REDACTED>",  OAuthPvtKeyPath "dffs:///hospital-405300-309b06a52602.json");REGISTER DATASOURCE TABLES FROM BIG_QUERY_HOSPITAL;
```

**Google Details**

**Where is your Google Cloud Service Account Email?**

> **Step 1:** Go to IAM & Admin > Service Accounts
> 
> ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Nov-17-2022-04-51-24-8984-AM.png)
> 
> **Step 2:** Copy your Service Account email
> 
> ![](https://kbase.zetaris.com/hubfs/image-png-Nov-17-2022-04-53-39-1771-AM.png)
> 
> The service account you use can have owner, editor or viewer privilges. 

**How to download your OAuthPvtKey from Google Cloud**

> **Step 1:** From the Service Account screen (following the steps above), select "Manage Keys" from the drop down options
> 
> ![](https://kbase.zetaris.com/hubfs/image-png-Nov-17-2022-04-55-23-1883-AM.png)
> 
> **Step 2:** Select “Create new key”
> 
> ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Nov-17-2022-04-55-45-8349-AM.png)
> 
> **Step 3:** Create JSON key
> 
> ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Nov-17-2022-04-56-27-8062-AM.png)

**Where to store and access your OAuthPvtKey in Zetaris**

> You are able to store your OAuthPvtKey in either the local file system which the backend runs on, or in the NDP file system in the "key-trust-store" folder (after manually uploading it), e.g.
> 
> ![ndp_new](https://kbase.zetaris.com/hs-fs/hubfs/kbaseupdationImages/ndp_new.png)
> 
> _NDP file system_
> 
> -   If on the local file system, just provide the path e.g. /path/to/file/\[OAuthPvtKey\].json
>     
> -   If from NDP file system, ensure in format like dffs:///\[OAuthPvtKey\].json
>
