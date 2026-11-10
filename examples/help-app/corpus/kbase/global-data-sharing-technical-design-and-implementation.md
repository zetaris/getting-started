---
source: kbase
url: https://kbase.zetaris.com/knowledge/global-data-sharing-technical-design-and-implementation
title: "Global Data Sharing - Technical Design and Implementation"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 808bcaebe1fbe11d50d1f062429b421b2b9f2889be978642e856c8d3a73af2ac
---
# Global Data Sharing - Technical Design and Implementation

### Infrastructure Diagram

### ![](https://kbase.zetaris.com/hubfs/image-png-Nov-29-2022-03-01-14-2725-AM.png)

### Configuring the Zetaris environments

#### Configuring the Nation-based Zetaris Instances

In this example, we are working with 3 regions. The Singapore region is assumed to be the headquarters and there are two regional reporting entities in Australia and the US.

In each of the country or region , there will be a standard installation of Zetaris Networked Data Platform

In our case a standard installation was completed in both the Australia Southeast region and East US region to demonstrate the Credit Bureau datasets for each region. The headquarters are assumed to be in the Singapore region and each of the Australia and US regions' aggregated and anonymized datamarts are provisioned into the Singapore Zetaris

#### Configuring the Global Zetaris Instance

When setting up the Global environment this must be added to the _**lightning-server-deployment.yaml**_ under the following path:

```
  deps:    jars:      ...      - local:///home/zetaris/lightning/jdbc-driver/ndp-jdbc-driver-2.1.0.13-driver.jar
```

This will enable Zetaris to utilize its JDBC driver to connect with other Zetaris platforms

#### Configuring the JDBC connection on Kubernetes

To allow for JDBC connectivity, each environment will be required to open port 10000. This can be done by adding the following to the end of the _**lightning-server-service.yaml.**_

```
---apiVersion: v1kind: Servicemetadata:  name: lightning-jdbc-driver-svc  namespace: defaultspec:  type: LoadBalancer  ports:    - port: 10000      name: lightning      targetPort: 10000  selector:    app: lightning-server
```

#### Setting up the dataset in the regions (US and Australia)

1.  Upload the respective country/region datasets to Zetaris using the NDP File System.![](https://kbase.zetaris.com/hubfs/image-png-Nov-29-2022-02-21-01-2615-AM.png)
2.  Navigate to the NDP Fabric Builder feature tab.![](https://kbase.zetaris.com/hubfs/image-png-Nov-29-2022-02-18-00-6234-AM.png)
3.  Add a **Virtual File Source** using the dataset files uploaded in **step 1**.![](https://kbase.zetaris.com/hubfs/image-png-Nov-29-2022-02-20-10-1402-AM.png)
    
4.  Upon successful registration, the registered dataset can be previewed and inspected as shown below:![](https://kbase.zetaris.com/hubfs/image-png-Nov-29-2022-02-21-47-9764-AM.png)
    

The dataset can be aggregated in a pipeline of query builder and associated with a VDM (virtual datamart).

 ![](https://kbase.zetaris.com/hubfs/image-png-Nov-29-2022-02-23-37-0202-AM.png)

_Pipeline contains related datasets which are stored within a VDM_

> The user access management needs to be set-up carefully to ensure that the global instance of Zetaris have the right privileges and avoid any direct access to the raw data in the regions
> 
> 1.  Navigate to the User Management feature tab
>     
> 2.  Assign the global user to the global role
>     
> 3.  Navigate to the Access Control feature tab
>     
> 4.  Select the previously created data mart
>     
> 5.  Assign the global role select privileges
>     

#### **etting up the dataset for the global (Singapore) instance**

### Intention

In order to adhere to GDPR, data pipelines are created to ensure that the global admin account receives de-identified data with its corresponding aggregated data. Providing the global admin account the means to join the aggregated data of both countries to create a cumulative view.

* * *

### Connecting to the National Zetaris Instances from the Global Zetaris Instance

#### Using Lightning Wizard

1.  Create a new virtual data source connection within Zetaris.
    
    1.  Datasource: Other JDBC
        
    2.  Datasource Name: CB\_<Region>
        
    3.  JDBC Driver Class: com.zetaris.lightning.jdbc.LightningDriver
        
    4.  JDBC URI: jdbc:zetaris:lightning@<JDBC-LoadBalancer-IP>:10000
        
        1.  e.g. jdbc:zetaris:lightning@10.0.0.0:10000
            
    5.  username: global account username
        
        1.  e.g. [<REDACTED>](mailto:<REDACTED>)
            
    6.  password![](https://kbase.zetaris.com/hubfs/image-png-Nov-29-2022-02-24-56-2804-AM.png)
        
2.  Select **Next**, then select the Pipeline/Permanent View for the aggregated data.![](https://kbase.zetaris.com/hubfs/image-png-Nov-29-2022-02-25-41-7900-AM.png)
    
3.  Select **Next** to validate the data and register the datasource.![](https://kbase.zetaris.com/hubfs/image-png-Nov-29-2022-02-26-25-7625-AM.png)
    

#### Using SQL Editor  

1.  Navigate to the **Schema Store** feature tab.
2.  Run the following queries for each region:
    
    ```
    CREATE DATASOURCE CU_<country/region> DESCRIBE BY "CU_<country/region>" OPTIONS (    jdbcdriver "com.zetaris.lightning.jdbc.LightningDriver",     jdbcurl "jdbc:zetaris:lightning@<JDBC-LoadBalancer-IP>:10000",      username "<global_username>",      password "<global_password>"  );REGISTER DATASOURCE TABLES FROM CU_<country/region>;
    ```
    
3.  The final connections will be displayed as seen below:![](https://kbase.zetaris.com/hubfs/image-png-Nov-29-2022-02-35-46-3263-AM.png)
4.  The access controls for the global user will need to be set-up as shown below:  
    ![](https://kbase.zetaris.com/hubfs/image-png-Nov-29-2022-02-34-49-6060-AM.png)  
    _Provisioning access using the same authorization used in the US and Australia data mart_
5.  To complete the reporting process, the aggregated datasets can be joined together using the common surrogate key to create a global view of the individual’s credit information.
    
    ![](https://kbase.zetaris.com/hubfs/image-png-Nov-29-2022-02-36-48-3641-AM.png)  
    
    _Aggregated permanent view to be used in reporting or ML algorithms for PD calculation_
