---
source: kbase
url: https://kbase.zetaris.com/knowledge/how-to-ccnnect-to-json-from-local-machine
title: "How to Connect to a json/csv file from local machine"
kind: how-to
lastmod: 2026-10-28
retrieved: 2026-11-10
sha256: 22a3323f9e025884f238ec7b7ed37b2b451ede166662803e3e7acfce78be8b68
---
# How to Connect to a json/csv file from local machine

This article describes how to upload a local JSON or CSV file to the Zetaris NDP File System and register it as a virtual table so it can be queried through SQL.

The process involves two main steps:

1\. Upload the file to the NDP File System (Zetaris internal storage).

2\. Register the uploaded file as a virtual table using the **Create Table** wizard.

<table style="border-collapse: collapse; border-style: none;"><tbody><tr><td style="width: 720px; vertical-align: top; border: 1px solid #e7e7ee;"><p><strong>Prerequisite: You must have access to a File Source &amp; API data source (e.g. public_demo) in the Data Explorer. If you do not see one, contact your Zetaris administrator.</strong></p></td></tr></tbody></table>

Part 1: Upload Files to the NDP File System

The NDP File System is internal storage within the Zetaris platform. You can upload JSON, CSV, XML, Parquet and ORC files here before registering them as tables.

**1.** In the left sidebar, click **NDP File System**. The root directory lists the storage folders, including **file-store** and **key-trust-store**.

**2.** Open the **file-store** folder. This is where data files are stored.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-23-18-1989-AM.png)

_NDP File System root directory_

**3.** To organise your files, create a subfolder. Click the **New folder** icon in the toolbar (top-right), enter a folder name (e.g. json\_files) and press Enter or click the checkmark to confirm.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-23-17-9438-AM.png)

_Creating a subfolder in file-store_

**4.** Open your folder, then click the **Upload** icon in the toolbar. An upload panel appears at the top of the page. Drag your JSON or CSV file into the drop zone, or click **Browse files** to select it from your computer.

**5.** The file is listed as ready. Click the **Upload** icon in the panel to upload it.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-23-19-9136-AM.png)

_Upload panel: drag files or click Browse files, then Upload_

**6.** The uploaded file appears in the folder listing.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-23-20-1982-AM.png)

_Uploaded file visible in the NDP File System_

<table style="border-collapse: collapse; border-style: none;"><tbody><tr><td style="width: 720px; vertical-align: top; border: 1px solid #e7e7ee;"><p><strong>Tip: You can upload multiple files at once by dragging them together into the drop zone.</strong></p></td></tr></tbody></table>

Part 2: Register the File as a Virtual Table

Once the file is uploaded, register it as a virtual table so it can be queried with SQL.

**7.** In the Data Explorer (left panel), expand **File Source & API** and click your data source (e.g. public\_demo) to open its detail page. In the toolbar, click **Create Table** to launch the three-step wizard.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-23-19-3797-AM.png)

_File source detail page with Create Table_

**8.** **Step 1, Source Type:** select **File store** (the default) and click **Next**.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-23-18-4404-AM.png)

_Create Table wizard, Step 1: Source Type_

**Step 2, Configuration:** configure the following fields (9 to 12), then click **Next** (13).

