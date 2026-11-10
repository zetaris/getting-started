---
source: kbase
url: https://kbase.zetaris.com/knowledge/enable-sso-via-oidc
title: "Enable SSO via OIDC"
kind: other
lastmod: 2026-10-28
retrieved: 2026-11-10
sha256: cdd9a4ae33616e14f08d4bda1fa677af493e06dfb16c819cef49b41368331b6c
---
# Enable SSO via OIDC

Zetaris supports single sign-on (SSO) via OIDC with Microsoft Entra ID (Azure AD). SSO can be configured from **Management > SSO** or with SQL commands in **SQL Workspace**. Only Admin users can configure SSO.

Set the login URL

1\. Go to **Management > Organisation**.

2\. In **Slug**, enter your organisation's unique ID in lowercase letters and digits, e.g. zetaris. Click **Save**.

3\. The **Login URL** is shown below the slug, i.e. https://<your-zetaris-host>/<slug>/login. This is the URL users open to sign in via SSO.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-39-03-1509-AM.png)

_Organisation slug and login URL_

Configure SSO in Zetaris

1\. Go to **Management > SSO**. The page shows the **SSO login URL** and the configured providers.

2\. Click **+** to add a provider.

_Management > SSO_

3\. Enter the provider details:

• **Name**: a name for the provider, e.g. Azure AD SSO

• **Provider**: **Microsoft (Outlook)**

• **Outlook Client ID**: the Application (client) ID from the Azure app registration

• **Outlook Tenant ID**: the Directory (tenant) ID from the Azure app registration

4\. Click **Create**.

_New SSO provider_

Configure SSO using SQL

Alternatively, SSO can be configured with the following commands in **Workbench > SQL Workspace**. Choose your uid (your own unique ID) in lowercase and replace <uid>, e.g. zetaris. Use the same uid in every step below.

Enable OIDC

Run the following query in SQL Workspace:

UPDATE SSO WITH (uid "<uid>", type\_selected "oidc");

_UPDATE SSO in SQL Workspace_

Confirm the SSO config

Run the following query in SQL Workspace:

SHOW SSO BY UID "<uid>";

Update the OIDC with required parameters

\--UPDATE THE OIDC WITH THE REQUIRED PARAMETERS

\--clientId is the service principal

\--clientSecret is the secret key for the service principal

\--tenantId is your tenantId

\--They can be found in app registration

UPDATE OIDC

WITH (

uid "zetaris",

clientId "c087XXXX",

clientSecret "Bja8XXXXXXXXXX",

tenantId "0d94XXXXXX",

DISCOVERYURI "https://login.microsoftonline.com/<tenant\_id>/v2.0/.well-known/openid-configuration"

);

Confirm the OIDC has been configured

SHOW OIDC CONFIG BY UID "<uid>";

Refer to the following parameters to change values:

• **clientId**: The Application (client) ID

• **clientSecret**: The client secret of the above Service Principal

• **tenantId**: The Directory (tenant) ID

Configure SSO on Azure

1\. Go to **App Registrations** and open your application.

2\. Click **Authentication**.

3\. Enter your Zetaris URL into the **Web Redirect URIs**, i.e. https://<your-zetaris-host>/<slug>/callback

4\. Review that the URLs provided are correct.

5\. Click **Save**.
