---
source: kbase
url: https://kbase.zetaris.com/knowledge/available-logging-capture-on-kubernetes
title: "Available Logging Capture"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 5c9076f4388cb9bf4dc16fc3e030e08c4a46621c0701896cb73e76da7d0404a7
---
# Available Logging Capture

## This article explains how to capture both server and GUI logs.

### **Log capture of enterprise on Kubernetes**

#### **a. Step to see server logs**

     i.   Open terminal which has your amazon/azure config files.

     ii.  Run the command:

          kubectl --kubeconfig /<path to config>/<config name> get pod

     iii. You will see all the things running. Find the thunderstorm-driver in that list. Copy it.

     iv. Run command:

          kubectl --kubeconfig /<path to config>/config name logs -f pod/thunderstorm-driver  
  
     v. This will show you the server log.

#### b. Step to see GUI logs

     i.  Open terminal which has your amazon/azure config files.

     ii.  Run the command:

          kubectl --kubeconfig /<path to config>/<config name> get pod

     iii. You will see all the things running. Find the thunderstrom-guiXXXXXXXXX in that list.           Copy it.

     iv. Run command:

          kubectl --kubeconfig /<path to config>/config name logs -f pod/thunderstorm-guiXXXX

     v.  This will show you the GUI log.

### Log capture on Enterprise in on-premise virtual machine

#### a. Step to see server logs:

     i.   By default logs are created in folder:

          cd/home/centos/zetaris/spark/spark-3.1.2-XXXXXX/logs

     ii.  ls- lrth.

     iii. Check the latest log file.

#### b. Step to see GUI logs

     i.   By default log are created in folder:

          cd/home/centos/zetaris/gui/zetaris-ndp-gui-XXXX/logs

     ii.  Check application.log.
