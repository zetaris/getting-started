---
source: kbase
url: https://kbase.zetaris.com/knowledge/zetaris-environment-variables
title: "Zetaris Environment Variables"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 70b6bf9c00fe17ed5dd98e9165eb3b9cff8147f8a78507064273653e05e1b7ae
---
# Zetaris Environment Variables

Zetaris environment variables are a powerful feature that allows you to store and reuse data across multiple objects  within Zetaris. These variables can be defined at the environment level and can be used to customize data objects, connection strings, and DSN dynamically. Here are some common uses of Zetaris environment variables:

1.  **Configuring Endpoints**: Store the base URL of your API/database JDBC connection string as an environment variable, and use it in all data objects, so you only need to change it in one place if the endpoint/connection string changes.
    
2.  **Authentication**: Store authentication tokens, user names, or passwords as environment variables to easily manage authentication across multiple data objects in Zetaris.
    
3.  **Testing and Validation**: Store expected response data as environment variables and use them in tests to validate responses from API calls.
    
4.  **Environment-specific Data**: Create separate environments for development, testing, and production. Use environment variables to define different values for each environment, making it easy to switch between environments without changing the objects.
    
5.  **Multi-Environment Testing**: Set up multiple environments with different values for variables, making it simple to test the same objects in different environments.  
      
    
6.  **Global Variables**: Define global variables at the environment level, accessible across all objects in the data product, for shared data across multiple collections.
    

Using environment variables in Zetaris enhances the reusability and maintainability of your data products, making it easier to manage complex pipelines, handle different environments, and create more dynamic and versatile data products.
