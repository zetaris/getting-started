---
source: kbase
url: https://kbase.zetaris.com/knowledge/installing-zetaris-on-opensource-kubernetes-microk8
title: "Installing Zetaris on OpenSource kubernetes (microk8)"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: d8aff700c28756cef69defaf7ceadeb3f0c3a6da076236dbdd1ece4d5579a9ea
---
# Installing Zetaris on OpenSource kubernetes (microk8)

## This article demonstrates how to install Zetaris on a single node box for exploratory use on a open source kubernetes like minikube

### 1\. Introduction

Installing a Helm chart on Minikube allows you to quickly deploy applications into a local Kubernetes environment for development and testing. Helm acts as a package manager for Kubernetes, simplifying the deployment of complex workloads. After starting Minikube and setting up Helm, you can add the Zetaris Helm chart repositories, update your repository list, and install the chart with  simple commands. This setup provides a fast, flexible way to prototype, validate, and manage open-source kubernetes based Zetaris application locally.

#### 1.1. Overview

This guide provides detailed instruction on how to install Zetaris software on Red Hat OpenShift/Kubernetes environment

#### 1.2. How to Use this Guide

-   Introduction explains the purpose of the document along with its structure and defines the audience.
-   Installation Prerequisites list all the prerequisites to plan an installation in your environment.
-   Installation Instructions provides the installation procedure.

#### 1.3. Zetaris Support

We are committed to providing the highest level of support to Zetaris users. If you encounter any issue or need assistance with the installation, or suggest improvements, please contact our support team.

#### 2\. Installation Prerequisites

For installing Zetaris software we need to have the following components running:

Managed K8s OR Openshift Environment (Cloud or Managed platform)

<table style="width: 100%; border-collapse: collapse; table-layout: fixed; border: 1px solid #99acc2; height: 227px;"><tbody><tr style="height: 35px;"><td style="width: 49.9273%; padding: 4px; height: 35px; border-width: 2px; border-style: solid;"><strong>Components</strong></td><td style="width: 49.9273%; padding: 4px; height: 35px; border-width: 2px; border-style: solid;"><strong>Requirements</strong></td></tr><tr style="height: 61px;"><td style="width: 49.9273%; padding: 4px; height: 61px; border-width: 1px; border-style: solid;">Red Hat OpenShift</td><td style="width: 49.9273%; padding: 4px; height: 61px; border-width: 1px; border-style: solid;">OpenShift version &gt; 4.10.40 with kubeadmin level access.</td></tr><tr style="height: 61px;"><td style="width: 49.9273%; padding: 4px; height: 61px; border-width: 1px; border-style: solid;">oc command line tool</td><td style="width: 49.9273%; padding: 4px; height: 61px; border-width: 1px; border-style: solid;">Required to execute command on Red Hat OpenShift cluster</td></tr><tr><td style="width: 49.9273%; padding: 4px; border-width: 1px; border-style: solid;">Docker engine (running state)</td><td style="width: 49.9273%; padding: 4px; border-width: 1px; border-style: solid;">&nbsp;</td></tr><tr style="height: 35px;"><td style="width: 49.9273%; padding: 4px; height: 35px; border-width: 1px; border-style: solid;">Kubectl</td><td style="width: 49.9273%; padding: 4px; height: 35px; border-width: 1px; border-style: solid;">v1.32.0</td></tr><tr style="height: 35px;"><td style="width: 49.9273%; padding: 4px; height: 35px; border-width: 1px; border-style: solid;">Helm</td><td style="width: 49.9273%; padding: 4px; height: 35px; border-width: 1px; border-style: solid;">v3.16.4</td></tr></tbody></table>

**Microk8s Installation**

**Centos**

```
sudo yum install -y epel-releasesudo yum update -ysudo yum install -y snapdsudo systemctl enable --now snapd.socketsudo ln -s /var/lib/snapd/snap /snapsnap versionsudo snap install microk8s --classic
```

