---
source: kbase
url: https://kbase.zetaris.com/knowledge/graceful-shutdown-for-patching
title: "How to carry out a graceful shutdown for patching of Zetaris Enterprise"
kind: how-to
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 827782018a9b10b09136f7c21fa8bbbad08b163db03fd62c8b72c3f4b19a99a0
---
# How to carry out a graceful shutdown for patching of Zetaris Enterprise

### Shutdown of Enterprise edition on kubernetes

Shut down of Enterprise edition on Kubernetes in case patching is **NOT** required. It just requires updating server and GUI yaml file. that does need any shut down.

Incase shut down is required:

> 1.  Edit the autoscaling group
>     
> 2.  Set the instances to 0.
>     
> 3.  This will shut down all worker nodes.
>     
> 4.  Now you can use AWS Automation to schedule a repetitive action through automation documents that will be stopping/starting at given periods of time.
>     
> 5.  You can't stop the master nodes as they are managed by AWS.
>     

### **Shutdown of Enterprise edition on stand alone box**

1.  Open terminal
    
2.  Go to the path where Zetaris server is installed
    
    1.  default path is:
        
        ```
         /<home directory>/zetaris/server/zetaris-ndp-2.1.0.1-p1-production/bin
        ```
        
3.  Run command:
    
    ```
    ./stop-all
    ```
    
4.  This will stop the server component of the application
    
5.  Go to the path where the Zetaris GUI is installed
    
    1.  Default path is:
        
        ```
        /<home directory>/zetaris/gui/zetaris-ndp-gui-2.1.0.1-p1/bin
        ```
        
6.  Run command
    
    ```
    ./stop-lightning-gui.sh
    ```
    
7.  The GUI component of the application will now stop
    

### **Starting of Enterprise edition on stand alone box**

1.  Open terminal.
    
2.  go to path where Zetaris server is installed.
    
    1.  default path is:
        
        ```
        /<home directory>/zetaris/server/zetaris-ndp-2.1.0.1-p1-production/bin
        ```
        
3.  Run command
    
    ```
    ./start-all
    ```
    
4.  This will start the server component of the application.
    
5.  Go to the path where the Zetaris GUI is installed.
    
    1.  Default path is:
        
        ```
        /<home directory>/zetaris/gui/zetaris-ndp-gui-2.1.0.1-p1/bin
        ```
        
6.  Run command:
    
    ```
    ./start-lightning-gui.sh
    ```
    
7.  The GUI component of the application will now start
