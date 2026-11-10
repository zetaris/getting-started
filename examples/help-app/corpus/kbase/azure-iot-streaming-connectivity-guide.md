---
source: kbase
url: https://kbase.zetaris.com/knowledge/azure-iot-streaming-connectivity-guide
title: "Azure IoT Streaming Connectivity Guide"
kind: how-to
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 4e62c78c9b9e7598ec573bf8005bab34c424f659e277772e963e5f0f2e4895d6
---
# Azure IoT Streaming Connectivity Guide

## In this article we discuss a use case of connecting an IOT device to Zetaris for further analysis.

### Technical Diagram:

![](https://kbase.zetaris.com/hubfs/image-png-Mar-21-2023-12-15-59-4858-AM.png)

### Prerequisites:

-   A Zetaris Instance
    
-   A Mobile device with the ability to connect to Azure IoT Central
    

#### Connectivity Guide:

### Part 1: Connecting your Mobile Device to an Azure IoT Central Application

In your Smart Phones application store, i.e. Google Play Store, Download the Azure IoT Plug and Play app. Link can be found in the following Microsoft document.

Follow the Steps from the “Connect the app” section in the following Microsoft documentation.

[![](https://learn.microsoft.com/favicon.ico)Use your smartphone as an Azure IoT device](https://learn.microsoft.com/en-us/azure/iot-fundamentals/iot-phone-app-how-to)

 Part 2: Exporting IoT Stream to Azure Event Hub Entity

#### Creating Azure Event Hubs

Within the Azure Portal, search for “Event Hubs” in the search bar. and select Event Hubs as shown in the screenshot.

![](https://kbase.zetaris.com/hubfs/image-png-Mar-21-2023-12-18-13-7994-AM.png)

![](blob:https://zetaris.atlassian.net/b1d8bbf0-f04f-491c-b86b-e7a695f73ba5#media-blob-url=true&id=c417f9fa-9a3c-491f-aa6e-a461a2ab2a32&collection=contentId-2754576433&contextId=2754576433&height=380&width=876&alt=)

Select Create and input your desired values. Please refer to the below screenshot for an example of inputs.  
![](https://kbase.zetaris.com/hubfs/image-png-Mar-21-2023-12-18-39-0923-AM.png)

![](blob:https://zetaris.atlassian.net/1becce3d-0d56-4859-8b42-ae7c7ee62d9e#media-blob-url=true&id=d8694020-98ef-410c-b89c-0ff0fc140562&collection=contentId-2754576433&contextId=2754576433&height=643&width=814&alt=)

Once created navigate to your created Event Hub resource and select Event Hubs under Entities. Create a new Event Hub Entity using the \[+ Event Hub\] Button as shown in the screenshot.

![](blob:https://zetaris.atlassian.net/4473487b-afd1-424d-bda9-7ca18a6b8e60#media-blob-url=true&id=289db6b4-1708-4596-80a4-8da472e9f03d&collection=contentId-2754576433&contextId=2754576433&height=632&width=1373&alt=)![](https://kbase.zetaris.com/hubfs/image-png-Mar-21-2023-12-20-11-6625-AM.png)

This Event hub will contain the connection details used to connect to Kafka.

Once created select your Event Hub Entity and navigate to Shared access policies. Create a new policy with Send and Listen privileges. Once created, select the newly created policy and copy the Connection string-primary key into notepad. _This will be used later on._

Setting up Azure IoT Central to export data.

Navigate to your Azure IoT central url in your browser and select your application.

Navigate to Data Export in the side navigation bar as shown in the following screenshot.

![](blob:https://zetaris.atlassian.net/f28ca9af-0a13-49e4-83e0-770a6433c36c#media-blob-url=true&id=63dccea4-e8c1-4a69-91e8-d76077ba8a61&collection=contentId-2754576433&contextId=2754576433&height=637&width=185&alt=)![](https://kbase.zetaris.com/hubfs/image-png-Mar-21-2023-12-21-49-7349-AM.png)

Select Destinations and Create a new Destination and input the following information.

<table style="border-collapse: collapse; table-layout: fixed; margin-left: auto; margin-right: auto; border: 1px solid #99acc2;" data-number-column="false"><tbody><tr><td rowspan="1" colspan="1" data-colwidth="340"><p data-renderer-start-pos="1657">Destination type</p></td><td rowspan="1" colspan="1" data-colwidth="340"><p data-renderer-start-pos="1677">Azure Event Hubs</p></td></tr><tr><td rowspan="1" colspan="1" data-colwidth="340"><p data-renderer-start-pos="1699">Authorization</p></td><td rowspan="1" colspan="1" data-colwidth="340"><p data-renderer-start-pos="1716">Connection String</p></td></tr><tr><td rowspan="1" colspan="1" data-colwidth="340"><p data-renderer-start-pos="1739">Connection String</p></td><td rowspan="1" colspan="1" data-colwidth="340"><p data-renderer-start-pos="1760"><em data-renderer-mark="true">Copied Connection from previous step</em></p></td></tr></tbody></table>

Once you have validated the information click on the save icon.

Navigate to Exports and create a new export.

Within the Data section select “Telemetry” for “Type of data to Export”. Within Destinations select your previously added Destination and click on Transform. In build transformation query change it to the following.

. as $in | .telemetry\[\] | {  
    deviceId: $in.device.id,  
    messageSource: $in.messageSource,  
    enqueuedTime: $in.enqueuedTime,  
    sensor: .name,  
    sensor\_data: .value,  
    sensor\_data\_x: (.value.x // null),  
    sensor\_data\_y: (.value.y // null),  
    sensor\_data\_z: (.value.z // null),  
    component: $in.component  
}

Click on Update.

Click on the save icon.

### Part 3: Exposing your IoT stream through Kafka

#### Create a Kafka Virtual Machine:

Navigate to Azure Marketplace and search for Kafka. Install the following Kafka in your desired resource group.

![](blob:https://zetaris.atlassian.net/27fcb7d1-72f5-40d7-95a8-35ab61e27da3#media-blob-url=true&id=943602c2-c623-4d48-84eb-4826ddbd6e54&collection=contentId-2754576433&contextId=2754576433&height=350&width=226&alt=)![](https://kbase.zetaris.com/hubfs/image-png-Mar-21-2023-12-23-38-8171-AM.png)

#### Create the Exposer:

SSH into the VM and clone the following repository.

git clone <placeholder>.git

Install the Maven dependency.

sudo apt install maven

Update the consumer.config file and change the following:

<table style="border-collapse: collapse; table-layout: fixed; margin-left: auto; margin-right: auto; border: 1px solid #99acc2;" data-number-column="false"><tbody><tr><td rowspan="1" colspan="1" data-colwidth="226.67"><p data-renderer-start-pos="2916">NAMESPACE</p></td><td rowspan="1" colspan="1" data-colwidth="226.67"><p data-renderer-start-pos="2929">Your Event Hub Namespace</p></td><td rowspan="1" colspan="1" data-colwidth="226.67"><p data-renderer-start-pos="2957">IoT-EventHub</p></td></tr><tr><td rowspan="1" colspan="1" data-colwidth="226.67"><p data-renderer-start-pos="2975">{YOUR.EVENTHUBS.CONNECTION.STRING}</p></td><td rowspan="1" colspan="1" data-colwidth="226.67"><p data-renderer-start-pos="3013">The connection string you copied to notepad</p></td><td rowspan="1" colspan="1" data-colwidth="226.67"><p data-renderer-start-pos="3060">&nbsp;</p></td></tr></tbody></table>

Run the following commands to expose your event hub

 cd ~/event-hub-to-zetaris

mvn clean package

mvn exec:java -Dexec.mainClass="EventHubToZetaris"

### Part 4: Connecting your IoT Stream to Zetaris

Connect your Zetaris Instance in your browser and navigate to the Schema Store View feature tab.

Copy the following SQL into your SQL Editor and change to your respectively.

REGISTER STREAMING DATASOURCE iot\_telemetry INPUT\_SOURCE KAFKA INPUT\_FORMAT JSON INPUT\_OPTIONS(  
  kafka.bootstrap.servers "<Kafka VM Public IP>:9092",  
  kafka.topic "telemetry"  
)  
INPUT\_SAMPLE  
{  
     "component":"sensors",  
     "deviceId":"xxxxxxxxxxxxx",  
     "enqueuedTime":"2023-01-12T05:52:23.735Z",  
     "messageSource":"telemetry",  
     "sensor":"accelerometer",  
     "sensor\_data":"xxxxxx",  
     "sensor\_data\_x":0.11492519080638885,  
     "sensor\_data\_y":0.8882759809494019,  
     "sensor\_data\_z":9.759063720703125  
};  
  
REGISTER STREAMING AGGREGATION full\_telemtry\_data FROM iot\_telemetry OUTPUT\_MODE APPEND OUTPUT\_FORMAT PARQUET OUTPUT\_OPTIONS(  
  path "/home/zetaris/customer-data/streaming/iot\_telemetry/telemetry\_data"  
)  
AS  
select timestamp, json\_body.\* from iot\_telemetry;

Notice it gets listed as a Zetaris streaming source

![](https://kbase.zetaris.com/hubfs/image-png-Mar-21-2023-12-28-27-3663-AM.png)
