---
source: kbase
url: https://kbase.zetaris.com/knowledge/sugarcrm
title: "SugarCRM"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 4f58c7ef1e697f15af5751e9b96748d7860777818a1f9771b7047aa10ecba23c
---
# SugarCRM

[API and OAuth Information](#api_oauth)

[Connect via SQL Editor](#connect_sql)

[Query SugarCRM](#query_sugar)

### API and OAuth2 Information

You are able to remotely connect to your SugarCRM platform, by connecting through its API.

[SugarCRM REST API Details](https://support.sugarcrm.com/documentation/sugar_developer/sugar_developer_guide_13.1/integration/web_services/rest_api/)

Sugar uses a two-legged OAuth2 for authentication. You simply need to do a POST to /rest/<version>/oauth2/token with the following parameters:

<table style="border-collapse: collapse; table-layout: fixed; margin-left: auto; margin-right: auto; border: 1px solid #99acc2; width: 116.134%; border-width: 1px; border-color: #000000;"><tbody><tr><td style="width: 23.4352%;"><strong>grant_type</strong></td><td style="width: 13.246%;">String</td><td style="width: 63.3188%;">Type of request. Available grant types are "password" and "refresh_token".</td></tr><tr><td style="width: 23.4352%;"><strong>client_id</strong></td><td style="width: 13.246%;">String</td><td style="width: 63.3188%;">The client_id of "sugar" will automatically create an OAuth Key in the system and can be used for "password" authentication. The client_id of "support_portal" will create an OAuth Key if the portal system is enabled and will allow for portal authentication. Other client_id's can be created by the administrator in the OAuthKeys section in the Administration section and can be used in the future for additional grant types, if the client secret is filled in, it will be checked to validate the use of the client id.</td></tr><tr><td style="width: 23.4352%;"><strong>client_secret</strong></td><td style="width: 13.246%;">String</td><td style="width: 63.3188%;">The client's secret key.</td></tr><tr><td style="width: 23.4352%;"><strong>username</strong></td><td style="width: 13.246%;">String</td><td style="width: 63.3188%;">The username of the user authenticating to the system.</td></tr><tr><td style="width: 23.4352%;"><strong>password</strong></td><td style="width: 13.246%;">String</td><td style="width: 63.3188%;">The plaintext password the user authenticating to the system.</td></tr><tr><td style="width: 23.4352%;"><strong>platform</strong></td><td style="width: 13.246%;">String</td><td style="width: 63.3188%;">Defaults to "base" allows you to have custom meta-data per platform. If using a value other than "base", you should make sure it is registered using the&nbsp;<a href="https://support.sugarcrm.com/documentation/sugar_developer/sugar_developer_guide_13.1/architecture/extensions/platforms/" data-orig-href="../../../architecture/extensions/platforms/">Platform extension</a>&nbsp;or&nbsp;<a href="https://support.sugarcrm.com/smartlinks/administration_guide/developer_tools/hdr_configure_api_platforms/" target="_blank" rel="noopener" data-orig-href="/smartlinks/administration_guide/developer_tools/hdr_configure_api_platforms/">configure an API platform</a>&nbsp;in Administration panel.</td></tr></tbody></table>

### Connect via SQL Editor

In Zetaris, you can structure this POST request in the following way, through the Schema Store (SQL Editor):

**Step 1: Create the authorisation post request, and save it, so it can be referenced.**

```
UPSERT AUTH sugar_crm REQUEST(endpoint "https://{site_url}/rest/v10/oauth2/token",method "post",http_encoding "JSON") HEADER (  Content-Type "application/json") BODY (  grant_type "password",  client_id "sugar",  client_secret "{client_secret}",  username "{username}",  password "{password}",  platform "base");
```

**Step 2: Call the table and its details, with the saved authorisation embedded in the body:**

```
CREATE LIGHTNING REST TABLE Contacts FROM sugar_crm REQUEST(endpoint "https://{site_url}/rest/v10/Contacts?max_num=${rec_count}",method "get",response_type "json",http_encoding "URLENCODED",rec_count "4700") HEADER (Cache-Control "no-cache",OAuth-Token "${access_token}") BODY ()AUTH BY sugar_crm;
```

### Query SugarCRM

If you have followed the above steps, the table, **Contacts**, is now created.

The incoming structure of the connection might be in JSON form, in which case, you will need to flatten the structure to a compatible data frame, using either the **flatten** or **explode commands.** An example is shown below:  

```
select a.* from (select explode(records) a from SUGAR_CRM.CONTACTS)
```

  

Once the JSON has been expanded, it can be called like any other table through

-   Query Builder
-   Virtual Data Pipeline
-   Virtual Data Mart
