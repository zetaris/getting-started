---
source: kbase
url: https://kbase.zetaris.com/knowledge/install-zetaris-on
title: "Install Zetaris Enterprise on Redhat 8"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: ac845f7e005a382788b0ba997186796767f75dab4fd1266d0926dd45d5263a88
---
# Install Zetaris Enterprise on Redhat 8

## This articles covers installation of Zetaris Enterprise on Redhat 8 Linux

### Introduction

As part of the installation the following tasks will be performed including installation of Zetaris prerequisite software:

1.  Java Installation
    
2.  Apache Spark Installation
    
3.  Zetaris Installation
    
4.  Create non-privileged user
    
5.  Start Zetaris
    
6.  Configure Redhat Firewall
    
7.  Configure AWS or Azure Inbound security roles (if applicable)
    
8.  Login to Zetaris Platform
    

### Software Requirements

  

<table style="width: 100%; border-collapse: collapse; table-layout: fixed; border: 1px solid #99acc2; height: 237px;"><tbody><tr style="height: 61px;"><td style="width: 50.3635%; padding: 4px; height: 61px;">User privileges</td><td style="width: 49.7821%; padding: 4px; height: 61px;">Privileged access to your Linux system as root or via the sudo command</td></tr><tr style="height: 35px;"><td style="width: 50.3635%; padding: 4px; height: 35px;">Operating System</td><td style="width: 49.7821%; padding: 4px; height: 35px;">Red Hat Enterprise Linux 8</td></tr><tr style="height: 35px;"><td style="width: 50.3635%; padding: 4px; height: 35px;">Java</td><td style="width: 49.7821%; padding: 4px; height: 35px;">java-1.8.0-openjdk</td></tr><tr style="height: 35px;"><td style="width: 50.3635%; padding: 4px; height: 35px;">Spark</td><td style="width: 49.7821%; padding: 4px; height: 35px;">3.1.3</td></tr><tr style="height: 35px;"><td style="width: 50.3635%; padding: 4px; height: 35px;">Zetaris Binaries</td><td style="width: 49.7821%; padding: 4px; height: 35px;">Contact <a href="mailto:<REDACTED>" rel="noopener">Zetaris</a> for installation binaries</td></tr><tr style="height: 35px;"><td style="width: 50.3635%; padding: 4px; height: 35px;">Linux packages/utilities</td><td style="width: 49.7821%; padding: 4px; height: 35px;">lsof, &nbsp;net-tools package</td></tr></tbody></table>

### Install Java

1.  Run the following command to install Java:
    
    ```
    sudo yum install java-1.8.0-openjdk
    ```
    
2.  Run the following command to verify your Java installation and version:
    
    ```
    java -version
    ```
    
    You should see similar output:
    
    ```
    openjdk version "1.8.0_332"OpenJDK Runtime Environment (build 1.8.0_332-b09)OpenJDK 64-Bit Server VM (build 25.332-b09, mixed mode) 
    ```
    

### Install Apache Spark

1.  Run the following command to download Spark:
    
    ```
    curl https://dlcdn.apache.org/spark/spark-3.1.3/spark-3.1.3-bin-hadoop3.2.tgz --output spark-3.1.3-bin-hadoop3.2.tgz 
    ```
    
2.  Extract the archive
    
    ```
    sudo tar xvf spark-3.1.3-bin-hadoop3.2.tgz -C /opt
    ```
    
3.  Create a symbolic link to make our paths easier to remember (you will need this later):
    
    ```
    sudo ln -s /opt/spark-3.1.3-bin-hadoop3.2/ /opt/spark
    ```
    

### Install Zetaris Server and GUI

This article uses installation binaries for version 2.1.0.1.  If using later installation binaries for your installation the file names and path names will vary accordingly.

Installation binaries will be in the format:

-   Server binary; zetaris-ndp-<version>\*.tgz
-   GUI binary: zetaris-ndp-gui-<version>\*.tgz

1.  Create the directory to extract the archive into:
    
    ```
    sudo mkdir /opt/zetaris
    ```
    
2.  Extract the **server** archive:
    
    ```
    sudo tar xvf zetaris-ndp-2.1.0.1-production.tgz -C /opt/zetaris
    ```
    
3.  Create a symbolic link to the **server** make our paths easier to remember
    
    ```
    sudo ln -s /opt/zetaris/zetaris-ndp-2.1.0.1-p3-production/ /opt/zetaris/server
    ```
    
4.  Extract the **gui** archive:
    
    ```
    sudo tar xvf zetaris-ndp-gui-2.1.0.1-production.tgz -C /opt/zetaris
    ```
    
5.  Create a symbolic link to the **gui** make our paths easier to remember
    
    ```
    sudo ln -s /opt/zetaris/zetaris-ndp-gui-2.1.0.1-p3/ /opt/zetaris/gui
    ```
    

### Create non-privileged user

1.  Create a non-privileged user named ndpadmin:
    
    ```
    sudo useradd zetaris
    ```
    