**RHEL**

```
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpmsudo dnf update -ysudo dnf install -y snapdsudo systemctl enable --now snapd.socketsudo ln -s /var/lib/snapd/snap /snapsudo snap install microk8s --classic
```

Helm

```
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**Micork8s User Setup:**

```
sudo usermod -a -G microk8s $USERsudo chown -f -R $USER ~/.kube
```

```
newgrp microk8sexport KUBECONFIG=/var/snap/microk8s/current/credentials/client.config
```

```
microk8s enable dns storagemicrok8s enable ingress dashboard metrics-server
```

```
echo "alias kubectl='microk8s kubectl'" >> ~/.bashrcsource ~/.bashrc
```

```
sudo systemctl stop firewalld
```

```
mkdir -p ~/.kubecp /var/snap/microk8s/current/credentials/client.config ~/.kube/config
```

**Helm**

```
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

#### 3\. Setup the ‘namespaces’

· Login to OpenShift / Kubernetes cluster using kubeadmin credentials from oc/kubectl command line tool.

```
kubectl create namespace zetaris
```

```
kubectl create namespace airflow
```

Set the below variables for the current version release in your terminal.

> Please contact Zetaris for the token below

```
$zettoken=<REDACTED>
```

```
$zetrelease=helm_latest
```

Set the env value to reflect the Infrastructure provider 

like 'aws', 'azure', 'ibm', 'gcp', 'dell', 'hitachi', 'local' (minikube)

```
$environment=local
```

#### 4\. Postgres installation

Please install Postgres external using the below two option

**A).**Postgres on external source like RDS or other managed services. Go with the low cost one like Azure flexible server, AWS Aurora postgres..etc  

OR

**B)** .Postgres on k8s inside the cluster.

> Run “kubectl get sc” to confirm the storage class

> Set appropriate “storageClassName”. “kubectl get sc”

```
$storageclass=default
```

```
helm repo add helm-postgres https://$<REDACTED>/zetaris/openshift/$zetrelease/postgres
```

```
helm upgrade --install postgres \helm-postgres/postgres --namespace zetaris \--set storageClassName=$storageclass \--set environment=$environment
```

List out all generated pods

```
kubectl get pods -n zetaris
```

Get the pod name of postgres

```
kubectl exec -it <postgres pod name> -n zetaris -- /bin/sh
```

```
su - postgres
```

The below command would ask password and enter “<Your Choice Password>”

```
psql -h postgres -U rds_admin postgres
```

```
create database metastore;
```

```
create database auditlog;
```

```
create database airflowdb;
```

#### 5\. Install the Spark Operator and Opensearch

· Add the spark operator, cert repo;

```
helm repo add spark-operator https://kubeflow.github.io/spark-operator helm repo add jetstack https://charts.jetstack.io
```

```
helm repo update
```

· Install the spark operator , cert manager;

```
helm upgrade --install spark-operator spark-operator/spark-operator --namespace spark-operator --create-namespace --version=1.2.15 --set webhook.enable=true
```

```
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
```

```
helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.7.0 --set installCRDs=true
```

Install the opensearch;

**Option 1: Using helm charts**

```
helm uninstall opensearch -n zetaris
```

```
 helm upgrade --install opensearch opensearch/opensearch --namespace zetaris --set image.tag=2.11.0 --set serviceAccount.name=zetaris-sa
```

**Option 2**:  **Using git repo**

```
git clone https://github.com/zetaris/opensearch.git
```

```
helm uninstall opensearch -n zetaris
```

```
helm upgrade --install opensearch opensearch/hitachi --namespace zetaris --set image.tag=2.11.0 --set serviceAccount.name=zetaris-sa
```

#### 6\. Lightning Deployments

Add below helm repos,

```
helm repo add helm-zetaris-lightning-solr https://$<REDACTED>/zetaris/HelmDeployment/$zetrelease/solr/helm/
```

