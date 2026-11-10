---
source: kbase
url: https://kbase.zetaris.com/knowledge/the-fluid-data-vault
title: "The Fluid Data Vault"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 59b285992db522f15afc9914c1035be0928e273495246e64052f7ecf7e9c7dcd
---
# The Fluid Data Vault

**Objectives:**

The DataVault is a hub and spoke architecture that is easily scalable and can to a large extent be automated . In this whitepaper we will focus on the mechanisms that will be implemented to automate a Data Vault by using Zetaris models to infer the schema and keys for the Vault layers

**Databases**

A database is a structured collection of data with some implicit meaning. The data in a database is typically derived or collected from some real world source, and has an intended application. A database is made up of different tables, each table with columns that each represent a entity with a different data type. A row, or a tuple, of a table represents an instance of this table object.

**Business Keys**

Business keys are the unique attributes of data objects that can identify any given record in a dataset. A minimalistic approach is generally applied to a business key to maintain its uniqueness property. Note that a business key does not need to be a primary key.

**Foreign Keys**

In a relational schema , a foreign key represents the relation between two entities. It answers questions like Which is the parent object and which is the child object.

What is the nature of the relationship ? Is it a 1-to-1/1-to-many /many-to-many relationship. In the Data Vault world these relationships are key to establishing link tables or correlating between two hub tables

**Volatility of data**

Volatility is the measure of change. How frequently does the data in the data object change. A “name” field might rarely change in the lifetime of the record as compared to a “phone-number” field that has a probability of multiple changes over the life course of the record.

**The Mechanism**

The intention of the fluid data vault is to create and train models on existing data models so that we can enable the ability to infer a schema and relationships in case these are not made available explicitly. Based on these inferences , the system should be able to self-generate a proposed data vault model that will be made available for review to the end-users

![DVSequence](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/DVSequence.jpg)