2.  Set the password for the new user:
    
    ```
    sudo passwd zetaris
    ```
    
3.  Assign ownership of the Spark directory to non-privileged user:
    
    ```
    sudo chown -R zetaris: /opt/spark*
    ```
    
4.  Assign ownership of the Zetaris directory to non-privileged user:
    
    ```
    sudo chown -R zetaris: /opt/zetaris
    ```
    

### Post Installation Configuration

#### Create and Configure Data Directory 

Zetaris makes use of a data directory for cache and its network file system (which can be used for File Data Sources).

This requires creating the data directory, and specifying this directory in the GUI and Server configuration files.

1.  Run the following command to create the Zetaris data directory:
    
    ```
    sudo mkdir /opt/zetaris/data
    ```
    
2.  Edit **application.conf  
    **
    1.  Open the file:
        
        ```
        sudo vi /opt/zetaris/gui/conf/application.conf
        ```
        
    2.  At the top of the file set **fileSavingPath** to the following:
        
        ```
        path="/opt/zetaris/data"
        ```
        
         ![2022-08-29_13-27-13](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/2022-08-29_13-27-13.png)
        
    3.  Go to line  148 and set **filesystem\_staging** to the following:  
        
        ```
        filesystem_staging="/opt/zetaris/data"
        ```
        
         ![Screen Shot 2022-08-29 at 1.29.40 pm](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/Screen%20Shot%202022-08-29%20at%201.29.40%20pm.png)
        
    4.  Save and close the file.
3.  Edit Meta Store properties
    
    1.  Open the **metastore\_properties** file
        
        ```
        sudo vi /opt/zetaris/server/conf/meta_store.properties
        ```
        
    2.  Press **:** (colon), type **set** **nu**, and hit Enter to display line numbers.
        
    3.  Go to line 109 and edit the **filesystem\_staging** property to reflect the following:  
        **filesystem\_staging=/opt/zetaris/data**  
          
        ![2022-08-29_13-17-52](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/2022-08-29_13-17-52.png)
        
    4.  Go to line 141 and edit the **lightning\_filecache\_root\_path** to reflect the following:  
        **lightning\_filecache\_root\_path=/opt/zetaris/data/cache  
        **  
        ![2022-08-29_13-19-42](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/2022-08-29_13-19-42.png)
        
    5.  Save your changes and close the file.
        

#### Add SPARK\_HOME environment variable

There are several script files that reference the SPARK\_HOME environment variable.  This will need to be set in each of these script files.

1.  Add SPARK\_HOME to **start-lightning-server-with-derby.sh**
    1.  Open the file
        
        ```
        sudo vi /opt/zetaris/server/bin/start-lightning-server-with-derby.sh
        ```
        
    2.  On the 2nd line add the following:
        
        ```
        export SPARK_HOME=/opt/spark
        ```
        
         ![2022-08-29_13-22-17](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/2022-08-29_13-22-17.png)
        
    3.  Save and close the file.
        
2.  Add SPARK\_HOME to **register-org.sh**

1.  1.  Open the file:
        
        ```
        sudo vi /opt/zetaris/server/bin/register-org.sh
        ```
        
    2.  On the 2nd line add the following:
        
        ```
        export SPARK_HOME=/opt/spark
        ```
        
         ![Screen Shot 2022-08-29 at 1.34.33 pm](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/Screen%20Shot%202022-08-29%20at%201.34.33%20pm.png)
        
    3.  Save and close the file.
        
2.  Edit **stop-all.sh**
    1.  Open the file  
        
        ```
        sudo vi /opt/zetaris/server/bin/stop-all.sh
        ```
        
    2.  On the 2nd line add the following:  
        
        ```
        export SPARK_HOME=/opt/spark
        ```
        
        ![Screen Shot 2022-08-29 at 1.34.33 pm](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/Screen%20Shot%202022-08-29%20at%201.34.33%20pm.png)
        
    3.  Save and close the file.

#### Run Zetaris as a Service

1.  Create the service file for the server component:  
    
    ```
    sudo vi /etc/systemd/system/zetaris-enterprise.service
    ```
    
2.  Add the following content  
    
    ```
    [Unit]Description=Zetaris Enterprise Server Service[Service]Type=oneshotRemainAfterExit=yesUser=zetarisWorkingDirectory=/opt/zetaris/server/binExecStart=/opt/zetaris/server/bin/start-all.shExecStop=/opt/zetaris/server/bin/stop-all.sh[Install]WantedBy=multi-user.target
    ```
    
3.  Save and close the file.
4.  Create the service file for the GUI component:  
    
    ```
    sudo vi /etc/systemd/system/zetaris-enterprise-gui.service
    ```
    
