---
source: kbase
url: https://kbase.zetaris.com/knowledge/user-management-overview
title: "User Management Overview"
kind: other
lastmod: 2026-11-04
retrieved: 2026-11-10
sha256: 012b44c06350911697813aa59121a3b1b22e6c349cf6bd6b294d537362e5fc75
---
# User Management Overview

## Create local user, create roles, assign and revoke, reset passwords

User Management helps in managing different users and their roles. Users and roles are managed from **Management > Users** and **Management > Roles**. Only Admin users can access these pages.

Create a new user

1\. Go to **Management > Users** and click **+** (**New user**).

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-44-36-4961-AM.png)

_Management > Users_

2\. Enter the user's **Email**.

3\. Enter the **Display name**.

4\. Select the **Level**: **General** or **Admin**.

5\. Enter the **Password**. The password must be a minimum of 6 characters. If the user signs in with LDAP, tick **LDAP authentication**.

6\. Click **Create**.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-44-36-1929-AM.png)

_New user_

If using local authentication, Administrators will initially set the user's password, though this can be changed by the user after login.

Create a new role

1\. Go to **Management > Roles** and click **+** (**New role**).

2\. Enter a valid **Name** (no spaces).

3\. Select the **Level**: **General** or **Admin**. Optionally, enter a **Description**.

4\. Click **Create**.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-44-35-7137-AM.png)

_New role_

Roles are usually associated by domains, departmental, hierarchical, or geographic locations.

Assign and Revoke

Roles are assigned to and revoked from a user on the user's **Details** page.

1\. In **Management > Users**, click **⋮** next to the user and select **Edit**.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-44-37-0683-AM.png)

_User actions_

2\. Under **Roles**, tick a role to assign it to the user, or untick it to revoke it.

3\. Click **Save**.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-44-37-4238-AM.png)

_Assign and revoke roles_

Reset a user's password

Passwords can be changed by the user by clicking their avatar in the top right of the screen and selecting **Change Password**.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-44-35-9876-AM.png)

_Change Password_

To reset a user's password:

<REDACTED> In **Management > Users**, click **⋮** next to the user and select **Edit**.

2\. Open the **Reset password** tab.

3\. Select either **Auto-generate** or **Set a specific password**. If auto-generate is selected, Zetaris creates a secure password.

4\. Click **Reset**. The new password is displayed once.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-44-37-6980-AM.png)

_Reset password_

Otherwise, the admin can reset the password in **Workbench > SQL Workspace** with the following SQL command:

RESET USER PASSWORD 'user\_id' 'new\_password'

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-44-36-8491-AM.png)

_RESET USER PASSWORD in SQL Workspace_
