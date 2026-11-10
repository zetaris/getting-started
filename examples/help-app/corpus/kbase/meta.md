---
source: kbase
url: https://kbase.zetaris.com/knowledge/meta
title: "Accessing your metastore database"
kind: other
lastmod: 2026-11-04
retrieved: 2026-11-10
sha256: 8ce8b1df5603dadcf635ebdeafe973516918a8476c200fbb1e8421b33909e1c9
---
# Accessing your metastore database

Zetaris Enterprise keeps the metadata for its Data Catalog in a metastore. Out of the box, this metastore runs on Apache Derby. If your organisation prefers a different backend, you can configure the deployment to use an external relational database such as PostgreSQL instead.

The metastore serves two purposes:

-   **Metadata repository:** it describes the data sources, schemas, relations and tags defined in the catalog.
-   **Audit trail:** it records a complete log of the queries run through the platform.

Because both are stored in ordinary database tables, you can register them in Zetaris like any other data source and query them directly. The steps below show how.

**Step 1: Register the metadata tables**

Run the following commands to create a data source that points at the metastore, then register all of its tables:

CREATE DATASOURCE derby DESCRIBE BY "Zetaris\_Metadata" OPTIONS (

jdbcdriver "org.apache.derby.jdbc.ClientDriver",

jdbcurl "jdbc:derby://localhost:1527/../metastore/lightning/lightningMetaStore",

username "admin",

password "password"

);

REGISTER DATASOURCE TABLES FROM derby

Once registered, these are the tables you are most likely to use:

-   datasource\_relation\_schema
-   datasource\_relation\_schema\_tag
-   datasource\_relation
-   datasource\_relation\_tag

**Step 2: Register the audit logs**

The query audit trail lives in a separate Derby database. Register it as its own data source:

CREATE DATASOURCE derby\_logs DESCRIBE BY "Zetaris\_Metadata\_logs" OPTIONS (

jdbcdriver "org.apache.derby.jdbc.ClientDriver",

jdbcurl "jdbc:derby://localhost:1527/../metastore/lightning/auditLog",

username "admin",

password "password"

);

    REGISTER DATASOURCE TABLES FROM derby\_logs

**Before you run these commands**

1.  **Check the connection details.** The host, port (1527), paths, username and password shown above are examples. Replace them with the values for your own deployment.
2.  **Using PostgreSQL or another database?** If your metastore is not on Derby, change the jdbcdriver and jdbcurl options to match that database.
3.  **Data source names are up to you.** The names derby and derby\_logs are only labels; pick names that suit your naming conventions.

**Security tip:** avoid leaving default credentials in place on a production metastore, and limit who can query the audit-log tables.