5.  Add the following content  
    
    ```
    [Unit]Description=Zetaris Enterprise GUI ServiceRequires=zetaris-enterprise.serviceAfter=zetaris-enterprise.service[Service]Type=oneshotRemainAfterExit=yesUser=zetarisWorkingDirectory=/opt/zetaris/gui/binExecStart=/opt/zetaris/gui/bin/start-lightning-gui.shExecStop=/opt/zetaris/gui/bin/stop-lightning-gui.sh[Install]WantedBy=multi-user.target
    ```
    
6.  Save and close the file.

### Start Zetaris

1.  Start the Server
    
    ```
    sudo systemctl start zetaris-enterprise
    ```
    
2.  Start the GUI
    
    ```
    sudo systemctl start zetaris-enterprise-gui
    ```
    
3.  Check the status of the Server
    
    ```
    sudo systemctl status zetaris-enterprise
    ```
    
    You should output similar to the following  
    
    ```
    zetaris-enterprise.service - Zetaris Enterprise Server ServiceLoaded: loaded (/etc/systemd/system/zetaris-enterprise.service; disabled; vendor preset: disabled)Active: active (exited) since Mon 2022-08-29 03:43:10 UTC; 28min agoProcess: 15992 ExecStart=/opt/zetaris/server/bin/start-all.sh (code=exited, status=0/SUCCESS)Main PID: 15992 (code=exited, status=0/SUCCESS)
    ```
    
4.  Check the status of the GUI
    
    ```
    sudo systemctl status zetaris-enterprise-gui
    ```
    
    You should output similar to the following  
    
    ```
    zetaris-enterprise-gui.service - Zetaris Enterprise GUI ServiceLoaded: loaded (/etc/systemd/system/zetaris-enterprise-gui.service; disabled; vendor preset: disabled)Active: active (exited) since Mon 2022-08-29 03:44:40 UTC; 30min agoProcess: 16743 ExecStart=/opt/zetaris/gui/bin/start-lightning-gui.sh (code=exited, status=0/SUCCESS)Main PID: 16743 (code=exited, status=0/SUCCESS)
    ```
    
5.  Enable (optional) automatic start for both Server and GUI services.  
    
    ```
    sudo systemctl enable zetaris-enterprise
    ```
    
    ```
    sudo systemctl enable zetaris-enterprise-gui
    ```
    
6.  Verify the Zetaris processes are running as the non-root user **zetaris**
    
    ```
    ps -u zetaris | grep java
    ```
    
    ![Screen Shot 2022-07-05 at 1.25.57 pm](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/Screen%20Shot%202022-07-05%20at%201.25.57%20pm.png)
    
7.  Register Zetaris user
    
    1.  Switch to the **zetaris** user account
        
        ```
        su - zetaris
        ```
        
    2.  Create the user file
        
        ```
        vi /opt/zetaris/server/bin/dev-org.csv
        ```
        
    3.  Insert the following user details
        
        ```
        First Name\tSurname\tEmail\tTeam(org name)\tPasswordDev,Account,<REDACTED>,Account,password
        ```
        
        Note - you can adjust the values accordin
        
        This creates the following user for login to the Zetaris platform:  
        userid: <REDACTED>  
        password; password
    4.  Save and close the file.
    5.  Register the user
        
        ```
        /opt/zetaris/server/bin/register-org.sh dev-org.csv
        ```
        

### Open Redhat ports

Zetaris leverages the following ports that need to be externally accessible:

-   Web Application GUI port - default 9001
    
-   JDBC Driver port - default 10000
    

If the Redhat firewall is running you will need to configure the Redhat firewall to allows access to these ports.

1.  Run the command **exit** to switch back to the user with sudo privileges
    
    ```
    exit
    ```
    
2.  Check if the Redhat firewall is running:
    
    ```
    sudo systemctl status firewalld
    ```
    
3.  Look for the following output:
    
    ![installing_zetaris_redhat_ports](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/install/installing_zetaris_redhat_ports.png)
4.  If the firewall is running, configure the firewall as per [**Configure Redhat Firewall**](https://kbase.zetaris.com/knowledge/redhatfirewall?hs_preview=VlJrwBrh-78297156988).
    

#### Create AWS or Azure Inbound Security Rules

For Zetaris running on AWS or Azure, you will need to add inbound rules that allow access to the following ports:

-   Web Application GUI port - default 9001
    
-   JDBC Driver port - default 10000
    

For Azure perform the steps as outlined in - [Create Azure Inbound rules](https://kbase.zetaris.com/knowledge/create-azure-inbound-rules).

For AWS perform the steps as outlined in - [Create AWS Inbound rules](https://kbase.zetaris.com/knowledge/aws-inbound-rules).

#### Login to Zetaris Platform

1.  Login to Zetaris via your browser using:  
    http:<public IP address>:9001
    
2.  Enter the following credentials:  
    **username**: dev@account  
    **password**: password
    
    ![installing_zetaris_login](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/install/installing_zetaris_login.png)
3.  You should now see the Zetaris GUI:
    
    ![installing_zetaris_login_2](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/install/installing_zetaris_login_2.png)
    
      
    You should now be successfully logged into your Zetaris deployment.
