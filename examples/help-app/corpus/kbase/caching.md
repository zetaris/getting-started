---
source: kbase
url: https://kbase.zetaris.com/knowledge/caching
title: "Caching"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: b149f5ddbf70a6814c18e90415f966b48ecda8e1e3d0fae156e34d84a117307d
---
# Caching

## This document tells us about caching and how it can be used in Zetaris. It also articulates all the syntax needed when caching a table is required.

### What is **caching**?

A **data** block that contains frequently accessed **data** in a textual or binary format, which may be either saved to a persistent storage at the client or server side, or persistent in the memory for the lifetime of a single client request, a user session, or an application process

Depending upon the business type, different business has different aspects of computing requirement. However, There is one aspect which all business will have in common i.e _**Speed**_.

_**Caching**_ is a way of using main memory or RAM to efficiently manage data which is accessed frequently. . The main purpose of using a cache is to increase the performance in data retrieval by minimising the need to constantly access the slower disk storage layer or network layer. Compared to traditional databases, caching focuses more on speed than capacity. It stores a subset of the data transiently, instead of having data that's complete and durable. Caching, however, has a track record of success, helping companies big or small in the improvement of application performance.

The main **advantage** of using an in-memory cache is that it helps in facilitating fast access without putting a significant load on the main data stores or cloud.

There are other reasons to use cache beyond performance, and those are when:

-   we want to be careful to not inundate source systems with queries, and overload their capacity,
-   source systems are transactional and sensitive, or
-   costs associated with source systems are expensive (common with autoscaling cloud databases), and we want to limit the amount of direct egress that is incurred.

There are two ways in which you can cache any table in our NDP-Lightning.  

### 1\. Offsite Query.

Once you have registered a data source, you can use the Offsite sql query in SQL Editor which you can find in schema store view.

```
OFFSITE CACHE TABLE  to  with (expireInSec )
```

**Understanding the query**:

Let us take an example. Say, you have a datasource **AWS\_ORCL** and a table called **customer** in it

```
OFFSITE CACHE TABLE AWS_ORCL.orders to Memory with (expireInSec "-1" )
```

This will cache the table customer of Datasource AWS\_ORCL to memory. Here, as we can see expireInSec is given the value of -1. This makes the lifetime of the table permanent.

**Storage**:

Our NDP-Lightning supports two type of storage - **MEMORY** and **FILE**.

If you wish to store your data in the file and not in memory. you have to switch the storage from memory to file as shown below.

```
OFFSITE CACHE TABLE AWS_ORCL.customer to File with (expireInSec "-1" )
```

**Lifetime:**

The lifetime of this cache can be permanent or temporary.

If you wish to make it's lifetime permanent, you have to give the value of -1 for expireInSec.

For temporary caching, you have to specify the time in seconds. Hence, after the time provided is elapsed the table will be uncached.

```
OFFSITE CACHE TABLE AWS_ORCL.customer to File with (expireInSec "3600" )
```

This will expire the cache after 1 hour (60\*60 seconds). The lifetime

**Understanding Delta.**

Once the data has been cached, any new data added to the table won't be cached. In cases, where you want to keep on adding data to the existing cache you have to use keywords deltaColumn, deltaCycle.

**DeltaColumn:**

DeltaColumn is a column on the basis of which the new data will be added to the existing cache from the table. Delta Column can only have two formats : date and timestamp or dateTime.

For example: If there is a table in which new data is added every hour/day like orders, sales. Once the table is cached, new data which has been added after the given time/date will be added to the existing cache without the need of uncaching and caching it again.

**DeltaCycle:**

Different organisation have different needs and different aspects when it comes to caching. We have segregated this needs and aspects in 4 cycle when it comes to delta or adding new changes to existing cache.

| 
**Delta Cycle**

 | 

**Execution Time(i.e when new data will be added)**

 |
| --- | --- |
| 

Hourly

 | 

0th minute of every hour ( Note: This cycle will only work for columns whose type is **timestamp**)

 |
| 

Daily

 | 

At 12:00 am of every day

 |
| 

Weekly

 | 

On Monday at 12:00am of every Week.

 |
| 

