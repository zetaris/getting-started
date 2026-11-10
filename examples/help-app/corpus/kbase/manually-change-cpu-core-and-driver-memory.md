---
source: kbase
url: https://kbase.zetaris.com/knowledge/manually-change-cpu-core-and-driver-memory
title: "How to update the CPU core and Driver Memory"
kind: how-to
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 3656464d32999670533a6f3ea89c5cf5a52d1a60d1564787f8c817f2326c1674
---
# How to update the CPU core and Driver Memory

1.   Login to VM via zetaris user or switch to zetaris user after login.
    
    ```
    sudo su - zetaris
    ```
    
    ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Oct-30-2023-03-32-40-2029-AM.png)
2.  Stop the Lightning server using:
    1.  ```
        sudo service lightning-server stop
        ```
        
        ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Oct-30-2023-03-34-10-4750-AM.png)
3.  Go to path 
    1.  ```
        cd /home/zetaris/.environment
        ```
        
        ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Oct-30-2023-03-35-09-5091-AM.png)
4.  Open the file server\_env
    1.  ```
         vi server_env
        ```
        
5.  For a VM with 16 GB RAM ,update ZSPARK\_DRIVER\_CORES to 4 and  ZSPARK\_DRIVER\_MEM to 10GB. As shown below  
     _**<The below values should be based on the selected VM size. It is recommended to consult Zetaris before making any changes to these values. The SPARK\_DRIVER\_MEM and SPARK\_EXECUTOR\_MEM can be configured up to (Available RAM -8GB) >**_

```
ZSPARK_DRIVER_CORES=4. ZSPARK_DRIVER_MEM=10g 
```

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Oct-30-2023-03-36-54-1239-AM.png). Save the file using the below command  

```
!wq
```

6.  Start the Lightning server and check status using:  

1.  1.  sudo service lightning-server start
    2.  sudo service lightning-server status  
        ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Oct-30-2023-03-38-29-1225-AM.png)
