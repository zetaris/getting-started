---
source: kbase
url: https://kbase.zetaris.com/knowledge/connecting-to-your-azure-iot-application
title: "Connecting to your Azure IoT application"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 310a96e8089771fa3d8c95495a857a9e1e58e016b086f83b541c6508f3e42663
---
# Connecting to your Azure IoT application

In recent years there has been an acceleration in the adoption of IoT technology in the data industry. The possibilities are endless, and the outcomes have serious implications. The importance of enabling this technology comes with a heavy responsibility of ensuring its usage in an ethical manner. At Zetaris, our technology is constantly reimagining the boundaries of the datasphere.

In this latest blog, we present you with a use case where we have combined IOT (Internet of Things) data and the consumer information from CRM (Customer Resource Management) systems to create an algorithm that will allow you to provide customer satisfaction for your package delivery service.

To achieve this, we have collected the telemetry logs from your handheld device (mobile phones) using an IOT application offered by Azure (IoT PnP) and delivery data from point to point.

The collected data is then evaluated for any changes in state using our CDC (change data capture) mechanism in Zetaris. By creating an active stream of telemetry information, we combine the two streams of information in the Zetaris VDP (Virtual data pipeline).

In the VDP (Virtual Data Pipeline), a transformation rule checks for the distance from the target location and the route to ensure the delivery is delivered to the right address. Based on the variation of the distance from the target, the pipeline auto creates a dataset which contains whether the driver has delivered the package and whether it has been delivered on time. The driver’s location is derived using the geolocation information collected from the handheld device. Please note that all the IOT devices must be connected to the same IoT source for this use case.

Once the user geolocation is captured, a request is sent to the Zetaris API to determine whether a package has been delivered and whether it was made within a time window around the potential time.

The potential for activating the power of IOT is immense. Combine that with the ability to query and combine all IOT logs in real-time to create engineering marvels from self-serviced EVs (Electric Vehicles) to consumer-aware shopping experiences. Try Zetaris today to give flight to your IOT dreams.
