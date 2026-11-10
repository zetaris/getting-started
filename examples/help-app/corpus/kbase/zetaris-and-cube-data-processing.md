---
source: kbase
url: https://kbase.zetaris.com/knowledge/zetaris-and-cube-data-processing
title: "Zetaris and cube data processing"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 3482c4e632a872431bf8c1fef93bd69cd15953905b9aa1930eac7cfe86f13c07
---
# Zetaris and cube data processing

## This guide provides all the required steps in creating data cubes within Zetaris and how to visualize the data within the cube.

### Creating a Data Cube within Zetaris

### Permanent Views

In this example, we create a data cube using the virtual view functionality of Zetaris.

The benefits of creating a data cube using a permanent view within Zetaris is that the query utilizes up-to-date data when executed which allows for powerful integration with streaming sources.

The following was executed to create a basic Data Cube.

```
CREATE DATASOURCE VIEW orders_cube as (    SELECT COUNT(DISTINCT o_orderkey) as total_customer_orders,  SUM(l_quantity) as total_units_purchased,  ROUND(AVG(o_totalprice), 2) as average_sales_price,  year_c as year,  nation_id, nation    FROM (        SELECT o_orderkey,  l_quantity,  o_totalprice,  EXTRACT(            YEAR            FROM o_orderdate        ) as year_c, n_nationkey as nation_id,  n_name as nation        FROM (            SELECT *            FROM AZURE_MSSQL.customer c            INNER JOIN AZURE_MSSQL.orders o on o.o_custkey = c.c_custkey            INNER JOIN AZURE_MSSQL.lineitem l on o.o_orderkey = l.l_orderkey            INNER JOIN AZURE_MSSQL.nation n on n.n_nationkey = c.c_nationkey        )    )    GROUP BY CUBE(year_c, nation_id, nation))
```

### Example output of permanent view

![ex_pv_dc](https://kbase.zetaris.com/hs-fs/hubfs/ex_pv_dc.png)

### Data Pipelines

Alternatively you can create a data cube within Zetaris using Data Pipelines.

The Benefits of using a data pipeline is that you can separate select queries and data manipulation across multiple pipeline objects for easier visual management of the resources.

For Example the following pipeline was used to create a similar data cube as above shown above.

![ex_dp_dc](https://kbase.zetaris.com/hs-fs/hubfs/ex_dp_dc.png)

To reproduce the above refer to the below steps.

1.  sqltable\_0:
    
    ```
     SELECT * FROM AZURE_MSSQL.customer
    ```
    
2.  sqltable\_1:
    
    ```
     SELECT *, EXTRACT(YEAR FROM o_orderdate) as year_c FROM AZURE_MSSQL.orders
    ```
    
3.  sqltable\_2:
    
    ```
     SELECT * FROM AZURE_MSSQL.lineitem
    ```
    
4.  sqltable\_3: 
    
    ```
    SELECT * FROM AZURE_MSSQL.nation
    ```
    
5.  join\_4:![join_1](https://kbase.zetaris.com/hs-fs/hubfs/join_1.png)
    
6.  join\_5:![join_2](https://kbase.zetaris.com/hs-fs/hubfs/join_2.png)
7.  join\_6:![join_3](https://kbase.zetaris.com/hs-fs/hubfs/join_3.png)
8.  projection\_1:![proj_1](https://kbase.zetaris.com/hs-fs/hubfs/proj_1.png)
9.  aggregation:![aggr_1](https://kbase.zetaris.com/hs-fs/hubfs/aggr_1.png)

### Example preview of Data Pipeline

 ![exo_dp_dc](https://kbase.zetaris.com/hs-fs/hubfs/exo_dp_dc.png)

### Visualizing a Data Cube

### Requirements

-   Python version 3.8+
    
-   Python Libraries Required:
    
    -   pandas
        
    -   requests
        
    -   json
        
    -   getpass
        
    -   matplotlib.pyplot
        
    -   seaborn
        
-   An accessible machine with a GUI
    

utilize the pip install function to download the above Python Libraries

### Instructions

1.  Download the following python scripts [here](https://github.com/zetaris/custsuccess/tree/main/data_cube_visualization).
    
    1.  Encrypt Script
        
    2.  Decrypt Script
        
    3.  Cube Visualization Script
        
2.  Ensure that you’re environment is running the advanced API on version 5 or greater
    
3.  Run the following command to visualize your data cube:
    
    1.  ```
        python cube_visualization.py <decrypt_key> <alpha-numeric_org_id> <api_url> <permanent_view_name> <aggregated_column> <main_column_1> <main_column_2>
        ```
        
        For Example:
        
        ```
        python cube_visualization.py zetaris XXXXXXXX apiservice.trial.enterprise.zetaris.com orders_cube average_sales_price year nation_id
        ```
        

### Example Output

![Chart Output](https://kbase.zetaris.com/hs-fs/hubfs/Chart%20Output.png)
