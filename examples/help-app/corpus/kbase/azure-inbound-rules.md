---
source: kbase
url: https://kbase.zetaris.com/knowledge/azure-inbound-rules
title: "Azure Inbound Rules"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: daff2c9c0814af72ff13e0621a691d4f270e591d0ed22a2132609aeb7fa24033
---
# Azure Inbound Rules

## This article covers configuration of Azure Inbound Rules for Zetaris external ports.

In Azure, a _security group_ acts as a virtual firewall for your instance to control inbound and outbound traffic. For Zetaris running on Azure, you will need to add inbound rules that allow access to the following ports:

1.  Web Application GUI port - default 9001
    
2.  JDBC Driver port - default 10000

  

Create Azure Inbound Rules

1.  Sign in to the Azure portal at [https://portal.azure.com](https://portal.azure.com/).
2.  Select your new network security group.
3.  Select **Inbound security rules** from the left menu, then select **Add**.
    1.  For **Source port ranges** leave the default of _Any_.
    2.  For **Destination** leave the default of _Any_.
    3.  For **Service** from the drop-down menu, select Custom to provide a specific port to use.
    4.  For **Destination port ranges**, specify a value of 9001.
    5.  For **Protocol** specify TCP.
    6.  For **Action** specify Allow.
    7.  For **Priority** specify 100.
    8.  For the **Name** specify GUI\_9001 (you can assign any value to this).
    9.  Click **Add** to create the rule.
4.  Select **Add** to create the JDBC rule.
    1.  For **Source port ranges** leave the default of _Any_.
    2.  For **Destination** leave the default of _Any_.
    3.  For **Service** from the drop-down menu, select Custom to provide a specific port to use.
    4.  For **Destination port ranges**, specify a value of 10000.
    5.  For **Protocol** specify TCP.
    6.  For **Action** specify Allow.
    7.  For **Priority** specify 101.
    8.  For the **Name** specify JDBC\_10000 (you can assign any value to this).
5.  Click **Refresh** to see your newly created inbound rules:  
    ![Screen Shot 2022-07-18 at 12.07.07 pm](https://kbase.zetaris.com/hs-fs/hubfs/connectDS/Screen%20Shot%202022-07-18%20at%2012.07.07%20pm.png)
