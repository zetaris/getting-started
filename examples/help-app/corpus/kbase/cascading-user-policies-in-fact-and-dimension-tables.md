---
source: kbase
url: https://kbase.zetaris.com/knowledge/cascading-user-policies-in-fact-and-dimension-tables
title: "Cascading user policies in fact and dimension tables"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 47677ba98f9d452c253d932b3a965ad14ec209d04fdf883f69ef9031b86a1f6d
---
# Cascading user policies in fact and dimension tables

## Implement cascaded role-based access control in a Virtual Data environment for an insurance company's data model, Apply filters to related tables without continuously referencing business tables to establish governance across dimension tables.

The requirement here is to apply role/user based access on related tables in a VD , so that the filtering is applied to all relational tables and doesn’t need a look up reference with a system table to determine whether the user is allowed access to that data. Let us consider the below data model

![Insurance domain](https://kbase.zetaris.com/hs-fs/hubfs/Insurance%20domain.png)

Imagine you have an insurance company that sells different types of insurance policies to people. To keep track of everything and make sure everything runs smoothly, you need a way to organize all the information. That's where the data model comes in.

In our data model, we have four main things we want to keep track of: policies, agencies, leads, contacts, and quotes.

1.  Policies: These are like contracts or agreements between the insurance company and the people who buy insurance. Each policy has a unique ID, type of insurance (like auto or home), start and end dates when the insurance is active, and the amount of money the person pays for the insurance (called premium). It also has the name of the person who bought the insurance and references to the agency, contact, and quote related to this policy.
    
2.  Agencies: These are like the offices or branches of the insurance company. Each agency has its own unique ID, a name (like ABC Insurance Agency), a location (where it is based, like New York), and a phone number you can call for help.
    
3.  Leads: When someone is interested in buying insurance, we call them a lead. A lead could come from different sources, like the company's website or a friend referring them. Each lead has its own unique ID, the date it was generated, the status of the lead (like if it's still being worked on or if they have been contacted already), and references to the contact and quote related to this lead.
    
4.  Contacts: These are the people who are interested in buying insurance or already have insurance with the company. Each contact has a unique ID, their first name and last name, an email address, a phone number, and their home address.
    
5.  Quotes: Before someone buys insurance, the company gives them a quote, which is like an estimate of how much the insurance will cost. Each quote has a unique ID, the date when the quote was provided, the estimated amount of money the person needs to pay for the insurance, and the status of the quote (like if it's finalized or still being decided).
    

By organizing all this information in a structured way using the data model, the insurance company can keep track of policies, manage agencies and leads, store customer information in contacts, and provide quotes to potential customers efficiently and effectively.

Assuming the admin wants to provision Jack Smith who is reporting from Agency ‘AG005’ , the same data model but with filters applied at record level so that he can only see the contacts , quotes and policies filtered for Agency ‘AG005’. How would we do it on Zetaris?

**Pre-Requisites :** Import the pipelines located in the [Zetaris git repo](https://github.com/zetaris/WestBend-VersionControl/blob/06a6bb2f652cb2c355944fefc6603a6c8200d418/backup/auto_policy-pipeline-349.sql) (Please request git repository access)

**Step 1:** Create and apply the filtering policy on the **Policies** table (the parent table)

![](blob:https://zetaris.atlassian.net/f76af761-1c73-48bc-bc58-9a1d3a29f4de#media-blob-url=true&id=1e32842f-a334-4159-aa7f-a5e087c8327b&collection=contentId-2838167553&contextId=2838167553&width=757&height=471&alt=)![](https://kbase.zetaris.com/hubfs/image-png-Aug-08-2023-10-18-17-4747-PM.png)

![](https://kbase.zetaris.com/hubfs/image-png-Aug-08-2023-10-19-26-6010-PM.png)

**Step 2:** Import and run the Airflow DAG -->[Update Policies](/wiki/spaces/CSKB/pages/2725347418) (Please request git repository access)

![](https://kbase.zetaris.com/hubfs/image-png-Aug-08-2023-10-20-45-7799-PM.png)

**Step 3:** Check if the child tables have the associated policies auto-generated for them

![](https://kbase.zetaris.com/hubfs/image-png-Aug-08-2023-10-21-34-7857-PM.png)

![](https://kbase.zetaris.com/hubfs/image-png-Aug-08-2023-10-22-12-4789-PM.png)

**Note:** The cascading of policies should be done before creation of **any** policy on the platform. This script does not overwrite or delete existing policies.

The implementation of role-based access control in the insurance company's Virtual Data environment using Zetaris ensures that authorized users, such as the 'Business Analyst' role, are granted filtered access to pertinent data across interconnected tables, including policies, agencies, leads, contacts, and quotes. By applying filters at the record level without requiring system table references, this approach enables seamless and secure data management, allowing users to focus on their specific tasks and responsibilities while ensuring data privacy and efficient information retrieval within the context of Agency 'AG005'.
