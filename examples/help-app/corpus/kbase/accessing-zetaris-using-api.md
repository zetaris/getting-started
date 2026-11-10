---
source: kbase
url: https://kbase.zetaris.com/knowledge/accessing-zetaris-using-api
title: "Accessing Zetaris using API"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: ded098e4207fc64e5365e4418bc61afbfefc0f38af547790b6393e29fa32bdcc
---
# Accessing Zetaris using API

## This article explains how to configure Postman for Zetaris API access, authenticate using Org ID, credentials& API Key, store and reuse tokens securely and begin testing Zetaris APIs using the official OpenAPI documentation

#### **1\. Prerequisites**

You will need the following:

| Item | Who Provides |
| --- | --- |
| Zetaris Org ID | Zetaris Support / Admin |
| Username & Password | Zetaris |
| API Key | Zetaris Console |
| Postman (v11+) | User |
| Zetaris API Docs (Redoc) | Zetaris |

#### **2\. Create a Postman Workspace**

1.  Open Postman
    
2.  Click Workspaces → Create Workspace
    
3.  Workspace name
    

#### **3\. Import Zetaris Environment Variables**

-   ##### Steps
    

1.  -   Open Environments
        
    -   Click Import
        
    -   Import the provided file: 
        
        `Zetaris API Environment Variables.json`
        

-   #### Variables Included
    

| Variable | Description |
| --- | --- |
| `baseUrl` | Zetaris SaaS API endpoint |
| `orgId` | Customer organization ID |
| `username` | Login username |
| `password` | Login password |
| `requestId` | UUID for request tracing |

-   Update the following values:
    
    -   `orgId`
        
    -   `username`
        
    -   `password`
        

#### **4\. Authenticate Using Login API**

-   ##### Create Login Request
    

| Setting | Value |
| --- | --- |
| Method | **GET** |
| URL | `/api/v1.0/auth/login` |

-   ##### Headers
    

| Header | Value |
| --- | --- |
| `X-Request-ID` |  |
| `X-Org-ID` |  |

-   ##### Authorization
    
    -   Type: **Basic Auth**
        
    -   Username:
        
    -   Password:
        
<REDACTED>   ##### Successful Response
    

##### `{     "idToken": "ey...",     "refreshToken": "ey..."   }`

#### **5\. Save Tokens in Environment**

Add the following environment variables:

`idToken = <REDACTED> idToken>   refreshToken = <REDACTED> refreshToken>   `

#### **6\. Configure API Key (Bearer Authentication)**

For all APIs beyond login:

1.  -   Open Authorization tab
        
    -   Select Bearer Token
        
    -   Paste your Zetaris API Key
        
    -   ⚠️ Both Bearer API Key and required headers must be present
        

#### **7\. Start Using Zetaris APIs**

From this point onward, use the official Zetaris API documentation:

`https://api.saas.enterprise.zetaris.com/redoc/index.html`

Recommended starting points:

-   -   DataCatalog APIs
        
    -   DataMart APIs
        
    -   Lightning Database APIs
        
    -   Pipeline APIs
        
    -   SQL Query APIs
        

#### **8\. API Categories**

| Category | Purpose |
| --- | --- |
| Auth | Login & token refresh |
| DataCatalog | Metadata tagging & discovery |
| DataMart | Data mart & table listing |
| LightningDatabase | File-store metadata |
| Pipeline | Create, clone, patch, execute pipelines |
| SQL Query | Start, page, and close SQL queries |
