---
source: kbase
url: https://kbase.zetaris.com/knowledge/creating-automated-consent-mechanisms-with-metadata-tagging
title: "Creating automated consent mechanisms with metadata tagging"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 112572a9f3158f990b6026bc92e04b7e663d46421761102355bdf1f40d6c729f
---
# Creating automated consent mechanisms with metadata tagging

A data catalog is a very powerful tool in the data world for classifying and organizing data. We at Zetaris have recently unleashed the power of our metadata tagging and search mechanism by incorporating data redaction principles into the way metadata is tagged in the Zetaris data catalog

* * *

### **User Story**

Data collection in the research industry follows a strict principle of collecting and holding data that has been consented by participants. There is a legal obligation in the industry to remove and discontinue usage of and personal data that has not been consented to or has undergone a withdrawal of consent. To align to strict data privacy rules, time is essential in managing the dynamic nature of the consent associated with the participant’s personal data.

![](blob:https://zetaris.atlassian.net/90379696-fe81-41ea-86bf-1153235e6f54#media-blob-url=true&id=749571dc-0871-4184-970f-61599c235ef8&collection=contentId-2722529281&contextId=2722529281&height=343&width=926&alt=)

![The process of dynamic consent in a data ecosystem](https://kbase.zetaris.com/hubfs/image-png-Nov-14-2022-01-33-54-4412-AM.png)The process of dynamic consent in a data ecosystem

**Implementing a simple scalable and flexible solution**

![](blob:https://zetaris.atlassian.net/ab4d7089-aafc-4661-bc45-cd386f419d7a#media-blob-url=true&id=9fa07046-fb01-4917-926e-ab361004d9aa&collection=contentId-2722529281&contextId=2722529281&height=306&width=1101&alt=)![](https://kbase.zetaris.com/hubfs/image-png-Nov-14-2022-01-34-09-6818-AM.png)

**Below are the steps that need to be implemented for the Withdrawal system**

1.  **Creation of a virtual Data Filter**
    1.  **_Purpose_** of the view is to record the IDs/Primary Keys of all the unconsented records from incoming tables/file sources
2.  **Deletion Script to remove all unconsented data from the incoming source files**
    1.  **Purpose** of the script is to isolate and delete the unconsented records from the Zetaris Lightning File source system as soon as it gets registered in the system.
    2.  **Input** of the script will be virtual Data Filter(Step 1).
    3.  **Output** Script will delete all the unconsented records from the File source as soon as it is registered so that unconsented data will not be accessible within the system.
3.  **_**Modification in existing pipelines(Data Store)**_**
    1.  **Purpose** of the pipeline modification is to include virtual Data Filter(Step 1) to block the unconsented data (if any). It is acting as a precaution to block the unconsented data towards the downward systems.
    2.  **Input** will be virtual Data Filter(Step 1). The view will be used as an inner join in each Data Store pipeline to block the unconsented records (if any).
    3.  **Output** Only consented data gets transformed and flows into the Data Store
4.  _**History View Data Filter**_
    1.  **Purpose** of the view is to store all the unconsented records of the Data Store history tables with their corresponding DML statements.
    2.  **Input** of the View will be the data from the Data Store history tables.
    3.  **Output** View will be used by the data repository administrator to execute the DML statements to delete the unconsented records.
5.  _**Audit Table**_
    1.  **Purpose** of the audit table is to store all the unconsented deleted records when the deletion is being done by the data repository administrator.
    2.  **Input** of the Audit table will be History View Data Filter(Step 4) & Zetaris Lightning Audit table(to record the user deletion information).
    3.  **Output** The table can be used for admin and audit reporting.

* * *

### Implementation of Auto Consent Mechanism

Once this guide has been followed, please click the link below for a guide to implement the auto consent mechanism

-   [Implementation of auto consent mechanism](https://kbase.zetaris.com/knowledge/implementation-of-auto-consent-mechanism)
