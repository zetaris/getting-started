---
source: kbase
url: https://kbase.zetaris.com/knowledge/zetaris-enterprise-on-azure
title: "Clustered enterprise installation on Azure"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 9f247715babe43d4954ee4f24665d631bba24a28e555a076b7888e4bbf9e5d81
---
# Clustered enterprise installation on Azure

## This article details how to install Zetaris Enterprise on Microsoft Azure.

### Prerequisites:

-   Terminal
-   Helm3
-   kubectl
-   Azure CLI
-   Download and unzip the file in the terminal
    -   [https://installationsecret.blob.core.windows.net/secrets/Enterprise\_on\_azure.zip](https://installationsecret.blob.core.windows.net/secrets/Enterprise_on_azure.zip)
    -   To download on terminal use the command below:
        -   ```
            curl https://installationsecret.blob.core.windows.net/secrets/Enterprise_on_azure.zip --output Enterprise_on_azure.zip
            ```
            
    -   To unzip use:

-   -   -   ```
            sudo yum install unzip
            ```
            
        -   ```
            unzip Enterprise_on_azure.zip
            ```
            

### Steps to Install

**Steps 1-9:** Preparing Azure resources

**Step 10-15:** Deploying Zetaris

* * *

#### Step 1: Prepare Resource Group (usually provided by client)

#### Step 2: Install PostgreSQL

-   Search Azure Database for PostgreSQL server
-   Click on create and choose single server

-   -   Resource Group → the resource group created for installation
        
    -   Server Name → choose server name
        
    -   Location → same as Resource Group
        
    -   Click review and create

Try to avoid # character inside password

#### ![Azure Installation 1](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%201.png)

#### Step 3: Create storage account

-   Search for storage account and create a storage account

![Azure Installation 2](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%202.png)

-   Select the same resource group and region
-   Click review + create

#### Step 4: Create a storage container

Once storage is created, create a storage container with the following syntax: \[suffix\]-**cache**  
![Azure Installation 3](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%203.png)  
File Shares (4)  

```
cusdatashare
```

-   keep it empty
    

```
datafabricligshare
```

-   to store config files for server deployment
    
-   copy all the folder structure from XXXX/config\_files/servershare
    

![Azure Installation 4](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%204.png)

```
datafabricliguishare
```

-   to store config files for gui deployment
    
-   copy all the folder structure from XXXX/config\_files/guishare 
    

![Azure Installation 5](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%205.png)![](blob:https://zetaris.atlassian.net/b088c844-dfb9-45ee-a716-3df04529cae9#media-blob-url=true&id=18985b0e-298d-41b2-8ff4-054f42cdc65c&collection=contentId-2626322433&contextId=2626322433&height=196&width=953&alt=)

```
datafabricstreamshare
```

-   keep it empty
    

#### Step 5: Create log analytic workspace

-   Search for log analytic workspace in azure
-   resource group → the one which is created
-   region → same as resource group

![Azure Installation 6](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%206.png)

-   Click review +create
-   monitoring Azure statistics

#### Step 6: Create virtual network

-   Resource group → The one which is created
-   Region → same as resource group

![Azure Installation 7](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%207.png)

-   click on next and set **Address Space -** 10.1.0.0/16
    
-   Set Subnet
    
    -   **subnet address -** 10.1.0.0/20
        

![Azure Installation 8](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%208.png)

-   -   Click review +create

#### Step 7: Create kubernetes cluster

-   Search for Kubernetes services
    
-   Click on create kubernetes services 
    -   kubernetes version → 1.20.13 / 1.21.9
        
    -   resource group → the one which is created
        

![Azure Installation 9](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%209.png)

-   Click on next:Node pools -->next : Authentication
    
    -   Keep rbac to be enabled in Authentication tab
        
    -   Keep Authentication method as “Service principal”
        
        -   Add your service principal client ID
            
        -   Add your service principal client secret
            
    
    ![Azure Installation 10](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%2010.png)
    
    ![](blob:https://zetaris.atlassian.net/74f45c5e-9d4d-40fa-94bb-ebabc63eb244#media-blob-url=true&id=4bf68c93-fb40-4215-9dc5-29cc3518c4de&collection=contentId-2626322433&contextId=2626322433&height=394&width=611&alt=)
    
-   Click on next: Networking

-   -   Choose "Azure CNI"
        

-   -   -   You need to wait for getting permission from the client

![Azure Installation 11](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%2011.png)![](blob:https://zetaris.atlassian.net/32967f50-3951-4a2c-b55e-62c33aa5a554#media-blob-url=true&id=55f94d99-2260-4462-aace-06f530677bc2&collection=contentId-2626322433&contextId=2626322433&height=165&width=769&alt=)

  

-   -   -   Virtual network & Cluster subnet choose the one created above
            
        -   Kubernetes service address range 10.2.32.0/20
            
        -   Kubernetes DNS service IP address 10.2.32.2
            
        -   Docker Bridge address 10.2.48.1/20 
            

![Azure Installation 12](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%2012.png)![](blob:https://zetaris.atlassian.net/9db610e3-c396-4ece-ad20-b751207dab4a#media-blob-url=true&id=384537a9-ea61-42bb-bf1f-60ec7645c53d&collection=contentId-2626322433&contextId=2626322433&height=394&width=636&alt=)

-   Click on review +create
-   After k8s is created, you need to ask permission for MC\_\*\*\*\*\*\*\*\_<region> resource group
    
    -   this resource group is generated with k8s cluster automatically  
        [Frequently asked questions for Azure Kubernetes Service (AKS) - Azure Kubernetes Service](https://docs.microsoft.com/en-us/azure/aks/faq#why-are-two-resource-groups-created-with-aks)
        
    -   <region> is australiaeast for example
        

#### Step 9: Create Public IP

-   search for Public IP address
    
-   click on create
    
-   resource group → the one which is created
    
-   Click on review +create
    

#### Step 10: Connect to databases using DbVisualizer/ DBeaver /Any database tool

-   Under left-side _**Connection security,**_ allow access to Azure services and add your own ip to firewall rules

![](blob:https://zetaris.atlassian.net/0f40c2f9-3151-4338-b5aa-a2ed3166d1e6#media-blob-url=true&id=cd269d58-33f6-4e2c-8df1-eef1f407f92e&collection=contentId-2626322433&contextId=2626322433&height=278&width=1041&alt=)![Azure Installation 13](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%2013.png)

-   Once the connection to the database is made, create 2 databases:  
    
    ```
    CREATE DATABASE metastore;CREATE DATABASE audit_log;
    ```
    

![Azure Installation 14](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%2014.png)

-   Now connect to metastore database

-   -   Execute the the sql statements (metastore queries attached below)
        

![Azure Installation 15](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%2015.png)

-   Now connect to audit\_log database
    -   Execute the the sql statements (audit\_log queries attached below)

![Azure Installation 16](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%2016.png)

#### Step 11: Deployment or Service

-   Once k8s cluster is ready, we can do deployments _**OR**_ make IP / DNS on cluster, these two parts are not sequential.
-   Let’s do deployments first, but before that, we need to download kube\_config to work on cluster.
-   Click Connect on Azure Portal

![](blob:https://zetaris.atlassian.net/1cdbd57a-37fe-49f5-86db-68d591f1dca3#media-blob-url=true&id=a9b49fb1-269e-4213-99c6-5fe9a3207ab0&collection=contentId-2626322433&contextId=2626322433&height=103&width=658&alt=)![Azure Installation 17](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%2017.png)

-   Run commands as instructed

```
az account set --subscription <subscription_id>az aks get-credentials --resource-group <rg_name> --name <k8s_cluster_name>
```

You can add

```
--file /path_to_config/custom_kube_config
```

to save it as a separate config file instead of merging it into

```
~/.kube/config
```

#### Step 12: Solr VM

-   Create a ubuntu VM
    
    -   Use version ubuntu 18.4 or above
        

![](blob:https://zetaris.atlassian.net/b5afcfd0-0fbc-4a0b-a667-bb3355c4e8c5#media-blob-url=true&id=7a8f406c-4db6-4090-919d-cadb1820c4ea&collection=contentId-2626322433&contextId=2626322433&height=707&width=946&alt=)![Azure Installation 18](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%2018.png)

-   -   Use the same virtual network as k8s service

![Azure Installation 19](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%2019.png)

-   -   Click on create button to create virtual machine. This will download .PEM file on your machine. Keep it safe. Will be using it later.
-   Modify meta\_store.properties file in File Share datafabricligshare. For example the Solr VM private ip address is 10.1.0.115, change this line in _**meta\_store.properties**_  
    
    ```
    solr_server=10.1.0.115:8983/solr/
    ```
    
-   Open terminal and run
    
    ```
    chmod 600 xxxx.pem
    ```
    
    to change permission
    
-   Using .pem file ssh to the VM. Do following once you are in the VM:
    
    -   Run
        
        ```
        sudo apt-get update 
        ```
        
        to update.
        
    -   install java by using
        
        ```
        sudo apt-get install openjdk-8-jdk.
        ```
        
        -   Type “java -version” to see if java is installed
            
    
    ![Azure Installation 20](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%2020.png)
    
    -   config java path
        
        ```
        Find out jvm/jdk path. by default it is:/usr/lib/jvm/java-1.8.0-openjdk-amd64Edit .bashrc filevi ~/.bashrc# add this path 6export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64source ~/.bashrcto check if path is accessible:echo $JAVA_HOME
        ```
        
    -   Download lightning server binary from s3 and running solr
        
        ```
        mkdir /home/azureuser/solrcd /home/azureuser/solrwget https://zetaris-download.s3.ap-southeast-2.amazonaws.com/server/20220114/zetaris-ndp-2.1.0.1-production.tgztar -xf zetaris-ndp-2.1.0.1-production.tgzrm zetaris-ndp-2.1.0.1-production.tgzcd zetaris-ndp-2.1.0.1-production/cp -r solr-8.6.0/ /home/azureuse/solrrm -r zetaris-ndp-2.1.0.1-production/cd solr-8.6.0/bin./solr start>> output *** [WARN] *** Your open file limit is currently 1024. It should be set to 65000 to avoid operational disruption. If you no longer wish to see this warning, set SOLR_ULIMIT_CHECKS to false in your profile or solr.in.sh*** [WARN] *** Your Max Processes Limit is currently 15579. It should be set to 65000 to avoid operational disruption. If you no longer wish to see this warning, set SOLR_ULIMIT_CHECKS to false in your profile or solr.in.shWaiting up to 180 seconds to see Solr running on port 8983 [\]Started Solr server on port 8983 (pid=2623). Happy searching!
        ```
        
    -   Verify solr is up
        
        -   Go to Azure portal, add inbound rules > open port 8983, then browse
            
            ```
            <VM-public-ip>:8983
            ```
            
            ```
            kubectl exec -it thunderstorm-driver bash### go into bashcd /usr/share/zetaris/lightning/conf/vi meta_store.properties# to verify solr private ip has been applied by comparing solr private ip
            ```
            

#### Step 13: Deployment

-   Click **Connect** on Azure Portal  
    ![Azure Installation 21](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%2021.png)
-   Run commands as instructed
    
    ```
    az account set --subscription <subscription_id>az aks get-credentials --resource-group <rg_name> --name <k8s_cluster_name>
    ```
    
    You can add
    
    ```
    --file /path_to_config/custom_kube_config
    ```
    
    to save it as a separate config file instead of merging it into ~/.kube/config
    
-   Install Spark Operator, Cert Manager, Nginx-Ingress
    
    -   Helm add repo spark-operator
        
        -   helm repo add spark-operator [spark-on-k8s-operator](https://googlecloudplatform.github.io/spark-on-k8s-operator)
            
        -   helm repo update  
            Our server deployment is of kind: SparkApplication, so we have to install Spark Operator first
            
            ```
            # repo add does not need --kubeconfig helm repo add spark-operator https://googlecloudplatform.github.io/spark-on-k8s-operatorhelm repo add jetstack https://charts.jetstack.iohelm repo add ingress-nginx https://kubernetes.github.io/ingress-nginxhelm repo updatehelm --kubeconfig /path_to_config/kube_config_name \          install spark-operator \          spark-operator/spark-operator \          --namespace spark-operator --create-namespace \          --set webhook.enable=true \          --version 1.1.6kubectl --kubeconfig  create namespace cert-managerkubectl --kubeconfig  label namespace cert-manager certmanager.k8s.io/disable-validation=truehelm --kubeconfig  install \         cert-manager jetstack/cert-manager \          --namespace cert-manager \          --version v1.6.0 \          --set installCRDs=truehelm --kubeconfig  install \        general-ingress ingress-nginx/ingress-nginx \          --namespace kube-system \          --version 4.0.6 \          --set rbac.create=true --set rbac.createRole=true --set rbac.createClusterRole=true \          --set controller.service.loadBalancerIP='' \          --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-resource-group"='' \          --set-string controller.config.proxy-body-size=100m \          --set-string controller.config.server-tokens=false
            ```
            
    
    ![Azure Installation 22](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%2022.png)
    
    Cert Manager  
    
    ![Azure Installation 23](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%2023.png)
    
    Ingress
    
    ![Azure Installation 24](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%2024.png)![](blob:https://zetaris.atlassian.net/328ef014-1f44-4892-a3ed-4cbef0cea204#media-blob-url=true&id=970a7035-2216-41e5-b665-1c093f34d6d8&collection=contentId-2626322433&contextId=2626322433&height=892&width=1232&alt=)
    
-   Apply Secret yaml files
    -   Open secrets.yml file
    -   You will see <Change Here> in line 18,19 and 20-->[![](https://cdn.base64decode.org/assets/images/b64-16.png)Base64 Decode and Encode - Online](https://www.base64decode.org/)
        -   in line 18--> add your storage name for example enterprisetraning2storage
        -   in line 19--> add your account storage name but encoded using base64

![Azure Installation 25](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%2025.png)

-   -   -   in line 20--> add your account storage key but encoded using base64

![Azure Installation 26](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%2026.png)  
![Azure Installation 27](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%2027.png)  
  

-   -   -   Once the file is modified with storagename , storagename in base64 and storagekey in base64 then run
            
            ```
            kubectl --kubeconfig /path of config/name_of_config apply -f secrets.yml
            ```
            
-   Upload deployment config files into relevant File share
    -   go to you storage container in azure
        
    -   open file shares
        
    -   open datafabricligshare
        
    -   edit meta\_store\_properties
        
        -   update connection details of metastore with detail of your database created in above steps
            
        -   update connection details of audit\_log with detail of your database created in above steps
            

  

![Azure Installation 28](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%2028.png)

-   -   -    update the container name and azure blob access key and secret key  
              
            ![Azure Installation 29](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%2029.png)

-   Apply gui deployment file
    -   open terminal where your yaml files are stored and go to XXX/01\_deploy folder
        
    -   Run
        
        ```
        kubectl --kubeconfig /path to config/cofig_name apply -f gui-deployment.yaml
        ```
        
    -   Use _kubectl get pod_ to see if gui is successfully deployed:
        
        ```
        kubectl --kubeconfig /path to config/cofig_name get pod
        ```
        
        ![Azure Installation 30](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%2030.png)
    -   if status is not running, use kubectl get pod/thunderstorm-gui-\*\*\*\*\*\* to see if image is pulled successfully
        -   kubectl --kubeconfig /path to config/cofig\_name get pod/thunderstorm-gui-\*\*\*\*\*
            
-   Apply server deployment file
    
    -   Same step as done for gui deployment
        
        -   instead of uning gui-deployment.yaml use server-deployment.yaml
            
    -   If thunderstorm-driver does not run that Additional step is to use kubectl logs -f pod/thunderstorm-driver to see logs
        
        -   If you see missing table \[table\_name\], you should add tables in Azure Postgres
            
        -   If you see missing settings, please update meta\_store.properties inside datafabricligshare - File share to store server deployment config
            

#### Step 14: Service

-   Apply cluster issuer
    -   open terminal and got folder xxx/yaml\_files
    -   vi ca-issuer.yml
    -   put your email where change email id is mentioned
    -   save the file
    -   run
        -   Cluster issuer which is used to generate Certificate
            
            ```
            kubectl --kubeconfig  apply -f ca-issuer.yml
            ```
            
-   service yaml files
    -   Add DNS record
        
        -   Record name \*.SUBDOMAIN.DOMAIN
            
        -   Record type A
            
        -   value is public static IP inside the k8s auto-created Resource Group  
            the image below is an example, subdomain is enterprise, and domain is zetaris.com
            
            ![](blob:https://zetaris.atlassian.net/9d8336aa-7522-4c0a-98d8-0ebda056331c#media-blob-url=true&id=b6b61114-f5d7-4062-b1d1-a8f4c17992f2&collection=contentId-2626322433&contextId=2626322433&height=635&width=273&alt=)![Azure Installation 31](https://kbase.zetaris.com/hs-fs/hubfs/Azure%20Installation%2031.png)
            
            Example of DNS record
            
    -   Modify the url (host field) inside gui / server / admin gui
        
    -   Apply yaml files
        
        -   gui
            
            -   Go to folder xxx/02\_service
                
            -   vi gui-service.yaml
                
                -   change line 20 and 23 (where CHANGE HERE is mention)
                    
                -   in line 20-> add **ui**.subdomain.domain for example we create enterprise as subdomain and zetaris .com as domain so final edit will be ui.enterprise.zetaris.com
                    
                -   in line 23 -->make same change as line 20
                    
        -   server
            
            -   Go to folder xxx/02\_service
                
            -   vi server-service.yaml
                
                -   change line 20 and 23( where CHANGE HERE is mention)
                    
                -   in line 18-> add **rest**.subdomain.domain for example we create enterprise as subdomain and zetaris .com as domain so final edit will be [rest.enterprise.zetaris.com](http://ui.enterprise.zetaris.com/)
                    
                -   in line 21 -->make same change as line 18
                    

#### Step 15: Creating account on lightning

1.  -   open terminal
        
    -   run command
        
        ```
        kubectl --kubeconfig /path to config/config_name exec -it thunderstorm-driver bash
        ```
        
    -   then run command
        
        ```
        cd /usr/share/zetaris/lightning/bin
        ```
        
    -   once you are in bin folder run command
        
        1.  modify dev.account.sh file
            
            ```
            printf "First Name\tSurname\tEmail\tTeam(org name)\tPassword\nDev,Account,<REDACTED>,Account,password" >> $devOrgChange toprintf "First Name\tSurname\tEmail\tTeam(org name)\tPassword\n{YOUR_FIRST_NAME},{YOUR_SURNAME},{YOUR_EMAIL},{YOUR_ORG_NAME},{YOUR_PASSWORD}" >> $devOrgNote that YOUR_EMAIL is the admin level
            ```
            
        2.  ```
            ./dev-account.sh
            ```
            
        3.  mod
            
        4.  once the site open login to it with credentials
            
            1.  username → YOUR\_EMAIL (by default → <REDACTED>)
                
            2.  password → YOUR\_PASSWORD (by default → password)
