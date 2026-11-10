---
source: kbase
url: https://kbase.zetaris.com/knowledge/data-quality-exception-management-technical-implementation
title: "Data Quality & Exception Management - Technical implementation"
kind: other
lastmod: 2026-10-28
retrieved: 2026-11-10
sha256: ab6be6d0098ba199d358fdb3002c0bce3ea9e3edca910f8787a873952a219a72
---
# Data Quality & Exception Management - Technical implementation

## This article covers the automation of the Data Quality rules within Zetaris.

This page details the automation of the Data Quality (DQ) rules within Zetaris. The implementation enables the user to add new DQ rules to objects/tables, retrieve DQ results for the applied rules and produce the DQ exception report in Zetaris. The output of this DQ analysis is shown on the DQ Tableau dashboard, which enables the user to visually track, analyse and display key performance indicator metrics to understand the quality of data on a daily basis. This enables the user to identify the exact records for the objects where an applied DQ rule is failing.

As part of the automation, the user can add new DQ rules or deactivate existing DQ rules by maintaining that information in the Zetaris NDP File System.

Data Quality Pipelines

Zetaris provides a Data Quality pipeline node, **SimpleDQ**, which automatically calculates results based on different DQ dimensions (for example Uniqueness and Completeness).

The DQ pipelines are grouped in a Data Quality container. To view them, go to **Workbench > Pipeline** and open the container.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-30-11-3606-AM.png)

_Data Quality pipelines within Zetaris_

The pipelines with the suffix **\_dq** are the data quality pipelines created for a specific table, for example crash\_dq, customer\_dq and nation\_dq. Each pipeline applies the DQ rules to one table using the **SimpleDQ** node, which automatically calculates the DQ results for that table.

To create a DQ pipeline for a table:

1\. Open the Data Quality container and click **New Pipeline**. Enter a name with the suffix **\_dq** and click **Create**.

2\. Drag the source table from **Data Explorer** onto the canvas.

3\. From **Node Blocks > Data Quality**, drag **SimpleDQ** onto the canvas and connect the source table to it.

4\. Select the **SimpleDQ** node. On the **Single Column Rules** tab, select the rules for each column (Uniqueness, Completeness, Size, Contained In, Histogram Values, Distinct Values, Approx Quantile). Use **Composite Column Rules** for rules that span multiple columns.

An example of a DQ pipeline (crash\_dq):

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-30-12-0216-AM.png)

_Example of a Data Quality pipeline within Zetaris_

It contains the **crash** object from the **NY\_VEHICLE\_COLLISIONS** database along with the **SimpleDQ** node with its rules applied. To view the result, click **Preview node output** on the **SimpleDQ** node. The result of the crash\_dq pipeline is as follows:

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-30-11-6728-AM.png)

_Result for the crash\_dq DQ pipeline_

This is how the DQ pipelines are created for each object.

Alldq\_Table Pipeline

The **Alldq\_Table** pipeline performs the union of all the DQ pipelines and provides the aggregate DQ result for all of these objects. The result is written by a **Sink** node to the **alldq** table.

The result for **SELECT \* FROM alldq** in **Workbench > SQL Workspace** is as follows:

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-30-12-8512-AM.png)

_Example of the DQ result stored in Zetaris_

DQ Exception Report - Exception report at the record level for DQ rule failure

The **dq\_exception\_details** table provides the DQ exception report for the DQ rules applied to the objects. It enables the user to identify the exact records where a DQ rule is failing. The primary key of each failing record is stored in the **spid** column. The DQ batch runs daily (scheduled with **Schedule** on the pipeline) and stores the exception report in this table, which helps the user to identify DQ failures at the record level.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-30-13-1493-AM.png)

_Example of the DQ exception result in Zetaris_

DQ Tableau Report - Visual representation of key performance metrics

The **dataquality\_data\_mart** contains all objects that are used for the DQ exception reporting in the Tableau dashboard.

This dashboard uses the **alldq** and **dq\_exception\_details** objects (described in the sections above) to represent the data quality results through different visuals. It enables the user to visually track, analyse and display key performance indicator metrics. The report consists of the following dashboards:

**Data Profiling Dashboard:** This acts as the home page of the DQ Tableau report. Here the user can view the DQ results based on three DQ dimensions (Completeness, Uniqueness and Validity).

Users can view the overall score of each DQ dimension through the doughnut charts. These charts are clickable and navigate to the respective DQ exception report.

Users can view the overall score of each object for these three dimensions.

Users can drill down into the tables and view these scores for their respective columns.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-30-12-3755-AM.png)

_Data Profiling Dashboard (Home Page)_

**Uniqueness Exception Report:** When the user clicks the Uniqueness doughnut chart on the Data Profiling home page, the user is navigated to the Uniqueness Exception Report page. This dashboard shows the following information:

**Overall Uniqueness:** the overall uniqueness score for the data.

**Attribute Count:** the record count where the applied DQ rule is failing.

**Exception Attribute List:** the attributes at record level for each object where the DQ rule failed. This helps the user to find the primary key of the record where the DQ rule failed and fix the issue.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-30-13-7579-AM.png)

_Uniqueness Exception Report_

There are two other exception reports, for Completeness and Validity, which present the corresponding exceptions in the same way as the Uniqueness Exception Report.

Automation of DQ rules - Easy way of adding/deleting the DQ rules in Zetaris

The Data Quality implementation allows the user to add or deactivate DQ rules by maintaining that information in the **Business\_Rules.csv** file in the Zetaris NDP File System. The DQ automation then applies those rules when calculating the DQ results.

Addition of new DQ Rules

The DQ implementation allows the user to add new rules to the objects/tables. To do this, add the rules to the **Business\_Rules.csv** file and store it in the NDP File System at the following path:

/file-store/DQ\_EXTERNAL\_FILES

1\. Go to **NDP File System** and open **file-store > DQ\_EXTERNAL\_FILES**.

2\. Click **Upload**, select the updated **Business\_Rules.csv** and click **Upload** to confirm.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-30-13-4584-AM.png)

_Uploading Business\_Rules.csv to the NDP File System_

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-30-14-0160-AM.png)

_Business\_Rules.csv within the NDP File System_

Once the rules are added to **Business\_Rules.csv**, they automatically become part of the DQ analysis from the next day, as the DQ batch runs nightly. A newly added DQ rule must have **Y** as the value of the **rule\_active** column.

An example of adding/deleting DQ rules in the **Business\_Rules.csv** file:

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-30-12-6345-AM.png)

_Example showing the addition/deletion of DQ rules in the Business\_Rules.csv file_

Deleting/Inactivating an existing DQ Rule

To deactivate an existing DQ rule, add that DQ rule with **I** as the value of the **rule\_active** column. An example of deactivating an existing rule is shown in the image above.
