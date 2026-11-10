---
source: kbase
url: https://kbase.zetaris.com/knowledge/migrating-data-objects-from-one-zetaris-instance-to-another-using-airflow
title: "Migrating Data Objects from one Zetaris instance to another using Airflow"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: af9642be4d4beabd4ef24ec024195cdd9e0622e1e53c62547a1fa9ada3f92ad0
---
# Migrating Data Objects from one Zetaris instance to another using Airflow

## This page lists all the steps that needs to be followed in order to implement the data objects migration mechanism for Zetaris Lightning. This mechanism is useful to migrate objects (pipelines, data marts, views) from one Zetaris instance to another.

### **Prerequisites:**

-   Before running the dags, make sure to have Microsoft Teams and Slack connections set up in Airflow for notifications. Refer to the [Version Control In Zetaris](https://kbase.zetaris.com/knowledge/version-control-in-zetaris-using-github-and-airflow?hs_preview=UhOYfMdK-96022112275) documentation for the setup steps.

* * *

### Setting up Airflow for Migration of Data Objects

We need to create variables on the Airflow UI to provide parameters for the migration process.  Follow these steps:

-   On the Airflow UI, navigate to the Admin section and select "Variables" from the dropdown list.
    
-   Upload the [Airflow Variables](https://kbase.zetaris.com/hubfs/Zetaris_Migration_Objects.json)  content as a JSON file by selecting "Choose File," and then import it by clicking "Import Variables" in Airflow.
    

| 
**Variable Name**

 | 

**Value**

 |
| --- | --- |
| 

Email\_Address

 | 

<email\_address\_for\_notifications>

 |
| 

Migration\_Data\_Object\_Container\_Name

 | 

<pipeline\_container name **or** data\_mart name **or** permanent\_view name>

 |
| 

Migration\_Data\_Object\_Pipeline\_Name

 | 

<pipeline\_name>

 |
| 

Migration\_Data\_Object\_Type

 | 

permanent\_views _**OR**_ data\_marts _**OR**_ pipelines

 |
| 

Option\_For\_Migration

 | 

Any value from 1-5 or 7 (please refer to table below)

 |
| 

Target\_Lightning\_API\_URL

 | 

<target-environment-api-url>

 |
| 

Target\_Lightning\_Password

 | 

<target-environment-user-password>

 |
| 

Target\_Lightning\_User

 | 

<target-environment-user-email>

 |

  
![Screenshot 2023-07-28 at 13.25.39](https://kbase.zetaris.com/hs-fs/hubfs/Screenshot%202023-07-28%20at%2013.25.39.png)  

Variables in airflow

  

> **Please Note:**
> 
> -   By default, the installation of Airflow includes predefined variables related to Airflow configuration and the Source Zetaris Environment.
>     
> -   The table provided below contain either example values or parameter names, which should be replaced with appropriate and specific values.
>     
> -   In the case of migration of Pipeline Container / Permanent View / Data Mart, leave the variable ' _**Migration\_Data\_Object\_Pipeline\_Name**_' with a default value of a single space (' ').
>     
> -   On the Airflow UI, for migration mechanism, edit the variable values below in LOWER CASE before triggering the DAG.
>     

  

-   Please refer to the table below for the different types of migration mechanisms with the specific required user inputs for the variables defined in the above step on the Airflow UI.

| 
**Type of Migration (Level of Migration)**

 | 

**Description**

 | 

**Variable1**  
Migration\_Data\_Object\_Type

 | 

**  
Variable2**  
Migration\_Data\_Object\_Container\_Name

 | 

**  
Variable3**  
Migration\_Data\_Object\_Pipeline\_Name

 |
| --- | --- | --- | --- | --- |
| 

Container

 | 

Migrate any Pipeline Container or Data Mart Container or a individual permanent view (allowed to enter only one option at any time)

 | 

_pipelines_  
**OR**  
_data\_marts_  
**OR**  
permanent\__views_

 | 

_<pipleine\_container\_name>_

**OR**

_<data\_mart\_container\_name>_

**OR**

_<permanent\_view\_name>_

 | 

_<single\_space>_

 |
| 

Individual Pipeline

 | 

Migrate any individual pipeline

 | 

_pipelines_

 | 

_<pipleine\_container\_name>_

 | 

_<pipeline\_name>_

 |

  

-   Please refer to the table below for the different options of migration.

  

| 
**Option of Migration**

 | 

**Description**

 |
| --- | --- |
| 

1

 | 

Data Pipeline Container

 |
| 

2

 | 

Individual Data Pipeline

 |
| 

3

 | 

Data Quality Pipelines Container

 |
| 

4

 | 

Individual Data Quality Pipeline

 |
| 

5

 | 

Data Mart

 |
| 

7

 | 

Permanent View

 |

-   After setting up the airflow and defining the necessary variables, you are all set to execute the '_**Migrate****\_Zetaris\_Data\_Objects**_' dag.  
    
    #### **![Screenshot 2023-07-28 at 13.56.32](https://kbase.zetaris.com/hs-fs/hubfs/Screenshot%202023-07-28%20at%2013.56.32.png)**
    
    #### **  
    Walkthrough of Data Objects Migration Mechanism (Video)  
      
    **
