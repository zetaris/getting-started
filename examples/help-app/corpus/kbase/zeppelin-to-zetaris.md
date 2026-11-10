---
source: kbase
url: https://kbase.zetaris.com/knowledge/zeppelin-to-zetaris
title: "Connect Apache Zeppelin to Zetaris"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 1481ad763f19cbc3a086aef4b2f6f797f273b21d37e338c2f01a2d992c9c0803
---
# Connect Apache Zeppelin to Zetaris

## This article covers configuring Apache Zeppelin to connect to Zetaris.

### Introduction

Apache Zeppelin supports JDBC drivers to connect to data sources.  Zetaris provides its JDBC driver as a single jar file, which will be used to connect Apache Zeppelin to Zetaris.

### Configure JDBC Driver

1.  Download the Zetaris JDBC driver  
    For Zetaris Enterprise it is located in the installation directory:
    
    ```
    ZETARIS_DIR/jdbc-driver/
    ```
    
2.  To install the driver, copy the Zetaris JDBC driver to a directory on your Zeppelin installation.

### Determine Zetaris JDBC Connection Information

The JDBC URL for Zetaris Enterprise has the following format:

```
jdbc:zetaris:lightning@[host]:[port]
```

**Note** - default port is 10000

### Connect to Zetaris

1.  Start Zeppelin.
2.  Login to Zetaris http://<hostname>:8080
3.  Click on your username from the navigation bar and click on the option **Interpreter**.  
    ![Screen Shot 2022-07-11 at 3.33.02 pm](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/Screen%20Shot%202022-07-11%20at%203.33.02%20pm.png)
4.  Click the **Create** button.  
    ![Screen Shot 2022-07-11 at 3.40.52 pm](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/Screen%20Shot%202022-07-11%20at%203.40.52%20pm.png)  
      
    
5.  Specify the following values:  
    **Interpreter Name:** Zetaris  
    **Interpreter group:** jdbc  
      
    For properties, specify the following:  
    **default.driver:** com.zetaris.lightning.jdbc.LightningDriver  
    **default.url:** jdbc:zetaris:lightning@\[host\]:\[port\]  
    **default.user:** your Zetaris username  
    **default.password:<REDACTED> your Zetaris password  
      
    Under **Dependencies->Artifact** specify the full path to your Zetaris jdbc driver, similar to:  
    
    ```
    /<jdbc_path>/ndp-jdbc-driver-2.1.0.10-driver.jar
    ```
    
6.  Click **Save**.
