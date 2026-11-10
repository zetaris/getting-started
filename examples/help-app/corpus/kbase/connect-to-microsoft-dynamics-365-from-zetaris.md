---
source: kbase
url: https://kbase.zetaris.com/knowledge/connect-to-microsoft-dynamics-365-from-zetaris
title: "Microsoft Dynamics 365"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 01bf74955a59b754864a2377eed0589724c8d26c9a23f0c97c1e38afad679993
---
# Microsoft Dynamics 365

**Step 1: Setting up Dynamics 365 Account**

1.  Open Dynamics 365 and log in to your account.
    
2.  In the top right corner, click on "Settings" and select "Advanced Settings" from the dropdown menu.
    
3.  On the top left corner, click on the dropdown menu and select "Customizations" followed by "Developer Resources".
    

![](https://kbase.zetaris.com/hubfs/image-png-Aug-23-2023-10-21-19-6951-PM.png)

**Step 2: Register an Application in Azure AD**

1.  Open Azure Active Directory by clicking on the following link: [Azure Active Directory admin center](https://aad.portal.azure.com/) .
    
2.  Click on the "Azure Active Directory" link in the left panel and navigate to the "App Registration" option.
    
3.  Click on the "+ New registration" button to register a new application.
    
4.  Provide the following details in the "Register an application" screen:
    
    -   Name: Enter a name for your application (e.g., "Postman Access").
        
    -   Supported account types: Choose "Accounts in any organizational directory (Any Azure AD directory – Multitenant)".
        
    -   Redirect URI (optional): Enter a desired redirect URI (e.g., "[http://localhost](http://localhost/)").
        
5.  Click on "Register" to save the application.
    

![](https://kbase.zetaris.com/hubfs/image-png-Aug-23-2023-10-22-13-0400-PM.png)

![](https://kbase.zetaris.com/hubfs/image-png-Aug-23-2023-10-23-59-5062-PM.png)

**Step 3: Add API Permissions**

1.  On the application page, click on "API Permissions" and select "+ Add a permission".
    
2.  In the "Request API Permission" window, select "Dynamics CRM".
    
3.  In the permission window, select "Delegated permission" and check the "User Impersonation" option, then click "Add Permission".
    

![](https://kbase.zetaris.com/hubfs/image-png-Aug-23-2023-10-23-15-2166-PM.png)

![](https://kbase.zetaris.com/hubfs/image-png-Aug-23-2023-10-24-30-0423-PM.png)![](blob:https://zetaris.atlassian.net/1bc34211-4412-4d9c-a373-b0102ce208eb#media-blob-url=true&id=644476c3-c132-4d20-bbe2-73a28aed7f22&collection=contentId-2829254773&contextId=2829254773&height=473&width=860&alt=)

**Step 4: Grant Admin Consent**

1.  Click on "Grant Admin Consent" and confirm by clicking "Yes" to complete the grant. If the "Grant Admin Consent" option is disabled, please contact your account administrator.
    
2.  Verify that the permissions have been granted admin access.
    

![](blob:https://zetaris.atlassian.net/a6425398-3bee-410d-92b8-3dac837af966#media-blob-url=true&id=cffd1b24-9007-41cd-b1ee-f2a69e3aa892&collection=contentId-2829254773&contextId=2829254773&mimeType=image%2Fpng&name=2e.png&size=140264&height=630&width=839&alt=)![](https://kbase.zetaris.com/hubfs/image-png-Aug-23-2023-10-24-58-3186-PM.png)![](https://kbase.zetaris.com/hubfs/image-png-Aug-23-2023-10-25-25-5644-PM.png)

**Step 5: Update Manifest Settings**

1.  Go to the "Manifest" option.
    
2.  Locate the "allowPublicClient" flag and set it to "true".
    
3.  Similarly, find the "oauth2AllowImplicitFlow" setting and set it to "true".
    
4.  Click on "Save" to apply the changes.
    

![](https://kbase.zetaris.com/hubfs/image-png-Aug-23-2023-10-26-28-9005-PM.png)

**Step 6: Generate Client Secret**

1.  Click on "Certificates & Secrets" on the left panel.
    
2.  Click on "New client secret" to create a new secret.
    
3.  After creating the secret, copy and securely store the "Client Secret Value". Note that this value will be masked after some time.
    

![](https://kbase.zetaris.com/hubfs/image-png-Aug-23-2023-10-27-15-7980-PM.png)  
![](https://kbase.zetaris.com/hubfs/image-png-Aug-23-2023-10-28-05-4718-PM.png)

![](https://kbase.zetaris.com/hubfs/image-png-Aug-23-2023-10-29-14-4247-PM.png)

**Step 7: Register App in Power Platform Admin Center (PPAC)**

1.  Access the Power Platform Admin Center (PPAC).
    
2.  In the "Environments" section, locate your Dynamics 365 CRM/Dataverse environment.
    

![](https://kbase.zetaris.com/hubfs/image-png-Aug-23-2023-10-29-48-2331-PM.png)

3.  Under "Settings," expand the "Users" option, then select "Application Users."

![](https://kbase.zetaris.com/hubfs/image-png-Aug-23-2023-10-30-40-7816-PM.png)

4\. Click on the "+ New App User" button.

![](https://kbase.zetaris.com/hubfs/image-png-Aug-23-2023-10-31-09-5668-PM.png)

5\. Select "+ Add an app" and choose your registered application from the list in Azure Active Directory.

![](https://kbase.zetaris.com/hubfs/image-png-Aug-23-2023-10-31-38-4220-PM.png)

6\. Click "Add" and then "Create" to add the app as an Application User for your environment.

![](https://kbase.zetaris.com/hubfs/image-png-Aug-23-2023-10-32-12-7849-PM.png)

![](https://kbase.zetaris.com/hubfs/image-png-Aug-23-2023-10-32-37-9494-PM.png)

![](https://kbase.zetaris.com/hubfs/image-png-Aug-23-2023-10-33-17-6431-PM.png)

7\. Assign appropriate security roles to the App User based on your requirements.

![](https://kbase.zetaris.com/hubfs/image-png-Aug-23-2023-10-33-52-1805-PM.png)

8\. Select the App User and click on "Edit security roles," then assign the desired roles and click "Save." (In this case, We have provided System Administrator role as well)

![](https://kbase.zetaris.com/hubfs/image-png-Aug-23-2023-10-34-23-3607-PM.png)

To connect to Dynamics 365 using Zetaris and the obtained credentials, follow these steps:

**Step 1: Save the Required Information**

Provide the following information when prompted:

1.  Resource: Enter the Service Root URL obtained from Step 1, excluding the "api/data/v9.2/" part of the URL.
    
2.  Directory (Tenant) ID: Enter the Directory (Tenant) ID obtained after Step 5 in the overview section of Azure AD.
    
3.  Client ID: Enter the Client ID obtained after Step 5 in the overview section of Azure AD.
    
4.  Client Secret: <REDACTED> the Client Secret obtained from Step 6.  
      
    

**Step 2: Execute the below queries on Zetaris UI in Schema Store View**

```
CREATE LIGHTNING DATABASE D365 DESCRIBE BY "D365 CONNECTION";------------------------------------------------------------------------------------UPSERT AUTH d365 REQUEST(endpoint "https://login.microsoftonline.com/<directory-tenant-id>/oauth2/token",method "post",http_encoding "urlencoded") HEADER () BODY (grant_type "client_credentials",resource "<resource>",client_id "<client-id>",client_secret "<client-secret>");------------------------------------------------------------------------------------CREATE LIGHTNING REST TABLE WhoAmI FROM D365 REQUEST(endpoint "<resource>api/data/v9.2/WhoAmI()",method "get",response_type "json",http_encoding "URLENCODED") HEADER (Authorization "Bearer ${access_token}") BODY ()AUTH BY d365;------------------------------------------------------------------------------------
```

**Example Queries:**

```
CREATE LIGHTNING DATABASE D365 DESCRIBE BY "D365 CONNECTION";------------------------------------------------------------------------------------UPSERT AUTH d365 REQUEST(endpoint "https://login.microsoftonline.com/0d945ac4-faea-4f93-81fd-6a0bb13d764d/oauth2/token",method "post",http_encoding "urlencoded") HEADER () BODY (grant_type "client_credentials",resource "https://orga6c738ca.api.crm6.dynamics.com/",client_id "02e3dc0d-8bca-xxxxxxxxxxxxxxxxxxx",client_secret "HTT8Q~dtiLqxxxxxxxxxxxxxxxxxxxxxxxx");------------------------------------------------------------------------------------CREATE LIGHTNING REST TABLE WhoAmI FROM D365 REQUEST(endpoint "https://orga6c738ca.api.crm6.dynamics.com/api/data/v9.2/WhoAmI()",method "get",response_type "json",http_encoding "URLENCODED") HEADER (Authorization "Bearer ${access_token}") BODY ()AUTH BY d365;------------------------------------------------------------------------------------
```