Monthly

 | 

On 1st day at 12:00 am of every Month.

 |

All the other cycles except Hourly will work only for column with type of **DATE**

The syntax for this will be as follows:

```
OFFSITE CACHE TABLE AWS_ORCL.orders to Memory with (expireInSec "-1", deltaColumn "o_orderdate", deltaCycle "Daily")
```

Similarly, for Hourly Cycle:

```
OFFSITE CACHE TABLE AWS_ORCL.orders to Memory with (expireInSec "-1", deltaColumn "o_ordertime", deltaCycle "Hourly")
```

**Partition Count:**

This setting can only be applied when the storage type is set to file. you can use the keyword partCount to assign number of partitions you want to make in hdfs in order to run any query efficiently.

```
OFFSITE CACHE TABLE AWS_ORCL.orders to File with (expireInSec "-1", partCount "100")
```

this will create 100 partitions of the table orders in hdfs.

### 2\. The Cache GUI:

Once the data source is registered. you can click on the name of the data source.

you will see a list of tables with a blue icon on the right side of each table name.

![6](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/caching/6.png)

Cache display

On clicking the blue icon you will see a dialog box as shown below.

![1](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/caching/1.png)Cache options

You can apply your options/setting and press on ok button. This will create an offsite cache query in the background and send it to server.

Once the table is cached. You can see it in the table list. The green icon states that the table is cached.

 ![2](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/caching/2.png)

_'customer' and 'orders' tables are cached._

### **UNCACHING AND SHOWING CACHE TABLES**

The red icon in the image shown above is used to **uncache** the table. The other way of **uncaching** the table is by running the query shown below.

```
OFFSITE UNCACHE TABLE AZURE_MSSQL.customer;
```

if you want to get a List of all the tables that are cached. You can use

```
SHOW CACHE TABLES;
```

This will generate a Table with all the tables that are cached.

### **ADAPTIVE CACHE POLICY:**

In the above section, we discussed how we can cache a table explicitly by running a query or with the help of GUI.

This section elaborates the implicit caching method which can be implemented. Overall, the tables are divided in 3 types.

1.  Dimension
    
2.  Fact
    
3.  Other.
    

Now based on this table type you can set policies for dimension and fact tables.

```
UPDATE CACHE POLICY TABLE TYPE DIMENSION STORAGE FILE BASELINE SCAN 3;
```

And if you wish to set policy for fact where storage is memory. You just need to change type and storage.

```
UPDATE CACHE POLICY TABLE TYPE FACT STORAGE MEMORY BASELINE SCAN 3;
```

This means for the tables whose type is dimension and fact will be cached to file and memory respectively once it has been queried for 3 times.

To know about the existing policies. you can run command:

```
SHOW CACHE POLICY;
```

It will return a table as show in the image below.

![3](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/caching/3.png)

If you wish to update the policy you can use the **update cache policy** query.

### **QUERY STATISTICS.**

Query statistics tells us about how many times a query has been executed. it also tells us whether the query was a join query or/and a aggregation query or none.

To see the statistics you need to run:

```
SHOW QUERY STATISTICS;
```

The result of the above query will be as follows:

![4](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/caching/4.png)

Getting deeper into statistics, if you want to know what exactly are the table identifiers, its type(i.e Dimension, fact or other), and how many times the table has been used in the query.

you can use the **queryhash** from the above table and run a command like:

```
SHOW QUERY TABLE STATISTICS '9c700871fb63c71f1c32ec3fa1a6c53c';
```

You can also use the query shown below to see the query table statistics for all the queries present is **QUERY STATISTICS.**

```
SHOW QUERY TABLE STATISTICS TYPE ALL;
```

This query will generate result as displayed in the image below.

![5](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/caching/5.png)

If you wish to delete the query statistics:

```
DELETE QUERY STATISTICS;
```

it will delete all the query statistics from the table.

### CACHE PROGRESS

This is our final topic for caching. Caching can sometime take time if the amount of data present is big. To know the progress of your cache you can run the following query.

```
OFFSITE CACHE PROGRESS;
```

This will return a table with the table name and its cache progress. Once it is completed, the data will be removed from this table.
