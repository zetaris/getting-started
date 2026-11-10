---
source: kbase
url: https://kbase.zetaris.com/knowledge/aws-inbound-rules
title: "Create AWS Inbound Rules"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 98fc48f1a168ea9ac28806004058f82a100af6509d192d5708ac35e0473d7582
---
# Create AWS Inbound Rules

## This article covers the configuration of AWS inbound rules for Zetaris external ports.

### Introduction

In AWS, a _security group_ acts as a virtual firewall for your instance to control inbound and outbound traffic. When you create a security group in AWS, it has no inbound rules. No inbound traffic originating from another host to your instance is allowed until you add inbound rules to the security group.

For Zetaris running on AWS, you will need to add inbound rules that allow access to the following ports:

-   Web Application GUI port - default 9001
    
-   JDBC Driver port - default 10000
    

Configure AWS

1.  Open the Amazon EC2 console at [https://console.aws.amazon.com/ec2/](https://console.aws.amazon.com/ec2/)
    
2.  In the navigation pane, choose **Security Groups**.  
    ![Screen Shot 2021-09-15 at 8.47.47 am](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/Screen%20Shot%202021-09-15%20at%208.47.47%20am.png)
    
3.  Select the network security group associated with your Zetaris instance.
    
4.  Choose **Edit inbound rules  
    ![Screen Shot 2021-09-15 at 9.00.30 am](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/Screen%20Shot%202021-09-15%20at%209.00.30%20am.png)  
    **
5.  Choose **Add Rule**, and specify the following values for the GUI port:  
    **Type**: Custom TCP  
    **Port range:** 9001  
    **Source:** Any  
    **Identifier:** CIDR blocks value of **0.0.0.0/0  
    ![Screen Shot 2021-09-15 at 10.43.05 am](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/Screen%20Shot%202021-09-15%20at%2010.43.05%20am.png)**
6.  Choose **Add Rule**, and specify the following values for the JDBC port:  
    **Type**: Custom TCP  
    **Port range:** 10000  
    **Source:** Any  
    **Identifier:** CIDR blocks value of **0.0.0.0/0  
    ![Screen Shot 2021-09-15 at 10.43.05 am](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/Screen%20Shot%202021-09-15%20at%2010.43.05%20am.png)**
7.  You should now see both your inbound rules  
    ![Screen Shot 2021-09-15 at 10.48.40 am](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/Screen%20Shot%202021-09-15%20at%2010.48.40%20am.png)  
    
    Click **Save** **rules**.