<table style="border-collapse: collapse; border-style: none;"><tbody><tr><td style="width: 360px; vertical-align: top; border: 1px solid #e7e7ee;"><p><strong>Field</strong></p></td><td style="width: 360px; border-top: 1px solid #e7e7ee; border-right: 1px solid #e7e7ee; border-bottom: 1px solid #e7e7ee; border-left-style: none; vertical-align: top;"><p><strong>Description</strong></p></td></tr><tr><td style="width: 360px; border-right: 1px solid #e7e7ee; border-bottom: 1px solid #e7e7ee; border-left: 1px solid #e7e7ee; border-top-style: none; vertical-align: top;"><p>File Format</p></td><td style="width: 360px; border-style: none solid solid none; border-bottom-width: 1px; border-bottom-color: #e7e7ee; border-right-width: 1px; border-right-color: #e7e7ee; vertical-align: top;"><p>Select the format of your file: CSV, JSON, XML, Parquet or ORC.</p></td></tr><tr><td style="width: 360px; border-right: 1px solid #e7e7ee; border-bottom: 1px solid #e7e7ee; border-left: 1px solid #e7e7ee; border-top-style: none; vertical-align: top;"><p>Storage Provider</p></td><td style="width: 360px; border-style: none solid solid none; border-bottom-width: 1px; border-bottom-color: #e7e7ee; border-right-width: 1px; border-right-color: #e7e7ee; vertical-align: top;"><p>Select NDP File System. No cloud credentials are needed.</p></td></tr><tr><td style="width: 360px; border-right: 1px solid #e7e7ee; border-bottom: 1px solid #e7e7ee; border-left: 1px solid #e7e7ee; border-top-style: none; vertical-align: top;"><p>Table Name</p></td><td style="width: 360px; border-style: none solid solid none; border-bottom-width: 1px; border-bottom-color: #e7e7ee; border-right-width: 1px; border-right-color: #e7e7ee; vertical-align: top;"><p>Enter a name for the virtual table (e.g. customers).</p></td></tr><tr><td style="width: 360px; border-right: 1px solid #e7e7ee; border-bottom: 1px solid #e7e7ee; border-left: 1px solid #e7e7ee; border-top-style: none; vertical-align: top;"><p>Files</p></td><td style="width: 360px; border-style: none solid solid none; border-bottom-width: 1px; border-bottom-color: #e7e7ee; border-right-width: 1px; border-right-color: #e7e7ee; vertical-align: top;"><p>An inline file browser shows the /file-store directory. Open your folder and select the file to register.</p></td></tr><tr><td style="width: 360px; border-right: 1px solid #e7e7ee; border-bottom: 1px solid #e7e7ee; border-left: 1px solid #e7e7ee; border-top-style: none; vertical-align: top;"><p>Delimiter</p></td><td style="width: 360px; border-style: none solid solid none; border-bottom-width: 1px; border-bottom-color: #e7e7ee; border-right-width: 1px; border-right-color: #e7e7ee; vertical-align: top;"><p>CSV only. Set the column delimiter character (default: comma).</p></td></tr><tr><td style="width: 360px; border-right: 1px solid #e7e7ee; border-bottom: 1px solid #e7e7ee; border-left: 1px solid #e7e7ee; border-top-style: none; vertical-align: top;"><p>Additional Parameters</p></td><td style="width: 360px; border-style: none solid solid none; border-bottom-width: 1px; border-bottom-color: #e7e7ee; border-right-width: 1px; border-right-color: #e7e7ee; vertical-align: top;"><p>Optional. Add key-value pairs such as header=true or inferSchema=true.</p></td></tr></tbody></table>

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-23-18-6557-AM.png)

_Create Table wizard, Step 2: Configuration with NDP File System_

**Step 3, Preview:** review the detected columns and sample rows (14). If everything looks correct, click **Create** (15) to register the table.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-23-19-5978-AM.png)

_Create Table wizard, Step 3: Preview_

<table style="border-collapse: collapse; border-style: none;"><tbody><tr><td style="width: 720px; vertical-align: top; border: 1px solid #e7e7ee;"><p><strong>Note: For JSON files, the Delimiter field is hidden. Each JSON file is read as one JSON document, so store multiple records as a JSON array. For CSV files, the header and inferSchema parameters appear by default.</strong></p></td></tr></tbody></table>

Verify the Table

After registration, confirm the table is available:

**16.** The new table appears in the **Table Metadata** list of your data source and in the Data Explorer tree.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-23-20-4034-AM.png)

_New table listed under the data source_

**17.** Open **Workbench > SQL Workspace** and run a query to test the table:

SELECT \* FROM public\_demo.customers LIMIT 10;

**18.** Click **Execute** (or press Ctrl+Enter).

**19.** The query results confirm that the file has been successfully registered and is queryable through SQL.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-23-19-0326-AM.png)

