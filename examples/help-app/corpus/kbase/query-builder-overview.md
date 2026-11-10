---
source: kbase
url: https://kbase.zetaris.com/knowledge/query-builder-overview
title: "Query Builder Overview"
kind: other
lastmod: 2026-10-28
retrieved: 2026-11-10
sha256: 4b0acbfc348be3e5f6b90ea983d22903150a359cbe7c775982de79704bc64688
---
# Query Builder Overview

Use the Query Builder to build a query and save it as a view interactively, using drag and drop. Zetaris generates the SQL statement automatically as you work.

To open it, go to **Workbench > Query Builder**. Views are organised in containers: open a container and click **New View**, enter a **View Name** and click **Create**. To edit an existing view, click its name.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-33-59-1013-AM.png)

_Query Builder containers and views_

The Query Builder editor has the following areas:

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-33-58-7781-AM.png)

_Query Builder Overview_

**Data Explorer** - This panel lists all available data sources, data marts, streams, pipeline tables and views. Drag a table from here onto the canvas to use it in the query.

**Canvas** - In this panel, you view the tables on the canvas, join them and add clauses to build the query. To join two tables, click the connector dot next to a column in one table, then click the matching column in the other table. An **INNER JOIN** is added between them.

**Clauses** - To add a clause to a column, click **+** next to the column, choose the clause type and click **Add**. The available clause types are **Select Column**, **Expression**, **Predicate**, **Group By**, **Having** and **Order By**.

_Adding a clause to a column_

The grouping options are set on the column in the canvas:

**Aggregation** - Applies an aggregate function to the column: AVG, COUNT, SUM, MIN, MAX, COUNT DISTINCT, COLLECT\_LIST, COLLECT\_SET, FIRST or LAST.

**GROUP BY** - The columns with the Group By clause are used in the GROUP BY section of the generated SQL query.

**CUBE** - Select **CUBE** in the Group By dropdown to apply the CUBE grouping operator to the GROUP BY.

**ROLLUP** - Select **ROLLUP** in the Group By dropdown to apply the ROLLUP grouping operator to the GROUP BY.

_Aggregation and Group By (CUBE / ROLLUP) options_

**SQL** - Returns the SQL generated from the Query Builder actions. It updates as you add tables, joins and clauses.

**Result** - Output from running the query. Click **Run** to execute the query and **Save** to save the view.

_Running the query and viewing the result_

Example: total order amount by country

1\. Drag **customers** and **orders** from **Data Explorer** onto the canvas.

2\. Join **customers.customer\_id** to **orders.customer\_id**.

3\. On **country**, add **Select Column** and **Group By**.

4\. On **amount**, add **Select Column** and set **Aggregation** to **SUM**.

5\. Click **Run** to see the total amount per country, then click **Save**.
