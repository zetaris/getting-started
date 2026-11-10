---
source: kbase
url: https://kbase.zetaris.com/knowledge/sso-using-okta
title: "SSO using OKTA"
kind: other
lastmod: 2026-11-04
retrieved: 2026-11-10
sha256: 22a0e91da56b7cae74773473019a969946d74e5874571e723625fac1cf821dbf
---
# SSO using OKTA

Configuring Zetaris

1\. Log into your Zetaris instance.

2\. Go to **Workbench > SQL Workspace** and run the following command, replacing <your UID> with your organisation, i.e. zetaris:

UPDATE SSO WITH (

uid "<your UID>",

type\_selected "SAML2"

)

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-47-55-2105-AM.png)

_UPDATE SSO in SQL Workspace_

### Configuring Okta

1\. Sign into Okta.

2\. Go to **Admin > Applications > Create App Integration**.

3\. Select **SAML 2.0**, then select **Next**.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-47-55-6554-AM.png)

_Create a new app integration in Okta_

4\. Create an application name.

5\. Click **Next**.

6\. Provide the following inputs:

• **Single sign on URL**: your Zetaris login URL, i.e. https://<your-zetaris-host>/<slug>/login. The slug is set in **Management > Organisation**, and the full login URL is shown below it.

• Ensure the checkbox **Use this for Recipient URL and Destination URL** is checked.

• **Audience URI (SP Entity ID)**: urn:mace:saml:zetaris.com

• **Name ID format**: Email address

• **Application username**: Okta username

• **Update application username on**: Create and update

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-47-55-9202-AM.png)

_Organisation slug and login URL_

7\. Click **Next**.

8\. Select the option **I'm an Okta customer adding an internal app**. The questions provided are optional.

9\. Click **Finish**.

10\. Once created, you will see the newly created application within the applications list.

11\. Select the newly created application, then select the **Sign On** tab.

12\. Scroll down to the **SAML Signing Certificates** section.

13\. Click **View SAML setup instructions**.

14\. Scroll down to the bottom of the screen and copy the **IDP Metadata**.

15\. Log into your Zetaris instance and go to **Workbench > SQL Workspace**.

16\. Run the following command, replacing the placeholder with the IDP Metadata copied in step 14:

UPDATE SAML2 WITH (

idp '<IDP>'

);

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-47-55-4256-AM.png)

_UPDATE SAML2 in SQL Workspace_

17\. Use the login URL from step 6 to log in via Okta, e.g. https://<your-zetaris-host>/<slug>/login
