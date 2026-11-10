---
source: kbase
url: https://kbase.zetaris.com/knowledge/create-azure-inbound-rules
title: "Create Azure Inbound Rules"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: c75ff72df40ba673b84fc144357be2d36ced9ac06dc5067657e5c57ea2b30cb2
---
# Create Azure Inbound Rules

## This article covers the configuration of Azure Inbound Rules to allow access to the required Zetaris ports.

### Introduction

In Azure, a _security group_ acts as a virtual firewall for your instance to control inbound and outbound traffic. For Zetaris running on Azure, you will need to add inbound rules that allow access to the following ports:

-   Web Application GUI port - default 9001
    
-   JDBC Driver port - default 10000
    

### Configure Azure 

1.  Sign in to the Azure portal at [https://portal.azure.com](https://portal.azure.com/).
    
2.  Select your new network security group.
    
3.  Select **Inbound security rules** from the left menu, then select **Add**.
    
4.  Specify the following values for the GUI port:  
    **Source port ranges:** leave the default of _Any  
    _**Service:** select _Custom_ from the drop down list  
    **Destination port ranges**, 9001  
    **Protocol:** TCP  
    **Action:** Allow  
    **Priority:** specify a numeric value (e.g. 100)  
    **Name:** GUI\_9001 (you can assign any value to this)  
      
    Confirm your values as per screenshot, then click **Add** to create the rule.  
      
    ![Screen Shot 2021-09-09 at 9.01.31 am](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/Screen%20Shot%202021-09-09%20at%209.01.31%20am.png)
5.  Specify the following values for the JDBC port:  
    **Source port ranges:** leave the default of _Any  
    _**Service:** select _Custom_ from the drop down list  
    **Destination port ranges**, 10000  
    **Protocol:** TCP  
    **Action:** Allow  
    **Priority:** specify a numeric value (e.g. 101)  
    **Name:** JDBC\_1000 (you can assign any value to this)  
      
    Confirm your values as per screenshot, then click **Add** to create the rule.  
    ![Screen Shot 2021-09-09 at 10.22.13 am](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/Screen%20Shot%202021-09-09%20at%2010.22.13%20am.png)
6.  Click **Refresh** to view your newly created inbound rules  
    ![Screen Shot 2021-09-09 at 10.27.26 am](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/Screen%20Shot%202021-09-09%20at%2010.27.26%20am.png)
