---
source: kbase
url: https://kbase.zetaris.com/knowledge/roles-permissions
title: "Roles & Permissions"
kind: other
lastmod: 2026-10-28
retrieved: 2026-11-10
sha256: f4ae80c32ff9172170d8c378d0a4f0c5814739b63440396e9fce6ff108b71646
---
# Roles & Permissions

## This article delves deeper into creating multiple control planes for roles and permission on the Zetaris platform. Lightning provides a unique feature of multi-tier user access that allows the admin user to provide a granular access control mechanism

Understanding of Users, Roles, and Permissions

A user is anyone who can access the Zetaris UI. An admin user grants permissions that decide which areas of the product each user can access and what they can do in them.

The admin user can create a role (user group) and assign it to a group of users. A role groups permissions together, so every user with that role gets the same access.

How to create Users/Roles: see User Management Overview. Users are created in **Management > Users** and roles in **Management > Roles**. Each role has a **Level**: **Admin** (full access to everything) or **General** (access only to what is granted).

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-42-42-1135-AM.png)

_Management > Roles_

The admin user can grant permission at the role level or the user level on the **Permissions** page (**Management > Permissions**). Only admin users can access this page. It has two panels:

1\. **Roles**: lists all roles created in the environment. Access given to a role applies to every user with that role.

2\. **Users**: lists all users created in the environment. Access given here applies to that user only.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-42-43-8330-AM.png)

_Management > Permissions_

Permission/Access assigned through a Role

This makes it easier to add or remove permissions for a group of users. The admin only needs to update the permission at the role level instead of for each user.

Before you start, create the users and roles, and assign the roles to users (**Management > Users**, then **⋮** **> Edit > Roles**).

1\. Go to **Management > Permissions** and, in the **Roles** panel, expand the role.

2\. Tick **View** and/or **Execute** for each resource the role needs.

3\. Click **Save**.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-42-45-0336-AM.png)

_Permissions granted to the DA role_

In the example above, the DA role is given access to two resources:

• **NDP File System**: **View** and **Execute**

• **Data Catalog**: **View**

There are two types of privilege:

• **View**: the user can open the resource and see only the data objects that have been shared with them through **Access Control**. The user cannot create data objects.

• **Execute**: the user can also create objects in the resource, for example create data marts in **Virtual Data Mart**. Ticking **Execute** automatically ticks **View** as well.

Roles with the **Admin** level have access to every resource, so these settings don't apply to them.

Permission/Access assigned through a User

This is useful when the permission needs to be given at the user level instead of the role (user group) the user belongs to.

1\. Go to **Management > Permissions** and, in the **Users** panel, expand the user.

2\. Tick **View** and/or **Execute** for each resource.

3\. Click **Save**.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-42-42-8443-AM.png)

_Permissions granted to DA\_TRAINING@ZETARIS.COM_

In the example above, the user DA\<REDACTED> has, among others:

• **Query Builder**: **View** and **Execute**. The user can open Query Builder and create views in it.

• **Data Pipeline**: **View**. The user can open pipelines that have been shared with them but cannot create pipelines.

Granular level of access for the Data Objects

Once the admin has given users access to a resource, the admin can also decide which data objects inside it each user can see. This is done with **Access Control** on each data object.

For example, to give DA\<REDACTED> access to the sales\_data data source:

1\. In **Data Explorer**, click the data source (e.g. **File Source & API > sales\_data**). The data source opens in its own tab. Click **Access Control** in the toolbar. You will see two sections: **Assigned Users** and **Assigned Roles**.

2\. Click **Assign Users**. To give access to a whole role instead, click **Assign Roles**.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-42-44-1797-AM.png)

_Access Control on a data source_

3\. A pop-up window shows the list of users. Tick DA\<REDACTED>.

4\. Click **Assign**. The user now appears under **Assigned Users**.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-42-44-5058-AM.png)

_Assign Users pop-up_

5\. To set table-level access for an assigned user, click the user in **Assigned Users**. The **Grant <user> to <data source>** pop-up lists the tables in the data source (<data source>.\* covers all tables). Use this when no column access policy applies to the user.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-42-43-5008-AM.png)

_Click an assigned user to open the Grant pop-up_

6\. Tick **SELECT** (read) and/or **INSERT** (write) for each table. Tick the column header to apply it to every table.

7\. Click **Apply**.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-42-42-5975-AM.png)

_Grant SELECT / INSERT on tables_

Follow the same steps to give other users access to other data sources. Each user sees only the data sources they have been assigned. In the same way, the admin can control access to other data objects, such as data marts, pipelines and views, using **Access Control** on each object.

For access below table level:

1\. Open a table in **Data Explorer** and click **Column Access**.

2\. Assign a column policy to individual users (**User Policy**).

3\. Assign a column policy to every user in a role (**Role Policies**).

4\. Create policies with **New Policy** to mask, encrypt, deny or hide individual columns. Use **Policy Level Filter** to restrict which rows the policy's users can see.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-42-43-1733-AM.png)

_Column Access on a table_
