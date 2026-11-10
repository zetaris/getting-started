---
source: kbase
url: https://kbase.zetaris.com/knowledge/automated-change-data-capture-pipelines-creation-using-parameter-store
title: "Metadata driven architecture to auto-create change capture mechanism"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 71834bbf58f90941b5efb470a62d48bfa9cada9c471ecf420f0aa9de8b50f230
---
# Metadata driven architecture to auto-create change capture mechanism

## Creation of Change Data Capture (CDC) pipelines for multiple tables is a tedious task, and referring to this page will help us create the CDC pipelines automatically for any number of tables on the Zetaris UI.

Metadata driven architectures powers solutions or product by decomposing the metadata definitions instead of using data definitions for defining ETL or ELT flows.

In the data world, we tend to focus more on data driven solutions and architecture models. However, the metadata driven architecture has been widely adopted in product architectures and has been established as a flexible and resilient model that suits many product architectures.

Why not shift the attention now , to metadata driven solutions instead of data driven solutions? In a metadata driven solution, detailed attention is paid to how the data is stored on a platform and how can it be referred to without the complications of referential integrities. The focus is more on building reusable solutions without being disrupted by changes. Maybe it’s time we accept change as an integral part of a solution lifecycle. Keeping change in mind, every solution will need to cater for the scenario where the metadata or data might change.

For every such change, should we create a change and release management lifecycle? How about building solutions that will foresee change and will adapt to future changes.

#### **Some advantages of a metadata driven architecture are**

-   Future proof solutions for minor fixes and changes to the platform/solution/enterprise
    
-   Create more saleable and resilient transformation during an ETL/ELT flow to minimise the effect of data changes
    
-   Add and remove components of a solution without triggering a full-fledged engineering and release management life cycle
    
-   Reduce dependencies on IT expertise in any particular tool or technology to manage changes to existing pipelines
    
-   Improve the cost efficiency of every engineering effort that goes into building the foundation of a metadata driven solution.
    
-   The metadata driven model generates a shift in the uniform development process , wherein business analysts and data engineers use the same set of variants to build the solution. This leads to a democratic consumption of data.
    
-   Create fluid data models like a fluid data vault structure can be enabled by using a metadata driven architecture
    

#### **How do we implement a metadata driven solution?**

To implement this architecture we will need to define data structures similar to those shown in the below diagram.

The Zetaris Networked Data Platform  has been used to capture the meta information of various source systems like streaming distributions(Apache Kafka) , SQL/NoSQL databases , API applications and the possible addition of AWS Glue in future

The incoming meta information results in the creation of the driver entities i.e the Metadata entity and the Data entity. The metadata entity is a physical entity which stores the source objects and their schema, relationships and status in a conformed model. The Data Entity is a virtual object that established virtual connections via the Zetaris platform and allows for searchable and analytics focused information retrieval from source.

These drivers are then used to create various solutions like Data Quality and Data Provisioning solutions.

