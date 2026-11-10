---
source: kbase
url: https://kbase.zetaris.com/knowledge/connect-to-xml-on-datalake
title: "XML on Datalake"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 4b8568e53d071ab1ab7c2d5e62e47970e5ff8c3a8c5c22e4d16ea75d86cb6634
---
# XML on Datalake

1.  Login to Zetaris.
2.  Go to NDP Fabric Builder tab.
3.  Create a Virtual File source Container
    1.  File source container can be created by click on "+" button next to Virtual file source  
        ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Nov-01-2023-11-45-26-8113-PM.png)
    2.  Once "+" is clicked, A pop will appear enter any data source name and description than press "Create"  
        ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Nov-01-2023-11-48-29-0949-PM.png)
    3.  Container will be created  
        ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Nov-01-2023-11-50-19-0324-PM.png)
    4.  Click on the "+" button of newly created created container. In our case it is "Sample\_container\_name". A pop will appear.  
        ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Nov-01-2023-11-52-26-3366-PM.png)
    5.  Select File Store and click Next and move to step 2
    6.  In step 2, Fill the require information to make connection to XML file on a Datalake.  
        ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Nov-02-2023-12-09-57-8986-AM.png)  
        1.  File Source : Choose "XML"
        2.  Storage : Choose from the given option. In this example We have chosen "Azure Blob Storage"
        3.  Table Name :  Give any name without space or special character. Underscore can be used
        4.  File Path : Give Wasbs path link to your xml file. In the example:
            1.  Azureqafile : Is container name on azure.
            2.  Azureqastore : Is storage account name on azure.
            3.  /abc/nestedxml.xml : Is directory and xml filename
        5.  Access key name : fs.azure.account.key.\[your Storage name\].blob.core.windows.net.
        6.  Access Key Value : Your access key
        7.  Rowtag : Is the Name from where XML body is starting. In this example it "PurchaseOrder"
    7.  Once all the above details are filled, Click next and move to step 3. where it will preview first 50 records if the connection details are correct.  
        ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Nov-02-2023-12-14-51-9785-AM.png)
    8.  Click on create. This will make successful connection to you xml file source.
4.  New created XML file source will appear inside the container that was created.  
    ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Nov-02-2023-12-19-13-9212-AM.png)
5.  Run query on the newly created XML file source.
    1.  Go to schema store View
    2.  Run
        1.  SELECT \* FROM Sample\_container\_name.datalake\_xml;
            
6.  Alternatively connection to XML file source on datalake can be made via query as well:
    1.  Go to schema store View
    2.  Run
        1.  Create lightning database Sample\_container\_name
        2.  CREATE LIGHTNING FILESTORE TABLE datalake\_xml FROM Sample\_container\_name FORMAT xml OPTIONS (path "wasbs://<REDACTED>/abc/nestedxml.xml", fs.azure.account.key.azureqastore.blob.core.windows.net "Qv7xc11pidXpnAxSjp0YqFHVXEJ3iFUnShpzIGYsC8ee1RXXXXXXXXXXXXXXXXXXXXXX", rowTag "PurchaseOrders");
            
    3.  That will create the connection.
