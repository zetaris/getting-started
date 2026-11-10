---
source: kbase
url: https://kbase.zetaris.com/knowledge/collibra
title: "Collibra"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: c21ebf53549ce13f3640990b453d7babaaad3124e1fb2846ce12eba44bb7163d
---
# Collibra

Collibra offers a number of REST API endpoints, each with a different purpose for managing its environment and accessing its resources:

#### Core API

The core API is the main entry point to interact with your Collibra Data Governance Center environment. Create, update or delete all resources such as users, assets, domains or trigger workflows. [More Information](https://developer.collibra.com/rest/data-governance#/).

#### Search API 

The Search API allows you to create your own integration with Collibra Search Engine. Find your data! [More information](https://developer.collibra.com/rest/search).

#### Catalog API

The Catalog API offers functionality related to the catalog product. It is mainly focused on facilitating the ingestion of information into Catalog. The API enables users to more easily connect Catalog to sources that are not necessarily natively supported in the product. [More information](https://developer.collibra.com/rest/catalog#/).

Generally, the more useful APIs from Collibra to use in Zetaris, would be the **Core API, Search API** and **Catalog API**, though the other APIs could also be used:

Import API

Catalog Data Classification API

Catalog Database Registration API

REST Catalog Sampling API

REST Catalog Cloud Ingestions API

REST Catalog External Profiling Upload API

Collibra Protect API

Management Console

### Access Collibra from Zetaris

Accessing Collibra from Zetaris can be done through two ways, either through the SQL Editor or through the REST API connection interface.

### Connect via NDP Fabric Builder

**Step 1:** Click the **Data Fabric Builder** icon.

**Step 2:** Under File Sources click the '+' next to Virtual File Source to launch the wizard.

![](https://kbase.zetaris.com/hubfs/image-png-Jan-31-2023-11-12-04-6014-PM.png)

**Step 3:** Enter a database name for the connection and select **'Create'**

**Step 4:** Select the **'+'** icon next to your Collibra connection, then select **'API'**. 

**Step 5:** Enter the necessary fields as outlined in the screenshot below, and select **'Next'**:

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Jul-26-2023-05-54-32-0576-AM.png)

**Step 6:** Finalise connection and select **'Create'.**
