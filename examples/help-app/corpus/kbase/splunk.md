---
source: kbase
url: https://kbase.zetaris.com/knowledge/splunk
title: "Splunk"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 7c2b90270fdcf8e43f31df7dd200edc8c3971d32bbd8ceb23be70b4219cea3d7
---
# Splunk

### Prerequisites

-   Port 8089 is listening publicly or from approved IPs including Zetaris, from Splunk

### Access Splunk from Zetaris

The Splunk Enterprise Rest API grants users access to all functionalities available within the software's core system, including those used by Splunk Web, which also utilizes the API. Through the Rest API, users gain the ability to execute searches, create and manage objects, as well as configure various aspects of Splunk.

Accessing Splunk from Zetaris can be done through two ways, either through the SQL Editor or through the REST API connection interface.

[Splunk Enterprise documentation](https://docs.splunk.com/Documentation/Splunk/9.1.0/RESTREF/RESTprolog) for its REST API.

### Connect via NDP Fabric Builder

**Step 1:** Click the **Data Fabric Builder** icon.

**Step 2:** Under File Sources click the '+' next to Virtual File Source to launch the wizard.

![](https://kbase.zetaris.com/hubfs/image-png-Jan-31-2023-11-12-04-6014-PM.png)

**Step 3:** Enter a database name for the connection and select **'Create'**

**Step 4:** Select the **'+'** icon next to your Splunk connection, then select **'API'**. 

**Step 5:** Enter the necessary fields as outlined in the screenshot below, and select **'Next'**:

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Jul-26-2023-05-54-32-0576-AM.png)

**Step 6:** Finalise connection and select **'Create'.**
