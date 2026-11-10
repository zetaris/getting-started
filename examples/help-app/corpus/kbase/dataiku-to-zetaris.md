---
source: kbase
url: https://kbase.zetaris.com/knowledge/dataiku-to-zetaris
title: "Connect Dataiku to Zetaris"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: c8429ad70cad6879f689e7b7a66dd9b6c7329a6e7698064e604988cf4ab24f54
---
# Connect Dataiku to Zetaris

## Installation and Configuration of Zetaris JDBC driver on Dataiku Data Studio

### Installing Zetaris JDBC Driver

The driver is a single JAR file.  It is located in the installation directory

```
ZETARIS_DIR/jdbc-driver/
```

It can also be downloaded from the following [link](https://kbase.zetaris.com/hubfs/ndp-jdbc-driver-2.1.0.10-driver.jar).

### Download and Install JDBC Driver

Installation of JDBC drivers must be done while Data Science Studio is stopped.

DATA\_DIR refers to the data directory of your Data Science Studio installation.

ZETARIS\_DIR refers to the installation directory of the Zetaris installation

1.  Stop Data Science Studio
    
    ```
    DATA_DIR/bin/dss stop
    ```
    
2.  Obtain the JDBC Driver  
      
    For Zetaris Enterprise the JDBC driver can be found in the following directory:  
    
    ```
    ZETARIS_DIR/jdbc-driver/
    ```
    
3.  Copy Zetaris JDBC driver to the following directory:
    
    ```
    DATA_DIR/lib/jdbc
    ```
    
4.  Start Data Science Studio
    
    ```
    DATA_DIR/bin/dss start
    ```
    

### Connect to Zetaris

1.  Login to Data Science Studio
    
    ```
    http://<your server address>:11000
    ```
    
2.  Go to the Administration > Connection page
    
3.  Click “New connection” and select Other **SQL databases**  
    ![Screen Shot 2022-06-29 at 9.36.05 am](https://kbase.zetaris.com/hs-fs/hubfs/Screen%20Shot%202022-06-29%20at%209.36.05%20am.png)
    
4.   Enter the following connection information:  
      
    
    <table style="width: 100%; border-collapse: collapse; table-layout: fixed; border: 1px solid #99acc2; height: 241.062px;"><tbody><tr style="height: 39.7734px;"><td style="width: 47.6107%; padding: 4px; height: 40px;"><strong>Connection Name</strong></td><td style="width: 52.3351%; padding: 4px; height: 40px;">Zetaris</td></tr><tr style="height: 39.7734px;"><td style="width: 47.6107%; padding: 4px; height: 40px;"><strong>JDBC Driver class</strong></td><td style="width: 52.3351%; padding: 4px; height: 40px;">com.zetaris.lightning.jdbc.LightningDriver</td></tr><tr style="height: 40.0703px;"><td style="width: 47.6107%; padding-top: 4px; padding-right: 4px; padding-bottom: 4px; height: 40px;"><strong>JDBC Url</strong></td><td style="width: 52.3351%; padding-top: 4px; padding-right: 4px; padding-bottom: 4px; height: 40px;">jdbc:zetaris:lightning@[host]:[port]</td></tr><tr style="height: 39.7734px;"><td style="width: 47.6107%; padding: 4px; height: 40px;"><strong>User</strong></td><td style="width: 52.3351%; padding: 4px; height: 40px;">Zetaris username</td></tr><tr style="height: 39.7734px;"><td style="width: 47.6107%; padding: 4px; height: 40px;"><strong>Password</strong></td><td style="width: 52.3351%; padding: 4px; height: 40px;">Zetaris password</td></tr><tr style="height: 39.7969px;"><td style="width: 47.6107%; padding: 4px; height: 40px;"><strong>SQL Dialect</strong></td><td style="width: 52.3351%; padding: 4px; height: 40px;">Hive</td></tr></tbody></table>
    
5.  Click **Test** to validate your connection  
    ![Screen Shot 2022-06-29 at 12.23.22 pm](https://kbase.zetaris.com/hs-fs/hubfs/Screen%20Shot%202022-06-29%20at%2012.23.22%20pm.png)  
    Dataiku will attempt to connect to the database, and provide feedback on whether the attempt was successful.  
      
    You should receive a confirmation that the connection was successful  
    ![Screen Shot 2022-06-29 at 12.25.07 pm](https://kbase.zetaris.com/hs-fs/hubfs/Screen%20Shot%202022-06-29%20at%2012.25.07%20pm.png)
    
6.  Click **Save** to save your connection
