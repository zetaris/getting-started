---
source: kbase
url: https://kbase.zetaris.com/knowledge/global-data-sharing
title: "Global Data Sharing"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 1216ecc2b889142b089c638f582f244420fbfc344af61bd51d074b42e620df22
---
# Global Data Sharing

Global Data Sharing is one of the major challenges that big enterprises around the world are trying to figure out. The biggest operational challenge for global businesses is to share the data across borders without creating a violation of the General Data Protection Regulation (GDPR) policies and and country-specific data sharing laws and policies

This White Paper outlines the many challenges presented by data sharing projects and shows how Zetaris: The Networked Data Platform:

-   Ensures connection visibility of both the source and target environments,
    
-   Enables aggregations and obfuscation at a local level,
    
-   Allows data to be queried at source reducing the need to move data across borders for reporting,
    
-   Records modified or created in any of the entities within the enterprise will be replicated immediately, across all authorized entities.
    
-   Fields that are not selected for sharing are maintained in each local instance and will not be available for sharing
    
-   Ensures business continuity, and
    
-   Removes common barriers associated with data sharing projects.
    

### A deeper study of a use case for global data sharing

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Nov-29-2022-02-14-21-7396-AM.png)

In this use case we trace the credit history of Jane Doe , who is a global citizen and has been a resident of country AUS and country USA. The Credit Bureau of the region is aggregating information and creates credit scoring of borrowers based on their credit history. Austalia’s and USA’s compliance to GDPR rule do not allow for cross-border sharing of transactional data .

Banks play a crucial role in market economies. They decide who can get finance and on what terms and can make or break investment decisions. For markets and society to function, individuals and companies need access to credit. 

Credit scoring algorithms, which make a guess at the probability of default, are the method banks use to determine whether or not a loan should be granted

Using Zetaris' approach of creating virtual data marts , the challenge can be resolved without moving the data from its source. In this approach we set-up local installations of Zetaris in the countries governed by the credit bureau.

In this challenge we try to calculate the PD (Probability of Default) for Jane Doe as a debtor using variables that are approved for global use. This Probability of Default (PD) report covers a reference data set of large corporate exposures, provided by multiple banks. However it is important to note that the data from these banks were not transferred or copied to the global entity. The information was aggregated and collected at a local entity level. Pushdown queries from the global entity work on aggregated and anonymized information thus preventing a breach of any data privacy policies.

The insights gained from these high-level analyses confirm the benefits of detailed and granular collection of data – critical for banks using data-driven credit risk modelling to understand and quantify PD

### Considerations for successful data sharing

Several attributes in a global report are carefully considered for aggregation and obfuscation

-   All sub-entities reporting to the global entity should have a standard and uniform aggregation methodology and conventions
    
-   Any reference data or sequence number must be uniformly applied and standardized as part of business rules or business marts
    
-   Default options must be the same across all sub-entities reporting to global entities. For example country code is a 2 character ISO -3166 (Alpha-2) -AU for Australia.
    

#### When should I use cross-border data sharing?

Use cross-company data sharing for the following business scenarios:

-   Sharing of simple reference and group data in a single deployment
    
-   Sharing among companies that have very similar configurations
    
-   Sharing scenarios that have been explicitly endorsed by Zetaris
    

Cross-border data sharing isn't supported for the following scenarios:

-   Disparate solutions, where thousands of records are shared across thousands of companies.
    
-   Sharing of detailed transactional records for reporting or management purposes, such as consolidations.
    
-   Data which does not have currency indicators like effective dates
    
-   Tables that do not have a unique identifier
    

* * *

**Technical Design and Implementation**

See more information here: [Global Data Sharing - Technical Design and Implementation](https://kbase.zetaris.com/knowledge/global-data-sharing-technical-design-and-implementation)
