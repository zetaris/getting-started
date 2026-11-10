---
source: kbase
url: https://kbase.zetaris.com/knowledge/installing-zetaris-on-vmware
title: "Installing Zetaris on VMware Tanzu"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: b1279e021cd712c8b5f14441fa654b0b0d5820d016bf7104efc73bd1e3ffde45
---
# Installing Zetaris on VMware Tanzu

> **Pre-requisites:**  
> Please prepare all secret, config, and key files.   
> You will need access to Zetaris Helm charts on Github.  
> Contact the Zetaris team to obtain these files and access to Github.

1.  **Introduction**
    1.  **Overview**  
        This guide provides detailed instruction on how to install Zetaris software on VMware Tanzu.
    2.  **How to Use this Guide**  
        1.  **Introduction** explains the purpose of the document along with its structure and defines the audience.
        2.  **Installation Prerequisites** list all the prerequisites to plan an installation in your environment.
        3.  **Installation Instructions** provides the installation procedure.
    3.  **References**  
        Setting up spark workloads on Openshift   
        [https://cloud.redhat.com/blog/getting-started-running-spark-workloads-on-openshift](https://cloud.redhat.com/blog/getting-started-running-spark-workloads-on-openshift)
    4.  **Zetaris Support**  
        We are committed to providing the highest level of support to Zetaris users. If you encounter any issue or need assistance with the installation, or suggest improvements, please contact our support team.
2.  **Installation Prerequisites**  
    For installing Zetaris software we need to have the following components running:  
      
    
    <table style="border-collapse: collapse; table-layout: fixed; border: 1px solid #99acc2;"><tbody><tr><td style="text-align: center; border-width: 1px; border-style: solid;"><p><strong>Component</strong></p></td><td style="text-align: center; border-width: 1px; border-style: solid;"><p><strong>Requirement</strong></p></td></tr><tr><td style="text-align: center; border-width: 1px; border-style: solid;"><p>VMware Tanzu</p></td><td style="text-align: center; border-width: 1px; border-style: solid;"><p>Admin Access to VMware Tanzu</p></td></tr><tr><td style="text-align: center; border-width: 1px; border-style: solid;"><p>Postgres</p></td><td style="text-align: center; border-width: 1px; border-style: solid;"><p>Zetaris requires Postgres for its internal function</p></td></tr><tr><td style="text-align: center; border-width: 1px; border-style: solid;"><p>Zetaris GUI, API, Backend docker images</p></td><td style="text-align: center; border-width: 1px; border-style: solid;"><p>Actual Zetaris docker images for installation</p></td></tr><tr><td style="text-align: center; border-width: 1px; border-style: solid;"><p>NFS File System</p></td><td style="text-align: center; border-width: 1px; border-style: solid;"><p>Zetaris requires a FileShare with Readwritemany access for persistent storage</p></td></tr><tr><td style="text-align: center; border-width: 1px; border-style: solid;"><p>Certificate Manager</p></td><td style="text-align: center; border-width: 1px; border-style: solid;"><p>Deploy a certificate for Zetaris to use Https</p></td></tr></tbody></table>
    
      
    1.  **PostgreSQL installation**  
        
        Install a PostgreSQL server external to the VMware Tanzu cluster and ensure that the cluster has access to this PostgreSQL instance.
        
        Make sure you use a version of PostgreSQL above 13.
        
        1.   Install PostgreSQL on your server : https://www.postgresql.org/download/ 
        2.   Initialize and start the database  
            
            ```
            sudo postgresql-setup initdbsudo systemctl start postgresql
            ```
            
        3.   Login to postgresql and set a password  
            
            ```
            su – postgres psqlALTER USER postgres WITH PASSWORD 'NewPassword';
            ```
            
            Create an admin user (rds\_admin) using:
            
            ```
            create role rds_admin superuser login password 'password';
            ```
            
             Create the required databases for Zetaris:
            
            ```
            create database metastore;create database audit_log;create database airflow_db;
            ```
            
             Grant all privileges on databases using:
            
            ```
            grant all privileges on database metastore to rds_admin;grant all privileges on database audit_log to rds_admin;grant all privileges on database airflow_db to rds_admin;
            ```
            
        4.   Enable SSL for postgres:  
            Generate a new certificate using openssl.
            
            ```
            openssl genrsa -aes128 2048 > server.keyopenssl rsa -in server.key -out server.keychmod 400 server.keychown postgres.postgres server.keyopenssl req -new -key server.key -days 365 -out server.crt -x509cp server.crt root.crt 
            ```
            
            Go to the var/lib/pgsql/#{version}#/data directory and modify the postgresql.conf file:  
            
            1.  1.  Set listen\_addresses=’\*’
                2.  Set SSL to on by modifying these lines:  
                    
                    ```
                    ssl = onssl_ca_file = 'root.crt'ssl_cert_file = 'server.crt'ssl_crl_file = ''ssl_key_file = 'server.key'ssl_ciphers = 'HIGH:MEDIUM:+3DES:!aNULL' # allowed SSL ciphersssl_prefer_server_ciphers = on
                    ```
                    
            
            Modify the pg\_hba.conf file by adding these 2 lines under the IPv4 local connections:  
            
            ```
            host      all         all         0.0.0.0/0         md5hostssl   all         all         0.0.0.0/0         md5
            ```
            
            Restart the postgresql using sudo systemctl restart postgresql-{version}.
            
    2.  ****Install the Spark Operator  
        ****
        
        Spark operator is needed to manage Zetaris Spark application on helm charts.  
        Add the spark operator repo;
        
        ```
        helm repo add spark-operator https://googlecloudplatform.github.io/spark-on-k8s-operator
        ```
        
        Install the spark operator;
        
        ```
        helm install spark-operator spark-operator/spark-operator --namespace spark-operator --create-namespace --set webhook.enable=true --set resourceQuotaEnforcement.enable=true
        ```
        
    3.  **Install Ingress Nginx  
        **Ingress Nginx is needed for the load balancing so that Zetaris application can be accessible.  
        Add the Ingres Nginx repo:  
        
        ```
        helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
        ```
        
        Install ingress-nginx
        
        ```
        helm upgrade --install lightning-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --version 4.0.18 --set rbac.create=true --set rbac.createRole=true --set rbac.createClusterRole=true --set-string controller.config.proxy-body-size=100m --set-string controller.config.server-tokens=false --set controller.config.generate-request-id=\"false\"
        ```
        
    4.  **Configure Certificates  
          
        TLS Certificates**  
        Use your certificate authority to issue a TLS certificate for Zetaris to be able to use HTTPS.
        
        To install cert-manager:
        
        ```
        helm repo add jetstack https://charts.jetstack.iohelm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager  --create-namespace --version v1.7.0 --set installCRDs=true
        ```
        
        You then have to create a secret with the certificate issued by your CA.
        
        ```
        apiVersion: v1kind: Secretmetadata:   name: #{ca-secret}#type: kubernetes.io/tlsdata:  tls.crt: --BASE64 ENCODED STRING--   tls.key: --BASE64 ENCODED STRING-- 
        ```
        
         Once you created this secret, make sure you specify the name of your ca-secret in the solr/tanzuvalues.yaml file, so that the cluster issuer retrieves this certificate (cf part 8)  
        **Note:** If you cannot provide a TLS certificate, you can use letsencrypt to provide publicly signed certificates if the cluster is publicly accessible from the net.
        
          
        **Encryption keys  
        **Use OpenSSL to generate public and private keys to encrypt the password in Zetaris  
        
        ```
        #Generate a private_key.pemopenssl genrsa -out private_key.pem 2048#Generate a private_key.deropenssl pkcs8 -topk8 -inform PEM -outform DER -in private_key.pem -out private_key.der -nocrypt#Generate a public_key.deropenssl rsa -in private_key.pem -pubout -outform DER -out public_key.der
        ```
        
        Use public and private keys generated to create a k8s secret for password encryption in your namespace
        
        ```
        Kubectl create namespace {yournamespace}kubectl create secret generic lightning-password-security-encryption-secret --from-file=private_key.der --from-file=public_key.der –-namespace {yournamespace}
        ```
        
    5.  **Configure NFS**  
        Zetaris requires a ReadWriteMany file system to store persistent data.  
        Create a NFS in Tanzu and create a nfsvalues file as follows, and add the file share name and mount path in the values file.  
        
        ```
        nfs:    # The NFS server endpoint that we got from vSAN FS   server: vsan-fs01.tanzu.lab    # The NFS share mount path from vSAN FS   path: /share01storageClass:   # The name of the StorageClass to be created on the K8s cluster to allow provisioning of RWM volumes from the share   name: nfs-external   # The accessMode that we want to be created from these subvolumes    (ReadWriteMany allows multiple containers to mount it at once) accessModes: ReadWriteMany podSecurityPolicy:    # Enabling the pod security policy allows it to run on TKGS clusters out of the box   enabled: true
        ```
        
         Once created, you can install the storage class using the NFS helm charts  
        
        ```
        helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisionerhelm repo updatekubectl create namespace infrahelm install nfs-subdir-external-provisioner --namespace infra nfs-subdir-external-provisioner/nfs-subdir-external-provisioner -f nfsvalues.yaml
        ```
        
3.  **Install Zetaris  
    **Clone the helm charts from the git repository [https://github.com/zetaris/TanzuInstallation](https://github.com/zetaris/TanzuInstallation)
    1.  **Modify the values file for each component**
        1.  Modify the necessary “tanzuvalues.yaml” that are tokenized (between #{}#) for each component (server, gui, api, solr and airflow).
        2.  Make sure:
            1.  The components are correctly configured to the PostgreSQL server.
            2.  The URL corresponds to the certificate issued for https.
            3.  In the lightning-server values, specify cores and executors according to your cluster size. (a minimum of 2CPU and 8GBram is recommended per executor).
            4.  The image is by default pointing to the latest stable version, there is no need to modify this value.
    2.  **Run the helm install script  
        **From the root directory, modify the bash scripts to point to your namespace (by default zetaris) and run them to deploy the different components:
        
        ```
        ./lightning-server/deploy-lightning-server Y ./lightning-api/deploy-lightning-api Y ./lightning-gui /deploy-lightning-gui Y ./solr/deploy-solr Y
        ```
        
        All pods should be in running state. If there is any error, please contact us.
        
4.  **Install Airflow  
    **
    1.  **Install official airflow image  
        **
        1.  To install airflow, add the official airflow helm charts to your help repo:  
            
            ```
            helm repo add apache-airflow https://airflow.apache.org
            ```
            
        2.  Modify the airflowvalues file located in the airflow directory.
            
        3.  You can specify some environment variables for airflow from this values file.
            
        4.  It is recommended to add your Zetaris user credentials and JDBC IP to take advantage of airflow.
            
        5.  You can also add credentials for notification emails.
            
        6.  If you don’t have these information now, you will be able to set them in airflow UI.
            
        7.  Make sure you specify the PostgreSQL server for your airflow to have persistent storage. You can then deploy airflow using :  
            
            ```
            helm upgrade --install airflow apache-airflow/airflow -f ./airflow/airflowvalues.yaml --namespace airflow --create-namespace
            ```
            
    2.  **Install service for airflow** 
        1.  Modify the values.yaml file in the airflow directory, by configuring your postgresql instance and your NFS file share name.
        2.  You can then run to deploy ingress:  
            
            ```
            ./airflow/deploy-airflow.sh ing
            ```
            
        3.  Airflow will then be accessible directly from Zetaris UI, or at   
            
            ```
            airflow.#{deploymentname}#.#{dnsdomain}#
            ```
            
5.  **Create a DNS record for your application**
    1.  Add a DNS record for your application.
    2.  Use _**kubectl get ingress -n {yournamespace}**_ to retrieve the public IP of the UI, can create a DNS record in your DNS zone with the name _**\*.{yourdeploymentname}.{yourdnsdomain}**_.
    3.  This must match your certificate to enable https**.**
6.  **Create your user account**
    1.  Login to ‘lightning-server-driver’ pod using
        
        ```
        kubectl exec -it lightning-server-driver -n {yournamespace} -- bash
        ```
        
    2.  Run the dev-account.sh script to create your first admin user:  
        
        ```
        /home/zetaris/lightning/bin/dev-account.sh <REDACTED> password organisation
        ```
        
7.  **Launch Zetaris**
    1.  Open your browser from any computer that is connected to VM and can access the machine on which Zetaris is installed. Use the DNS created earlier to launch Zetaris from browser window.  
        ![Picture2-1](https://kbase.zetaris.com/hs-fs/hubfs/Picture2-1.png)
    2.  Please enter user email and password that you created earlier
        
8.  **Annexes**  
    **Install Zetaris with GPU**
    1.  **Make sure your Cluster has allocatable GPUs.**
        1.  Run _**kubectl get nodes**_ to see the node available in your cluster.
            
        2.  Run _**kubectl describe node <nodename>**_ to get information about your GPU node, and make sure you can see some GPU capacity:  
            ![Picture3-1](https://kbase.zetaris.com/hs-fs/hubfs/Picture3-1.png)
            
        3.  The easiest way to make use of these GPU in a Kubernetes cluster is to use the nvidia GPU operator, which will detect the GPU on your nodes and make them available to use: [Installing the NVIDIA GPU Operator — gpu-operator 23.6.0 documentation](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/openshift/install-gpu-ocp.html#:~:text=Installing%20the%20NVIDIA%20GPU%20Operator%20by%20using%20the,click%20Install.%20In%20the%20subsequent%20screen%20click%20Install.) It can be installed with a single helm command:
            
            ```
            helm repo add nvidia https://helm.ngc.nvidia.com/nvidia && helm repo updatehelm install --wait --generate-name \ -n gpu-operator --create-namespace \ nvidia/gpu-operator
            ```
            
    2.  **Modify the backend base image**
        1.  Zetaris has a dedicated image for GPU based on the nvidia cuda official image in order to run spark applications on GPU. Please contact us if you need this image ID.
    3.  **Add the required configuration in the spark configuration**
        1.  In the spark configuration part of the helm deployment, add the following params: (once the application is deployed, you can use _**kubectl edit sparkapplication lightning-server -n zetaris**_ to modify the configs).
        2.  Make sure the extra class path contains the spark rapid jar path.
            
            ```
            spark.driver.extraClassPath:/home/zetaris/lightning/conf:/home/zetaris/lightning/other/*:/home/zetaris/lightning/lib/com.nvidia.rapids-4-spark_2.12-23.06.0.jarspark.executor.extraClassPath:/home/zetaris/lightning/other/*:/home/zetaris/lightning/lib/com.nvidia.rapids-4-spark_2.12-23.06.0.jar
            ```
            
        3.  Add these GPU parameters:
            1.  The getGPUResource script is already copied from the image and is needed by sparkrapid)
            2.  Only 1 GPU per executor is allowed, but you can use the task.resource.gpu.amount to be 0.5.
            3.  Adapt the spark rapid memory values according to your cluster size.  
                
                ```
                spark.executor.resource.gpu.amount: "1"spark.executor.resource.gpu.vendor: "nvidia.com"spark.executor.resource.gpu.discoveryScript:/home/zetaris/lightning/bin/getGpusResources.shspark.plugins: "com.nvidia.spark.SQLPlugin"spark.rapids.sql.concurrentGpuTasks: "2"spark.task.resource.gpu.amount: "1"spark.rapids.memory.pinnedPool.size: "2G"spark.rapids.memory.host.spillStorageSize: "4g"spark.sql.shuffle.partitions: "20"
                ```
                
            4.  On the executor declaration, add this block to make sure the executor request 1 GPU from the nodes.  
                
                ```
                executor:   gpu:    name: nvidia.com/gpu    quantity: 1
                ```
                
                 Your application should now be running on GPUs. You can check the logs of your lightning-server-driver and run a simple command to see the GPU logs.
