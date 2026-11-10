---
source: kbase
url: https://kbase.zetaris.com/knowledge/setup-jdbc-driver
title: "Setup JDBC Driver"
kind: other
lastmod: 2026-11-02
retrieved: 2026-11-10
sha256: ba24086693b499feb5f651c2a832e495a4b80f82190c5370970448c7be230b37
---
# Setup JDBC Driver

## How to connect to Zetaris via JDBC.

There is no installation required for the JDBC driver, you only need it to be loaded into the correct location. Gain access to the JDBC driver (.jar file) by downloading the file here [JDBC Driver](https://kbase.zetaris.com/hubfs/ndp-jdbc-driver-2.4.3.1-driver.jar).

### Zetaris Enterprise (on-prem)

For Zetaris Enterprise (on-prem), the JDBC URL is of the format:

```
jdbc:zetaris:lightning@[Zetaris Server IP]:[Port]
```

The port by default is 10000 for enterprise.