![](https://kbase.zetaris.com/hubfs/image-png-Jan-25-2023-04-18-25-6301-AM.png)

Any future additions to source systems is handled via parameters and follow the same metadata model and storage patterns. Hence to add new sources to the Data Quality solution , it will require no major changes other than including the newly added information to the parameter store.

**Use-cases where metadata driven architectures automates the ETL process**

1.  In dealing with CRM systems like Salesforce where customers entities or system entities follow a proper naming convention. In such systems , the metadata of additional source systems can be inferred based on a pattern that the CRM system has already adopted
    
2.  The Raw Data Store maintained in data vaults can also be populated with these techniques as the data does not undergo transformation and the metadata can be used to redirect data from the source systems into the relevant hubs and satellites. This eliminates the need for engineering involvement every time a new source has to be brought into the integration.
    
3.  Repetitive rules based engines for data models that rely on a pattern for application of rules also benefit tremendously when they are metadata driven. This allows for easy manipulation of the engine without disturbing the actual rules.
    

| 
**Cost Factor**

 | 

**Reason for Cost**

 | 

**Traditional ETL**

 | 

**Metadata driven**

 |
| --- | --- | --- | --- |
| 

Software

 | 

Organisations can have varying needs from an ETL platform. In case a reporting tool and associated ETL tools are already being used across the organisation , it is preferred to opt for a standalone software.

With an Integrated software , the end-to-end BI platform can be opted for and is more suited to organisations who are looking for a suite of features.

 | 

Standalone Software=20%

Integrated ETL =45%

 | 

Metadata apps like Zetaris =20%

 |
| 

Hardware

 | 

Workstations for the initial ETL programming and servers (either on premises or in the cloud) on which to host the source data and target data repositories. Compute for the ETL processing itself, will be needed.

 | 

On-prem infrastructure = 30%

Cloud infrastructure =40%

(inclusive of storage)

 | 

On-prem infrastructure = 20%

Cloud infrastructure =30%

(no need for ETL storage)

 |
| 

Consulting

 | 

A discovery cost to help manage post-implementation ETL processes.

 | 

Discovery cost =20%

 | 

Discovery cost = 10%

 |
| 

Maintenance

 | 

Recurring costs for the ETL processes needs to be factored into ongoing maintenance costs to find your ETL's total cost of ownership (TCO).

TCO is dealt in different ways depending on the budget. Organisations may opt in for a one-time license cost or hire consultants for ongoing maintenance or upskill and train internal resources which becomes very cost effective in the long run

 | 

One -time license =20%

Consultants hired = 30%

Internal staff =25%

 | 

One -time license =20%

Consultants hired = 10%

Internal staff =10%

 |
| 

Training

 | 

Training becomes important if the strategy is to maintain the application internally. The ease of use of the software, reduces the training needs required to get developers up to speed. It becomes important for an ETL tool to connects to a wide variety of relational databases which will result in reduced training costs.

 | 

Training cost =20%

 | 

Training cost =5%

 |
| 

Development

 | 

In case of change management, it will be necessary to factor the opportunity cost of diverting efforts into maintaining changes to the data models or business rules.

The product allowing for parameterisation and pattern matching mechanism reduces development cost by reducing efforts involved in changes.

 | 

Developer cost =30%

 | 

Developer Cost =10%

 |

Using these meta modelling techniques , enterprises can be enabled to deploy multiple solutions using the same underlying infrastructure and resilient meta models . This makes the data solution lifecycle tremendously short allowing users to access their data quickly and without the hassle of a full-blown engineering intervention.  
  

### Zetaris Implementation Process

#### **Pre-requisites:**

1.  Zetaris must have its metastore DB registered on the Lightning UI with a given name **“metastore”**.
    
2.  JDBC credentials for the “_**metastore**_” datasource should be provided.
    
3.  Source and Target datasource connections should be present on the Zetaris UI.
    
4.  Tables in the source and target datasource should have the same schema.
    
5.  The cdc pipeline names should be prefixed with ‘_**cdc\_**_’ in the parameter store CSV file.
    

> Please Note:
> 
> 1\. The steps mentioned on this page use the source tables from the File Sources (CSV Files). Instead of CSV files, we can use any other data source (e.g. PostgresSQL, Snowflake, etc.).
> 
> 2\. On this page, ‘rds\_file’ is the source database, and ‘rds’ is the target database. Also, the CDC pipelines will be created for the tables ‘test\_table\_1’, ‘test\_table\_2’, ‘test\_table\_3’, and ‘test\_table\_4’.

### Flow Diagram

![](https://kbase.zetaris.com/hubfs/Flow%20Diagram-png.png)

### Pipeline Creation Steps:

**Step 1:**

Create the Parameter Store CSV file in the below format.

```
source_datasource_name,table_name,pipeline_name,target_datasource_namerds_file,test_table_1,cdc_test_table_1,rdsrds_file,test_table_2,cdc_test_table_2,rdsrds_file,test_table_3,cdc_test_table_3,rdsrds_file,test_table_4,cdc_test_table_4,rds
```

  

**Step 2:**

Upload the Parameter Store CSV file on Zetaris UI using the NDP File Store.

![](https://kbase.zetaris.com/hubfs/step%202-png.png)

**Step 3:**

Create a virtual file source named ‘_**param\_store**_’ using the NDP Fabric Builder on Zetaris UI.

![](https://kbase.zetaris.com/hubfs/step%203-png.png)

**Step 4:**

On the Zetaris UI, inside the ‘_**param\_store**_’ database, register the ‘_**parameter\_store.csv**_' file as a table named '_**parameter\_store**_’.

![](https://kbase.zetaris.com/hubfs/step%204-png.png)

**Step 5:**

Using the schema store view tab on Zetaris UI, create a database table ‘_**parameter\_store**_’ in any relevant datasource & register the datasource.

```
create table parameter_store(  id serial,  source_datasource_name text,  table_name text,  pipeline_name text,  target_datasource_name) using rds; register datasource tables from rds;
```

**Step 6:**

Create a pipeline container named ‘_**automated\_pipelines**_’ using the Data Pipelines tab on the Zetaris UI.

![](https://kbase.zetaris.com/hubfs/step%206-png.png)

_Please Note: Zetaris Team can assist to migrate the below pipelines.  
_

**Step 7:**

Inside the ‘_**automated\_pipelines**_’ container, create a pipeline named ‘_**param\_store**_’ to populate data into the database table from the Parameter Store CSV file.

![](https://kbase.zetaris.com/hubfs/step%207-png.png)

_**Possible changes in this pipeline:**_

1.  The ‘_**RDS.PARAMETER\_STORE**_’ could be different if the user has registered the parameter store table in any other database.
    
2.  The JDBC connection credentials for the ‘_**RDS.PARAMETER\_STORE**_’ table in the JDBC Sink Node named ‘_**jdbcsink\_3**_’.
    

**Step 8:**

Inside the ‘_**automated\_pipelines**_’ container, create a pipeline named ‘_**pipe\_rel\_inserts**_’ to populate data into the ‘_**pipeline\_relation**_’ Metastore database table that stores the name of the pipelines.

![](https://kbase.zetaris.com/hubfs/step%208-png.png)

_**Possible changes in this pipeline:**_

1.  The ‘_**RDS.PARAMETER\_STORE**_’ could be different if the user has registered the parameter store table in a different database.
    
2.  The value of the virtual column named ‘_**container\_name**_’ in ‘_**projection\_0**_’ will change if the user has any other pipeline container name other than ‘_**automated\_pipelines**_’.
    
3.  The SQL query in ‘_**sqltable\_2**_’, if the user has any other pipeline container name other than ‘_**automated\_pipelines**_’.
    
4.  The join predicate in ‘_**join\_4**_’, if the user has any other pipeline container name other than ‘_**automated\_pipelines**_’.
    
5.  The JDBC connection credentials for the ‘_**metastore**_._**pipeline\_relation**_’ table in the JDBC Sink Node named ‘_**jdbcsink\_6**_’.
    

**Step 9:**

Inside the ‘_**automated\_pipelines**_’ container, create a pipeline named ‘_**pipe\_node\_inserts**_’ to populate data into the ‘_**pipeline\_node**_’ Metastore database table that stores the information about the nodes inside the CDC pipelines.

![](https://kbase.zetaris.com/hubfs/step%209-png.png)

_**Possible changes in this pipeline:**_

1.  The SQL query in ‘_**sqltable\_0**_’ and ‘_**sqltable\_1**_’, if the user has any pipeline container name other than ‘_**automated\_pipelines**_’.
    
2.  The join predicate in ‘_**join\_3**_’, if the user has the pipeline container name other than ‘_**automated\_pipelines**_’.
    
3.  The JDBC connection credentials for the ‘_**metastore**_._**pipeline\_node**_’ table in the JDBC Sink Node named ‘_**jdbcsink\_5**_’.
    

**Step 10:**

Inside the ‘_**automated\_pipelines**_’ container, create a pipeline named ‘_**pipeline\_sql\_node\_inserts**_’ to populate data into the ‘_**pipeline\_sqltable**_’ Metastore database table that stores the information about the SQL Table nodes inside the CDC pipelines.

![](https://kbase.zetaris.com/hubfs/step%2010-png.png)

_**Possible changes in this pipeline:**_

1.  The SQL query in ‘_**sqltable\_0**_’ and ‘_**sqltable\_1**_’, if the user has any pipeline container name other than ‘_**automated\_pipelines**_’.
    
2.  The ‘_**RDS.PARAMETER\_STORE**_’ in ‘_**sqltable\_0**_’ could be different if the user has registered the parameter store table in any other database.
    
3.  The JDBC connection credentials for the ‘_**metastore**_._**pipeline\_sqltable**_’ table in the JDBC Sink Node named ‘_**jdbcsink\_9**_’.
    

**Step 11:**

Inside the ‘_**automated\_pipelines**_’ container, create a pipeline named ‘_**pipeline\_proj\_inserts**_’ to populate data into the ‘_**pipeline\_projection**_’ Metastore database table that stores the information about the Projection nodes inside the CDC pipelines.

![](https://kbase.zetaris.com/hubfs/step%2011-png.png)

_**Possible changes in this pipeline:**_

1.  The SQL query in ‘_**sqltable\_0**_’ and ‘_**sqltable\_1**_’, if the user has any pipeline container name other than ‘_**automated\_pipelines**_’.
    
2.  The ‘_**RDS.PARAMETER\_STORE**_’ in ‘_**sqltable\_0**_’ could be different if the user has registered the parameter store table in any other database.
    
3.  The JDBC connection credentials for the ‘_**metastore**_._**pipeline\_projection**_’ table in the JDBC Sink Node named ‘_**jdbcsink\_6**_’.
    

**Step 12:**

Inside the ‘_**automated\_pipelines**_’ container, create a pipeline named ‘_**pipeline\_join\_inserts**_’ to populate data into the ‘_**pipeline\_join**_ ’ Metastore database table that stores the information about the Join nodes inside the CDC pipelines.

![](https://kbase.zetaris.com/hubfs/step%2012-png.png)

_**Possible changes in this pipeline:**_

1.  The SQL query in ‘_**sqltable\_0**_’ and ‘_**sqltable\_1**_’, if the user has any pipeline container name other than ‘_**automated\_pipelines**_’.
    
2.  The ‘_**RDS.PARAMETER\_STORE**_’ in ‘_**sqltable\_0**_’ could be different if the user has registered the parameter store table in any other database.
    
3.  The JDBC connection credentials for the ‘_**metastore**_._**pipeline\_join**_’ table in the JDBC Sink Node named ‘_**jdbcsink\_1**_’.
    

**Step 13:**

Inside the ‘_**automated\_pipelines**_’ container, create a pipeline named ‘_**pipeline\_node\_schema\_inserts**_’ to populate data into the ‘_**pipeline\_node\_schema**_ ’ Metastore database table that stores the information about the Join nodes inside the CDC pipelines.

![](https://kbase.zetaris.com/hubfs/step%2013-png.png)

_**Possible changes in this pipeline:**_

1.  The ‘_**RDS.PARAMETER\_STORE**_’ could be different if the user has registered the parameter store table in any other database.
    
2.  The SQL query in ‘_**sqltable\_0**_’, if the user has any pipeline container name other than ‘_**automated\_pipelines**_’.
    
3.  The join predicate in ‘_**join\_5**_’ and ‘_**join\_7’**_, if the user has any other database where parameter store exists, instead of ‘_**RDS.PARAMETER\_STORE**_’.
    
4.  The value of the virtual column named ‘_**con\_name**_’ in ‘_**projection\_8**_’ if the user has any pipeline container name other than ‘_**automated\_pipelines**_’.
    
5.  The join predicate in ‘_**join\_1**_’, if the user has any pipeline container name other than ‘_**automated\_pipelines**_’.
    
6.  The JDBC connection credentials for the ‘_**metastore**_._**pipeline\_node\_schema**_’ table in the JDBC Sink Node named ‘_**jdbcsink\_4**_’.
    

**Step 14:**

Inside the ‘_**automated\_pipelines**_’ container, create a pipeline named ‘_**pipeline\_md5\_inserts**_’ to populate data into the ‘_**pipeline\_node\_schema**_ ’ Metastore database table that stores the information about the virtual columns stored in projection nodes which are created to store the md5 hash of all columns in a table to capture the delta data between source and target table.

![](https://kbase.zetaris.com/hubfs/step%2014-png.png)

_**Possible changes in this pipeline:**_

1.  The SQL query in ‘_**sqltable\_0**_’ and ‘_**sqltable\_3**_’, if the user has any pipeline container name other than ‘_**automated\_pipelines**_’.
    
2.  The join predicate in ‘_**join\_5'**_, if the user has any other pipeline container name other than ‘_**automated\_pipelines**_’.
    
3.  The SQL query in ‘_**sqltable\_1**_’, if the user has any other database where parameter store exists, instead of ‘_**RDS.PARAMETER\_STORE**_’ and target database has any name other than ‘RDS’.
    
4.  The JDBC connection credentials for the ‘_**metastore**_._**pipeline\_node\_schema**_’ table in the JDBC Sink Node named ‘_**jdbcsink\_9**_’.
    

### Pipeline Execution Steps

Once all the pipelines are created, we need to execute the pipelines in a specified order to avoid the primary and foreign key violation errors.  
  
The below image shows the order in which the pipelines need to be executed:

![](https://kbase.zetaris.com/hubfs/pipeline%20execution%20steps-png.png)

### Walkthrough of automated CDC Pipelines Creation Process (Video)
