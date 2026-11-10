---
source: kbase
url: https://kbase.zetaris.com/knowledge/ldap
title: "LDAP"
kind: other
lastmod: 2026-10-28
retrieved: 2026-11-10
sha256: 3cad17064f8d2e338c50d39cbe7070a5615a6b315266629d28e27b8626368ad6
---
# LDAP

## Zetaris users can be authenticated and created locally, or Zetaris can be integrated with an existing authentication provider through LDAP, where we are able to synchronise on-boarding of new users.

LDAP Rules

• You cannot assign LDAP users to another LDAP role

• You cannot assign a Zetaris user to an LDAP role

• You can assign an LDAP user to a Zetaris role

To set up the LDAP Configuration:

Log in using a user with an admin role and go to **Management > LDAP**. The page is set up in order: **1\. Connection**, **2\. Users & Groups**, **3\. Enable LDAP**.

1\. Under **Connection**, provide the following LDAP configuration details:

• **Description** (optional): a name for the connection, e.g. Corporate\_AD

• **LDAP URL**: ldap://host:389 or ldaps://host:636

• **Base DN**: e.g. DC=example,DC=com

• **Filter** (optional): e.g. objectClass=person

• **Attribute**: the attribute that holds the user's email address, e.g. mail

• **Principal**: the bind user, e.g. CN=admin,DC=example,DC=com

• **Password**: the bind password

2\. Click **Register**. This will register your details and save them. The next time you won't be asked to enter details again. If you wish to change LDAP details, edit the connection details and register again.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-46-12-6031-AM.png)

_LDAP connection_

3\. Under **Users & Groups**, click **Load** to browse the directory.

4\. Select the chosen LDAP group, then select the users you would like to add to Zetaris, and sync the selected users into the platform.

5\. Under **Enable LDAP**, use the toggle to enable or disable LDAP.

![](https://kbase.zetaris.com/hs-fs/hubfs/undefined-Oct-28-2026-06-46-12-3763-AM.png)

_Users & Groups and Enable LDAP_
