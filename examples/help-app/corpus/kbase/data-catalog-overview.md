---
source: kbase
url: https://kbase.zetaris.com/knowledge/data-catalog-overview
title: "Data Catalog Overview"
kind: other
lastmod: 2026-10-28
retrieved: 2026-11-10
sha256: b8a84d4e7e1778bf740da9a44580f027c4f4245b066e5fd78bb2b3f57bd204a4
---
# Data Catalog Overview

The Data Catalog holds table and column metadata for each data source and records changes to it. You can run statistics, add tags and descriptions, and search across metadata and data values.

In the new UI, catalog features are in two places:

-   The **Metadata** view of a data source, for statistics, tags, descriptions and change history.
-   **Search Metadata** in Data Explorer, for searching by tag, metadata or content.

You can also reach the Data Catalog from the command line or through a direct connection, so you can use it from your workflow tools.

Open the Metadata View

1.  In **Data Explorer**, expand **Database** (or **File Source & API** / **Lakehouse**).
2.  Select a data source. It opens in a new tab.
3.  In the toolbar, select **Metadata**.
4.  Select **Add tag…** in the table row.
5.  Type the tag name, or pick an existing tag, and press Enter.
6.  To remove a tag, select the **×** on the tag.
7.  Hover over the row and select the pencil icon at the end of the row.
8.  Type the description and press Enter.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-26-47-8929-AM.png)

The Metadata view has four sections: **Update Cycle**, **Table Metadata**, **Columns of <table>** and **Metadata History**.

Update Cycle

Sets how often the catalog checks the source for metadata changes. Choose **Monthly**, **Weekly**, **Daily** or **Hourly**.

Table Metadata

Lists every table in the data source with the following columns:

<table style="border-collapse: collapse;"><tbody><tr style="height: 20px;"><td style="vertical-align: top; width: 159px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;"><strong>Column</strong></p></td><td style="vertical-align: top; width: 464px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;"><strong>What it shows</strong></p></td></tr><tr style="height: 20px;"><td style="vertical-align: top; width: 159px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Table Name</p></td><td style="vertical-align: top; width: 464px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Name of the table. Select a row to see its columns.</p></td></tr><tr style="height: 20px;"><td style="vertical-align: top; width: 159px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Record Counts</p></td><td style="vertical-align: top; width: 464px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Number of rows</p></td></tr><tr style="height: 20px;"><td style="vertical-align: top; width: 159px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Size in Bytes</p></td><td style="vertical-align: top; width: 464px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Table size</p></td></tr><tr style="height: 20px;"><td style="vertical-align: top; width: 159px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Statistics</p></td><td style="vertical-align: top; width: 464px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Date and time statistics were last run, and the run button</p></td></tr><tr style="height: 20px;"><td style="vertical-align: top; width: 159px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Index</p></td><td style="vertical-align: top; width: 464px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Index status, and the button to index the table for content search</p></td></tr><tr style="height: 20px;"><td style="vertical-align: top; width: 159px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Tags</p></td><td style="vertical-align: top; width: 464px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Tags on the table</p></td></tr><tr style="height: 20px;"><td style="vertical-align: top; width: 159px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Description</p></td><td style="vertical-align: top; width: 464px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Table description</p></td></tr></tbody></table>

Run table statistics

Select the run icon (▷) in the **Statistics** column. Record count, size and the date update when the job completes.

Index a table

Select the **Run Index** icon in the **Index** column. The table's values can then be found with **By contents** search.

Add or remove a tag

Add a description

Column Metadata

Select a table row in **Table Metadata**. The **Columns of <table>** section opens below with each column's type, statistics, tags and description.

Run column statistics

Select the run icon (▷) on the column row. The **Statistics** column then shows:

-   **Card**: cardinality (number of distinct values)
-   **Min** and **Max**: string length for text columns, or the value for numeric columns

Metadata History

Shows changes to the data source, its tables and columns, with a timestamp. Select the refresh icon to load the latest changes.

<table style="border-collapse: collapse;"><tbody><tr style="height: 20px;"><td style="vertical-align: top; width: 159px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;"><strong>Column</strong></p></td><td style="vertical-align: top; width: 464px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;"><strong>What it shows</strong></p></td></tr><tr style="height: 20px;"><td style="vertical-align: top; width: 159px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Change On</p></td><td style="vertical-align: top; width: 464px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Date and time of the change</p></td></tr><tr style="height: 20px;"><td style="vertical-align: top; width: 159px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Entity</p></td><td style="vertical-align: top; width: 464px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">What changed, for example DATASOURCE or TABLE</p></td></tr><tr style="height: 20px;"><td style="vertical-align: top; width: 159px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Operation</p></td><td style="vertical-align: top; width: 464px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Type of change, for example INITIALIZE or ADD</p></td></tr><tr style="height: 20px;"><td style="vertical-align: top; width: 159px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Description</p></td><td style="vertical-align: top; width: 464px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Details of the change</p></td></tr></tbody></table>

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-26-48-1379-AM.png)

Search Metadata

In **Data Explorer**, select the **Search Metadata** icon next to the search box. A **Search Metadata** tab opens with three search options.

By tag

Select one or more tags, or type to filter the tag list. Results show the **Type**, **Name**, **Database** and **Tags** for each matching table or column.

By metadata

Search table names, column names, tags and descriptions. Use \* as a wildcard.

By contents

Search for values stored inside tables. Use \* as a wildcard.

**Note:** Only indexed tables are searched. Run the index from the **Index** column in Table Metadata, or select **Build index** on the search page.

Where to Find Old UI Features

<table style="border-collapse: collapse;"><tbody><tr style="height: 20px;"><td style="vertical-align: top; width: 213px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;"><strong>Old UI</strong></p></td><td style="vertical-align: top; width: 410px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;"><strong>New UI</strong></p></td></tr><tr style="height: 20px;"><td style="vertical-align: top; width: 213px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Table Metadata tab</p></td><td style="vertical-align: top; width: 410px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Data source &gt; <strong>Metadata</strong> &gt; Table Metadata and Columns of &lt;table&gt;</p></td></tr><tr style="height: 20px;"><td style="vertical-align: top; width: 213px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Metadata Change History tab</p></td><td style="vertical-align: top; width: 410px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Data source &gt; <strong>Metadata</strong> &gt; Update Cycle and Metadata History</p></td></tr><tr style="height: 20px;"><td style="vertical-align: top; width: 213px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Metadata Search tab</p></td><td style="vertical-align: top; width: 410px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Data Explorer &gt; <strong>Search Metadata</strong> &gt; By metadata / By contents</p></td></tr><tr style="height: 20px;"><td style="vertical-align: top; width: 213px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Tags tab</p></td><td style="vertical-align: top; width: 410px; border: 1px solid #bfbfbf;"><p style="margin-top: 0px; margin-right: 0px; margin-bottom: 0px;">Data Explorer &gt; <strong>Search Metadata</strong> &gt; By tag</p></td></tr></tbody></table>
