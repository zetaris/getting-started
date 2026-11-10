---
source: kbase
url: https://kbase.zetaris.com/knowledge/product-version-2.3.2.0-14th-aug-2023
title: "Product Version 2.3.3.0 (14th Aug 2023)"
kind: release-note
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 42370ec6df0ae6603c9d7893fadb8806923d8f8adcc0d683d3d0cb6ee5cc4645
---
# Product Version 2.3.3.0 (14th Aug 2023)

### Feature Enhancements

-   Zetaris now offers seamless [integration with Google](https://kbase.zetaris.com/knowledge/google-integrations), allowing users to access Google Cloud Storage for read and write capabilities.
    
-   Zetaris users have the ability to utilize Google Secrets Manager for secure storage and management of sensitive information, including API keys and passwords. This integration allows users to avoid entering secrets/passwords while registering Google data sources on Zetaris.
    
-   Zetaris provides the capability to effortlessly import and export User and Organization variables into Zetaris.
    
-   Data engineers can now use the Zetaris permanent views directly in the Zetaris data pipelines and perform transformations on them seamlessly.
    

#### Major Bug Fixes

-   Enhanced ODBC support to address the hive/glue issue for non-admin users.
    
-   Now, users can enable Hive/Glue access control for databases and tables that contain special characters.
    
-   Resolved the problem of the "Run Query" button being randomly disabled.
    
-   Column-based access controls on MongoDB databases have now been enabled.
    

#### Minor Bug Fixes:

-   Enhancements have been made to the pipelines to facilitate the reuse of datasources.
    
-   Enhancements have been made to the pipeline joins in the graphical user interface (GUI) to prevent the unintentional creation of invalid joins when utilizing the "LEFT JOIN" function.
    
-   The lakewarehouse migration widget has been enhanced to proactively prompt users to provide object names if the target file or table does not exist.
