---
source: kbase
url: https://kbase.zetaris.com/knowledge/controlling-row-level-access
title: "Row and Column Level Security"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: bd8568d1603d215b9c858c9f6ecddc258f99ace9f10e4c1944d18ba980e6f6c1
---
# Row and Column Level Security

## Database, file sources, and streaming sources can be restricted down, at a column and row level, to users and their associated roles.

Row and column level security settings can be established either through the SQL interface, or by using the **Advanced Access Control UI.** Firstly navigate to the **NDP Fabric Builder** widget.

![NDP_fabric_builder](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_access/NDP_fabric_builder.png)

The Advanced Access Control UI can be accessed via the Schema Store View by expanding a data source and clicking on a table name. You will see a button with a tooltip called “Configure Columns” appear. Click on it to launch the Advanced Access Control UI.

![data_access_control](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_access/data_access_control.png)

 _“Configure Columns” button._

![2](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_access/2.png)

_Opening the Advanced Access Control UI for the first time._

### UI Overview

The Advanced Access Control UI comprises of several sections. The “Users” table shows a list of the available users from which we can do either User Policy or Role Policy Assignments. The “Role Policies” table shows the list of available roles and allows you to control the policy assignment for each role. Subsequently, the “Policy Editor” section is for creating, deleting, and setting policy specific information such as the policy name and policy level filter.

### General Usage

_how to create a column-level security policy_

When opening the Advanced Access Control UI for the first time for the table, no policies will be available to choose from by default. In this case, the default policy for this table will be a grant all policy. To create a custom policy, you must first scroll down to the “Policy Editor” section. Then, enter a policy name. You can optionally provide a policy level filter and assign policies to each column. When done, click the “Update Policies” button to save the policy.

![3](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_access/3.png)

After entering a policy name and modifying the policy details, click “Update Policies” to save the policy.

![4](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_access/4.png)

_Assigning the newly created policy._

 ![5](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_access/5.png)

_Confirming our newly created policy works. In this case, the n\_comment column has been encrypted and we only show the result for n\_nationkey = 2._

As another example to demonstrate the Advanced Access Control feature, below we have created another policy called “encrypt 1” and encrypted the “n\_name” and “n\_comment” columns. After assigning the policy to the relevant user in the “Users” table, previewing the table shows that the “encrypt 1” policy is in effect.

![6](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_access/6.png)

_In this example, the “encrypt 1” policy encrypts two columns._

![7](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_access/7.png)

_Previewing the table shows that the “encrypt 1” policy is in effect._

### Policy (or Row) Level Filter

You can optionally provide a policy level filter when creating or editing a policy. Enter a filter expression into the “Policy Level Filter” input field. Click “Apply Filter” when finished. This will validate and check if your filter expression is correct or not. If there are any errors, an error message will appear.

![8](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_access/8.png)

Column Policies

You can also assign policies to each column in the table for a given policy. In the “Columns” table, you will see the column name, column data type, constraints, and the column policy. Select a column to bring up the column’s information.

![9](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_access/9.png)You can see the column name and its associated information. Most notably, you will also see a dropdown to control the policy of the column. The policy types are “Grant”, “Masked”, “Encrypted”, “Deny” and “Hide”.

 ![10](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_access/10.png) _The available policy types._

For the “Encrypted” and “Masked” policies, you will see further down below an options section. For the “Encrypted” policy, you supply an encryption key. The “Masked” policy takes a regular expression (e.g. \[a-zA-Z0-9\]).

![12](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_access/12.png)

_The masked policy takes a regular expression._

_![11](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_access/11.png)_

_The encrypted policy takes an encryption key_

The encrypt and mask policies will only work for columns with a data type of string.

When you are done assigning a policy, hit the “Apply” button at the bottom right of the UI.

You can also edit a column policy without hitting “Apply” and click on a new column in the Columns table. This will switch to the new columns associated information. The edited policy information of the previous column is temporarily saved for you to get back to when you switch back. However, in order to save the Policy information, you must ensure that all Columns have their details applied. Applied columns have a green tick icon in the status column of the Columns table. Unapplied/modified columns are indicated with an amber warning icon. If there are any unapplied columns remaining, the button to save the policy, “Update Policies”, will not show up.

![13](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_access/13.png)

_Applied and unapplied columns are present, so we cannot save the policy yet._

![](blob:https://zetaris.atlassian.net/9e3216f7-7917-4d99-8c3c-d59a2dd9455e#media-blob-url=true&id=03f041f1-e3f6-427a-93c4-1b651f514746&collection=contentId-2478735421&contextId=2478735421&mimeType=image%2Fpng&name=SAAS-2231%20All%20Columns%20Applied.png&size=43400&height=448&width=818&alt=)![14](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_access/14.png)

_All columns are applied and we can update the policy._

Once you have applied all columns, the “Update Policies” button is enabled.

If the policy level filter is modified, then the “Update Policies” button will be disabled, and you will need to re-validate the policy level filter by clicking “Apply Filter” again before you can proceed with saving the policy.

### Policy Management

You can create, delete, or switch between policies to view or edit their details.

![15](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_access/15.png)

#### Creating a Policy

To create a new policy when a user-created policy is already present, click the “Create Policy” button. This will generate an empty policy template, with text indicating that this is a new policy. Edit the policy to your needs and click “Update Policies” when done.

![16](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_access/16.png)_After clicking the “Create Policy” button, you can begin defining the policy._

#### Switching Between Policies

If you need to switch between policies for viewing or editing a policy, click the policy dropdown and select the policy you would like to switch to.

If you have any modified changes to a policy, they will be discarded when switching over to the new policy.

#### Deleting a Policy

Select the policy you would like to delete via the policy dropdown. Then, click the “Delete Policy” button. A delete confirmation popup will appear asking you to confirm the deletion of the policy. Click “Yes” to delete the policy.

![17](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_access/17.png)

### User and Role Policy Assignment

Once you have at least one or more custom policies created, you can begin to assign policies to users and roles. After assigning the policies, ensure you click the “Update Policies” button to save the policy assignments.

#### Role Policy Assignment

In the “Role Policies” table, a list of available roles is displayed. Each role has a dropdown associated with it, from which you can assign a policy to it.

#### ![18](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_access/18.png)

#### Assigning Policies to Users

The “Users” table displays a list of users and allows you to either assign a user or role policy. If no user policy is supplied for a user (i.e., “None” is selected), the role policy dropdown is shown, allowing you to select a role policy for the user instead. Selecting a user policy that is not “None” will remove the role policy dropdown. This is because user policies have higher precedence than role policies.

![19](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_access/19.png)
