---
source: kbase
url: https://kbase.zetaris.com/knowledge/elasticsearch
title: "ElasticSearch"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 8ca1b0ab0cd9c11c3802251e39e9983b10caa3b280bdfe958049345998fa809f
---
# ElasticSearch

Zetaris provides access to your ElasticSearch repository through JDBC. The following guide will guide you in establishing a live connection to Zetaris.

[Requirements](#requirements)

[Connect to ElasticSearch via NDP Fabric Builder](#ndp_fabric)

[Connect to ElasticSearch via SQL Editor](#sql_editor)

### Requirements

-   ElasticSearch JDBC Driver

#### Install ElasticSearch JDBC Driver

The ElasticSearch JDBC Driver (.jar file) needs to be uploaded to the Zetaris JDBC Library. This can be done using the following steps. 

The exact location of the JDBC library folder might differ slightly depending on how Zetaris has been installed (kubernetes, non-default etc.)

**Step 1:** Download the [ElasticSearch JDBC Driver](https://www.elastic.co/downloads/jdbc-client)

**Step 2:** Call your Zetaris JDBC Library from the terminal/command line

```
/home/zetaris/lightning-server/jdbc-lib/
```

**Step 3**: Paste the ElasticSeach JDBC Driver in the jdbc-lib/ folder

### Connect to ElasticSearch via NDP Fabric Builder

  
**Step 1:** Click the **Data Fabric Builder** icon.

**Step 2:** Under Database Sources click the '+' next to Virtual Database Source to launch the wizard.

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Nov-17-2022-04-50-01-0214-AM.png)

**Step 3:** When the GUI wizard launches accept the defaults and click **Next**.

**Step 4:** Specify the following values for the connection:

<table style="border-collapse: collapse; table-layout: fixed; margin-left: auto; margin-right: auto; border: 1px solid #99acc2; width: 96.5116%; height: 232px;"><tbody><tr style="height: 27px;"><td style="width: 31.8535%; height: 27px;"><strong>Parameter</strong></td><td style="width: 68.1489%; height: 27px;"><strong>Value</strong></td></tr><tr style="height: 27px;"><td style="width: 31.8535%; height: 27px;">Datasource</td><td style="width: 68.1489%; height: 27px;">Other JDBC</td></tr><tr style="height: 75px;"><td style="width: 31.8535%; height: 75px;">Data Source Name</td><td style="width: 68.1489%; height: 75px;"><p>create a name for the new connection</p><p>NOTE: name cannot contain spaces</p></td></tr><tr style="height: 27px;"><td style="width: 31.8535%; height: 27px;">JDBC Driver Class</td><td style="width: 68.1489%; height: 27px;">org.elasticsearch.xpack.sql.jdbc.EsDriver</td></tr><tr style="height: 75px;"><td style="width: 31.8535%; height: 75px;">JDBC URL</td><td style="width: 68.1489%; height: 75px;"><p>jdbc:es://{host}:{port}/</p><p>Default Port: 9200</p></td></tr><tr><td style="width: 31.8535%; padding: 4px;">Username</td><td style="width: 68.1489%; padding: 4px;"><p>{elasticsearch username}</p></td></tr><tr><td style="width: 31.8535%; padding: 4px;">Password</td><td style="width: 68.1489%; padding: 4px;"><p>{elasticsearch passord}</p></td></tr></tbody></table>

**Additional Parameters**

Other additional connection parameters can be included, check the [ElasticSearch documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/sql-jdbc.html) for information on the exact string detail required. These additional fields include:

-   Timezone
-   SSL
-   Network (connection and query timeout, page size)
-   Proxy
-   Mapping
-   Index (default false)
-   Cluster
-   Error Handling
-   Troubleshooting

Click **'Next'**

**Step 5:** Select the tables you wish to include, or tick the top box for wildcard inclusion that will include all tables, and register further tables once the connection has been made.

Click **'Next'**

**Step 6:** Review and Connect. Once connected your datasource will appear on the left hand-side in your Virtual Database Source connection list.

### Connect to ElasticSearch via SQL Editor

Example connection string below:

```
CREATE DATASOURCE ELASTICSEARCH OPTIONS (  jdbcdriver "oorg.elasticsearch.xpack.sql.jdbc.EsDriver",  jdbcurl "jdbc:es://myelasticsearch.repository:9200",  username "admin",  password "password");REGISTER DATASOURCE TABLES FROM ELASTICSEARCH;
```
