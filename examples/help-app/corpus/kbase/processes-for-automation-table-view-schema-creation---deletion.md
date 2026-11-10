---
source: kbase
url: https://kbase.zetaris.com/knowledge/processes-for-automation-table-view-schema-creation-/-deletion
title: "Processes for Automation: Table, View, Schema creation / deletion"
kind: other
lastmod: 2026-10-28
retrieved: 2026-11-10
sha256: 7a4af1e04a462cafba8a1cc71c6cb7b63328819473e40156706eefdbed6d57eb
---
# Processes for Automation: Table, View, Schema creation / deletion

## This article explains how to use Zetaris' Query Builder to create and delete views.

Steps to create view

1\. Log in to Zetaris and go to **Workbench > Query Builder**.

2\. Open the container that will hold the view.

3\. Click **New View**.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-07-05-45-9502-AM.png)

4\. Enter the **View Name**.

5\. Click **Create**. The view opens in the Query Builder editor.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-07-05-46-5116-AM.png)

6\. From **Data Explorer**, drag and drop the tables needed in the view onto the canvas.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-07-05-46-2190-AM.png)

7\. Join the key columns: click the connector dot next to the column in the first table, then the matching column in the second table. Click the join label to choose the type of join that is needed.

8\. Select the columns needed: click **+** next to each column, choose **Select Column** and click **Add**.

9\. Add the predicates, aggregations and ordering required for the view.

10\. Click **Save**. This will save your view. Click **Run** to check the result.

Steps to delete view

1\. Log in to Zetaris and go to **Workbench > Query Builder**.

2\. Open the container and click the view to be deleted.

3\. Click **Delete** in the view toolbar.

4\. Click **Delete** to confirm. This will delete your view.
