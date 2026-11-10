---
source: kbase
url: https://kbase.zetaris.com/knowledge/installing-on-aws-eks-using-cloudformation
title: "Installing on AWS EKS using cloudformation"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: de672a945ac530c7afd1ec8012ee47c682e7ff8b0d93f665f733214594e7cc13
---
# Installing on AWS EKS using cloudformation

Please follow the below prerequisites and deployment instructions to deploy Zetaris on EKS environment. 

**Prerequisites:** 

You can ensure the CLI environment to run the helm and kubectl command. Either it can be on AWS Cloud Shell OR Local CLI (Shell, CMD or PowerShell) 

-   **Helm** 

[https://helm.sh/docs/intro/install/](https://helm.sh/docs/intro/install/)  

-   **Kubectl CLI** 

[https://kubernetes.io/docs/tasks/tools/#kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)  

-   **AWS CLI** 

[https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions)  

-   **Configure AWS Credentials using “aws configure” OR “aws configure sso”** 

[https://docs.aws.amazon.com/cli/latest/reference/configure/](https://docs.aws.amazon.com/cli/latest/reference/configure/)  

[https://medium.com/@pushkarjoshi0410/how-to-set-up-aws-cli-with-aws-single-sign-on-sso-acf4dd88e056](https://medium.com/@pushkarjoshi0410/how-to-set-up-aws-cli-with-aws-single-sign-on-sso-acf4dd88e056) 

-   **DBeaver Installation OR  "postgres DB cli"**

[https://dbeaver.io/download/](https://dbeaver.io/download/) 

This product requires an internet connection to deploy properly. The following packages are downloaded on deployment.  
This product is going to be hosted on secure a virtual private cloud network.  
If pre-requisites installation are failed, please don't continue to do further installation. You can reach out to Zetaris support team.  
 If you get stuck on the helm installation or missed any steps, please don't continue to do further steps. Please reach out to Zetaris support team.

### Deployment Instructions: 

1). Deploy the below CloudFormation template on your AWS account. Update require parameters such as KeyName, DBUsername, DBPassword..etc 

[https://zetarislogo.s3.ap-southeast-2.amazonaws.com/aws+zetaris.json](https://zetarislogo.s3.ap-southeast-2.amazonaws.com/aws+zetaris.json)

**Creating a new Cloudformation stack**

Sign in to the AWS Management Console and open the AWS CloudFormation console at [https://console.aws.amazon.com/cloudformation.](https://console.aws.amazon.com/cloudformation.)

Choose Create Stack.

In the Specify template section, select Amazon S3 Template URL and then choose Next:

[https://zetarislogo.s3.ap-southeast-2.amazonaws.com/aws+zetaris.json](https://zetarislogo.s3.ap-southeast-2.amazonaws.com/aws+zetaris.json)  

In the Specify stack details section, enter a name in the Stack name field. For this example, use ZetarisStack. The stack name can't contain spaces.

In the Parameters section, you ensure to fill all the values for all parameters including DBUsername, DBPassword, and KeyName. In the KeyName field, enter the name of a valid Amazon EC2 pair in the same region you are creating the stack.

Choose Next.

In this scenario, we won't add any tags. Choose Next. Tags, which are key-value pairs, can help you identify your stacks. 

Review the information for the stack. When you're satisfied with the settings, choose Submit.

2). Follow the instructions to add an OIDC provider for your cluster. 

[https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html](https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html) 

3). Request for a public certificate for fully qualified domains from Zetaris and email us for approval. 

(i.e) 

uitest.**enterprise.zetaris.com** 

apitest.**enterprise.zetaris.com** 

Note the domain names and the cert ARN once its issued. 

(i.e) 

![](https://kbase.zetaris.com/hs-fs/hubfs/Screen%20Shot%202024-01-22%20at%203-54-22%20pm-png.png)

4). Connect your EKS cluster and ensure the nodes are in ready state. 

```
aws eks --region <region-code> update-kubeconfig --name <cluster_name>
```

[https://medium.com/@kevken1000/eks-connecting-to-the-cluster-3c20e0e39a0f](https://medium.com/@kevken1000/eks-connecting-to-the-cluster-3c20e0e39a0f)  

5). Run the below helm repos 

```
helm repo add spark-operator https://kubeflow.github.io/spark-operator
```

```
helm repo add jetstack https://charts.jetstack.io
```

```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
```

```
helm repo update
```

```
helm install spark-operator spark-operator/spark-operator --namespace spark-operator --create-namespace --set webhook.enable=true --version 1.1.20
```

```
kubectl create namespace cert-manager
```

```
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
```

```
helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.7.0 --set installCRDs=true
```

6). Create service account for AWS Load balancer controller. 

**Replace the AWS ID with your AWS ID** 

```
cat >aws-load-balancer-controller-service-account.yaml <<EOFapiVersion: v1kind: ServiceAccountmetadata:  labels:    app.kubernetes.io/component: controller    app.kubernetes.io/name: aws-load-balancer-controller  name: aws-load-balancer-controller  namespace: kube-system  annotations:    eks.amazonaws.com/role-arn: arn:aws:iam::281917764651:role/aws-load-balancer-controllerEOF
```

```
kubectl apply -f aws-load-balancer-controller-service-account.yaml
```

```
helm repo add eks https://aws.github.io/eks-charts
```

```
helm repo update eks
```

```
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \  -n kube-system \  --set clusterName=Zetaris \  --set serviceAccount.create=false \  --set serviceAccount.name=aws-load-balancer-controller
```

```
kubectl get deployment -n kube-system aws-load-balancer-controller
```

7). Get the Zetaris helm from AWS repository. 

```
export HELM_EXPERIMENTAL_OCI=1
```

```
kubectl create namespace zetaris
```

```
aws ecr get-login-password \    --region us-east-1 | helm registry login \    --username AWS \    --password-stdin 709825985650.dkr.ecr.us-east-1.amazonaws.com
```

```
mkdir awsmp-chart && cd awsmp-chart
```

```
helm pull oci://709825985650.dkr.ecr.us-east-1.amazonaws.com/zetaris-data-networked-platform/zetarislakehouse --version 2.4.0 
```

```
tar xf $(pwd)/* && find $(pwd) -maxdepth 1 -type f -delete
```

```
 cd zetarislakehouse/
```

7). Go to Cloudformation output and get the below details, 

Update the below variable’s values and run it on shell. 

```
efsid="EFS Value"cache="CacheAccessPoint"streaming="StreamingAccessPoint"data="DataAccessPoint"dbdns=" ZetarisDBEndpoint"dbusername="username"   ## which you defined in the parameter sectiondbpassword=<REDACTED> ## which you defined in the parameter sectiontlscert="Certificate ARN"   ## which you copied from Step 3.uidnsname="substring of the ui domain"   ##which you defined in the parameter section. Just provide the name alone, don’t include “.enterprise.zetaris.com”. (i.e) “uitest” for “uitest.enterprise.zetaris.com.”apidnsname="substring of the api domain"   ## which you defined in the parameter section. Just provide the name alone, don’t include “.enterprise.zetaris.com”. (i.e) “apitest” for “apitest.enterprise.zetaris.com.”metastorejdbc="jdbc:postgresql://$dbdns:5432/metastore?sslmode=require"auditlogjdbc="jdbc:postgresql://$dbdns:5432/auditlog?sslmode=require"apimetastorejdbc="jdbc:postgresql://$dbdns:5432/metastore?sslmode=require&user=$dbusername&password=<REDACTED>
```

8). Connect postgres DB instance using DBeaver tool OR **postgres CLI** then run the below query to create databases

```
CREATE DATABASE metastore;CREATE DATABASE auditlog;
```

9). Zetaris driver deployment 

