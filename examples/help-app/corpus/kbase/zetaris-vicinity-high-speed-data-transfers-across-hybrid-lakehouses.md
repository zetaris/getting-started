---
source: kbase
url: https://kbase.zetaris.com/knowledge/zetaris-vicinity-high-speed-data-transfers-across-hybrid-lakehouses
title: "Zetaris-Vcinity: High speed data transfers across hybrid lakehouses"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 81aea066e36b2ca841d4e906b83da05a45eef994513ec5ee1e74dfab87010dbd
---
# Zetaris-Vcinity: High speed data transfers across hybrid lakehouses

### Overview

Zetaris hybrid lakehouses leverage the power of Vcinity data pipes to enable seamless data transfers between cloud-based and on-premises lakehouses. These data pipes serve as the backbone for efficient and secure data exchange, ensuring that organizations can seamlessly move and synchronize data across different storage environments.

By utilizing Vcinity data pipes, organizations can take advantage of high-speed connectivity and optimized data transfer protocols, facilitating smooth and reliable data movement. Whether transferring data between cloud and on-premises environments or across multiple distributed sites, the Vcinity data pipes ensure that data transfer is fast, secure, and efficient.

The Vcinity Solution is a cutting-edge technology that seamlessly integrates with enterprise networks as a standard NAS or high-speed storage tier. When connected over the MAN/WAN, it facilitates high-performance, geo-diverse data exchange. Key components of the Vcinity solution include Ultimate X (ULT X), Command X, and Access X.

The architecture behind this approach is designed to streamline data management processes, enhance data accessibility, and support the scalability of hybrid lakehouse environments. With Vcinity data pipes at the core, organizations can confidently manage their data resources, maximize productivity, and drive innovation within their data ecosystem.

In terms of performance, the Vcinity Solution boasts exceptional features:

\- Achieving up to 95% bandwidth utilization on terrestrial and satellite links regardless of network connection size

\- Providing near-real-time access to remote data as if it were stored locally

\- Enabling the transfer of terabytes to petabytes of data at remarkable speeds, such as transferring 1PB in less than a day over a 100Gbps link, making it ideal for organizations with extensive data transfer needs.

![Vicinity (1)](https://kbase.zetaris.com/hubfs/Vicinity%20(1).svg)

#### Transfer data between virtual machines (VMs) equipped with Vcinity using the Zetaris notebook.

**Pre-Requisites**

2 VMs with Vcinity installed on them

Zetaris SaaS/VM

  

**Steps to configure Vcinity Source VM**

1.  Login to source VM
    
2.  Create a password for Vcinity frontend
    
    1.  Unlock the credentials for configuration by running the unlock script:
        
        `sudo /root/scripts/misc/root-unlock.sh`
        
    2.  Set the ULT X administration password: 
        
        <REDACTED>
        sudo ultx debug admin-reset <user-defined-password>
        sudo ultx enable all
        sudo ultx restart all
        ```
        
    3.  Set the ULT X hostname:
        
        `sudo hostnamectl set-hostname ultxv1-host`
        
    4.  Restart your ULT X instance either through the AWS console or by issuing reboot on the command line:
        
        `sudo reboot`
        
3.  Login to the first VM's frontend
    
    1.  <https://<Your\_ULT-X\_EC2\_Public\_IP\_Address>/login
        
        1.  For example : https://3.5.XXX.45/login
            
    2.  Login screen will appear
        
        ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Aug-14-2024-12-21-06-1079-AM.png)
    3.  Put username as “admin” and the password that created in 2.b.1. Click on sign in
        
    4.  Save the INI file which needed to be upload on your machine
        
        1.  Change the public IP on line 67 to your destination public IP. For example 44.XXX.33.16/X4 is destination Public IP
            
        2.  Save the file with .ini extension
            
    5.  On the next page upload the INI file and click Next
        
        ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Aug-14-2024-12-27-06-9054-AM.png)
    6.  Click on Save on the next screen  
          
        
4.  Now Open setting screen on the front and change tranfer to peer to peer method
    
    1.  Open link : [https://<Public IP of Source Machine>/accessx/settings](https://3.235.157.249/accessx/settings)
        
        ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Aug-14-2024-12-30-41-7587-AM.png)

**Steps to configure Vcinity Destination VM**

1.  Do the exact same steps as you did to configure Destination except
    
    1.  Change the public IP on line 67 in the .ini file to your Source public IP. For example 3.235.157.249/24 is destination Public IP
        

Check If configuration is done properly on both source and destination machine

  

1.  Login to Source VM
    
2.  Run command on source vm
    
    1.  Sudo check\_tunnel
        
    2.  status will be ok and it will show destination public IP
        
        ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Aug-14-2024-12-33-16-9747-AM.png)
3.  Login to Destination VM
    
4.  Run command on destination VM
    
    1.  1.  Sudo check\_tunnel
            
        2.  status will be ok and it will show source public IP
            
    2.  Now the machine is set up properly and can transfer data from source to destination and vice versa
        
        Step to transfer data between source and destination
        
    3.  Find source node information
        
        1.  Login to frontend : https://<public IP>/login
            
        2.  Go to configuration. Then click on inventory. you will see source details
            
        
          
        ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Aug-14-2024-12-36-35-3606-AM.png)  
         
        1.  1.  Go to configuration. Then click on locations. You will see destination details

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Aug-14-2024-12-38-32-2808-AM.png)

You can then carry out file transfers using curl commands or Zetaris notebooks. Contact [Zetaris](mailto:<REDACTED>) for sample connectivity notebooks
