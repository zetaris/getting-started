---
source: kbase
url: https://kbase.zetaris.com/knowledge/zetaris-integration-with-datadog
title: "Datadog Integration Guide"
kind: how-to
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 38918cfb77e0cc58625cd1f0bdd98665291f28d173c916588995f59e8c24bc5c
---
# Datadog Integration Guide

### **Installation steps**

1.  Create an account on [![](https://imgix.datadoghq.com/img/favicons/favicon-16x16.png)Cloud Monitoring as a Service | Datadog](https://www.datadoghq.com/)
2.  In the third step of creating the account, you will be asked to select an agent. For example, select **Kubernetes**.  
    ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Dec-08-2022-06-56-27-9928-AM.png).
3.  Install Helm and deploy the Datadog agent on your VM (which has Kubernetes configs), as mentioned in installation step 1 on the Datadog URL. Mention the RELEASE\_NAME for your Datadog Agent. For example, choose ‘datadog’.![](https://kbase.zetaris.com/hubfs/image-png-Dec-08-2022-06-57-38-9452-AM.png)  
    
    _Integrating Zetaris with Datadog Kubernetes Agent_
    
4.  Create a file named _**datadog-values.yaml**_ in the VM, and add the sample code mentioned below. The API Key needs to be mentioned in the below code, which you can retrieve from the Helm install command mentioned on the Datadog URL. See _Datadog API Key below:_  
      
    ![](https://kbase.zetaris.com/hubfs/image-png-Dec-08-2022-06-59-08-2593-AM.png)  
      
    
    ```
    touch datadog-values.yamlchmod 775 datadog-values.yaml
    ```
    
    Copy the below code in the _**datadog-values.yaml**_ file.
    
    ```
    datadog:  apm:    portEnabled: true  logs:    enabled: true    containerCollectAll: true  apiKey: <REDACTED>    # (...)  processAgent:    enabled: true    processCollection: true  agents:    containers:      processAgent:        env:        - name: DD_SCRUB_ARGS           value: "true"        - name: DD_CUSTOM_SENSITIVE_WORDS          value: "personal_key,*token,*token,sql*,*pass*d*"   networkMonitoring:    enabled: truetargetSystem: "linux"
    ```
    
5.  Upgrade the Helm chart, by running the command mentioned below.
    
    ```
    helm upgrade -f datadog-values.yaml RELEASE_NAME datadog/datadog
    ```
    
6.  Once installed, the datadog UI will be up and running. Login using the same credentials you mentioned when creating the account.

![](https://kbase.zetaris.com/hubfs/image-png-Dec-08-2022-07-07-27-0226-AM.png)

_Datadog UI Home Screen_

__![](https://kbase.zetaris.com/hubfs/image-png-Dec-08-2022-07-08-32-4152-AM.png)__

_Example of Kubernetes Metrics_

Installing Datadog in an integration model with Zetaris will help with observability of the platform and will enable the customer to create alerts for self-service of platform related issues.
