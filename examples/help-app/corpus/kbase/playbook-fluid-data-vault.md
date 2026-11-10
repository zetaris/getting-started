---
source: kbase
url: https://kbase.zetaris.com/knowledge/playbook-fluid-data-vault
title: "Playbook - Fluid Data Vault"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 6c786cc4f6698e83cdf2d00cd0be101df366bdf5caf04f8bb084cd54e95109ae
---
# Playbook - Fluid Data Vault

## This reference guide helps customers to configure and get started with the Fluid Data Vault on Microsoft Azure Marketplace

After downloading the Fluid Data Vault from the Microsoft Azure marketpace ,  it is necessary to follow the steps below to effectively utilize the fluid data vault on Zetaris.

![FluidDV](https://kbase.zetaris.com/hs-fs/hubfs/FluidDV.jpg)

**Step 1:**

Log in to Zetaris UI using the credentials provided in the welcome email. Click the '_**utilities**_' button located to the right of the '_**icons**_' on the top right corner of the page and select '_**Apache**_ _**Airflow**_.' Once inside the _**Airflow**_ _**UI**_, log in with the default username and password: <REDACTED> and '_**admin**_.'

 ![FluidDv1](https://kbase.zetaris.com/hs-fs/hubfs/FluidDv1.png)

**Step 2:**

To set up Outlook Email notifications, create an _**application**_ _**password**_ on your _**Google**_ account by visiting the link: [https://myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords). Select the _**app**_ and _**device**_ you're using, generate an _**app**_ _**password**_, and contact the _**Zetaris**_ _**Team**_ with your _**Google email**_ address and _**application password**_ to add the credentials to the _**Airflow**_ _**configuration**_ file.

![FluidDV2](https://kbase.zetaris.com/hs-fs/hubfs/FluidDV2.png)

**Step 3:**

To set up Failure Notifications on Microsoft Teams, open up Teams, browse to the channel where you want the messages to be sent, and click the ‘_**configure**_' **(. . .)** icon beside the channel name on the top right. Then select '_**Connectors**_' and search for '_**Incoming Webhook.**_' Click '_**Configure**_,' provide a webhook name, say '_**airflow-webhook**_’ , and select '_**Create**_.' A Webhook URL will be generated.

![FluidDV2](https://kbase.zetaris.com/hs-fs/hubfs/FluidDV2.png)

**Step 4:**

Add a connection on the _**Airflow UI**_ by clicking '_**Admin**_' and selecting '_**Connections**_' from the dropdown list. Click 'Add' and add the respective parameters as shown in the image. Use '_**msteams\_webhook\_url**_' as the Connection Id, '_**HTTP**_' as the Connection Type, '_**https**_' as the Schema, and the webhook URL from Step 3 as the '_**Host**_.'

![](blob:https://zetaris.atlassian.net/e5650170-ac8b-4675-bef1-3467ab2fd843#media-blob-url=true&id=9fbeb16c-43a1-4238-9ede-eba6d89ff347&collection=contentId-2809856001&contextId=2809856001&height=850&width=1917&alt=)![FluidDV4](https://kbase.zetaris.com/hs-fs/hubfs/FluidDV4.png)

**Step 5:**

Create and add a Git repository for version control and approval mechanism. Create a Git repository named '_**RawVault**_' and add a branch named '_**ddl\_dml\_statements**_' to store all the statements generated from the pipelines. Generate a token using the link: [![](https://github.githubassets.com/favicon.ico)https://github.com/settings/tokens](https://github.com/settings/tokens) - Connect your Github account (under _**personal access tokens → tokens classic**_) and add a branch protection rule for the '_**main**_' branch, requiring a pull request before merging.  
  

**Step 6:**

Add the specified variables on the _**Airflow UI**_ by clicking '_**Admin**_' and selecting '_**Variables**_.' Copy the exact variable names from the table and add the necessary values.

| 
**Variable Name**

 | 

**Example**

 |
| --- | --- |
| 

Email\_Address

 | 

<your\_email\_address>

 |
| 

Github\_Org\_Name

 | 

<your organisation\_name> e.g. **zetaris**

 |
| 

Github\_Repo\_Name

 | 

_<your\_repository\_name> e.g. **RawVault**_

 |
| 

GitHubToken

 | 

generated in above step, **e.g.** _**'**_ghp\_f98OJZORwc0SsdvnsdiqQoBkHF9yW51oqJox_**'**_

 |
| 

GitHub\_File\_URL

 | 

_**https://api.github.com/repos/zetaris/RawVault/contents/**_  
(the url will change on the basis of your organisation name and repository name)

 |
| 

Github\_Pull\_Request\_URL

 | 

_**https://api.github.com/repos/zetaris/RawVault/pulls**_  
(the url will change on the basis of your organisation name and repository name)

 |