```
helm repo add helm-zetaris-lightning-server https://$<REDACTED>/zetaris/zetaris-lightning/$zetrelease/deployments/helm/
```

```
helm repo add helm-zetaris-lightning-api https://$<REDACTED>/zetaris/lightning-api/$zetrelease/deployments/helm/
```

```
helm repo add helm-zetaris-lightning-gui https://$<REDACTED>/zetaris/lightning-gui/$zetrelease/deployments/helm/
```

```
helm repo add helm-zetaris-lightning-zeppelin https://$<REDACTED>/zetaris/zetaris-zeppelin/$zetrelease/deployments/helm/
```

```
helm repo add helm-zetaris-digiavatar https://$<REDACTED>/zetaris/digiavatar/$zetrelease/deployments/helm/
```

```
helm repo add helm-zetaris-privateai https://$<REDACTED>/zetaris/privateai/$zetrelease/deployments/helm/
```

```
helm repo add helm-zetaris-airflow-ing https://$<REDACTED>/zetaris/HelmDeployment/$zetrelease/airflow-ing/helm/
```

#### Replace the below values and apply helm install,

Update image and domain configs.

```
serverImage=zetregistry.azurecr.io/lightning-server:v2.4.1.0-latestapiImage=zetregistry.azurecr.io/lightning-api:v2.4.1.0-latestguiImage=zetregistry.azurecr.io/lightning-gui:v2.4.1.0-latestcomputesparkimage=zetregistry.azurecr.io/lightning-server:v2.4.1.0-latestcomputeprestoimageRepo=zetregistry.azurecr.io/lightning-presto-appcomputeprestoimageTag=zv2.4.1.0-latestzeppelinImage=zetregistry.azurecr.io/lightning-zeppelin-app:zv2.4.1.0-latestbasednsname=test.zetaris.comdnsprotocol=http
```

Update postgres details here,

```
dbdns=postgresdbport=5432metadb=metastoreauditdb=audit_logdbuser=rds_admindbpwd=<Your chosen password in Step 4>sslmode=requiremetastoreJdbcUrl="jdbc:postgresql://$dbdns:$dbport/$metadb?user=$dbuser&password=<REDACTED>
```

For AWS EFS as storage

```
awsefsid=""awsefsdata=""awsefszeppelin=""tls_cert_arn=""
```

For Azure SA as storage

For guidance on creating public and private keys, please refer to the following resource: https://stackoverflow.com/questions/44474516/how-to-create-public-and-private-key-with-openssl.

```
storageAccountName=""storageAccountKey=""$privateKeyDer=XXXXXXXXXXX$publicKeyDer=YYYYYYYYYY
```

Lightning solr deployment

```
helm upgrade --install lightning-solr \helm-zetaris-lightning-solr/solr \--namespace zetaris \--set storageClassName=$storageclass \--set environment=$environment
```

Lightning server deployment

```
helm upgrade --install lightning-server \helm-zetaris-lightning-server/lightning-server \--namespace zetaris \--set db.metastore.JdbcUrl=$metastoreJdbcUrl \--set db.auditLog.JdbcUrl=$auditLogJdbcUrl \--set storage.storageClass=$storageclass \--set environment=$environment \--set encryption.privateKeyDer=$privateKeyDer \--set encryption.publicKeyDer=$publicKeyDer \--set azure.storageAccountName=$storageAccountName \--set azure.storageAccountKey=$storageAccountKey \--set aws.efs.id=$awsefsid \--set aws.efs.data=$awsefsdata \--set serverImage=$serverImage
```

Lightning API deployment

```
helm upgrade --install lightning-api \helm-zetaris-lightning-api/lightning-api \--namespace zetaris \--set environment=$environment \--set apiImage=$apiImage \--set ingress.protocol=$dnsprotocol \--set aws.ingress.tls_cert_arn=$tls_cert_arn \--set ingress.baseDomain=$basednsname \--set db.metastore.JdbcUrl=$metastoreJdbcUrl \--set db.auditLog.JdbcUrl=$auditLogJdbcUrl \--set compute.spark.image=$computesparkimage \--set compute.presto.imageRepo=$computeprestoimageRepo \--set compute.presto.imageTag=$computeprestoimageTag
```

