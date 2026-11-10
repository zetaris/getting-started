---
source: kbase
url: https://kbase.zetaris.com/knowledge/tableau-to-zetaris
title: "Connect Tableau to Zetaris"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 08dffb96cfe276933ae8bc62fa806c499143e7911b1fc0c5f987d5dfe984a084
---
# Connect Tableau to Zetaris

## This article covers configuring Tableau to connect to Zetaris.

### Introduction

Tableau supports JDBC drivers for several connectors including named connectors and other JDBC-based drivers, referred to as **Other Databases (JDBC)** in the tool.

### Configure JDBC Driver

1.  Download the Zetaris JDBC driver  
    For Zetaris Enterprise it is located in the installation directory:
    
    ```
    ZETARIS_DIR/jdbc-driver/
    ```
    
2.  Close Tableau
3.  Place the .jar file in the folder for your operating system: 
    1.  **Windows:** C:\\Program Files\\Tableau\\Drivers
    2.  **Mac:** /Library/JDBC or ~/Library/JDBC
    3.  **Linux:** /opt/tableau/tableau\_driver/jdbc

### Determine Zetaris JDBC Connection Information

The JDBC URL for Zetaris has a different format depending on your Zetaris deployment.  

For Zetaris Enterprise it will be in the format:

```
jdbc:zetaris:lightning@[host]:[port]
```

**Note** - default port is 10000

### Connect to Zetaris

1.  Open Tableau
2.  Under **Connect**, select **Other Databases (JDBC)**.   
    ![Screen Shot 2022-07-08 at 3.24.44 pm](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/Screen%20Shot%202022-07-08%20at%203.24.44%20pm.png)
3.  Specify the following values:  
    **URL:** Zetaris JDBC URL - jdbc:zetaris:lightning@<ip adrress>:10000  
    **Dialect:** PostgreSQL  
    **Username:** your user name  
    **Password:<REDACTED> your password
4.  Click **Sign in**.
