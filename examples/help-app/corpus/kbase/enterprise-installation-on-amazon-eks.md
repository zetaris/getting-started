---
source: kbase
url: https://kbase.zetaris.com/knowledge/enterprise-installation-on-amazon-eks
title: "Clustered enterprise (with shared meta-store) installation on Amazon EKS"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: d4236f424b99a247d66d00c6062d1a255cf6a5d079c85701f392a84afc531d5f
---
# Clustered enterprise (with shared meta-store) installation on Amazon EKS

There are several steps to deploy on AWS EKS from our existing Azure AKS progress.

#### **Prerequisite**

-   Terminal
    
-   Install AWS cli version 2+
    
-   Helm3
    
-   kubectl
    
-   postgres 11 database (in case no PostgreSQL database is available then fresh installation steps are mention in last of the document)
    
-   Soft link to yaml files (need to have this on terminal) - [Download](https://zetaris-download.s3.ap-southeast-2.amazonaws.com/nbn_installation/eks_installation.zip)
    
    The above link is security protected. Contact your Zetaris representative for access.
    

#### Step 1 - Create a new VPC

1.  This step is to spin up a new virtual private cloud to run our EKS cluster.
2.  We can use default VPC then skip this step.  
      
    

![](https://kbase.zetaris.com/hubfs/image-png-Mar-28-2023-03-25-53-4091-AM.png)

#### Step 2 - Create MasterClusterRole and WorkerNodeRole

This step is using AWS console (UI)

1.  Search IAM service, click Roles on left-side dashboard
    
2.  Click on create roles. Choose “Custom trust policy” then click next
    
    1.  When creating MasterClusterRole, search for below and add it. then click on next and then further click on create role
        
        1.  AmazonEKSClusterPolicy
            
        2.  AmazonS3FullAccess
            
            ![2](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/2.png)
            
    2.  When creating WorkNodeRole, Search for below and add it. then click on next and then further click on create role
        
        1.  AmazonEKSWorkerNodePolicy
            
        2.  AmazonEC2ContainerRegistryReadOnly
            
        3.  AmazonElasticFileSystemFullAccess
            
        4.  AmazonEKS\_CNI\_Policy
            
        5.  AmazonS3FullAccess
            
            ![](blob:https://zetaris.atlassian.net/0a7f36eb-f6ce-425c-bcee-d7034db0cd40#media-blob-url=true&id=a50546ee-df10-42e1-94b5-90fe80a30d6d&collection=contentId-2617475073&contextId=2617475073&mimeType=image%2Fpng&name=Screen%20Shot%202022-04-12%20at%201.49.41%20pm.png&size=168435&height=311&width=933&alt=)![3](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/3.png)
            
    3.  The above 2 roles are used when creating EKS cluster (you can create Roles or use existing ones)
        

#### Step 3 - Create a EKS cluster

This step is using AWS console (UI)

1.  Search of EKS in search bar.
    
2.  Click Add Cluster
    
    1.  Cluster name, e.g. test-cluster, will be replaced by <cluster\_name>
        
    2.  Cluster Service Role choose _MasterClusterRole_
        
3.  Once cluster is up, under tab Configuration => Compute, click Add Node Group
    
    1.  Node IAM Role choose _WorkerNodeRole_
        
4.  Export cluster kubeconfig in AWS CLI
    
    1.  Variables will need to export are:
        
        1.  <account\_id> for example 2819177XXXXX
            
        2.  <cluster\_name> is <name of the cluster that got created>
            
        3.  <config\_name> is <any name for conifg>
            
        4.  <region> is < the region in which your cluster is>
            
    2.  Once you have all the above details go to AWS CLI and Run
        
        ```
        aws eks --region ap-southeast-2 update-kubeconfig --name <cluster_name>
        ```
        
        Expected Output:
        
        ```
        Added new context arn:aws:eks:ap-southeast-2:<account_id>:cluster/<cluster_name> to ~/.kube/config
        ```
        
    3.  If you want to specify a config file other than default, add --kubeconfig <config\_name>
        
        1.  ```
            aws eks --region ap-southeast-2 update-kubeconfig --name <cluster_name> --kubeconfig <config_name>
            ```
            

#### Step 4 - Install Solr VM

1.  Create Solr
    
    1.  EC2 Launch instance, search for _**bitnami solr 8.6.0**_
        
        ![5](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/5.png)
        
    2.  Add cores
        1.  Login into Solr VM
        2.  Download & copy cores folder
            
            ```
            wget https://zetaris-download.s3.ap-southeast-2.amazonaws.com/solr/cores.tarORFrom your localscp cores.tar <VM-username>@<VM-public-ip>:/home/<VM-username>/tar xf cores.tarcp cores/ <path_to>/solr-8.6.0/server/solr/
            ```
            
        3.  Start (or restart) solr
            
            ```
            cd <path_to>/solr-8.6.0/bin./solr start
            ```
            
    3.  Use private ip address of Solr VM, and change it in server config, _**meta\_store.properties**_
        
        ```
        # solr server instance solr_server=<private-ip-address>:8983/solr/
        ```
        
    4.  Open 8983 port of this solr VM by adding inbound rules in security group
        
        ![6](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/6.png)
        
        ![7](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/7.png)
        
        ![8](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/8.png)
        

#### **Step 5 - Set up EFS**

This step is to add persistent volumes for NDP server and gui.

Reference [Amazon EFS CSI driver - Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html)

1.  Variables which are used in the step and might change as per the environment
    
    1.  <EFS\_driver\_policy> is AmazonEKS\_EFS\_CSI\_Driver\_Policy--> any name can be given in 2-b
        
    2.  <EFS\_driver\_role> is AmazonEKS\_EFS\_CSI\_DriverRole--> any name can be given in 3-c-ii
        
    3.  <cluster name> --> your eks cluster name
        
    4.  <ID> --> OCID generated
        
    5.  <region> --> region of the EKS cluster
        
2.  Create an IAM policy
    
    1.  Download the IAM policy document from GitHub 
        
        ```
        curl -o iam-policy-example.json https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/v1.3.2/docs/iam-policy-example.json
        ```
        
    2.  Create the policy
        
        ```
        aws iam create-policy \ --policy-name <EFS_driver_policy> \ --policy-document file://iam-policy-example.json
        ```
        
3.  Create an IAM role and attach the IAM policy to it
    
    1.  Determine your cluster's OIDC provider URL.
        
        ```
        aws eks describe-cluster --name <cluster-name> --query "cluster.identity.oidc.issuer" --output text
        ```
        
        Output
        
        1.  ```
            https://oidc.eks.ap-southeast-2.amazonaws.com/id/EXAMPLEXXX45D83924220DC4815XXXXX
            ```
            
    2.  Create IAM role
        
        1.  Create a file called “trust-policy.json” using below code. Update account\_id, OCID and region as per the project. 
            
            ```
            { "Version": "2012-10-17",  "Statement": [   {   "Effect": "Allow",   "Principal": {    "Federated": "arn:aws:iam::<account_id>:oidc-provider/oidc.eks.ap-southeast-2.amazonaws.com/id/<EXAMPLEXXX45D83924220DC4815XXXXX>"   },    "Action": "sts:AssumeRoleWithWebIdentity",    "Condition": {     "StringEquals": {     "oidc.eks.ap-southeast-2.amazonaws.com/id/<EXAMPLEXXX45D83924220DC4815XXXXX>:sub": "system:serviceaccount:kube-system:efs-csi-controller-sa"    }   }  } ]}
            ```
            
        2.  Create the role
            
            ```
            aws iam create-role \ --role-name <EFS_driver_role> \ --assume-role-policy-document file://"trust-policy.json"
            ```
            
    3.  Attach the IAM policy to the role.
        
        ```
        aws iam attach-role-policy \  --policy-arn arn:aws:iam::<account_id>:policy/<EFS_driver_policy> \ --role-name <EFS_driver_role>
        ```
        
    4.  Create a Kubernetes service account that is annotated with the ARN of the IAM role that you created.
        
        1.  Create a file named efs-service-account.yaml. Update <account\_id>,<EFS\_driver\_role>
            
            ```
            ---apiVersion: v1kind: ServiceAccountmetadata:  name: efs-csi-controller-sa  namespace: kube-system  labels:   app.kubernetes.io/name: aws-efs-csi-driver  annotations:  eks.amazonaws.com/role-arn: arn:aws:iam::<account_id>:role/<EFS_driver_role>
            ```
            
            Then
            
            ```
            kubectl --kubeconfig /path_to_config/<config_name> apply -f efs-service-account.yaml
            ```
            
4.  Install the Amazon EFS driver
    
    1.  Add the helm repo & update helm
        
        ```
        helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/helm repo update
        ```
        
    2.  Install the chart.
        
        ```
        helm --kubeconfig /path_to_config/<config_name> upgrade -i aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \  --namespace kube-system \  --set image.repository=602401143452.dkr.ecr.ap-southeast-2.amazonaws.com/eks/aws-efs-csi-driver  --set controller.serviceAccount.create=false  --set controller.serviceAccount.name=efs-csi-controller-sa
        ```
        
5.  Create an Amazon EFS file system.
    
    1.  Get vpc\_id and
        
        ```
        vpc_id=$(aws eks describe-cluster \ --name <cluster-name> \ --query "cluster.resourcesVpcConfig.vpcId" \ --output text)
        ```
        
    2.  Retrieve the CIDR range for your cluster's VPC and store it in a variable for use in a later step.
        
        ```
        cidr_range=$(aws ec2 describe-vpcs \ --vpc-ids $vpc_id \ --query "Vpcs[].CidrBlock" \ --output text)
        ```
        
    3.  Create a security group with an inbound rule that allows inbound NFS traffic for your Amazon EFS mount points.
        
        1.  Create a security group. give any group-name for example MyEfsSecurityGroup
            
            ```
            security_group_id=$(aws ec2 create-security-group \ --group-name MyEfsSecurityGroup \ --description "My EFS security group" \ --vpc-id $vpc_id \ --output text)
            ```
            
        2.  Create an inbound rule that allows inbound NFS traffic from the CIDR for your cluster's VPC.
            
            ```
            aws ec2 authorize-security-group-ingress \ --group-id $security_group_id \ 3 --protocol tcp \ --port 2049 \ --cidr $cidr_range
            ```
            
    4.  Create an Amazon EFS file system for your Amazon EKS cluster.
        
        1.  Create a file system. Update you region 
            
            ```
            file_system_id=$(aws efs create-file-system \ --region us-west-2 \ --performance-mode generalPurpose \ --query 'FileSystemId' \ --output text)
            ```
            
        2.  Remember the file\_system\_id, it is later to be used.
            
            ```
            echo $file_system_id
            ```
            
            Output should be fs-abcdefgh
            
        3.  Create mount targets.
            
            1.  Determine the IP address of your cluster nodes.
                
                ```
                kubectl --kubeconfig /path_to_config/<config_name> get nodes
                ```
                
            2.  Determine the IDs of the subnets in your VPC and which Availability Zone the subnet is in.
                
                ```
                aws ec2 describe-subnets \ --filters "Name=vpc-id,Values=$vpc_id" \ --query 'Subnets[*].{SubnetId: SubnetId,AvailabilityZone: AvailabilityZone,CidrBlock: CidrBlock}' \ --output table
                ```
                
        4.  Add mount targets for the subnets that your nodes are in. In below change subnet- example to subnet-id you got for the previous step. if you you got 10 subnet id run below command 10 times but putting each of the subnet-ID
            
            ```
            aws efs create-mount-target \ --file-system-id $file_system_id \ --subnet-id subnet-EXAMPLEe2ba886490 \ --security-groups $security_group_id
            ```
            
6.  Deploy Persistent Volume Claim (Files should be attached)
    
    1.  For our gui and server deployment, we need in total 4 persistent volume claims, namely gui, server, data (customer data) and streaming.
        
    2.  Firstly, deploy the storage class.
        
        ```
        kubectl --kubeconfig /path_to_config/<config_name> apply -f storageclass.yaml
        ```
        
    3.  Secondly, deploy the persistent volumes to be attached. **Remember to edit/change all the files with the correct** _**file\_system\_id**_ which you got in above step.
        
        ```
        kubectl --kubeconfig /path_to_config/<config_name> apply -f pv-data.yamlkubectl --kubeconfig /path_to_config/<config_name> apply -f pv-gui.yamlkubectl --kubeconfig /path_to_config/<config_name> apply -f pv-server.yamlkubectl --kubeconfig /path_to_config/<config_name> apply -f pv-streaming.yamlkubectl --kubeconfig /path_to_config/<config_name> apply -f pv-cache.yamlORcd ../kubectl --kubeconfig /path_to_config/<config_name> apply -f pvs
        ```
        
    4.  Finally, deploy the persistent volume claims.
        
        ```
        kubectl --kubeconfig /path_to_config/<config_name> apply -f claim-data.yamlkubectl --kubeconfig /path_to_config/<config_name> apply -f claim-gui.yamlkubectl --kubeconfig /path_to_config/<config_name> apply -f claim-server.yamlkubectl --kubeconfig /path_to_config/<config_name> apply -f claim-streaming.yamlkubectl --kubeconfig /path_to_config/<config_name> apply -f claim-cache.yamlORcd ../kubectl --kubeconfig /path_to_config/<config_name> apply -f claims
        ```
        
    5.  Display persistent volumes and claims by 
        
        ```
        kubectl --kubeconfig /path_to_config/<config_name> get pvkubectl --kubeconfig /path_to_config/<config_name> get pvc
        ```
        
7.  Manually create an EC2 instance,
    
    1.  This step is for EFS system mounted.
        
    2.  Create an ubuntu VM
        
    3.  Go inside into the VM 
        
        ```
        chmod 600 xxx.pemssh -i xxx.pem ubuntu@<public_ip_address>
        ```
        
    4.  Create a folder _config_ for back-up
        
    5.  Create a folder _mount_ for file system mounted
        
    6.  Create folders inside _config_ folder, note that _data_, _streaming_ & _cache_ just keep them empty
        
        ```
        - gui- server- data- streaming- cache
        ```
        
    7.  Manually create files for gui config. You will get all the files in the attachment
        
        Inside gui/conf folder.copy below files
        
        \- application.conf
        
        \- logback.xml
        
        \- messages.en-AU
        
        Inside gui/fluentd folder. copy below files
        
        \- fluentlghtui.conf
        
        Inside /fluentd/conf.d folder. copy below files
        
        \- status.conf
        
        \- sessions.conf
        
    8.  Manually create or copy files for server config
        
        Inside /server/ copy below files
        
        \- lightning-conf.xml
        
        \- meta\_store.properties
        
        \- hive-site.xml
        
        \- core-site.xml
        
        \- config-client.xml
        
        \- metrics.properties
        
        \- log4j.properties
        
        \- aws-bundle.jar
        
    9.  Edit meta\_store.properties and search for
        
        1.  this is the place where you will have to give database hostnamen,username and passowrd
            
        2.   ![9](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/9.png)
            
        3.  solr IP/hostname
            
        4.   ![31](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/31.png)
            
    10.  Go to home dir/mount folder and mount file system.
        
        1.  To get <EFS\_ip\_address>
            
            1.  go to azure portal search for efs
                
            2.  find your file\_system\_id(this created in previous steps) and click on it.
                
                ![](blob:https://zetaris.atlassian.net/9e2138f7-7080-4e37-a6d4-0d4b11cc1a96#media-blob-url=true&id=cc89e0c1-c237-452b-bf14-bdb9ccdba2a2&collection=contentId-2617475073&contextId=2617475073&mimeType=image%2Fpng&name=image-20220411-040557.png&size=82624&height=344&width=952&alt=)![10](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/10.png)
                
            3.  click on on network tab. You will see all the <EFS\_public\_ip>
                
                ![11](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/11.png)
                
            4.  copy all the <EFS\_public\_ip> one by one in below command and run it. for example if you have 3 IP then you will have to run the below command 3 times.
                
                ```
                cd ~sudo apt updatesudo apt-get install nfs-commonsudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport <EFS_ip_address>:/ ~/mount
                ```
                
    11.  copy content in _config_ folder to _mount_ founder
        
        ```
        sudo cp -r config/* mount/
        ```
        

#### Step 5 - Install Zetaris

1.  Install Spark Operator
    
    1.  Add repo spark-operator.
        
        ```
        helm repo add spark-operator https://googlecloudplatform.github.io/spark-on-k8s-operator
        ```
        
    2.  Install helm chart.
        
        ```
        helm --kubeconfig /path_to_config/<config_name> install spark-operator \  spark-operator/spark-operator \  --namespace spark-operator --create-namespace \  --set webhook.enable=true \  --set replicaCount=3 \  --set leaderElection.lockNamespace=spark-operator \  --version 1.1.6
        ```
        
2.  Create service account - spark AND do the role binding to give proper permissions
    
    1.  spark service account should access s3, create a role using AWS console => IAM
        
    2.  Click Roles => Create Role => Choose Custom Trust Policy
        
    3.  Change policy content
        
        ```
        {    "Version": "2012-10-17",    "Statement": [        {            "Effect": "Allow",            "Principal": {                "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/oidc.eks.<region-code>.amazonaws.com/id/<EXAMPLED539D4633E53DE1B716D3041E>"            },            "Action": "sts:AssumeRoleWithWebIdentity"        }    ]}
        ```
        
    4.   <region-code> is _ap-sooutheast-2_ in our case  
        <EXAMPLED539D4633E53DE1B716D3041E> is _19637F061B8C25E63FF4DCXXXXXX_
    5.  Attach Policy => Search AmazonS3FullAccess
    6.  Provide a name - e.g. EksS3FullAccessRole
        
    7.  Click Create
    8.  Create service aaccount - spark  
        
        Option 1 - use kubectl command
        
        ```
        kubectl --kubeconfig /path_to_config/<config_name> create serviceaccount sparkkubectl --kubeconfig /path_to_config/<config_name> create clusterrolebinding spark-role \  --clusterrole=edit --serviceaccount=default:spark --namespace=defaultkubectl --kubeconfig /path_to_config/<config_name> annotate sa spark \  eks.amazonaws.com/role-arn=arn:aws:iam::<ACCOUNT_ID>:role/<S3_access_role>
        ```
        
        Remember to replace  
        <ACCOUNT\_ID> is 2819177XXXXX  
        <S3\_access\_role> is EksS3FullAccessRole in this example
        
        Option 2 - use yaml
        
        ```
        ---apiVersion: v1kind: ServiceAccountmetadata:  name: spark  namespace: default  annotations:    eks.amazonaws.com/role-arn: arn:aws:iam::<ACCOUNT_ID>:role/<S3_access_role>---apiVersion: rbac.authorization.k8s.io/v1kind: ClusterRoleBindingmetadata:  name: spark-roleroleRef:  apiGroup: rbac.authorization.k8s.io  kind: ClusterRole  name: editsubjects:  - kind: ServiceAccount    name: spark    namespace: default
        ```
        
3.  Deploy secrets.
    
    ```
    $ kubectl --kubeconfig /path_to_config/<config_name> apply -f secrets.ymlsecret/workspace-secrets created
    ```
    
    1.  workspace-secrets is used in both gui and server
        
    2.  run command to create docker secret to pull image from DockerHub
        
        ```
        kubectl --kubeconfig /path_to_config/<config_name> \  create secret docker-registry regcred \  --docker-server=https://index.docker.io/v1/ \  --docker-username=<your_username> \  --docker-password=<REDACTED> created
        ```
        
4.  Add code related to persistent volumes into server yaml files.
    
    1.  Reference [Running Spark on Kubernetes - Spark 3.2.1 Documentation](https://spark.apache.org/docs/latest/running-on-kubernetes.html#using-kubernetes-volumes)
        
    2.  Apply this only to server yaml file
        
5.  Deploy server and gui deployment yaml files
    
    ```
    kubectl --kubeconfig /path_to_config/<config_name> apply -f lightning-gui-deployment.yamlkubectl --kubeconfig /path_to_config/<config_name> apply -f lightning-server-deployment.yaml
    ```
    
6.  Install AWS Load Balancer controller
    
    1.  Reference this document to create load balancer [Installing the AWS Load Balancer Controller add-on - Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html)
        
7.  Add tags to related subnets inside VPC
    
    **Key** – kubernetes.io/role/elb **Value** – 1
    
    1.  1.  Click on your VPC
            
        2.   ![](https://kbase.zetaris.com/hubfs/image-png-Mar-28-2023-03-27-36-2557-AM.png)
            
        3.  inside you VCP . Click on subnet
            
            ![32](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/32.png)
            
        4.  Click on all subnet\_id one by . and click on tag tab at the bottom.
            
        5.  add tag **Key** – kubernetes.io/role/elb **Value** – 1
            
        6.  do this for all the subnet\_id which are used above.
            
        7.    ![17](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/17.png)
            
    2.  **Key** – kubernetes.io/cluster/<cluster\_name> **Value** – shared
        
        1.  Click on your VPC
            
        2.   ![](https://kbase.zetaris.com/hubfs/image-png-Mar-28-2023-03-28-59-9643-AM.png)
            
        3.  inside you VCP . Click on subnet
            
            ![32](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/32.png)
            
        4.  Click on all subnet\_id one by . and click on tag tab at the bottom.
            
        5.  add tag kubernetes.io/cluster/<cluster\_name> **Value** – shared
            
        6.  do this for all the subnet\_id which are used above.
            
            ![14](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/14.png)  
            
8.  Deploy server and gui service yaml files 
    
    ```
    kubectl --kubeconfig /path_to_config/<config_name> apply -f lightning-gui-service.yamlkubectl --kubeconfig /path_to_config/<config_name> apply -f lightning-server-service.yaml
    ```
    

#### Step 6 - Install AutoScaler inside Kubernetes

1.  Add tags to our node group of cluster
    
    In this example \*\*\*_**\-test-3**_ cluster, we should click **Configuration** > **Compute**, then click the node group name \*\*\*_**\-test-node-group**_
    
    ![](https://kbase.zetaris.com/hubfs/image-png-Mar-28-2023-03-31-03-7659-AM.png)
    
      
    
    Click Edit button on the top-right of screen
    
    ![](https://kbase.zetaris.com/hubfs/image-png-Mar-28-2023-03-30-20-4517-AM.png)
    
    Add tags
    
    1.  **Key** – k8s.io/cluster-autoscaler/<my-cluster> **Value** – owned
        
    2.  **Key** – k8s.io/cluster-autoscaler/enabled **Value** – TRUE  
          
        Output
        
        ![20](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/20.png)
        
2.  Create cluster autoscaler policy
    
    1.  Note that policy should be created once, if you have done this step for another cluster before, you can skip this step.
        
    2.  policy file (you can also find it in summary zip) - with name _**cluster-autoscaler-policy.json**_
        
        ```
        { "Version": "2012-10-17", "Statement":   {   "Action": [    "autoscaling:DescribeAutoScalingGroups",    "autoscaling:DescribeAutoScalingInstances",    "autoscaling:DescribeLaunchConfigurations",    "autoscaling:DescribeTags",    "autoscaling:SetDesiredCapacity",    "autoscaling:TerminateInstanceInAutoScalingGroup",    "ec2:DescribeLaunchTemplateVersions"   ],   "Resource": "*",   "Effect": "Allow"  } ]}
        ```
        
    3.  Create this policy - terminal should navigate to the enclosing folder, otherwise you have to provide full path
        
        ```
        aws iam create-policy \ --policy-name AmazonEKSClusterAutoscalerPolicy \ --policy-document file://cluster-autoscaler-policy.json
        ```
        
        If policy cannot be created, a policy named _**AmazonEKSClusterAutoscalerPolicy**_ might already exist in your AWS, double check it from AWS console => IAM => Policies.
        
3.  Create a Role based on autoscaler policy
    
    1.  Open the IAM console at [https://console.aws.amazon.com/iam/](https://console.aws.amazon.com/iam/).
        
    2.  In the left navigation pane, choose **Roles**. Then choose **Create role**.
        
    3.  In the **Trusted entity type** section, choose **Web identity**.
        
    4.  In the **Web identity** section:
        
        1.  For **Identity provider**, choose the URL for your Amazon EKS cluster.  
            If you do not know the url, go back to eks cluster and see **Details** > API server endpoint
            
            ![](https://kbase.zetaris.com/hubfs/image-png-Mar-28-2023-03-33-04-8643-AM.png)
        2.  For **Audience**, choose sts.amazonaws.com.
            
    5.  Choose **Next**.
        
    6.  In the **Filter policies** box, enter AmazonEKSClusterAutoscalerPolicy. Then select the check box to the left of the policy name returned in the search.
        
    7.  Choose **Next**.
        
    8.  For **Role name**, enter a unique name for your role, such as AmazonEKSClusterAutoscalerRole.
        
    9.  For **Description**, enter descriptive text such as Amazon EKS - Cluster autoscaler role.
        
    10.  Choose **Create role**.
        
    11.  After the role is created, choose the role in the console to open it for editing.
        
    12.  Choose the **Trust relationships** tab, and then choose **Edit trust policy**.
        
    13.  Find the _line_ that has _sts_ content  
        "sts.amazonaws.com"  
        to the following
        
        ```
        "oidc.eks.<region-code>.amazonaws.com/id/<EXAMPLED539D4633E53DE1B716D3041E>:sub": "system:serviceaccount:kube-system:cluster-autoscaler"
        ```
        
        <region-code> is _ap-sooutheast-2_ in our case  
        <EXAMPLED539D4633E53DE1B716D3041E> is _19637F061B8C25E63FF4DC53A460D27E_
        
    14.  Choose **Update policy** to finish.
        
4.  Deploy Cluster Autoscaler
    
    1.  Download YAML file  
        This step can be skipped because file is included in zip
        
        ```
        curl -o cluster-autoscaler-autodiscover.yaml https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
        ```
        
    2.  Modify YAML file
        
        1.  Change to your cluster name
            
            ![22](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/22.png)
            
        2.  Add more configuration under command (shown as blue indicators) 
            
            ```
            - --balance-similar-node-groups- --skip-nodes-with-system-pods=false- --scale-down-delay-after-add=3m- --scale-down-unneeded-time=3m- --scale-down-non-empty-candidates-count=3- --scale-down-candidates-pool-ratio=0.4
            ```
            
            ![23](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/23.png)
            
        3.  In this default YAML file line 147, it displays the default image to use (v1.21.0). Change it to your cluster version
            
            ![24](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/24.png)
            
        4.  Navigate to [Releases · kubernetes/autoscaler](https://github.com/kubernetes/autoscaler/releases)  
            To see the latest release of v.1.21.x. put the latest number of x
            
            ![26](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/26.png)
            
            Change the image to v.1.21.2
            
            ![27](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/27.png) 
            
    3.  Apply autoscaler yaml file
        
        ```
        kubectl --kubeconfig /path_to_config/<config_name> apply -f cluster-autoscaler-autodiscover.yaml
        ```
        
    4.  Annotate service account to Cluster Role (created at previous step. Update your account\_id before running it. 
        
        ```
        kubectl --kubeconfig /path_to_config/<config_name> \ annotate serviceaccount cluster-autoscaler \ -n kube-system \ eks.amazonaws.com/role-arn=arn:aws:iam::<ACCOUNT_ID>:role/<AmazonEKSClusterAutoscalerRole>
        ```
        
          
        <ACCOUNT\_ID> is 2819177XXXX  
        <AmazonEKSClusterAutoscalerRole> is AmazonEKSClusterAutoscalerRole
        
    5.  Patch the deployment to add the cluster-autoscaler.kubernetes.io/safe-to-evict annotation to the Cluster Autoscaler pods with the following command.
        
        ```
        kubectl --kubeconfig /path_to_config/<config_name> \ patch deployment cluster-autoscaler \ -n kube-system \ -p '{"spec":{"template":{"metadata":{"annotations":{"cluster-autoscaler.kubernetes.io/safe-to-evict": "false"}}}}}'
        ```
        
        Installation is done, check the logs using the following command.
        
        ```
        kubectl --kubeconfig /path_to_config/<config_name> \ -n kube-system logs -f deployment.apps/cluster-autoscaler
        ```
        
        Output
        
        ```
        I0926 23:15:55.165842 1 static_autoscaler.go:138] Starting main loopI0926 23:15:55.166279 1 utils.go:595] No pod using affinity / antiaffinity found in cluster, disabling affinity predicate for this loopI0926 23:15:55.166293 1 static_autoscaler.go:294] Filtering out schedulablesI0926 23:15:55.166330 1 static_autoscaler.go:311] No schedulable podsI0926 23:15:55.166338 1 static_autoscaler.go:319] No unschedulable podsI0926 23:15:55.166345 1 static_autoscaler.go:366] Calculating unneeded nodesI0926 23:15:55.166357 1 utils.go:552] Skipping ip-192-168-3-111.<region-code>.compute.internal - node group min size reachedI0926 23:15:55.166365 1 utils.go:552] Skipping ip-192-168-71-83.<region-code>.compute.internal - node group min size reachedI0926 23:15:55.166373 1 utils.go:552] Skipping ip-192-168-60-191.<region-code>.compute.internal - node group min size reachedI0926 23:15:55.166435 1 static_autoscaler.go:393] Scale down status: unneededOnly=false lastScaleUpTime=2019-09-26 21:42:40.908059094 ...I0926 23:15:55.166458 1 static_autoscaler.go:403] Starting scale downI0926 23:15:55.166488 1 scale_down.go:706] No candidates for scale down
        ```
        

#### **Step 7: Creating an account on Lightning**

-   Open terminal
    
-   Run command:
    
    ```
    kubectl --kubeconfig /path to config/config_name exec -it thunderstorm-driver bash
    ```
    
-   Then run command:
    
    ```
    cd /usr/share/zetaris/lightning/bin
    ```
    
-   Once you are in the bin folder, run command
    -   modify dev.account.sh file

\[_Note: If you do not modify the dev.account.sh file the default credentials below should be used._\]

```
printf "First Name\tSurname\tEmail\tTeam(org name)\tPassword\nDev,Account,<REDACTED>,Account,password" >> $devOrgChange toprintf "First Name\tSurname\tEmail\tTeam(org name)\tPassword\n{YOUR_FIRST_NAME},{YOUR_SURNAME},{YOUR_EMAIL},{YOUR_ORG_NAME},{YOUR_PASSWORD}" >> $devOrgNote that YOUR_EMAIL is the admin level
```

```
./dev-account.sh
```

1.  mod
    
2.  Once the site open login to it with credentials:

-   -   username → YOUR\_EMAIL (by default → <REDACTED>)
        
    -   password → YOUR\_PASSWORD (by default → password)
        

Step 8 - Install multiple instances inside single Kubernetes

1.  1.  Create a new namespace, e.g. for pre-sales team & customer success team
        
        ```
        kubectl --kubeconfig <your_config> create namespace pre-saleskubectl --kubeconfig <your_config> create namespace customer-success
        ```
        
    2.  Go back to Step 4 EFS
        
        1.  Repeat No.5 Create an Amazon EFS file system
            
        2.  Repeat No.6 Deploy Persistent Volume Claim
            
            1.  Skip the step of StorageClass because it is already inside cluster
                
            2.  For each persistent volume, give a specify name, not only the file name, but also the metadata name inside the file 
                
                ```
                pv-data-pre-sales.yaml---apiVersion: v1kind: PersistentVolumemetadata: name: efs-pv-data-pre-salesspec: ...
                ```
                
            3.  For each claim, add _**namespace**_ under metadata(Shown in line5), change _**volumeName**_ as well
                
                ```
                apiVersion: v1kind: PersistentVolumeClaimmetadata: name: efs-claim-data namespace: pre-salesspec: ... volumeName: efs-pv-data-pre-sales
                ```
                
        3.  Repeat No.7 Volume mount
            
            1.  You do not have to spin up another VM
                
            2.  create an empty folder _**/mount-pre-sales(or choose any name for the folder)**_
                
                ```
                cd ~sudo mount -t nfs -o ... <new_EFS_ip_address>:/ ~/mount-pre-salessudo cp -r config/* mount-pre-sales/
                ```
                
    3.  Repeat Step 5 Zetaris Installation
        
        1.  Skip #1 Spark Operator & #6 Load Balancer &#7 add taf
            
        2.  Specify namespace before create Service Account & Secret
            
            ```
            # Service Accountkubectl create serviceaccount spark --namespace=pre-sales# Role bindingkubectl create clusterrolebinding spark-role \ --clusterrole=edit --serviceaccount=pre-sales:spark --namespace=pre-salesapiVersion: v1kind: Secretmetadata: name: acssecret namespace: pre-sales....apiVersion: v1kind: Secretmetadata: name: workspace-secrets namespace: pre-sales....
            ```
            
        3.  Specify namespace for deployment & service as well
            
            ```
            # GUI---apiVersion: apps/v1kind: Deploymentmetadata: name: thunderstorm-gui namespace: pre-sales labels:  app: thunderstorm-gui...---apiVersion: v1kind: Servicemetadata: name: gui-service namespace: pre-sales...
            ```
            
            ```
            # Server---apiVersion: sparkoperator.k8s.io/v1beta2kind: SparkApplicationmetadata: name: thunderstorm namespace: pre-sales...---apiVersion: v1kind: Servicemetadata: name: thunderstorm << OR >> thunderstorm-rest namespace: pre-sales...
            ```
            

**Prerequisite step--> Postgres installation:**

1.  1.  1.  login to amazon
            
        2.  search for RDS. Click on create database button.
            
        3.  choose
            
            1.  Database creation method:standard database
                
            2.  Engine option : postgreSQL
                
            3.  version : 11
                
            4.  template : production
                
            5.  database name : any name
                
            6.  master usenrame : postgres
                
            7.  password : <REDACTED> password
                
            8.  confirm password : <REDACTED> password
                
            9.  public access (by default it is private)
                
        4.  Click Create database button
            
        5.  Create database and tables
            
            1.  once the connection to database is made create 2 databases
                
                ```
                CREATE DATABASE metastore;CREATE DATABASE audit_log;
                ```
                
                ![28](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/28.png)
                
            2.  Now connect to metastore database
                
                1.  Execute the the sql statements(metastore queries attached below)
                    
                2.   ![29](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/29.png)
                    
            3.  Now connect to audit\_log database
                
                1.  Execute the the sql statements(audit\_log queries attached below)
                    
                2.  ![30](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/deploying_zetaris/clustered_enterprise_eks/30.png)