Lightning GUI deployment

```
helm upgrade --install lightning-gui \helm-zetaris-lightning-gui/lightning-gui \--namespace zetaris \--set guiImage=$guiImage \--set ingress.protocol=$dnsprotocol \--set aws.ingress.tls_cert_arn=$tls_cert_arn \--set ingress.baseDomain=$basednsname \--set environment=$environment
```

Lightning Zeppelin deployment

```
helm upgrade --install lightning-zeppelin \helm-zetaris-lightning-zeppelin/lightning-zeppelin \--namespace zetaris \--set ingress.protocol=$dnsprotocol \--set ingress.baseDomain=$basednsname \--set ingress.tls_cert_arn=$tls_cert_arn \--set storage.storageClass.name=$storageclass \--set environment=$environment \--set aws.efs.id=$awsefsid \--set aws.efs.zeppelin=$awsefszeppelin \--set zeppelin.image=$zeppelinImage  --set storage.volume.size=$zeppelinpv 
```

Digiavatar deployment

```
helm upgrade --install digiavatar helm-zetaris-digiavatar/digiavatar --namespace zetaris \--set ingressprotocol=$dnsprotocol --set ingress.baseDomain=$basednsname \--set environment=$environment \--set serviceaccount=zetaris-sa
```

Private AI deployment

```
helm upgrade --install privateai helm-zetaris-privateai/privateai --namespace zetaris \--set ingress.baseDomain=$basednsname \--set ingressprotocol=$dnsprotocol \--set environment=$environment \--set gpuenabled=false \--set storageclass=$storageclass \--set serviceaccount.name=zetaris-sa
```

Airflow Deployment

```
helm upgrade --install airflow-ing \helm-zetaris-airflow-ing/airflow-ing \--namespace airflow \--set environment=$environment \--set storageclass=$storageclass \--set deploymentname=$deploymentname \--set dnsdomain=$dnsdomain
```

Final deployment should contain running pods as shown below;

```
NAME                                                  READY   STATUS             RESTARTS       AGEdigiavatar-5f69b44d68-w2tfs                           1/1     Running            0              12hlightning-api-988b7cbb6-nhwnk                         1/1     Running            0              12hlightning-gui-7f9b6bbb4d-h52bn                        1/1     Running            0              179mlightning-server-5439ec967ddf56d2-exec-1              0/1     Pending            0              174mlightning-server-5439ec967ddf56d2-exec-2              0/1     Pending            0              174mlightning-server-5439ec967ddf56d2-exec-3              0/1     Pending            0              174mlightning-server-driver                               1/1     Running            0              13hlightning-solr-555664b544-fpwlc                       1/1     Running            0              12hlightning-zeppelin-7975969f5f-fl6mj                   1/1     Running            0              12hollama-6977d564d8-l495p                               1/1     Running            0              68mopensearch-cluster-master-0                           1/1     Running            0              179mopensearch-cluster-master-1                           1/1     Running            0              179mos-opensearch-dashboards-57f49f85fc-zpfsn             1/1     Running            0              12hprivateai-566df5d786-68f49                            1/1     Running            0              162m
```

#### 8\. Create Lightning user account

· Login to ‘lightning-server-driver’ pod

```
kubectl exec --tty --stdin lightning-server-driver -n zetaris /bin/sh
```

· Run the dev-account.sh script

```
cd /home/zetaris/lightning/bin/./dev-account.sh
```

#### 9\. Launch Zetaris

Please Open browser window (preferably chrome) from any computer that is connected to VM and can access the machine on which Zetaris is installed. 

Use URL from route created earlier (e.g. **http://zetaris-zetaris.apps.zetaris.iac.ssc)** to launch Zetaris from browser window.
