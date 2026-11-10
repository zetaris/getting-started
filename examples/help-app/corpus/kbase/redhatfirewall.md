---
source: kbase
url: https://kbase.zetaris.com/knowledge/redhatfirewall
title: "Configure Redhat Firewall"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 75b1d9cefdaecb040a17ccbff587adf3076b9f70b061bacc3abd91cc35fd338c
---
# Configure Redhat Firewall

## This article covers how to configure the Redhat firewall for Zetaris ports that require external access

### Introduction

Zetaris leverages the following ports that need to be externally accessible:

-   Web Application GUI port - default 9001
    
-   JDBC Driver port - default 10000
    

You will need to configure the Redhat firewall to allow access to the required ports.  This requires a user account that has sudo privileges.

1.  Run the following command to open the GUI admin port 9001:
    
    ```
    sudo firewall-cmd --zone=public --permanent --add-port 9001/tcp
    ```
    
2.  Run the following command to open the JDBC listener port 10000:
    
    ```
    sudo firewall-cmd --zone=public --permanent --add-port 10000/tcp
    ```
    
3.  Run the following command to reload the firewall settings
    
    ```
    sudo firewall-cmd --reload
    ```
    
4.  Run the following command to confirm the ports were opened successfully:
    
    ```
    sudo firewall-cmd --list-all
    ```
    
    You should see the following output  
    ![Screen Shot 2022-07-05 at 1.34.26 pm](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/Screen%20Shot%202022-07-05%20at%201.34.26%20pm.png)
