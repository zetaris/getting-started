---
source: kbase
url: https://kbase.zetaris.com/knowledge/rest-api
title: "Accessing Zetaris through Rest API"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 5bb8a5ca6f01ba6fc949db5a066c68e3d743480f25017c401c98a6f03e2ceb1f
---
# Accessing Zetaris through Rest API

## This article shows users how to carry out Zetaris commands using the Zetaris secure API

### Import the Collection and Environment Variables

To start the usage of this API , it is recommended to download the [Postman collection](https://github.com/zetaris/zetaris-public).  

Once logged into the postman application and within a workspace click on the ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Mar-20-2023-09-13-29-4883-PM.png)collections widget as seen on the right.

Then click on the ![](https://kbase.zetaris.com/hubfs/image-png-Mar-20-2023-09-13-36-5982-PM.png)button and then click on the ![](https://kbase.zetaris.com/hubfs/image-png-Mar-20-2023-09-13-45-2070-PM.png)button. Navigate to where the collection and environment files are downloaded and select them both.

Ensure that the collection and environment variable is selected, as seen below, and then click on ![](https://kbase.zetaris.com/hubfs/image-png-Mar-20-2023-09-13-56-2965-PM.png) .

![](https://kbase.zetaris.com/hubfs/image-png-Mar-20-2023-09-14-05-5370-PM.png)

### Understanding the Environment variables for Postman

Currently the API collection utilises the following environment variables:

<table style="border-collapse: collapse; table-layout: fixed; margin-left: auto; margin-right: auto; border: 1px solid #99acc2; width: 100%; height: 1219.67px;"><tbody><tr style="height: 38.6667px;"><td style="width: 36.6533%; height: 39px;"><p><strong>Variable</strong></p></td><td style="width: 63.2982%; height: 39px;"><p><strong>Description</strong></p></td></tr><tr style="height: 100.667px;"><td style="width: 36.6533%; height: 101px;"><p><strong>refreshToken</strong></p></td><td style="width: 63.2982%; height: 101px;"><p>The refresh token is a token generated when logging into the API.</p><p>This token will be used to regenerate the idToken</p></td></tr><tr style="height: 64.6667px;"><td style="width: 36.6533%; height: 65px;"><p><strong>idToken</strong></p></td><td style="width: 63.2982%; height: 65px;"><p>The id token is a bearer token generated when logging into the API which will be used for authorisation in future calls</p></td></tr><tr style="height: 38.6667px;"><td style="width: 36.6533%; height: 39px;"><p><strong>url</strong></p></td><td style="width: 63.2982%; height: 39px;"><p>The url is the users API URI. i.e., api.zetaris.app.com</p></td></tr><tr style="height: 38.6667px;"><td style="width: 36.6533%; height: 39px;"><p><strong>targetRole</strong></p></td><td style="width: 63.2982%; height: 39px;"><p>The numerical identification for the role being targeted.</p></td></tr><tr style="height: 38.6667px;"><td style="width: 36.6533%; height: 39px;"><p><strong>resourceTypeDQ</strong></p></td><td style="width: 63.2982%; height: 39px;"><p>Variable store the string for the Data Quality reference.</p></td></tr><tr style="height: 38.6667px;"><td style="width: 36.6533%; height: 39px;"><p><strong>emailAdmin</strong></p></td><td style="width: 63.2982%; height: 39px;"><p>Username of the user</p></td></tr><tr style="height: 38.6667px;"><td style="width: 36.6533%; height: 39px;"><p><strong>operationTypeRead</strong></p></td><td style="width: 63.2982%; height: 39px;"><p>Variable stores the String for Read permissions, “Read”</p></td></tr><tr style="height: 38.6667px;"><td style="width: 36.6533%; height: 39px;"><p><strong>resourceTypeVD</strong></p></td><td style="width: 63.2982%; height: 39px;"><p>Variable store the string for the Virtual Data Mart reference.</p></td></tr><tr style="height: 64.6667px;"><td style="width: 36.6533%; height: 65px;"><p><strong>targetAccount</strong></p></td><td style="width: 63.2982%; height: 65px;"><p>For users with access to the Data Access features. Will target a specific users account to get/update information.</p></td></tr><tr style="height: 64.6667px;"><td style="width: 36.6533%; height: 65px;"><p><strong>requestId</strong></p></td><td style="width: 63.2982%; height: 65px;"><p>Request ID is the uuid required within the header when making API calls</p></td></tr><tr style="height: 38.6667px;"><td style="width: 36.6533%; height: 39px;"><p><strong>requestTypeSS</strong></p></td><td style="width: 63.2982%; height: 39px;"><p>Variable store the string for the Schema Store reference.</p></td></tr><tr style="height: 38.6667px;"><td style="width: 36.6533%; height: 39px;"><p><strong>requestTypeDC</strong></p></td><td style="width: 63.2982%; height: 39px;"><p>Variable store the string for the Data Catalog reference.</p></td></tr><tr style="height: 38.6667px;"><td style="width: 36.6533%; height: 39px;"><p><strong>operationTypeWrite</strong></p></td><td style="width: 63.2982%; height: 39px;"><p>Variable stores the String for Write permissions, “Write”</p></td></tr><tr style="height: 64.6667px;"><td style="width: 36.6533%; height: 65px;"><p><strong>resourceTypeNDP</strong></p></td><td style="width: 63.2982%; height: 65px;"><p>Variable store the string for the NDP Fabric Builder reference.</p></td></tr><tr style="height: 38.6667px;"><td style="width: 36.6533%; height: 39px;"><p><strong>defaultAdminPassword</strong></p></td><td style="width: 63.2982%; height: 39px;"><p>This is the API users’ password.</p></td></tr><tr style="height: 64.6667px;"><td style="width: 36.6533%; height: 65px;"><p><strong>pipelineContainerId</strong></p></td><td style="width: 63.2982%; height: 65px;"><p>The numerical id of a users’ Data Pipeline Container resource.</p></td></tr><tr style="height: 38.6667px;"><td style="width: 36.6533%; height: 39px;"><p><strong>pipelineRelationId</strong></p></td><td style="width: 63.2982%; height: 39px;"><p>The numerical id of a users’ Data Pipeline resource.</p></td></tr><tr style="height: 38.6667px;"><td style="width: 36.6533%; height: 39px;"><p><strong>DataMartId</strong></p></td><td style="width: 63.2982%; height: 39px;"><p>The numerical id of a users’ Data Mart resource.</p></td></tr><tr style="height: 38.6667px;"><td style="width: 36.6533%; height: 39px;"><p><strong>DataSourceId</strong></p></td><td style="width: 63.2982%; height: 39px;"><p>The numerical id of a users’ Data Source resource.</p></td></tr><tr style="height: 38.6667px;"><td style="width: 36.6533%; height: 39px;"><p><strong>DataSourceRelationId</strong></p></td><td style="width: 63.2982%; height: 39px;"><p>The numerical id of a users’ Data Source Table resource.</p></td></tr><tr style="height: 38.6667px;"><td style="width: 36.6533%; height: 39px;"><p><strong>tag</strong></p></td><td style="width: 63.2982%; height: 39px;"><p>An alphanumerical string to tag some resources.</p></td></tr><tr style="height: 90.6667px;"><td style="width: 36.6533%; height: 91px;"><p><strong>queryToken</strong></p></td><td style="width: 63.2982%; height: 91px;"><p>The query token is generated when a user makes an API call to query a datasource or execute a pipeline. This token is required when paginating between results.</p></td></tr><tr style="height: 38.6667px;"><td style="width: 36.6533%; height: 39px;"><p><strong>oidcid</strong></p></td><td style="width: 63.2982%; height: 39px;"><p>The id of the users SSO configuration.</p></td></tr><tr style="height: 38.6667px;"><td style="width: 36.6533%; height: 39px;"><p><strong>uid</strong></p></td><td style="width: 63.2982%; height: 39px;"><p>The uid is required to configure SSO. i.e., Zetaris</p></td></tr></tbody></table>

### Changing your Environment Variables

In the top right corner of the postman window, click on ![](https://kbase.zetaris.com/hubfs/image-png-Mar-20-2023-09-14-23-3267-PM.png)to view the environment variables.

Scroll down and edit the following variables.

<table style="border-collapse: collapse; table-layout: fixed; margin-left: auto; margin-right: auto; border: 1px solid #99acc2;"><tbody><tr><td><p><strong>Variable</strong></p></td><td><p><strong>Current Value</strong></p></td></tr><tr><td><p><strong>url</strong></p></td><td><p>&lt;The Zetaris instance you are using&gt;</p></td></tr><tr><td><p><strong>emailAdmin</strong></p></td><td><p>&lt;your registered email with SAAS&gt;</p></td></tr><tr><td><p><strong>defaultAdminPassword</strong></p></td><td><p>&lt;password for your registered account with SAAS&gt;</p></td></tr></tbody></table>

### Login

Once the above variables have been saved. Open the **_Auth_** folder within the collection select the **_Login_** request.

![](https://kbase.zetaris.com/hubfs/image-png-Mar-20-2023-09-14-52-1327-PM.png)

Click on![](https://kbase.zetaris.com/hubfs/image-png-Mar-20-2023-09-14-59-8032-PM.png) to send the API request.

The response returned will contain an identification token and refresh token as mentioned earlier. An example output can be seen below.

![](https://kbase.zetaris.com/hubfs/image-png-Mar-20-2023-09-15-06-7882-PM.png)

You **will not need** to copy the **_idToken_** or the **_refreshToken_** to the environment variables as they are automatically assigned to their respective environment variables due javascript located in the **_Tests_** tab as seen below.

![](https://kbase.zetaris.com/hubfs/image-png-Mar-20-2023-09-15-21-5053-PM.png)

### Querying your Data

#### Running a Query

Within the collection open the folder **_DBQuery_** and select the **_OpenSqlQuery_** request.

![](https://kbase.zetaris.com/hubfs/image-png-Mar-20-2023-09-15-29-8540-PM.png)

Navigate to the **_Body_** Tab where you will see the following.

![](https://kbase.zetaris.com/hubfs/image-png-Mar-20-2023-09-15-41-3893-PM.png)

If you do no see the above JSON within the body, select raw and ensure JSON is selected. Then copy the below snippet and add it to the body.

{

"select": "SELECT \* FROM NY\_VEHICLE\_COLLISIONS.crash",

"pageLimit": 2

}

One thing to note is that the pageLimit refers to the number of items returned per API call and has a range of 1 – 100.

To run the query, click on ![](https://kbase.zetaris.com/hubfs/image-png-Mar-20-2023-09-21-02-9116-PM.png) . In the response section of Postman, you will see a JSON payload containing the following.

![](https://kbase.zetaris.com/hubfs/image-png-Mar-20-2023-09-21-10-9502-PM.png)

You will not need to copy the **_queryToken_** over to the environment variables as it will be automatically added to the environment variables.

#### Paginate a Query

Within the collection open the folder **_DBQuery_** and select the **_PageSqlQuery_** request.

![](https://kbase.zetaris.com/hubfs/image-png-Mar-20-2023-09-21-26-5202-PM.png)

Navigate to the Params tab, where you will see the following key value pairs.

![](https://kbase.zetaris.com/hubfs/image-png-Mar-20-2023-09-31-15-7288-PM.png)

Place the values in your environment are the same as above.

To run the query, click on . In the response section of Postman, you will see a JSON payload containing the following.

#### Close a Query

Within the collection open the folder **_DBQuery_** and select the **_CloseSqlQuery_** request.

![](https://kbase.zetaris.com/hubfs/image-png-Mar-20-2023-09-34-20-1955-PM.png)

Within this request you will see the following:

![](https://kbase.zetaris.com/hubfs/image-png-Mar-20-2023-09-34-53-2329-PM.png)

This will remove the cached query information from the server to save memory and resources.

Click on ![](https://kbase.zetaris.com/hubfs/image-png-Mar-20-2023-09-32-07-9354-PM.png) . You will receive a response status of 200 which indicates that the query was successfully closed on the server.
