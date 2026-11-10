---
source: kbase
url: https://kbase.zetaris.com/knowledge/powerbi-to-zetaris
title: "Connect PowerBI to Zetaris"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 8e86f0761d0bd0f64057500efbf9d73f04ca8e35394468bb0bd886cf849947d6
---
# Connect PowerBI to Zetaris

## Steps needed to connect a local Power BI desktop to Zetaris using ODBC

First ensure that you have the ODBC connector installed on the device from where the connection will be made. Reference [here](https://kbase.zetaris.com/knowledge/setup-odbc-connectivity).

Then in Power BI Desktop, open the _**Get Data**_ dialog from the home menu: 

![](https://kbase.zetaris.com/hubfs/image-png-Jun-06-2022-11-53-25-48-PM.png)

![](https://kbase.zetaris.com/hubfs/image-png-Jun-06-2022-11-56-18-37-PM.png)

Once you click connect, you should see the list of installed ODBC DSNs. Select the relevant one and click OK. 

![](https://kbase.zetaris.com/hubfs/image-png-Jun-06-2022-11-57-09-31-PM.png)

Once connected to Zetaris via ODBC, you should now see the list of datasources from the Zetaris environment: 

![](https://kbase.zetaris.com/hubfs/image-png-Jun-07-2022-12-03-13-57-AM.png)

Click a table to preview the data. This ensures that the connection works:

![](https://kbase.zetaris.com/hubfs/image-png-Jun-07-2022-12-03-47-50-AM.png)
