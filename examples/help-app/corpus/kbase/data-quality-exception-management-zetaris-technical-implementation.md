---
source: kbase
url: https://kbase.zetaris.com/knowledge/data-quality-exception-management-zetaris-technical-implementation
title: "Data Quality & Exception Management- Zetaris Technical implementation"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 25d4a71fc171738424b9caf0a9a20734bc58daae5c967ed70d947e023500004a
---
# Data Quality & Exception Management- Zetaris Technical implementation

This page details the automation of the Data Quality rules within Lightning. The implementation enables the user to add new DQ rules onto the objects/tables and get the DQ results for the applied rules and the DQ Exception report in Lightning. The output of this DQ analysis is shown on the DQ Tableau dashboard which enables the user to visually track, analyze, and display key performance indicators metrics to understand the quality of data on a daily basis.  
This will enable the user to know the exact record for the objects where the applied DQ rule is failing.

As part of automation, the user will be able to add new DQ rules/delete the existing DQ rules by just including that information within the Lightning NDP Filestore system.

* * *

### **Data Quality Pipelines**

  
Lightning provides the feature of a Data Quality pipeline that automatically calculates the results based on different DQ dimensions.

The following image shows the DQ pipelines within the Data Quality container.

![](blob:https://zetaris.atlassian.net/682767d4-ab52-490a-a66d-b306d47005f3#media-blob-url=true&id=18741034-fe73-4f6e-a463-68de52c2f2e5&collection=contentId-2717646849&contextId=2717646849&height=764&width=645&alt=)![](https://kbase.zetaris.com/hs-fs/hubfs/51e3e6dd-0958-4abe-9856-f00ab2c0a0ad-png.png)

_Data Quality Pipelines within Lighting_

The pipelines with the suffix ‘\_dq’ are the data quality pipelines created for a specific table. For example:- ‘Crash\_dq’, ‘Customer\_dq', nation\_dq’ etc. Each of these pipelines is created to apply the DQ rules to a specific table. These pipelines make use of the Data quality node feature that automatically calculates the DQ results for that specific table. An example of one of these pipelines (nation\_dq):

![](blob:https://zetaris.atlassian.net/f0aba506-5fcf-4fe2-82fc-bf5b7fd195df#media-blob-url=true&id=5af190f5-d717-4aa6-b513-1394a651df39&collection=contentId-2717646849&contextId=2717646849&height=798&width=1625&alt=)![](https://kbase.zetaris.com/hubfs/2324e0c8-ff26-42fb-9e2e-69e1434e0e66%20(1)-png.png)

_Example for Data Quality Pipeline within Lightning_

It contains the ‘Nation’ object from the ‘AZURE\_MSSQL’ Database along with the Lightning DQ node having its rules applied. The result of this ’Nation\_dq' pipeline is as follows:  
![](https://kbase.zetaris.com/hubfs/1ada059a-fb00-47b9-aef0-1e88a8a10b1c-png.png)

![](blob:https://zetaris.atlassian.net/90709e0b-6a64-4458-be9a-ebec80454dce#media-blob-url=true&id=31264e52-7320-488a-aa48-32ff0748aa48&collection=contentId-2717646849&contextId=2717646849&height=375&width=1630&alt=)

_Result for ‘Nation\_dq’ DQ pipeline_

This is how the DQ pipelines are created for each object.

**‘Alldq\_Table’ Pipeline:** It performs the union of all of these DQ pipelines and provides the aggregate result of this DQ results on all of these objects. The result of this pipeline is stored in the ‘alldq’ Table within the RDS.  
  
The result for 'select \* from rds.alldq' is as follows:  
  
![](https://kbase.zetaris.com/hubfs/6829ea77-67aa-43fc-a391-49e0b7b1ffc6-png.png)

_Example for the DQ Result stored in Lightning_

* * *

### **DQ Exception Report** _**- Exception report at the record level for DQ Rule failure**_  
  

The ‘dq\_exception\_details’ table provides the DQ exception report for the applied DQ rules on the objects. It enables the user to know the exact record for the objects where the DQ rule is failing. It stores the value of the primary key of that record within the ‘spid’ column where the DQ rule failed. DQ batch runs on a daily basis and stores the exception report in this table that helps the user to know the DQ failure at the record level.

![](https://kbase.zetaris.com/hubfs/6829ea77-67aa-43fc-a391-49e0b7b1ffc6-png-1.png)

![](blob:https://zetaris.atlassian.net/7d4692e1-e2d4-43d0-8196-4499ce6fa74b#media-blob-url=true&id=4a54f90b-bae8-4bc9-b818-b608f5e721b9&collection=contentId-2717646849&contextId=2717646849&height=429&width=1643&alt=)

_Example for the DQ Exception Result stored in Lightning_

* * *

### **DQ Tableau Report** _**\- Visual representation of key performance metrics**_

The dataquality\_data\_mart contains all objects that will be used for the DQ exception reporting in the Tableau dashboard.

This dashboard makes use of ‘alldq' and 'dq\_exception\_details’ objects (mentioned in the above sections) to represent the data quality results through different visuals. It enables the user to visually track, analyze, and display key performance indicators metrics via the dashboard. The report consists of the following dashboards:

-   Data Profiling Dashboard: It acts as the home page of the DQ Tableau Report. Here the user can view the DQ results based on three DQ dimensions (Completeness, Uniqueness, and Validity).
    
    -   Users can view the overall score of each of the DQ dimensions through the doughnut charts. These charts are clickable to navigate to their respective DQ exception report.
        
    -   Users can view the overall score of each of the objects for these three dimensions.
        
    -   Users can drill down the tables and view these scores for their respective columns.  
          
        ![](https://kbase.zetaris.com/hubfs/5853fad7-66b3-4a19-a100-895c50df29ae-png.png)
        
        _Data Profiling Dashboard(Home Page)_
        

-   Uniqueness Exception Report: When the user clicks on the Uniqueness doughnut charts(on the Data Profiling home page), the user will be navigated to the ‘Uniqueness Exception Report' page. This dashboard will show the following information:
    
    -   Overall Uniqueness: It shows the overall uniqueness score for the data.
        
    -   Attribute Count: It represents the record count where the applied DQ rule is failing.
        
    -   Exception Attribute List: It shows the attributes list at the record level for each object where the DQ rule failed. This will help the user to grab the primary key of that record where the DQ rule failed and fix the issue.  
          
        ![](https://kbase.zetaris.com/hubfs/1c546a81-56a1-4e83-8276-c39183e0fc9d-png.png)
        
        ![](blob:https://zetaris.atlassian.net/00315490-ab45-4b4d-b55c-64b6bbeb477b#media-blob-url=true&id=e60b922f-ad78-4953-a5f3-50bb1e2e9051&collection=contentId-2717646849&contextId=2717646849&height=1095&width=2039&alt=)_Uniqueness Exception Report_
        
          
          
        Note: → There are two other exception reports for ‘Completeness’ & 'Validity’ to represent the corresponding exception report similar to Uniqueness Exception Report.
        

* * *

### **Automation of DQ rules** _**- Easy way of adding/deleting the DQ Rules in Lightning**_

  
The Data Quality implementation allows the user to add/ delete the DQ rules by just populating that information within the ‘Business\_Rules.csv’ file within the Lightning NDP file store and the DQ automated system will automatically consider those rules to provide the DQ results.  
  

-   **Addition of new DQ Rules**:  
      
    The DQ implementation allows the user to add new rules to the objects/tables. To perform this user needs to add these rules in a CSV file (Business\_Rules.csv) and store them in the Lightning NDP File store system. The path for storing these new rules within the NDP file store system :
    

/file-store/DQ\_EXTERNAL\_FILES

![](https://kbase.zetaris.com/hubfs/9c6fbdf8-83df-4e08-9e57-6d0c572bdfe8-png.png)

_‘‘Business\_Rules.csv’ file within the NDP file system_

Once the user adds the rules within the ‘Business\_Rules.csv’ file, these new rules will automatically become part of the DQ analysis from the next day as there is nightly DQ batch execution. The newly added DQ rule needs to have ‘Y' as the value of the 'rule\_active’ column.  
An example of adding/deleting the DQ rules via Lightning NDP File system.

![](blob:https://zetaris.atlassian.net/f5491cb3-ac7a-46ce-8dfd-1a6302afda0a#media-blob-url=true&id=60c15a08-0b85-4a45-9d81-b57c2ddaa6ea&collection=contentId-2717646849&contextId=2717646849&height=354&width=1742&alt=)![](https://kbase.zetaris.com/hubfs/189a4c14-6683-49fc-a255-ab9164a9e043-png.png)

_Example to show the addition/deletion of DQ rules in the ‘‘Business\_Rules.csv’ file_

-   **Deleting/Inactivating the existing DQ Rule:**  
      
    If the user needs to inactivate the existing DQ rule, the user needs to add that particular DQ rule with ‘I' as the value of the 'rule\_active’ column. An example of inactivating the existing rule is shown in the above image.