```
helm upgrade --install lightning-server lightning-server/ --set persistentvolume.id=$efsid --set accesspoint.cache=$cache \--set accesspoint.data=$data \--set accesspoint.streaming=$streaming \--set postgres.METASTORE_JDBC_URL=$metastorejdbc \--set postgres.AUDIT_LOG_JDBC_URL=$auditlogjdbc \ --set postgres.DB_USERNAME=$dbusername \--set postgres.DB_PASSWORD=<REDACTED> \--set ingress.tls_cert_arn=$tlscert \--namespace zetaris --version 0.1.0
```

```
kubectl get pods -n zetariskubectl get svc -n zetaris
```

10) Zetaris API deployment 

```
helm upgrade --install lightning-api lightning-api/ \--set db.METASTORE_DATABASE_URL=$apimetastorejdbc \--set db.AUDIT_LOG_DATABASE_URL=$apiauditlogjdbc \--set ingress.tls_cert_arn=$tlscert \--set allowed_origins=$corsurls \--namespace zetaris \--version 0.1.0
```

```
kubectl get pods -n zetariskubectl get ingress -n zetaris
```

11) Zetaris UI deployment 

```
helm upgrade --install lightning-gui lightning-gui/ \--set ndp.zeppelin_enabled=false \--set efs.id=$efsid \--set ingress.tls_cert_arn=$tlscert \--set api_service.api_external_url=$apiurl \--namespace zetaris \--version 0.1.0
```

```
kubectl get pods -n zetariskubectl get ingress -n zetaris
```

12). Create your admin account. 

```
kubectl exec --stdin --tty lightning-server-driver -n zetaris -- /bin/bash
```

```
cd /home/zetaris/lightning/bin/
```

```
./dev-account.sh <REDACTED> P@@sword Zetaris
```

```
exit
```

13). Ensure all the pods are running.

```
kubectl get pods -n zetaris
```

14)Get the load balancer URL for both UI and API ingress and share it with Zetaris support to create DNS for your application. 

```
kubectl get ingress -n zetaris
```
