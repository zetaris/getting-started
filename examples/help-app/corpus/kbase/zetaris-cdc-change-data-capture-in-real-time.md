---
source: kbase
url: https://kbase.zetaris.com/knowledge/zetaris-cdc-change-data-capture-in-real-time
title: "Zetaris CDC (Change Data Capture) in real-time"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: b7328accf22cfdddbe0b8079959fd2b347ad183c4da78917801a592d9643aaff
---
# Zetaris CDC (Change Data Capture) in real-time

## This article shows how to implement near real-time CDC-based change replication for SQL Server using Apache Kafka and Debezium and access CDC data through Zetaris Lightning Platform.

#### Overview

![](blob:https://zetaris.atlassian.net/52790962-01d2-4adf-b3a4-6fdf80d02130#media-blob-url=true&id=8ab08e41-450c-4f6b-ac50-04721da88d00&collection=contentId-2740912158&contextId=2740912158&height=438&width=799&alt=)![](https://kbase.zetaris.com/hubfs/52790962-01d2-4adf-b3a4-6fdf80d02130-png.png)

The Big data world is slowly transitioning into capturing event based delta processing and there are many advantages associated with the concept

-   Change data capture (capture changes to your datasources in the absence of a watermark or a delta column)
    
-   Event sourcing (use incremental data reducing ingress/egress costs)
    
-   Internal/external dashboards (stream source information directly into dashboards creating analytic insights)
    

Let us discuss in details a couple of the above advantages.

#### Change data capture

Applying a layer of federated query capability on a distributed layer can be challenging if all the incoming data sources are not well co-ordinated. The currency of the data in the platform is a key consideration for deriving value from distributed systems. The late arrival of data or data sources falling out of sync with each other create a lot of disparities and remediation needs in the modern data platform.

The diagnosis of such issues have to begin with the “source of truth” and eventually any changes applied to the raw data have to quickly and effectively find their way to the insights and analytics layer.

By loading the change events into Zetaris using Debezium and Kafka, you’ll be able to query every datasource change for the raw data in real-time and propagate it without loss of currency into the Analytics layer.

#### Event sourcing

Event sourcing is the means of understanding the state of the system in comparison to a specific point in time in the past. The benefits of event sourcing far outweighs the traditional method of comparing records using hashing mechanisms wherein there is a sustained need for a hash key or a watermark to uniquely identify records. in this example , we are using Debezium to query across an unindexed and hashed database to capture changes in state and propagate it in realtime to Zetaris.

The change events can either be materialised into a permanent view which can reliably hold a log of all the record changes that have happened since inception and continue to be captured in real-time.

#### Key Components

Apache Kafka - Transport

Debezium - Change Data Capture

Zetaris - Aggregation

#### Pre-Requisites

The solution requires installing and configuring Java, Apache Kafka, Kafka Connect, Debezium and SQL Server on Virtual Machine.

#### Linux VM

Java is a required dependency since the Kafka libs run on Java. To install Java and add it to the environment variables for the VM, use the commands listed below.

```
> sudo yum install java-1.8.0> export JAVA_HOME=/usr/lib/jvm/jre-1.8.0
```

#### Apache Kafka

Download and install [latest version of Apache Kafka](https://kafka.apache.org/downloads) on Linux VM

```
> mkdir kafka/> cd kafka> wget https://archive.apache.org/dist/kafka/3.3.1/kafka-3.3.1-src.tgz (asc, sha512)> tar -xzf kafka-3.3.1-src.tgz (asc, sha512)> cd kafka-3.3.1-src
```

#### Debezium

Debezium is an open source distributed platform for change data capture,It captures changes in database(s) and publishes those changes to topics in Kafka.

In the **kafka-3.3.1-src** folder that we ended the last set of commands with, we will download the Debezium libraries under **libs** folder. Then, we will untar it into your Kafka Connect environment before moving it to the directory of the plugins folder. Lastly, we will run the command to set our plugin path for Kafka Connect.

```
> wget https://repo1.maven.org/maven2/io/debezium/debezium-connector-sqlserver/2.0.1.Final/debezium-connector-sqlserver-2.0.1.Final-plugin.tar.gz> tar -xzf /kafka-3.3.1-src/libs/debezium-connector-sqlserver> plugin.path=/kafka-3.3.1-src/libs
```

jar files should placed under **“/kafka-3.3.1-src/libs/”**

![](blob:https://zetaris.atlassian.net/47c143f3-ea22-433a-869b-88fa7deafb78#media-blob-url=true&id=b7be337d-7c8a-4f28-878a-28cfe970212e&collection=contentId-2740912158&contextId=2740912158&height=510&width=1037&alt=)![](https://kbase.zetaris.com/hubfs/47c143f3-ea22-433a-869b-88fa7deafb78-png.png)

> Debezium currently supports following [list of connectors](https://debezium.io/documentation/reference/stable/connectors/index.html):
> 
> -   [MongoDB](https://debezium.io/documentation/reference/stable/connectors/mongodb.html)
>     
> -   [MySQL](https://debezium.io/documentation/reference/stable/connectors/mysql.html)
>     
> -   [PostgreSQL](https://debezium.io/documentation/reference/stable/connectors/postgresql.html)
>     
> -   [SQL Server](https://debezium.io/documentation/reference/stable/connectors/sqlserver.html)
>     
> -   [Oracle](https://debezium.io/documentation/reference/stable/connectors/oracle.html)
>     
> -   [Db2](https://debezium.io/documentation/reference/stable/connectors/db2.html)
>     
> -   [Cassandra](https://debezium.io/documentation/reference/stable/connectors/cassandra.html) (Incubating)
>     
> -   [Vitess](https://debezium.io/documentation/reference/stable/connectors/vitess.html) (Incubating)
>     
> 
> **Note**: An incubating connector is one that has been released for preview purposes and is subject to changes that may not always be backward compatible.

#### Azure SQL Database

As we want to set up CDC and Debezium to stream data from SQL Server, we would need SQL Server installed somewhere. For this article we have used Azure SQL Database with [Wide World Importers](https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0) as sample database.

 ![](https://kbase.zetaris.com/hubfs/26653414-4d14-493e-94ec-f71e4f9380c1-png.png)

> CDC on Azure SQL databases available for higher than the S3 (Standard) tier or vCore equivalent

**Steps to configure SQL Server for CDC:**

1.  Create Debezium User  
    
    ```
    -- Create user used in the sampleCREATE USER [debezium-wwi] WITH PASSWORD = <REDACTED> Make sure user has db_owner permissionsALTER ROLE [db_owner] ADD MEMBER [debezium-wwi]GO
    ```
    
2.  Enable CDC, In this sample only two tables are monitored:
    
    -   Sales.Orders
        
    -   Warehouse.StockItems
        
    
    ```
    -- Enable CDC on database EXEC sys.sp_cdc_enable_dbGO-- Enable CDC on selected tablesEXEC sys.sp_cdc_enable_table N'Sales', N'Orders', @role_name=null, @supports_net_changes=0EXEC sys.sp_cdc_enable_table N'Warehouse', N'StockItems', @role_name=null, @supports_net_changes=0GO-- Verify the CDC has been enabled for the selected tablesEXEC sys.sp_cdc_help_change_data_captureGO
    ```
    

### Configure Debezium to capture CDC events and publish them to the Kafka topic(s)

#### Step 1 : Start A Zookeeper

Kafka provides a CLI tool to start Zookeeper which is available in bin directory. Run the following command from Kafka folder **“/kafka-3.3.1-src/”**:

bin/zookeeper-server-start.sh config/zookeeper.properties

#### Step 2 : Start A Kafka Server

Run the following command:

bin/kafka-server-start.sh config/server.properties

> Before starting Kafka, make sure to update “**advertised.listeners**“ with your public ip address in “config/server.properties“ file

#### Step 3 : Configure Kafka Connect

Create a file “connect-debezium-source-mssql.properties” for Kafka Connect worker properties and place under **“/kafka-3.3.1-src/config/**“ directory.

![](blob:https://zetaris.atlassian.net/ceca6dba-336c-44ff-997e-1e2835d2930b#media-blob-url=true&id=5b1cea80-73f8-485f-89b0-07153c9c66ec&collection=contentId-2740912158&contextId=2740912158&height=484&width=1055&alt=)![](https://kbase.zetaris.com/hubfs/ceca6dba-336c-44ff-997e-1e2835d2930b-png.png)

> Refer [![](https://debezium.io/favicon.ico)Debezium connector for SQL Server :: Debezium Documentation](https://debezium.io/documentation/reference/stable/connectors/sqlserver.html#sqlserver-connector-properties) document for more information on required/advanced properties for SQL Server connector.

To start streaming by starting the Kafka connect, run the following command.

```
bin/connect-standalone.sh config/connect-standalone.properties config/connect-debezium-source-mssql.properties
```

Now check that the connector is established & running successfully using following commands.

curl -H "Accept:application/json" localhost:8083/connectors/

![](https://kbase.zetaris.com/hubfs/db6677be-e793-4308-8939-60eb3510e82d-png.png)

```
curl -X GET http://localhost:8083/connectors/sql-server-connection-wwi/status | jq
```

![](blob:https://zetaris.atlassian.net/423e13c5-d54b-41c6-add4-bbcbe4a94a23#media-blob-url=true&id=d01e3622-e4c4-41a9-bf93-15d043864b32&collection=contentId-2740912158&contextId=2740912158&height=474&width=1042&alt=)![](https://kbase.zetaris.com/hubfs/423e13c5-d54b-41c6-add4-bbcbe4a94a23-png.png)

_From above screenshot, If you see any errors in under tasks section there must be some issue in SQL Server connection properties, check the logs and make sure we have configured right values in “config/connect-debezium-source-mssql.properties“_

#### Step 4 : Monitor Kafka Logs For Change Data

-   Check list of topics generated
    

```
bin/kafka-topics.sh --list --bootstrap-server 20.213.213.5:9092
```

![](https://kbase.zetaris.com/hubfs/d20165da-daa2-4783-9b16-f83996ffc982-png-1.png)

-   Make some simple changes on SQL Database
    

UPDATE \[Sales\].\[Orders\] SET PickedByPersonID = 1 WHERE OrderID=1

```
UPDATE [Sales].[Orders] SET PickedByPersonID = 2 WHERE OrderID=2UPDATE [Warehouse].[StockItems] SET ColorID=7 WHERE StockItemID=21UPDATE [Warehouse].[StockItems] SET ColorID=8 WHERE StockItemID=22
```

-   Run following command specific to Orders & StockItem topics to view changed data 
    

```
bin/kafka-console-consumer.sh --bootstrap-server 20.213.213.5:9092 --topic zetaris-poc-wwi.WWI.Sales.Orders
```

![](https://kbase.zetaris.com/hubfs/1280e087-6549-43a8-8391-7b0f97aab199-png.png)

bin/kafka-console-consumer.sh --bootstrap-server 20.213.213.5:9092 --topic zetaris-poc-wwi.WWI.Warehouse.StockItems

![](https://kbase.zetaris.com/hubfs/9016f951-67c9-498b-b16f-f3d55a3ebe2f-png.png)

### Establishing connection to CDC Data through Zetaris Lightning

In order to connect CDC data on Kafka server, follow the instruction from the article [Streaming Data Source - specifically Apache Kafka](https://kbase.zetaris.com/knowledge/streaming-data-sources) to establish connection on Zetaris Platform.

![](blob:https://zetaris.atlassian.net/1396ed3e-461d-4092-b091-4c709b7105d2#media-blob-url=true&id=685b1a60-b7c0-448d-86d8-20306fabd26a&collection=contentId-2740912158&contextId=2740912158&height=497&width=2100&alt=)![](https://kbase.zetaris.com/hubfs/1396ed3e-461d-4092-b091-4c709b7105d2-png.png)

### **Video**

![](blob:https://zetaris.atlassian.net/6c6d36fb-74bc-45c1-8e05-c29959844d62#media-blob-url=true&id=9e358625-4224-4134-999f-7a194bb14196&collection=contentId-2740912158&contextId=2740912158&height=1872&width=3360&alt=)

### References

[![](https://debezium.io/favicon.ico)Debezium connector for SQL Server :: Debezium Documentation](https://debezium.io/documentation/reference/stable/connectors/sqlserver.html)
