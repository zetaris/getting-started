---
source: kbase
url: https://kbase.zetaris.com/knowledge/can-i-increase-the-performance-of-my-queries
title: "Can I increase the performance of my queries?"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 4af7cd1536e0d5b9663318c95f537b431bfb70207f09949927a6cdd91a29e5e7
---
# Can I increase the performance of my queries?

No data is stored within the Cloud Data Fabric.

Every query will interrogate the source system to generate a result.

In some cases the one or more source system can have a very slow response time, causing the Cloud Data Fabric to wait for sufficient data to be received before other data source information can be referenced.

For slow responsive source systems it is useful to cache the data, so that the response is much quicker. Instead of referencing the table, view or file in the source systems, the cached copy can be used.

Reference on how to cache and uncache data can be found in the SQL Guide
