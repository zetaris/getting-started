---
source: kbase
url: https://kbase.zetaris.com/knowledge/sql-editor-overview
title: "SQL Editor"
kind: other
lastmod: 2026-10-28
retrieved: 2026-11-10
sha256: 9a2f9a1a24e02ba9ea01cde26a668bf5a2b8dc210cac2f500f44d9a3929a0c64
---
# SQL Editor

Full list of SQL Commands

-   [Zetaris SQL Manual](https://kbase.zetaris.com/knowledge/sql-manual)

The SQL Editor (**Workbench > SQL Workspace**) allows you to:

Register metadata from physical, logical, and streaming data sources in bulk

Manage metadata schema platform-wide

Run ad-hoc queries across virtual data sources

Materialise and cache virtual data sources

Run virtual data source statistics

Specify virtual data source partitions

Create permanent views and data marts of your virtual data sources

Configure security, LDAP integration, user management, and role-based access control

When you open **SQL Workspace**, the list of saved SQL queries (**All Sql Scripts**) is displayed. Click **New Query** to open a new query tab, or click a saved query to open it. Use **Favorites** to show your favourite queries, and **Open Editor** to return to the query tabs that are already open.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-36-24-5143-AM.png)

_Saved SQL queries_

In the left panel, you can view **Data Explorer**. Here you can view all the virtual databases, data sources, streams, data marts, and views for use in any query.

The SQL Editor toolbar is at the top of the editor. It allows you to perform the following functions:

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-36-24-2096-AM.png)

_SQL Workspace editor_

**New Tab (+)** - adds a new query tab.

**Save (Ctrl+S)** - saves new or edited SQL queries with a name and description.

**Execute (Ctrl+Enter)** - executes the SQL code in the editor, or the SQL code that has been highlighted.

**Stop (Alt+S)** - stops SQL query execution.

**Plan (Alt+Q)** - displays the query execution plan in the **Query Plan** tab.

**Export (Alt+E)** - exports the query output.

**Format SQL** - displays the SQL code in the editor in a human-readable format.

**Engine selector** - selects the compute engine used to run the query (for example **Default** Spark, or a Presto engine).

**Limit** - sets the maximum number of results to be returned by a query (10, 50, 100, 500 or 1000).