![image-20211007-235901](https://kbase.zetaris.com/hs-fs/hubfs/image-20211007-235901.png)

### Technical Implementation

The steps mentioned below entails the creation of all the relevant hubs, sats and link tables for the fluid data vault on Zetaris UI.

**Prerequisites:**

1.  Zetaris must have its metastore DB registered on the Lightning UI with a given name **“metastore”**.
    
2.  JDBC credentials for the “_**metastore**_” datasource should be provided.
    
3.  All the source databases must be registered on the lightning UI.
    

> Please Note:
> 
> In this article,
> 
> 1\. The source databases are azure\_mssql, aws\_redshift and rds\_postgresql.
> 
> 2\. The database where the data vault entities/tables are stored is named as ‘trial\_vault’.
> 
> 3\. The container under which all the pipelines are created is named as ‘fluid\_data\_vault’.

**Step1:**

-   Create the pipeline named _**‘create\_hubs\_stmts’**_
    
-   This pipeline generates the DDL statements for hub tables creation
    
-   It considers the main datasource as ‘_**azure\_mssql**_’ and creates the same number of hub tables as the total number of tables in the ‘_**azure\_mssql**_’ datasource
    
-   The only requirement here is to add a business key tag in all of the ‘_**azure\_mssql**_’ tables
    
-   For example, the business key for the ‘_**customer**_’ table is ‘_**c\_custkey**_’ and the tag added is ‘_**bk**_’  
    ![step1](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/step1.png)
    
    ![](blob:https://zetaris.atlassian.net/9e2056ca-1f19-48ca-89f2-9f1f1e174f8d#media-blob-url=true&id=ed921fdb-39a9-44c2-bd00-e810abbaf44a&collection=contentId-2554691585&contextId=2554691585&height=353&width=1151&alt=)
    
    _**Business Key Tags**_
    
-   Each of the create hub table statements has the below columns:
    
    -   Business Key(s)
        
    -   BKCC
        
    -   Load Date
        
    -   Record Source
        
    -   MD5 Hash of Business Key(s) and BKCC (hk)
        
    -   MD5 Hash of all the columns other than the business key(s) (hd)
        

![](blob:https://zetaris.atlassian.net/e817a6cf-fbf8-4121-863a-2020894bf677#media-blob-url=true&id=1d4cf408-a440-4797-88c2-2d022d068d64&collection=contentId-2554691585&contextId=2554691585&height=340&width=1132&alt=)![e817a6cf-fbf8-4121-863a-2020894bf677](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/e817a6cf-fbf8-4121-863a-2020894bf677.png)

_**Example Output for Create Hubs Statements Pipelines**_

-   Example Query
    

CREATE TABLE h\_customer (hk\_h\_customer CHARACTER VARYING(100) NOT NULL, hd\_h\_customer CHARACTER VARYING(100) NOT NULL, c\_custkey integer ,dss\_load\_date date NOT NULL, dss\_record\_source CHARACTER VARYING(100) NOT NULL, bkcc CHARACTER VARYING(100) NOT NULL) using trial\_vault;

**Step2:**

-   Since we have three disparate sources from where we ingest data, we create three different pipelines
    
-   The pipelines are named _**‘create\_azure\_sats\_stmts’, ‘create\_postgre\_stg\_stmts’**_ and _**‘create\_aws\_redshift\_sats\_stmts’**_
    
-   These pipelines generate DDL statements for each of the satellite tables' creation
    
-   Each of the sat table names is suffixed with the source name (**eg**: ‘**s\_customer\_azure\_mssql**’), where ‘_**customer**_**'** is the table name and '_**azure\_mssql**_**’** is the source name
    
-   Each create sat table statement has the below columns:
    
    -   All the columns of the table except for the business key(s)
        
    -   Load Date
        
    -   Record Source
        
    -   BKCC
        
    -   MD5 Hash of Business Key column(s) and BKCC (hk)
        
    -   MD5 Hash of all the columns other than the business key column(s) (hd)
        

![](blob:https://zetaris.atlassian.net/d8e1a0dc-533c-4401-ba83-718343d3edb8#media-blob-url=true&id=1a8692a9-a346-4826-8be6-d3cefd07344d&collection=contentId-2554691585&contextId=2554691585&height=307&width=1009&alt=)![d8e1a0dc-533c-4401-ba83-718343d3edb8](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/d8e1a0dc-533c-4401-ba83-718343d3edb8.png)

_**Example Output for Create Sats Statements Pipelines for Postgre Source**_

-   Example Query:
    

CREATE TABLE s\_part\_azure\_mssql (hk\_h\_part CHARACTER VARYING(100) NOT NULL, hd\_h\_part CHARACTER VARYING(100) NOT NULL, p\_type text, p\_brand text, p\_retailprice float, p\_comment text, p\_mfgr text, p\_size integer, p\_name text, p\_container text ,dss\_load\_date date NOT NULL, dss\_record\_source CHARACTER VARYING(100) NOT NULL, bkcc CHARACTER VARYING(100) NOT NULL) using trial\_vault;

**Step3:**

-   Since we have three disparate sources from where we ingest data, we create three different pipelines and the pipelines are named _**‘create\_aws\_redshift\_stg\_stmts’, ‘create\_azure\_stg\_stmts’**_ and _**‘create\_postgre\_stg\_stmts’**_
    
-   These pipelines generate the DDL statements for staging views creation and these views will be used as the source to insert data into the hubs and the satellites
    
-   Each of the staging view names is suffixed with the source name (**eg**: ‘**v\_stg\_customer\_azure\_mssql**’), where ‘_**customer**_**'** is the table name and '_**azure\_mssql**_**’** is the source name
    
-   Each of the staging views has the below columns:
    
    -   All the columns of the table
        
    -   Load Date
        
    -   Record Source
        
    -   BKCC
        
    -   MD5 Hash of Business Key(s) and BKCC (hk)
        
    -   MD5 Hash of all the columns other than the business key(s) (hd)
        

![](blob:https://zetaris.atlassian.net/ba628665-c655-44a1-9b7b-07a52655d64a#media-blob-url=true&id=37143a3a-7dc6-4386-877d-7c46458c07c7&collection=contentId-2554691585&contextId=2554691585&height=288&width=1007&alt=)![ba628665-c655-44a1-9b7b-07a52655d64a](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/ba628665-c655-44a1-9b7b-07a52655d64a.png)

_**Example Output for Create Staging View Statements Pipelines for Azure Source**_

-   Example Query:
    

CREATE DATASOURCE VIEW v\_stg\_partsupp\_rds\_postgresql AS ( SELECT md5(concat('USA',lower(trim(coalesce(cast(ps\_partkey as varchar(255)),''''))))) as hk\_h\_partsupp, ps\_partkey, ps\_availqty, ps\_suppkey, ps\_supplycost, md5(concat(lower(trim(coalesce(cast(ps\_suppkey as varchar(255)),''''))),lower(trim(coalesce(cast(ps\_supplycost as varchar(255)),''''))),lower(trim(coalesce(cast(ps\_availqty as varchar(255)),''''))))) as hd\_h\_partsupp, current\_date() as dss\_load\_date, 'USA' as bkcc, 'rds\_postgresql' as dss\_record\_source FROM rds\_postgresql.partsupp);

 **Step4:**

-   Create the pipeline named _**‘create\_link\_tbl\_statements’**_
    
-   This pipeline generate the DDL statements for link tables creation
    
-   The only requirement here is to add a link tag in those hub tables between the tables we wish to connect/join
    
-   For example, if we want a link between the customer table and the nation table, then we add a tag ‘_**link\_customer\_to\_nation**_’ in front of both ‘_**h\_customer**_’ and ‘_**h\_nation**_’
    
-   Each of the link table names contains multiple hub table names (eg: If we wish to create a link between customer and nation then the link table name will be ‘_**l\_customer\_nation**_’)
    

![](blob:https://zetaris.atlassian.net/5b62c559-c166-4476-8274-47fc99135e5d#media-blob-url=true&id=cd5a5238-162f-4e80-88bb-4e116fe148ad&collection=contentId-2554691585&contextId=2554691585&height=469&width=1069&alt=)![5b62c559-c166-4476-8274-47fc99135e5d](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/5b62c559-c166-4476-8274-47fc99135e5d.png)

_**Link Table Tags**_

![](blob:https://zetaris.atlassian.net/83e8f407-1608-427a-b23a-036365e2231b#media-blob-url=true&id=6fb0c4f9-8716-44ae-ab36-242dbc1647b9&collection=contentId-2554691585&contextId=2554691585&height=203&width=1016&alt=)![83e8f407-1608-427a-b23a-036365e2231b](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/83e8f407-1608-427a-b23a-036365e2231b.png)

_**Example Output for Create Link Statements Pipelines**_

-   Example Query
    

CREATE TABLE l\_customer\_nation ( hk\_h\_link\_customer\_to\_nation CHARACTER VARYING (100), n\_nationkey integer, hk\_h\_nation text, dss\_load\_date date NOT NULL, dss\_record\_source CHARACTER VARYING(100) NOT NULL ) USING trial\_vault;

**Step5:**

-   Since we have three disparate sources from where we ingest data, we create three different pipelines
    
-   The pipelines are named _**‘create\_aws\_redshift\_link\_stg\_stmts’, ‘create\_azure\_mssql\_link\_stg\_stmts’**_ and _**‘create\_rds\_postgresql\_link\_stg\_stmts’**_
    
-   These pipelines generate the DDL statements for link staging views creation, and these views will be used as the source to insert data into the link tables
    
-   Each of the staging view name are suffixed with the source name (**eg**:‘**v\_stg\_link\_customer\_nation\_azure\_mssql**’), where ‘_**customer**_**'** and ‘_**nation**_’ are the table names and '_**azure\_mssql**_**’** is the source name
    
-   All the connected tables must have a column tag which defines the relationship between the tables. For example, ‘_**customer**_’ and ‘_**nation**_’ table are related to each other based on '_**nationkey**_'  
    ![collevellinktags1](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/collevellinktags1.png)![](blob:https://zetaris.atlassian.net/68defe54-2258-4c7d-9e2f-1e84dc4d5488#media-blob-url=true&id=b86ff6be-924f-4e94-bb9c-1f33e2f1ce06&collection=contentId-2554691585&contextId=2554691585&height=353&width=1151&alt=)_**Column Level Link Tags-1**_
    

![](blob:https://zetaris.atlassian.net/e2bfd733-b96f-4782-bffb-722f5edcd030#media-blob-url=true&id=3619df81-801c-4b13-838e-530b0bd909f6&collection=contentId-2554691585&contextId=2554691585&height=354&width=1153&alt=)![collevellinktags](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/collevellinktags.png)_**Column Level Link Tags-2**_

-   Each of the staging views has the below columns:
    
    -   Business keys of all the linked tables
        
    -   Load Date
        
    -   Record Source
        
    -   BKCC
        
    -   MD5 Hash of Business Key(s) of all the linked tables and BKCC (hk)
        
    -   MD5 Hash of all the Business Key(s) of individual tables and BKCC  
          
        
-   Example Query
    

CREATE DATASOURCE VIEW v\_stg\_link\_supplier\_to\_nation\_rds\_postgresql AS ( SELECT md5(concat('USA', n\_nationkey, s\_suppkey)) as hk\_h\_link\_supplier\_to\_nation, n\_nationkey, s\_suppkey, md5(concat('USA', lower(trim(coalesce(cast(s\_suppkey as varchar(255)),''''))))) as hk\_h\_supplier, md5(concat('USA', lower(trim(coalesce(cast(n\_nationkey as varchar(255)),''''))))) as hk\_h\_nation, NOW() as dss\_load\_date,'rds\_postgresql' as dss\_record\_source FROM rds\_postgresql.supplier, rds\_postgresql.nation WHERE n\_nationkey = s\_nationkey);

  
**Step6:**

-   Since we have three disparate sources from where we ingest data, we create three different pipelines and, the pipelines are named _**‘hubs\_azure\_insert\_statements’, ‘hubs\_postgre\_insert\_statements’**_ and _**‘hubs\_aws\_redshift\_insert\_statements’**_
    
-   These pipelines generate the DML statements for inserting the data into the hubs from the staging views
    
-   The insert statements will only insert delta records in the hub table and these delta records are captured based on the MD5 hash (hk) in the source and target tables
    
-   Since hub tables are common across all the sources and there is a possibility the entity name might not be the same as the hub name, so we need to map the entity to the relevant hub name and therefore we add the tag ‘_**maps\_to\_**_\*’ where \* is the hub table name
    
-   For example, if the entity name is ‘_**customer\_japan**_’, then we should map it to the customer hub and add the tag ‘_**maps\_to\_customer**_’  
    ![](blob:https://zetaris.atlassian.net/12e763fc-35e6-4833-8799-bce4abdfde60#media-blob-url=true&id=ec4de380-f5d3-46ed-a8f4-e81d69c5fc21&collection=contentId-2554691585&contextId=2554691585&height=491&width=828&alt=)![hubmappingleveltags](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/hubmappingleveltags.png)
    
    _**Hubs Mapping Table Level Tags**_
    

-   Example Query
    

INSERT INTO trial\_vault.h\_partsupp (ps\_partkey, hk\_h\_partsupp, hd\_h\_partsupp ,dss\_load\_date, dss\_record\_source, bkcc) SELECT vstg.ps\_partkey, vstg.hk\_h\_partsupp, vstg.hd\_h\_partsupp ,vstg.dss\_load\_date, vstg.dss\_record\_source, vstg.bkcc FROM v\_stg\_partsupp\_rds\_postgresql vstg LEFT JOIN trial\_vault.h\_partsupp htab ON vstg.hk\_h\_partsupp=htab.hk\_h\_partsupp WHERE htab.hk\_h\_partsupp IS NULL;

**Step7:**

-   Since we have three disparate sources from where we ingest data, we create three different pipelines
    
-   The pipelines are named _**‘sats\_aws\_redshift\_insert\_stmts’, ‘sats\_azure\_insert\_stmts’**_ and _**‘sats\_postgre\_insert\_stmts’**_
    
-   These pipelines generate the DML statements for inserting the data into the sats from the staging views
    
-   The insert statements will only insert delta records in the sat table and these delta records are captured based on the MD5 hash (hk) in the source and target tables
    
-   Example Query
    

INSERT INTO trial\_vault.s\_customer\_japan\_aws\_redshift (bkcc,  c\_name,  c\_phone,  dss\_load\_date,  dss\_record\_source,  hd\_h\_customer\_japan,  hk\_h\_customer\_japan) SELECT vstg.bkcc,  vstg.c\_name,  vstg.c\_phone,  vstg.dss\_load\_date,  vstg.dss\_record\_source,  vstg.hd\_h\_customer\_japan,  vstg.hk\_h\_customer\_japan FROM v\_stg\_customer\_japan\_aws\_redshift vstg LEFT JOIN trial\_vault.s\_customer\_japan\_aws\_redshift stab ON vstg.hd\_h\_customer\_japan=stab.hd\_h\_customer\_japan WHERE stab.hd\_h\_customer\_japan IS NULL;

**Step8:**

-   Since we have three disparate sources from where we ingest data, we create three different pipelines
    
-   The pipelines are named _**‘links\_azure\_insert\_statements’, ‘links\_aws\_redshift\_insert\_statements’**_ and _**‘links\_azure\_insert\_statements’**_
    
-   These pipelines generate the DML statements for inserting the data into the sats from the staging views
    
-   The insert statements will only insert delta records in the link table, and these delta records are captured based on the MD5 hash (hk\_h\_link) in the source and target tables
    
-   Example Query:
    

INSERT INTO trial\_vault.l\_supplier\_nation (dss\_record\_source,  hk\_h\_supplier,  n\_nationkey,  dss\_load\_date,  s\_suppkey,  hk\_h\_link\_supplier\_to\_nation,  hk\_h\_nation) SELECT vstg.dss\_record\_source ,vstg.hk\_h\_supplier ,vstg.n\_nationkey ,vstg.dss\_load\_date ,vstg.s\_suppkey ,vstg.hk\_h\_link\_supplier\_to\_nation ,vstg.hk\_h\_nation FROM v\_stg\_link\_supplier\_to\_nation\_azure\_mssql vstg LEFT JOIN trial\_vault.l\_supplier\_nation ltab ON vstg.hk\_h\_link\_supplier\_to\_nation = ltab.hk\_h\_link\_supplier\_to\_nation WHERE ltab.hk\_h\_link\_supplier\_to\_nation IS NULL;

**Step9:**

-   Create a git repository named ‘_**RawVault**_’
    
-   Add a branch named ‘_**ddl\_dml\_statements**_’ along with the ‘_**main**_’ branch where we can store all the statements generated from the above pipelines and store them as seperate file
    
-   Generate a token from [![](https://github.githubassets.com/favicon.ico)https://github.com/settings/tokens](https://github.com/settings/tokens) - Connect your Github account and save the token
    
-   Add a branch protection rule for main branch. The rule we need to tick is '**Require a pull request before merging**'
    

![3cbe8c21-1163-48fa-ae73-142130de54a2](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/3cbe8c21-1163-48fa-ae73-142130de54a2.png)

**Step10:**

-   create an airflow DAG named ‘_**DataVault\_Create\_Table\_Hubs\_Sats\_Stg\_Stmts**_’ on the airflow UI which generates the _**‘CREATE TABLE’**_ and _**‘CREATE VIEW’**_ statements for Hubs and Satellites and also stores the files in GitHub ‘_**ddl\_dml\_statements**_’ branch and generates a pull request to merge the changes into the ‘_**main’**_ branch, along with the email notification stating that the DAG execution was a success or a failure
    

![](blob:https://zetaris.atlassian.net/3cbe8c21-1163-48fa-ae73-142130de54a2#media-blob-url=true&id=f922d5c7-0517-4193-8311-a43381e3aabf&collection=contentId-2554691585&contextId=2554691585&height=609&width=1917&alt=)

_**DAG - DataVault\_Create\_Table\_Hubs\_Sats\_Stg\_Stmts**_

**Step11:**

-   The developer will then assign the pull request to the relevant authority/approver and after the approver has approved the pull request, the final changes in the Data Vault Schema (DDL/DML statements) will be merged into the ‘_**main’**_ branch
    

![](blob:https://zetaris.atlassian.net/350d8ca6-8f92-4304-9e45-b61ca60f51e1#media-blob-url=true&id=09771b19-90b9-4b99-af33-9096801cf314&collection=contentId-2554691585&contextId=2554691585&height=671&width=946&alt=)![350d8ca6-8f92-4304-9e45-b61ca60f51e1](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/350d8ca6-8f92-4304-9e45-b61ca60f51e1.png)

_**Pull Request after approval and merging changes**_

**Step12:**

-   Once the changes are approved and merged into the main branch, create an airflow DAG named ‘_**DataVault\_Execute\_Create\_Table\_Hubs\_Sats\_Stg\_Stmts**_’ on the airflow UI which executes all the create statements (both hubs & sats tables and staging views) on the Zetaris UI via the API  
      
    
    ![](blob:https://zetaris.atlassian.net/978c8950-f7a2-40ad-bcac-cc3724e90dc8#media-blob-url=true&id=e779ac2a-4bd0-4849-90ac-6e650b584238&collection=contentId-2554691585&contextId=2554691585&height=718&width=1915&alt=)![978c8950-f7a2-40ad-bcac-cc3724e90dc8](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/978c8950-f7a2-40ad-bcac-cc3724e90dc8.png)
    
    _**DAG -**_ _**DataVault\_Execute\_Create\_Table\_Hubs\_Sats\_Stg\_Stmts**_
    

**Step13:**

-   After the hubs & sats entities (tables & views) are created by scheduling the DAG created in Step 12, create another DAG named ‘_**DataVault\_Create\_Table\_Links\_Stg\_Stmts**_’ on the airflow UI which generates the _**‘CREATE TABLE’**_ and _**‘CREATE VIEW’**_ statements for Links and also stores the files in GitHub ‘_**ddl\_dml\_statements**_’ branch and generates a pull request to merge the changes into the ‘_**main’**_ branch  
      
    
    ![](blob:https://zetaris.atlassian.net/40136938-1a82-44bc-8863-5c2783737ac1#media-blob-url=true&id=1d57eda6-b326-4aaa-9723-48048b71061d&collection=contentId-2554691585&contextId=2554691585&height=571&width=1917&alt=)![DataVaultcreatetbllnkstg](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/DataVaultcreatetbllnkstg.png)
    
    _**DAG -**_ _**DataVault\_Create\_Table\_Links\_Stg\_Stmts**_
    

**Step14:**

-   Once the changes are approved and merged into the main branch, create an airflow DAG named ‘_**DataVault\_Execute\_Create\_Table\_Links\_Stg\_Stmts**_’ on the airflow UI which executes all the create statements (link tables and staging views) on the Zetaris UI via the API
    

![](blob:https://zetaris.atlassian.net/bcc086a2-22cd-4260-87da-433a16bed264#media-blob-url=true&id=6442bd8a-1961-4099-a647-bb31a2e9633d&collection=contentId-2554691585&contextId=2554691585&height=666&width=1911&alt=)

_**DAG - DataVault\_Execute\_Create\_Table\_Links\_Stg\_Stmts**_

**Step15:**

-   After the hubs, sats & links entities (tables & views) are created by scheduling the DAGS created in previous steps, create another DAG named ‘_**DataVault\_Create\_Hubs\_Sats\_Links\_Insert\_Stmts**_’ on the airflow UI which generates the _**‘INSERT INTO TABLE’**_ statements for Hubs, Sats & Links and also stores the files in GitHub ‘_**ddl\_dml\_statements**_’ branch and generates a pull request to merge the changes into the ‘_**main’**_ branch
    

![](blob:https://zetaris.atlassian.net/87812cbe-e177-415e-b48b-1c86060575a7#media-blob-url=true&id=b13c2bb8-7bd3-4971-aa94-e7df3bf148a0&collection=contentId-2554691585&contextId=2554691585&height=616&width=1918&alt=)![DAG createhubssatslinks](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/DAG%20createhubssatslinks.png)

_**DAG - DataVault\_Create\_Hubs\_Sats\_Links\_Insert\_Stmts**_

**Step16:**

-   Once the changes are approved and merged into the main branch, create an airflow DAG named ‘_**DataVault\_Execute\_Insert\_Statements**_’ on the airflow UI which executes all the insert statements on the Zetaris UI via the API  
    ![DAG Execute Inserts](https://kbase.zetaris.com/hs-fs/hubfs/DAG%20Execute%20Inserts.png)
    
    ![](blob:https://zetaris.atlassian.net/088d8aa0-9b63-4920-8187-1e36b3fecdcb#media-blob-url=true&id=500e5531-e1bc-4027-b027-9de8e5b446b2&collection=contentId-2554691585&contextId=2554691585&height=663&width=1915&alt=)_**DAG - DataVault\_Execute\_Insert\_Statements**_
    

**Step17:**

-   If there any changes to the existing satellite tables, after the changes are made in the source tables, execute the DAG named ‘_**DataVault\_Create\_Sats\_Alter\_Stmts’**_ on the airflow UI which checks whether the modifications for the columns are additions or deletions and generates alter table statements accordingly on the Zetaris UI via the API
    

![](blob:https://zetaris.atlassian.net/ab567591-8f6a-424d-a906-0bea9dcdd0b5#media-blob-url=true&id=cc86cc6b-89c8-461e-8281-05a5c5535500&collection=contentId-2554691585&contextId=2554691585&height=788&width=1901&alt=)![DAG create SAT](https://kbase.zetaris.com/hs-fs/hubfs/DAG%20create%20SAT.png)

**DAG -** _**DataVault\_Create\_Sats\_Alter\_Stmts**_

**Step18:**

-   Once the changes are approved and merged into the main branch, create an airflow DAG named ‘_**DataVault\_Execute\_Sats\_AlterStmts**_’ on the airflow UI which executes all the insert statements on the Zetaris UI via the API
    
    ![](blob:https://zetaris.atlassian.net/b0ffb203-5ab8-4d32-ab3a-770937e50efc#media-blob-url=true&id=298b8381-b3eb-45c7-b026-cb92adbee8bc&collection=contentId-2554691585&contextId=2554691585&height=623&width=1889&alt=)![DAG-Vault](https://kbase.zetaris.com/hs-fs/hubfs/DAG-Vault.png)
    
    **DAG -** _**DataVault\_Execute\_Sats\_AlterStmts**_
    

Step 17 , Step 18 and Step 19 are required only if we need to make changes to the data vault. For example, modifying existing sat table, adding a new hub or a link table and their corresponding staging views.

**Step19:**

-   Execute all the dags mentioned from Step10 to Step18, if we need to:
    
    -   Add new hub tables
        
    -   Add new link tables
        
    -   Add new sat tables
        
    -   Modify corresponding Staging Views
        
    -   Insert the new data into hubs, sats and links
