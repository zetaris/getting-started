---
source: kbase
url: https://kbase.zetaris.com/knowledge/sql-guide
title: "Zetaris SQL Guide"
kind: sql-reference
lastmod: 2026-03-19
retrieved: 2026-11-10
sha256: 41bd03740c986572fd932797e84fd6eca3aee81d55c77228ee412065762a2073
---
# Zetaris SQL Guide

CURRENTLY IN REVISION

The Zetaris SQL Guide will help you to write queries natively within the Zetaris SQL Editor, but also when connecting through external tools.

[Data Source Connection and Registration Statements](#registration)

[Pipeline and View Statements](#pipeline_view_statements)

[DDL Statements](#ddl) (connected data sources and lakehouses)

[DML Statements](#dml) (connected data sources and lakehouses)

[DCL Statements](#dcl_statements) (for Zetaris)

[Data Retrieval Statements](#data_retrieval_statements) (connected data sources and lakehouses)

[Auxiliary Statements](#auxilliary_statements)

### Connection and Registration Statements

Connection and Registration statements are used to connect your data sources and lakehouses, and subsequently register the nominated tables/files.

NOTE: For Object Store, File Source, or RESTful API connections, you will need to create a LIGHTNING DATABASE first.

-   [CREATE DATALAKE](#create_datalake)
-   CREATE DATASOURCE
-   CREATE LIGHTNING DATABASE (Filesource, Object Store, and RESTful API  connections)
-   CREATE TABLE
    -   [LAKEHOUSE](#create_datalake_table)
    -   CREATE LIGHTNING FILESTORE TABLE
    -   CREATE LIGHTNING REST TABLE
-   DROP DATASOURCE
-   DROP LIGHTNING DATABASE
-   DROP DATALAKE
-   REGISTER DATASOURCE TABLES
-   REGISTER METASTORE
-   REGISTER STREAMING DATASOURCE

#### **CREATE DATALAKE**

Create initial Datalake connection

for S3:

```
CREATE DATALAKE [DATALAKE_NAME] OPTIONS (    storageType 'S3',      storagePath 's3a://path/to/lakehouse',      AwsAccessKeyId '<AwsAccessKeyId',      AwsSecretAccessKey '<AwsSecretAccessKey.');
```

for Azure:

```
CREATE DATALAKE [DATALAKE_NAME] OPTIONS (    storageType 'AzureBlob',      storagePath 'wasbs://<container-name>@<storage-account-name>.blob.core.windows.net/<directory>',    AzureAccountName '<AzureAccountName>',      AzureAccessKey '<AzureAccessKey>);
```

for local:

```
create datalake [DATALAKE_NAME] options (    storageType 'Local',      storagePath '/home/zetaris/path/to/lakehouse');
```

**CREATE TABLE** (lakehouse)

When creating a table, you need to reference the \[DIRECTORY\_NAME\] which is either a current folder in the path you are currently connected to, or it will create a new directory

Create a table with schema

```
CREATE TABLE [DATALAKE_NAME].[DIRECTORY_NAME].[YourTableName](    -- put your schema here    -- id bigint NOT NULL COMMENT 'unique id',    -- data string)USING icebergPARTITIONED BY (-- put your partition columns here-- category)
```

Create a table using select

```
CREATE TABLE [DATALAKE_NAME].[DIRECTORY_NAME].[YourtableName]USING icebergAS-- Add your select query here-- SELECT * from table
```

### Pipeline and View Statements

Pipeline and View statements are used to create, and manage the virtual pipelines and views that are created in Zetaris..

NOTE: Any Pipeline or View must be stored in a Container

-   ALTER VIEW
-   CREATE CONTAINER
    -   CREATE PIPELINE CONTAINER
    -   CREATE SCHEMASTORE CONTAINER
-   CREATE SCHEMASTORE VIEW
-   DROP VIEW
-   DROP CONTAINER
    -   DROP PIPELINE CONTAINER
    -   DROP SCHEMASTORE CONTAINER

Example:

CREATE SCHEMASTORE CONTAINER <viewcontainername>;

CREATE SCHEMASTORE VIEW <viewname> WITH CONTAINER <viewcontainername> AS (…);  
   
drop view <container\_name>.<view\_name>

### DDL Statements (connected databases and lakehouses)

Data Definition statements (Data Definition Language, DDL) are used to create or modify the structure of database objects in a database or in Zetaris. Zetaris supports for followings Data Definition Statements

-   ALTER TABLE
-   CREATE TABLE  
    -   CREATE TABLE (Database) 
    -   CREATE TABLE (Lakehouse)
-   TRUNCATE TABLE

### DML Statements (connected databases and lakehouses)

Data Manipulation statements (Data Manipulation Language, DML) are used to add, change, or delete data. Spark SQL supports the following Data Manipulation Statements:

-   [INSERT TABLE](#insert_table)

#### **INSERT TABLE**

The `INSERT` statement inserts new rows into a table or overwrites the existing data in the database table, lakehouse table or file. The inserted rows can be specified by value expressions or result from a query.

**table\_identifier**, with emphasis on the namespace convention.

INSERT INTO `<datasource_name>.<table_name>` ....

-   [Spark Insert Statements](https://spark.apache.org/docs/latest/sql-ref-syntax-dml-insert-table.html)
-   Presto Insert Statements

### Data Retrieval Statements 

Data retrieval statements are commands used to extract specific data from databases, primarily using **Structured Query Language (SQL)**.  The most fundamental and widely used data retrieval statement is the `SELECT` statement, which allows users to query databases to fetch data based on defined criteria.

**table\_identifier,** with emphasis on the namespace convention.

`SELECT column1, column2 FROM <datasource_name>.<table_name>;`

-   [Spark Data Retrieval Statements](https://spark.apache.org/docs/latest/sql-ref-syntax.html#data-retrieval-statements)
-   Presto Data Retrieval Statements

### DCL Statements

Data Control statements (Data Control Language, DCL) allow you to, through SQL, manage security elements across the Zetaris platform.

-   [USER](#user)
    -   ADD
    -   UPDATE
    -   DESCRIBE
    -   DELETE
    -   SHOW
-   [ROLE](#role)
    -   CREATE
    -   DROP
    -   ASSIGN
    -   REVOKE
    -   SHOW

-   [GRANT](#grant)
-   [REVOKE](#revoke)
-   [UPSERT AUTH](#upsert_auth) (for RESTful API connections)

#### **USER**

##### ADD USER

```
ADD USER WITH (email '<REDACTED>',name 'someone',level 'general',password '1234567')
```

##### UPDATE USER password[](https://kbase.zetaris.com/knowledge/sql-manual#update-user-password)

```
UPDATE USER user_id SET PASSWORD 'new_password'
```

##### DESCRIBE USER[](https://kbase.zetaris.com/knowledge/sql-manual#describe-user)

```
DESCRIBE USER user_id
```

##### DELETE USER[](https://kbase.zetaris.com/knowledge/sql-manual#delete-user)

```
DROP USER user_id
```

##### SHOW USERS[](https://kbase.zetaris.com/knowledge/sql-manual#show-users)

```
SHOW USERS
```

#### **ROLE**

##### CREATE ROLE[](https://kbase.zetaris.com/knowledge/sql-manual#create-role)

```
CREATE ROLE role_name [DESCRIBE BY "this is blah~~~"]
```

##### DROP ROLE[](https://kbase.zetaris.com/knowledge/sql-manual#drop-role)

```
DROP ROLE role_name;
```

##### ASSIGN ROLE a Role

```
ASSIGN USER user_name [, user_name] ...TO ROLE role_name
```

##### REVOKE USER from Role[](https://kbase.zetaris.com/knowledge/sql-manual#revoke-user-from-role)

```
REVOKE USER user_name[, user_name] ...FROM ROLE role_name
```

##### SHOW ROLES[](https://kbase.zetaris.com/knowledge/sql-manual#show-roles)

```
SHOW ROLES
```

##### SHOW ROLE Assigned to user[](https://kbase.zetaris.com/knowledge/sql-manual#show-role-assigned-to-user)

```
SHOW ROLE ASSIGNED TO USER user_name
```

##### SHOW USER Assigned to Role[](https://kbase.zetaris.com/knowledge/sql-manual#id16)

```
SHOW USER ASSIGNED TO ROLE role_name
```

#### **GRANT**[](https://kbase.zetaris.com/knowledge/sql-manual#grant)

Granted user with GRANT OPTIONS can grant same privilege on the table.

**Privileges**

SELECT privilege - Give read access to the data source or relation

INSERT privilege - Give insert access to the data source or relation

CACHE privileges - Give cache access to a relation

```
GRANT SELECT | INSERT | CACHE ON table_or_view_name TO principal_spec [,principal_spec] ... [WITH GRANT OPTION]
```

#### **REVOKE**[](https://kbase.zetaris.com/knowledge/sql-manual#revoke)

```
REVOKE SELECT | INSERT | CACHE ON table_or_view_name FROM principal_spec [,principal_spec] ...
```

#### **UPSERT\_AUTH**

#### _Example_

UPSERT AUTH salesforce\_auth REQUEST(  
     endpoint "https://login.salesforce.com/services/oauth2/token",  
     method "post",  
     http\_encoding "urlencoded"  
) HEADER (  
) BODY (  
      grant\_type "password",  
      username "<REDACTED>",  
      password "gac7XTK1tvg\*vmx@pazMfSMCBJSt16VqRSGamFghtca5",  
      client\_id "<SALESFORCE_CLIENT_ID>",  
      client\_secret "<SALESFORCE_CLIENT_SECRET>"  
);

  
  

### Auxiliary Statements

-   -   -   ANALYZE
        -   DESCRIBE
            -   DESCRIBE MASTER DATASOURCE
            -   DESCRIBE TABLES
        -   SHOW
            -   SHOW CACHE TABLES
            -   SHOW DATASOURCE TABLES
        -   [OPTIMIZER](#optimizer)

#### **ANALYZE**

#### **OPTIMIZER ON/OFF**

To turn the Zetaris Optimization on and off, execute the following command in the SQL Editor

TURN OPTIMIZER “PUSHDOWN\_DIFFERENT\_TYPE\_PREDICATE” ON | OFF <datasource>

TURN OPTIMIZER "PUSHDOWN\_AGGREGATION" ON | OFF datasource
