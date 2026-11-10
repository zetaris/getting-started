---
source: kbase
url: https://kbase.zetaris.com/knowledge/sql-user-management
title: "SQL User Management"
kind: other
lastmod: 2026-10-28
retrieved: 2026-11-10
sha256: 98c870332e3d411b15d2aebc6c8870f778d5d04a6c89a22839174f47b700ecff
---
# SQL User Management

Zetaris supports the following SQL commands to manage users:

• Add users

• Update user passwords

• Describe and show users

• Delete users

Only Admin users can perform user management commands. Run the commands in **Workbench > SQL Workspace**: enter the command in the editor and click **Execute** (Ctrl+Enter). The output is shown in the **Result** tab.

Add User

ADD USER WITH (

email '<REDACTED>',

name 'someone',

level 'general',

password '1234567'

)

The password must meet the following rules:

• At least 1 punctuation character

• Minimum 8 characters

• At least 1 upper case letter

• No spaces

Update Password

RESET USER PASSWORD 'user\_id' 'new\_password'

Describe User

DESCRIBE USER 'user\_id'

The result returns the user's **name**, **email**, **level**, **organisation\_id**, **isLdap** and **orgId**.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-37-45-5182-AM.png)

_DESCRIBE USER in SQL Workspace_

Show users

SHOW USERS

The result lists all users in the organisation with their **email**, **name**, **level**, **organisation\_name** and **isLdap**.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-37-45-7659-AM.png)

_SHOW USERS in SQL Workspace_

Delete User

DROP USER 'user\_id'
