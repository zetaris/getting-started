---
source: kbase
url: https://kbase.zetaris.com/knowledge/controlling-table-level-access
title: "Data Object Level Security"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 93563aa03892e027f28c8b25d9bae511c4e4e920a9a0bffad58f4aaad2e727f9
---
# Data Object Level Security

## Data objects include raw databases, filesources, pipelines, and views

[Assign Users/Roles to Data](#assign-users-roles)

[Select and Insert Permissions](#select-insert-permissions)

[Permission Hierarchy](#permission-hierarchy)

[Steps to assign permissions](#steps-permissions)

Controlling access to raw, aggregated or joined tables is done through the **Access Control** widget.

![access_control](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_access/access_control.png)

Provision access to Databases, Data sources, Data-marts, Pipelines, and Views for users and roles.

> BEST PRACTICE
> 
> If you can, provision access at the **Role level**, as this makes for successful ongoing user management. i.e. when a user is onboarded into a company, they are placed into a Role, and that role already has predefined data access measures in place. Further, managing a handful of roles is easier than managing hundreds of users.

#### Assign Users/Roles to Data

Modify user or role access associated with Databases, Data sources, Data-marts, Pipelines, and/or Views by following the below steps.

1.  Select Database, Data source, Data-mart, Pipeline, or View
    
2.  Using Assign and Revoke, manage your users and role who have access
    
3.  Click Apply
    

#### Select and Insert permissions

You are then able to modify what level of access that user or role is given through Select and Insert

1.  Click on a user or role for which you want to next configure access to tables and a window shall pop up.
    
2.  Either click on the checkbox beside SELECT to grant select privilege on all tables or check separate checkboxes to grant select privilege on the corresponding table.
    
3.  Either click on the checkbox beside INSERT to grant insert privilege on all tables or check separate checkboxes to grant insert privilege on the corresponding table.
    
4.  Click Apply.
    

#### Permission Hierarchy

User and role data access are explicitly configured, unless a user is granted access, they will be denied access to data.

The below diagram show the logic in permission evaluation.

![permission_hierarchy](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/data_access/permission_hierarchy.png)

#### **Step to assign permission to roles**

1.  Login to Zetaris
    
2.  Go to access management tab
    

![Roleimage1](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/processes-for-automation/Roleimage1.png)

![](blob:https://zetaris.atlassian.net/78a47228-79e8-4089-baed-92e5defed23f#media-blob-url=true&id=99c472b7-11ed-4716-91a9-2d675eb10199&collection=contentId-2620981264&contextId=2620981264&height=455&width=1268&alt=)3.   Click on data source/ file source on left pane.

4.   Click on assign button for assigned roles.

![Roleimage2](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/processes-for-automation/Roleimage2.png)

5.   After clicking on "Assign" all the available roles will appear. Select the role you want to assign to a particular data source / file source. Then click "Apply."

![Roleimage3](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/processes-for-automation/Roleimage3.png)

6.   The role will be assigned to particular data source / file source ![Roleimage4](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/processes-for-automation/Roleimage4.png)7\.   Now click on the role which you have just assigned. Pop-up will appear.

![Roleimage5](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/processes-for-automation/Roleimage5.png)

8.   Click on the check boxes to select/insert as needed and then click "Apply"

9.   Selected permissions will be assigned to that role for that particular data source/file source

10.  To revoke the permission, click on the role again.

11.  Pop-up will appear. Simply de-select where permission is not needed. This will revoke the permission

12.  To completely remove the role from the data source / file source, click on the "Revoke" button.

![Roleimage6](https://kbase.zetaris.com/hs-fs/hubfs/knowledge_base_images/processes-for-automation/Roleimage6.png)

13.  Select the role you want revoke and click "Apply."

14.  This will completely revoke the role
