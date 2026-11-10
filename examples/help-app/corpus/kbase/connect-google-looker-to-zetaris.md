---
source: kbase
url: https://kbase.zetaris.com/knowledge/connect-google-looker-to-zetaris
title: "Connect Google Looker to Zetaris"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 7f3e3eae9a337c023af47b1b098edacf9fdb118ad1969035fc3c3644bc1711cc
---
# Connect Google Looker to Zetaris

This guide provides a step-by-step walkthrough on how to connect to Google Looker and retrieve data from Zetaris using the Zetaris Community Connector. The Zetaris Community Connector is a robust tool that seamlessly integrates Zetaris, a data virtualization platform, with Google Looker, a powerful business intelligence and data visualization tool.

**Pre-Requisites:** Start a free Zetaris trial account

[CLICK HERE](https://www.zetaris.com/get-started?hsCtaTracking=a7ede1b4-35e0-49f3-b068-da6a198939b1%7C9d12f52b-683e-4008-94bb-41e503016e06) to start your free trial and rapidly create a data model in the Zetaris Virtual data mart.

**Step 1: Search and Access Zetaris Data**

-   Go to the "Marketplace" tab in Google Looker.
    
-   Search for "Zetaris."
    

![](https://kbase.zetaris.com/hubfs/image-png-Aug-16-2023-12-24-32-1493-AM.png)

**Step 2: Access Data Preparation Studio**

-   Click on "Data Preparation Studio."
    
-   Authorize your Google Account.
    
-   Enter your Zetaris API URL in the "Path" field,  Org ID as the "Username," and the Password that corresponds to your Zetaris environment.
    

![](blob:https://zetaris.atlassian.net/2c30e3ca-4e5e-46b4-bbf8-592f074668e9#media-blob-url=true&id=91483513-0d95-46df-a0de-c991d1129cce&collection=contentId-2841772037&contextId=2841772037&height=674&width=796&alt=)![Looker_password](https://kbase.zetaris.com/hs-fs/hubfs/kbaseupdationImages/Looker_password.png)

**Step 3: Choose Datamart and Table**

-   Once logged in, a dropdown list of available datamarts will be displayed.
    
-   Select a datamart from the list and click "Next."
    
-   The list of tables within the chosen datamart will appear.
    
-   Choose a table and click "Connect" located at the top right.
    

![](blob:https://zetaris.atlassian.net/8bba5e27-650b-48b6-8e71-355926cfa6fd#media-blob-url=true&id=7b9eaa9f-83a3-4aa9-b0a2-e93846d77b72&collection=contentId-2841772037&contextId=2841772037&height=656&width=904&alt=)![Screenshot 2023-08-24 at 12.01.38](https://kbase.zetaris.com/hs-fs/hubfs/Screenshot%202023-08-24%20at%2012.01.38.png)

**Step 4: Configure Data Schema**

1.  The schema for the selected table will be shown.
    
2.  You can modify data types and object descriptions for the selected entity.
    

 ![](https://kbase.zetaris.com/hubfs/image-png-Aug-16-2023-12-25-33-5081-AM.png)

**Step 5: Create and Visualize Report**

-   Once schema configuration is complete, click "Create Report" at the top right.
    
-   A pop-up will appear; click "Add to Report" to fetch data for the chosen schema.
    
-   Begin visualizing the data.
    

![](blob:https://zetaris.atlassian.net/bcee8918-4e86-4a1e-a766-c7f0d302ea54#media-blob-url=true&id=655f2538-d371-4e55-afaf-79b99278e20b&collection=contentId-2841772037&contextId=2841772037&height=635&width=1349&alt=)![](https://kbase.zetaris.com/hubfs/image-png-Aug-16-2023-12-25-51-6026-AM.png)

**Step 6: Adding Additional Tables (Optional)**

-   Repeat Steps 3 to 5 for each additional table you want to include.