_Query results in SQL Workspace_

Summary

<table style="border-collapse: collapse; border-style: none;"><tbody><tr><td style="width: 360px; vertical-align: top; border: 1px solid #e7e7ee;"><p><strong>Step</strong></p></td><td style="width: 360px; border-top: 1px solid #e7e7ee; border-right: 1px solid #e7e7ee; border-bottom: 1px solid #e7e7ee; border-left-style: none; vertical-align: top;"><p><strong>Action</strong></p></td></tr><tr><td style="width: 360px; border-right: 1px solid #e7e7ee; border-bottom: 1px solid #e7e7ee; border-left: 1px solid #e7e7ee; border-top-style: none; vertical-align: top;"><p>1</p></td><td style="width: 360px; border-style: none solid solid none; border-bottom-width: 1px; border-bottom-color: #e7e7ee; border-right-width: 1px; border-right-color: #e7e7ee; vertical-align: top;"><p>Open the NDP File System from the left sidebar</p></td></tr><tr><td style="width: 360px; border-right: 1px solid #e7e7ee; border-bottom: 1px solid #e7e7ee; border-left: 1px solid #e7e7ee; border-top-style: none; vertical-align: top;"><p>2</p></td><td style="width: 360px; border-style: none solid solid none; border-bottom-width: 1px; border-bottom-color: #e7e7ee; border-right-width: 1px; border-right-color: #e7e7ee; vertical-align: top;"><p>Open file-store and create a subfolder if needed</p></td></tr><tr><td style="width: 360px; border-right: 1px solid #e7e7ee; border-bottom: 1px solid #e7e7ee; border-left: 1px solid #e7e7ee; border-top-style: none; vertical-align: top;"><p>3</p></td><td style="width: 360px; border-style: none solid solid none; border-bottom-width: 1px; border-bottom-color: #e7e7ee; border-right-width: 1px; border-right-color: #e7e7ee; vertical-align: top;"><p>Upload your JSON or CSV file using the Upload tool</p></td></tr><tr><td style="width: 360px; border-right: 1px solid #e7e7ee; border-bottom: 1px solid #e7e7ee; border-left: 1px solid #e7e7ee; border-top-style: none; vertical-align: top;"><p>4</p></td><td style="width: 360px; border-style: none solid solid none; border-bottom-width: 1px; border-bottom-color: #e7e7ee; border-right-width: 1px; border-right-color: #e7e7ee; vertical-align: top;"><p>Open your File Source in the Data Explorer and click Create Table</p></td></tr><tr><td style="width: 360px; border-right: 1px solid #e7e7ee; border-bottom: 1px solid #e7e7ee; border-left: 1px solid #e7e7ee; border-top-style: none; vertical-align: top;"><p>5</p></td><td style="width: 360px; border-style: none solid solid none; border-bottom-width: 1px; border-bottom-color: #e7e7ee; border-right-width: 1px; border-right-color: #e7e7ee; vertical-align: top;"><p>Select File store as the source type</p></td></tr><tr><td style="width: 360px; border-right: 1px solid #e7e7ee; border-bottom: 1px solid #e7e7ee; border-left: 1px solid #e7e7ee; border-top-style: none; vertical-align: top;"><p>6</p></td><td style="width: 360px; border-style: none solid solid none; border-bottom-width: 1px; border-bottom-color: #e7e7ee; border-right-width: 1px; border-right-color: #e7e7ee; vertical-align: top;"><p>Set File Format, choose NDP File System as the storage provider and select the file</p></td></tr><tr><td style="width: 360px; border-right: 1px solid #e7e7ee; border-bottom: 1px solid #e7e7ee; border-left: 1px solid #e7e7ee; border-top-style: none; vertical-align: top;"><p>7</p></td><td style="width: 360px; border-style: none solid solid none; border-bottom-width: 1px; border-bottom-color: #e7e7ee; border-right-width: 1px; border-right-color: #e7e7ee; vertical-align: top;"><p>Preview the data and click Create</p></td></tr></tbody></table>
