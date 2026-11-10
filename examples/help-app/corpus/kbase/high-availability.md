---
source: kbase
url: https://kbase.zetaris.com/knowledge/high-availability
title: "High Availability"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 048327f8f3ed8af1ef377ceb86196b0783a3e0e31fd0a9abc7ce5fc0a2e09f57
---
# High Availability

Configuring your Zetaris Platform to run in a Highly Available (HA) manner, can be achieved by deploying an additional controller node to operate as a hot/warm standby, waiting activation.

Your Zetaris cluster is deployed in a master-slave configuration, where you master, also known as the cluster controller, coordinates queries on run-time between slaves, also known as workers.

_![controller_slave](https://kbase.zetaris.com/hs-fs/hubfs/architecture/controller_slave.png)_

_Standard cluster_

### Setting up for HA

Your Zetaris HA environment will require use of **Apache Zookeeper**, to coordinate the failover, in addition to a **hot/warm standby controller node**.

Your cluster will effectively channel queries through the primary controller node, and in case of a failure in the primary controller node, Zookeeper will trigger the standby controller to activate as the primary.

_![onprem_ha](https://kbase.zetaris.com/hs-fs/hubfs/architecture/onprem_ha.png)_

_Cluster with High Availability_

### Setting up for HA in the cloud

When deploying Zetaris in a cloud based infrastructure, like Azure, Amazon Web Services, or Google Cloud Platform, we recommend setting up your shared metastore, so that all nodes have a common repository, which are often provided by the vendor with built in HA.

![cloud_ha](https://kbase.zetaris.com/hs-fs/hubfs/architecture/cloud_ha.png)

_High availability with shared metastore_

### Steps for deploying High Availability

The specific steps for implementing the coordination of Apache Zookeeper your master nodes, is slightly different depending on the OS we have installed on.
