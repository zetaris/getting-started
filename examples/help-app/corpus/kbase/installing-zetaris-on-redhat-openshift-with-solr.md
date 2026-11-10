---
source: kbase
url: https://kbase.zetaris.com/knowledge/installing-zetaris-on-redhat-openshift-with-solr
title: "Installing Zetaris on Redhat Openshift"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 56ab1eaa11e6b93f6ae36298703e94b9bbbef02488e0ea547ea6d52abaeab0e5
---
# Installing Zetaris on Redhat Openshift

> **Pre-requisites:**  
> Please prepare all secret, config, and key files. Contact the Zetaris team to obtain these files.

1.  **Introduction**
    1.  **Overview**  
        This guide provides detailed instruction on how to install Zetaris software on Red Hat OpenShift.
    2.  **How to Use this Guide**  
        1.  **Introduction** explains the purpose of the document along with its structure and defines the audience.
        2.  **Installation Prerequisites** list all the prerequisites to plan an installation in your environment.
        3.  **Installation Instructions** provides the installation procedure.
    3.  **References**  
        Setting up spark workloads on Openshift   
        [https://cloud.redhat.com/blog/getting-started-running-spark-workloads-on-openshift](https://cloud.redhat.com/blog/getting-started-running-spark-workloads-on-openshift)
    4.  **Zetaris Support**  
        We are committed to providing the highest level of support to Zetaris users. If you encounter any issue or need assistance with the installation, or suggest improvements, please contact our support team.
2.  **Installation Prerequisites**  
    For installing Zetaris software we need to have the following components running:  
      
    
    <table style="width: 100%; border-collapse: collapse; table-layout: fixed; border: 1px solid #99acc2; height: 390.667px;"><tbody><tr style="height: 35px;"><td style="width: 50.0169%; padding: 4px; text-align: center; border-width: 1px; border-style: solid; height: 35px;"><strong>Component</strong></td><td style="width: 50.0169%; padding: 4px; text-align: center; border-width: 1px; border-style: solid; height: 35px;"><strong>Requirement</strong></td></tr><tr style="height: 71px;"><td style="width: 50.0169%; padding: 4px; text-align: center; border-width: 1px; border-style: solid; height: 71px;">&nbsp;Red Hat OpenShift&nbsp;</td><td style="width: 50.0169%; padding: 4px; text-align: center; border-width: 1px; border-style: solid; height: 71px;"><p>OpenShift version 4.10.40 with kubeadmin level access.</p></td></tr><tr style="height: 71px;"><td style="width: 50.0169%; padding: 4px; text-align: center; border-width: 1px; border-style: solid; height: 71px;"><p style="text-align: center;"><strong>oc </strong>command line tool</p></td><td style="width: 50.0169%; padding: 4px; text-align: center; border-width: 1px; border-style: solid; height: 71px;"><p>Required to execute command on Red Hat OpenShift cluster</p></td></tr><tr style="height: 71px;"><td style="width: 50.0169%; padding: 4px; text-align: center; border-width: 1px; border-style: solid; height: 71px;"><p>Docker Hub access</p></td><td style="width: 50.0169%; padding: 4px; text-align: center; border-width: 1px; border-style: solid; height: 71px;"><p>Access to Zetaris docker hub can be given by Zetaris Sys admin</p></td></tr><tr style="height: 71px;"><td style="width: 50.0169%; padding: 4px; text-align: center; border-width: 1px; border-style: solid; height: 71px;">&nbsp;Postgres&nbsp;</td><td style="width: 50.0169%; padding: 4px; text-align: center; border-width: 1px; border-style: solid; height: 71px;"><p>Zetaris 2.3.3.0 requires Postgres for it’s internal function</p></td></tr><tr style="height: 71px;"><td style="width: 50.0169%; padding: 4px; text-align: center; border-width: 1px; border-style: solid; height: 71px;"><p>Zetaris GUI, API, Backend docker images</p></td><td style="width: 50.0169%; padding: 4px; text-align: center; border-width: 1px; border-style: solid; height: 71px;"><p>Actual Zetaris docker images for installation</p></td></tr></tbody></table>
    
3.  **Setup the ‘namespace’ and ‘serviceaccount’**
    1.  Login to Red Hat OpenShift cluster using kubeadmin credentials from **oc** command line tool.
    2.  Create a new project using
        
        ```
        oc new-project zetaris
        ```
        
    3.  Create service account for all pods to run with appropriate level of access. Use this command 
        
        ```
        oc create sa zetaris-sa-scc-anyuid -n zetaris
        ```
        
    4.  Add the service account in the **_anyuid scc_**. Use this command.  
        
        ```
        oc adm policy add-scc-to-user anyuid -z zetaris-sa-scc-anyuid -n zetaris
        ```
        
    5.  Add the service account and policy to the project. Use the following command  
        
        ```
        kubectl create clusterrolebinding spark-role --clusterrole=edit --serviceaccount=zetaris:zetaris-sa-scc-anyuid --namespace=zetaris
        ```
        
4.  ****Postgres Installation  
    ****
    
    Please install Postgres external to Red Hat OpenShift cluster. Also please ensure that Red Hat OpenShift cluster can have access to this Postgres instance.
    
    1.  **Install PostgreSQL  on CentOS**   
        
        ```
        sudo yum install postgresql-13-server postgresql-contrib
        ```
        
    2.   ****Initialise the database****
        
        ```
        sudo postgresql-setup initdb
        ```
        
    3.  ****Start the database  
        ****
        
        ```
        sudo systemctl start postgresql
        ```
        
    4.  **PostgreSQL basic setup**
        
        1.  Change user to postgres  
            
            ```
            su – postgres
            ```
            
        2.  Login to database  
            
            ```
            psql
            ```
            
        3.  Set new password for default user “postgres”  
            
            ```
            ALTER USER postgres WITH PASSWORD 'NewPassword';
            ```
            
    5.  Open terminal and run;  
        
        ```
        psql
        ```
        
    6.  Create user rds\_admin and make this user database admin. Please keep a note of its password as it is required for connecting to database.  
        
        ```
        create role rds_admin superuser login password 'password';
        ```
        
    7.  Create database metastore using,  
        
        ```
        create database metastore;
        ```
        
    8.  Create database audit\_log using,  
        
        ```
        create database audit_log;
        ```
        
    9.  Grant all privileges on database metastore using,  
        
        ```
        grant all privileges on database metastore to rds_admin;
        ```
        
    10.  Grant all privileges on database audit\_log using,  
        
        ```
        grant all privileges on database audit_log to rds_admin;
        ```
        
5.  **Install the Spark Operator**
    1.  Add the spark operator repo;  
        
        ```
        helm repo add spark-operator https://googlecloudplatform.github.io/spark-on-k8s-operator
        ```
        
    2.  Install the spark operator;  
        
        ```
        helm install spark-operator spark-operator/spark-operator --namespace spark-operator --create-namespace --set webhook.enable=true --set resourceQuotaEnforcement.enable=true
        ```
        
6.  **Create the secrets**
    1.  Apply the secrets manifests yaml;  
        
        ```
        oc apply -f zetaris-manifests-secrets.yaml
        ```
        
    2.  Create secret _**lightning-password-security-encryption-secret**_ in project Zetaris using following key and values. In our setup we have used Red Hat OpenShift GUI Console to do this.  
        
        <table style="width: 100%; border-collapse: collapse; table-layout: fixed; border: 1px solid #99acc2;"><tbody><tr><td style="width: 49.9196%; padding: 4px; text-align: center; border-width: 1px; border-style: solid;"><strong>Key</strong></td><td style="width: 49.9196%; padding: 4px; text-align: center; border-width: 1px; border-style: solid;"><strong>Value</strong></td></tr><tr><td style="width: 49.9196%; padding: 4px; text-align: center; border-width: 1px; border-style: solid;">private_key.der</td><td style="width: 49.9196%; padding: 4px; text-align: center; border-width: 1px; border-style: solid;">private_key.der file provided by Zetaris</td></tr><tr><td style="width: 49.9196%; padding: 4px; text-align: center; border-width: 1px; border-style: solid;">pubic_key.der</td><td style="width: 49.9196%; padding: 4px; text-align: center; border-width: 1px; border-style: solid;">public_key.der file provided by Zetaris</td></tr></tbody></table>
        
7.  **Create the config maps  
    **Apply the configmaps manifests yaml;  
    
    ```
    oc apply -f zetaris-manifests-configmaps.yaml
    ```
    
8.  **Create the deployments  
    **Apply the deployments manifests yaml;  
    
    ```
    oc apply -f zetaris-manifests-deployments.yaml
    ```
    
9.  **Create the services  
    **Apply the services manifests yaml;  
    
    ```
    oc apply -f zetaris-manifests-svcs.yaml
    ```
    
10.  **Create the routes  
    **Apply the routes manifests yaml;  
    
    ```
    oc apply -f zetaris-manifests-routes.yaml
    ```
    
11.  **Install Solr**
    1.  Pull the solr helm chart  
        
        ```
        helm pull registry-1.docker.io/zetaris/solr
        ```
        
    2.  Run the helm chart as below:  
        
        ```
        helm upgrade -i --create-namespace -n zetaris solr -f values.yaml
        ```
        
        Here is the explanation of the helm value attributes found in values.yaml:  
        **Registrysecretname** – The secret that holds the auth creds for zetaris’ dockerhub account so that K8s can pull the solr image.  
        **Sslname** – The name of LetsEncrypt Issuer.  
        **Emailaddress** – Any relevant email address. This is needed by the Issuer.  
        If you don’t understand any other attribute, just leave the values the way it is or replace it with blank.
        
12.  **Install Airflow**
    1.  ****Install official airflow image  
        ****To install airflow, add the official airflow helm charts to your help repo:
        
        ```
        helm repo add apache-airflow https://airflow.apache.org
        ```
        
        Modify the airflowvalues.yaml file :
        
        1.  You can specify some environment variables for airflow from this values file.
            
        2.  It is recommended to add your Zetaris user credentials and JDBC IP to take advantage of your airflow environment.
            
        3.  You can also add credentials for notification emails.
            
        4.  If you don’t have these information now, you will be able to set them in airflow UI.
            
        5.  Make sure you specify the PostgreSQL server for your airflow to have persistent storage.
            
        6.  You can then deploy airflow using :  
            
            ```
            helm upgrade --install airflow apache-airflow/airflow -f ./path/to/your/airflowvalues.yaml --namespace airflow --create-namespace
            ```
            
    2.  ****Install service for airflow  
        ****
        
        After installing airflow, you will need to create a service to redirect to airflow.
        
        1.  Retrieve the helm template here [HelmDeployment/airflow-ing/azure at main · zetaris/HelmDeployment (github.com).](https://github.com/zetaris/HelmDeployment/tree/main/airflow-ing/azure)
            
        2.  Modify the values file to have your persistent volume configured for airflow Dags, and run the helm install command to create the PV and the service:  
            
            ```
            helm upgrade -i --create-namespace -n airflow airflow-ing -f airflow-ing/aws/eks-load-testing-cluster.airflow.values.yaml airflow-ing/aws
            ```
            
        3.  Once done, specify the airflow apache URL in the lightning-gui deployment as an environment variable so that it appears in the UI.
            
        4.  Run _**kubectl edit deployment lightning-gui -n zetaris**_ and add the following variable if not already existing:  
            
            ```
                 containers:…         env:…            - name: APACHE_AIRFLOW_URL             value: https://airflow..
            ```
            
        5.  Airflow will then be accessible directly from Zetaris UI, or airflow.#{deploymentname}#.#{dnsdomain}#.
            
13.  **Final deployment should contain running pods as shown below;  
    ![Picture1-3](https://kbase.zetaris.com/hs-fs/hubfs/Picture1-3.png)**
14.  **Create Lightning user account  
    **
    1.  Login to ‘lightning-server-driver’ pod
    2.  Run the dev-account.sh script  
        
        ```
        /home/zetaris/lightning/bin/dev-account.sh
        ```
        
15.  **Launch Zetaris**

1.  1.  Please Open browser window (preferably chrome) from any computer that is connected to VM and can access the machine on which Zetaris is installed.
    2.  Use URL from route created earlier (e.g. [http://zetaris-zetaris.apps.zetaris.iac.ssc](http://zetaris-zetaris.apps.zetaris.iac.ssc)) to launch Zetaris from browser window.  
        ![Picture2-1](https://kbase.zetaris.com/hs-fs/hubfs/Picture2-1.png)
    3.  Please enter user email: **<REDACTED>**
    4.  Please enter the password: <REDACTED>
    5.  This should log you in. and see Zetaris front end.
