---
source: kbase
url: https://kbase.zetaris.com/knowledge/streaming-data-sources
title: "Apache Kafka"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: b7817f4a64a88f3002c77e79476f26f32c38a0a28212d6742f29fbf04f2bf9a0
---
# Apache Kafka

## This article covers connecting to a Streaming Data Source - specifically Apache Kafka.

### Introduction

Leveraging a streaming data source provides the ability to:

-   Collect data from any application
-   Ingest the streaming data and perform additional processing such as persisting the contents to a database or file format (e.g. Parquet, JSON).

Zetaris supports Apache Kafka streaming which consists of the following logical components:

-   Topic - messages belong to a particular category called a topic
-   Producer - publish messages to one or more Kafka topics. 
-   Consumer - subscribe to one or more topics and consume published messages

### Architecture

![Screen Shot 2022-11-23 at 10.30.47 pm](https://kbase.zetaris.com/hs-fs/hubfs/streaming/Screen%20Shot%202022-11-23%20at%2010.30.47%20pm.png)

In this architecture, Zetaris plays the role of the **Consumer**, with topic definitions and publishing of messages performed outside of Zetaris.

The integration point between Zetaris and Kafka is the **topic**.

On the **Producer** side, we will leverage the Kafka producer console to publish messages.

For our scenario, we will ingest streaming data from and perform additional processing such as persisting the contents to a database or file format (e.g. Parquet, JSON).

### Use Case

For our scenario, we have a Stock Ticker stream that publishes updates on technology stock equities.  As the consumer, Zetaris will ingest streaming data and persist the contents to a Parquet file format to the file system.

### Kafka Steps

1.  Ensure Kafka is running
2.  Create a topic, in our example the topic is named **stock.**
3.  Ensure your firewall permits connections to your kafka bootstrap port (e.g. 9092).

### Connect to a Streaming Data Source

1.  Click on NDB Fabric Builder widget.  
      
    ![2022-11-21_10-52-10](https://kbase.zetaris.com/hs-fs/hubfs/2022-11-21_10-52-10.png)
2.  Click ![Screen Shot 2022-11-21 at 12.08.55 pm](https://kbase.zetaris.com/hs-fs/hubfs/Screen%20Shot%202022-11-21%20at%2012.08.55%20pm.png)next to Streaming Data Sources.  
      
    ![2022-11-21_12-10-07](https://kbase.zetaris.com/hs-fs/hubfs/2022-11-21_12-10-07.png)
3.  Specify the following values:  
    
    <table style="width: 100%; border-collapse: collapse; table-layout: fixed; border: 1px solid #99acc2; height: 176px;"><tbody><tr style="height: 35px;"><td style="width: 49.9237%; padding: 4px; height: 35px;"><strong>Data Source Name</strong></td><td style="width: 49.9237%; padding: 4px; height: 35px;">Stock_Ticker</td></tr><tr style="height: 35px;"><td style="width: 49.9237%; padding: 4px; height: 35px;"><strong>Input Format</strong></td><td style="width: 49.9237%; padding: 4px; height: 35px;">JSON</td></tr><tr style="height: 35px;"><td style="width: 49.9237%; padding: 4px; height: 35px;"><strong>Input Source</strong></td><td style="width: 49.9237%; padding: 4px; height: 35px;">Kafka</td></tr><tr style="height: 35px;"><td style="width: 49.9237%; padding: 4px; height: 35px;"><strong>kafka.bootstrap.servers</strong></td><td style="width: 49.9237%; padding: 4px; height: 35px;">your kafka boostrap server and port</td></tr><tr style="height: 35px;"><td style="width: 49.9237%; padding: 4px; height: 35px;"><strong>kafka.topic</strong></td><td style="width: 49.9237%; padding: 4px; height: 35px;">stock</td></tr><tr><td style="width: 49.9237%; padding: 4px;"><strong>kafka.security.protocol</strong></td><td style="width: 49.9237%; padding: 4px;">PLAIN</td></tr><tr><td style="width: 49.9237%; padding: 4px;"><strong>kafka.sasl.mechanism</strong></td><td style="width: 49.9237%; padding: 4px;">PLAIN</td></tr></tbody></table>
    
       
    For **Input Sample** enter the following JSON payload:
    
    ```
    { "symbol" : "AAPL","name": "Apple","price": 150.12,"previous_close" : 148.01,"open" : 148.13,"bid" : 150.26,"ask" : 150.27,"volume" : 50304716,"avg_volume": 89767359}
    ```
    
4.  Your completed dialogue should look like the following:  
      
    ![2022-11-24_11-46-27](https://kbase.zetaris.com/hs-fs/hubfs/streaming/2022-11-24_11-46-27.png)  
    Click **Create**.
5.  Your streaming data source should now appear.  
      
    ![Screen Shot 2022-11-23 at 4.06.46 pm](https://kbase.zetaris.com/hs-fs/hubfs/streaming/Screen%20Shot%202022-11-23%20at%204.06.46%20pm.png)
6.  Click ![Screen Shot 2022-11-21 at 12.08.55 pm](https://kbase.zetaris.com/hs-fs/hubfs/Screen%20Shot%202022-11-21%20at%2012.08.55%20pm.png)next to your streaming data source to add an aggregation table.  
      
    ![2022-11-23_16-10-23](https://kbase.zetaris.com/hs-fs/hubfs/streaming/2022-11-23_16-10-23.png)
7.  Specify the following values:  
      
    
    <table style="width: 100%; border-collapse: collapse; table-layout: fixed; border: 1px solid #99acc2; height: 247px;"><tbody><tr style="height: 40.8203px;"><td style="width: 49.9237%; padding: 4px; height: 41px;"><strong>Aggregate Table Name</strong></td><td style="width: 49.9237%; padding: 4px; height: 41px;">stock</td></tr><tr style="height: 40.8203px;"><td style="width: 49.9237%; padding: 4px; height: 41px;"><strong>Output Mode</strong></td><td style="width: 49.9237%; padding: 4px; height: 41px;">Append</td></tr><tr style="height: 40.8203px;"><td style="width: 49.9237%; padding: 4px; height: 41px;"><strong>Output Format</strong></td><td style="width: 49.9237%; padding: 4px; height: 41px;">Parquet</td></tr><tr style="height: 40.8203px;"><td style="width: 49.9237%; padding: 4px; height: 41px;"><strong>Storage</strong></td><td style="width: 49.9237%; padding: 4px; height: 41px;">Local File System</td></tr><tr style="height: 40.8203px;"><td style="width: 49.9237%; padding: 4px; height: 41px;"><strong>File Path</strong></td><td style="width: 49.9237%; padding: 4px; height: 41px;">File path accessible to Zetaris</td></tr></tbody></table>
    
    For the Query enter the following:
    
    ```
    select timestamp, json_body.* from Stock_Ticker
    ```
    
8.  Your completed dialogue should look like the following:  
      
    ![2022-11-24_11-52-27](https://kbase.zetaris.com/hs-fs/hubfs/streaming/2022-11-24_11-52-27.png)  
    Click **Create**.
9.  You should now see your newly created aggregate table.  
      
    ![Screen Shot 2022-11-23 at 8.52.06 pm](https://kbase.zetaris.com/hs-fs/hubfs/streaming/Screen%20Shot%202022-11-23%20at%208.52.06%20pm.png)
10.  Click the aggregated table to expand.    
      
    ![2022-11-23_20-53-30](https://kbase.zetaris.com/hs-fs/hubfs/streaming/2022-11-23_20-53-30.png)
11.  You should see a data structure that corresponds to the query we entered.  
      
    ![Screen Shot 2022-11-23 at 8.55.28 pm](https://kbase.zetaris.com/hs-fs/hubfs/streaming/Screen%20Shot%202022-11-23%20at%208.55.28%20pm.png)
12.  Click preview next to stock to view the contents of the table.   
      
    ![2022-11-23_20-59-28](https://kbase.zetaris.com/hs-fs/hubfs/streaming/2022-11-23_20-59-28.png)  
      
    **Note** - there will not be any contents as messages are yet to be published to the topic.  
      
    ![Screen Shot 2022-11-23 at 9.00.43 pm](https://kbase.zetaris.com/hs-fs/hubfs/streaming/Screen%20Shot%202022-11-23%20at%209.00.43%20pm.png)

### Publish messages

1.  Switch to your KAFKA\_HOME/bin directory
2.  Start the topic producer  
    
    ```
    ./kafka-console-producer.sh --broker-list localhost:9092 --topic stock
    ```
    
3.  Enter the following JSON payload and hit **Enter** to send the message.  
    
    ```
    {"symbol" :"AAPL", "name":"Apple","price":150.12,"previous_close" :148.01,"open":148.13,"bid" :150.26,"ask":150.27,"volume":50304716,"avg_volume":89767359}
    ```
    
4.  Repeat the above exercise the the following JSON payload and hit **Enter** to send the message:  
    
    ```
    {"symbol":"SPOT","name":"Spotify","price":75.25,"previous_close":74.12,"open":72.97,"bid" :74.98,"ask":75.25,"volume":1564035,"avg_volume":1847590}
    ```
    

### View Messages

1.  Switch back to your Zetaris GUI to view messages consumed.
2.  Click preview next to stock to view the contents of the table.   
      
    ![2022-11-23_20-59-28](https://kbase.zetaris.com/hs-fs/hubfs/streaming/2022-11-23_20-59-28.png)  
    You should see the following 2 messages in the result, corresponding to the messages we published from Kafka in the previous step  
      
    ![Screen Shot 2022-11-23 at 10.33.40 pm](https://kbase.zetaris.com/hs-fs/hubfs/streaming/Screen%20Shot%202022-11-23%20at%2010.33.40%20pm.png)

With messages now appearing in Zetaris, we have successfully integrated Zetaris with Apache Kafka.
