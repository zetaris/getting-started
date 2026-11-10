---
source: kbase
url: https://kbase.zetaris.com/knowledge/update-metadata-tags-description-using-python-and-excel
title: "How to \"bulk load\" an existing data dictionary into Zetaris Catalogue"
kind: how-to
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: b0e208e27508359dd18d18a784acf1de4bb11fc48c811ef4cb161b70b38e1083
---
# How to "bulk load" an existing data dictionary into Zetaris Catalogue

#### **Overview:**

Users might want to update metadata tags and descriptions into the data catalog of Lightning. To make the process easier and avoid manual work of writing hundreds of SQL queries or manually adding them, a python library is available for our use.

#### **Description of Library:**

  

| 
**Information** 

 | 

**Details** 

 |
| --- | --- |
| 

Name of the Python library

 | 

ndpmetadata

 |
| 

Version

 | 

0.5

 |
| 

Purpose

 | 

Automatically update tags & descriptions in data catalog on Lightning platform from a excel sheet

 |

#### **Requirements:**

1.  Python should be installed (The latest version if possible)
    
2.  Python Libraries
    
    1.  Pandas (version 1.1.5 or newer)
        
    2.  Jaydebeapi (Latest version)
        
    3.  Xlrd (version 1.2.0)
        
3.  Any IDE (Google Colab, Jupyter Notebooks, PyCharm, etc.)
    
4.  An excel sheet (.xlsx) containing all the tags and descriptions.
    
5.  Tags should be alphanumeric. Descriptions should not contain quotes. ( “ , ' )
    
6.  Lightning Java Archive file (.jar).
    
7.  Enterprise version’s server details and user credentials
    
8.  Lightning Driver’s class file
    

### **Steps:**

-   _**Install the library using either of the methods.**_
    
    -   Use Command Prompt / Terminal and use the command :
        
        ```
        pip install ndpmetadata
        ```
        
    -   Using Jupyter / Colab or any other notebook, you can install the library using:
        
        ```
        !pip install ndpmetadata
        ```
        
-   _**Use the below command to import the function:**_
    

```
from metadata_dc.metadata import execute_metadata
```

-   _**Call the function along with the necessary arguments. The arguments are described in detail in the table below along with examples.**_
    

```
execute_metadata(  host,   port,   user,   password,   path_of_excel_sheet,   driver,   path_of_jar_file)
```

| 
**Argument** 

 | 

**Description**

 | 

**Example** 

 |
| --- | --- | --- |
| 

**host**

 | 

Host / IP address of the enterprise version of lightning

 | 

“13.75.254.117”

 |
| 

**port**

 | 

Lightning Port

 | 

“10000”

 |
| 

**user**

 | 

Email Address of the admin User

 | 

“<REDACTED>”

 |
| 

**password**

 | 

Password

 | 

“password”

 |
| 

**path\_of\_excel\_sheet**

 | 

Entire path of the excel file

 | 

“/Users/harshal/Desktop/metadata.xlsx”

 |
| 

**driver**

 | 

Lightning JDBC Driver

 | 

“com.zetaris.lightning.jdbc.LightningDriver”

 |
| 

**path\_of\_jar\_file**

 | 

Entire path of the Java Archive file

 | 

“/Users/harshal/Desktop/lightning-jdbc-driver-2.1.0.1-driver.jar”

 |

_**Please Note:** Port and Driver will remain the same every time and for every user._

### Demonstration:

-   Use the below table, and save as an Excel sheet containing tags and descriptions in the below-mentioned format
    

<table style="border-collapse: collapse; table-layout: fixed; margin-left: auto; margin-right: auto; border: 1px solid #99acc2; width: 88.3721%; height: 154px;"><tbody><tr style="height: 51px;"><td style="width: 19.5107%; height: 51px; border-width: 1px; border-style: solid;"><strong>Database Name</strong></td><td style="width: 14.5354%; height: 51px; border-width: 1px; border-style: solid;"><strong>Table Name</strong></td><td style="width: 17.3135%; height: 51px; border-width: 1px; border-style: solid;"><strong>Column Name</strong></td><td style="width: 20.6775%; height: 51px; border-width: 1px; border-style: solid;"><strong>Description</strong></td><td style="width: 13.9057%; height: 51px; border-width: 1px; border-style: solid;"><strong>Tag1</strong></td><td style="width: 13.9057%; height: 51px; border-width: 1px; border-style: solid;"><strong>Tag2</strong></td></tr><tr style="height: 51px;"><td style="width: 19.5107%; height: 51px; border-width: 1px; border-style: solid;">Test_DB</td><td style="width: 14.5354%; height: 51px; border-width: 1px; border-style: solid;">table_test1</td><td style="width: 17.3135%; height: 51px; border-width: 1px; border-style: solid;">alarm_origin</td><td style="width: 20.6775%; height: 51px; border-width: 1px; border-style: solid;">Test Description1</td><td style="width: 13.9057%; height: 51px; border-width: 1px; border-style: solid;">Test Tag 11</td><td style="width: 13.9057%; height: 51px; border-width: 1px; border-style: solid;">Test Tag 21</td></tr><tr style="height: 51px;"><td style="width: 19.5107%; height: 51px; border-width: 1px; border-style: solid;">Test_DB</td><td style="width: 14.5354%; height: 51px; border-width: 1px; border-style: solid;">table_test2</td><td style="width: 17.3135%; height: 51px; border-width: 1px; border-style: solid;">alarm_type</td><td style="width: 20.6775%; height: 51px; border-width: 1px; border-style: solid;">Test Description2</td><td style="width: 13.9057%; height: 51px; border-width: 1px; border-style: solid;">Test Tag 12</td><td style="width: 13.9057%; height: 51px; border-width: 1px; border-style: solid;">Test Tag 22</td></tr></tbody></table>

> _**Please Note:** The columns Database Name, Table Name, Column Name, and Description are mandatory and should be written in the same way as shown in the image above._

Database name → Datasource Name

Table Name → Entity

Column Name → Attribute

Description → Descriptions for the respective attributes

Tag1, Tag2 are the tags for the columns and there could be as many tags as possible and with any column names.

For example, after the Description column, we have 4 tags per attribute. In this case, we can have different columns like Tag1, Tag2, Tag3, Tag4.

-   Open any IDE and execute the code as shown (if, ndpmetadata library is already installed):
    

```
from metadata_dc.metadata import execute_metadataexecute_metadata("18.219.104.62",                 "10000",                 "<REDACTED>",                 "password",                 "/Users/harshal/Desktop/trial.xlsx",                 "com.zetaris.lightning.jdbc.LightningDriver",                "/Users/harshal/Desktop/lightning-jdbc-driver-2.1.0.1-driver.jar")
```

#### **Output**

Python Notebook Output

![python_output](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_catalog/python_output.png)

Updated Data Catalog in Zetaris

![updated_catalog](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_catalog/updated_catalog.png)
