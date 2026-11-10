---
source: kbase
url: https://kbase.zetaris.com/knowledge/automate-creation-of-data-marts-and-provisioning-of-data-sources-through-the-api-service
title: "Automate creation of Data Marts and provisioning of data sources through the API Service"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 0f5557c82a986214a8ce935922bfbc36b82db94f03808e89dcc3ab3f55de7c28
---
# Automate creation of Data Marts and provisioning of data sources through the API Service

* * *

#### **Requirements**

> -   _Datamart\_Injection.py_
>     
> -   An environment _utilizing app\_v6.py_ for the API service
>     

#### **Purpose**

Any enterprise platform that has many domains, such as HR, Sales and, Finance. Each of these domains have hundreds of views associated to them.

We have proposed to utilize data marts to achieve this function as it provides the desired grouping and the ability to utilize the access control feature within Zetaris which will help enterprises provision the selected data mart to its respective business domain.

Due to the user discomfort with the UI, they do not want to manually drag and drop data sources into Data Marts. For this reason, we have developed an automated approach to create data marts and assign data sources, specifically permanent views, to the respective data mart.

#### **How It works**

To run the script you will need to ensure that you have the following python libraries installed:

1.  requests (which should be automatically installed)
    
2.  json (which should be automatically installed)
    
3.  getpass (which should be automatically installed)
    

To run the script use the following command in a terminal

```
py Datamart_Injection.py
```

### Understanding the process

-   The user will be asked for their password, which will be encrypted by the API service
    
-   The user will be asked to input their username
    
    -   The encrypted password and username are sent to the API service to generate a bearer token which is used to run the required queries
        
-   The script will loop through an array of data mart names provided with an array of views to be added the respective data mart.
    
    -   The queries run will also be automatically closed through the API as well
        
-   Users will be able to view the data marts within the Zetaris platform and the respective views within
    

### **Where to find the script?**

The **_Datamart\_Injection.py_** script is located on **GitHub** in the [custsuccess repository](https://github.com/zetaris/custsuccess/blob/043a1f469df9c0c14febdd8c7aba6b6a0885fd8a/Datamart_Injection.py%20-%20Connect%20to%20preview)

> _Please note that requested access to [![](https://github.githubassets.com/favicon.ico)](https://github.com/zetaris/custsuccess/blob/) GITHUB links will be required in order access files_
