---
source: kbase
url: https://kbase.zetaris.com/knowledge/product-version-2.3.1.0-21st-july-2023
title: "Product Version 2.3.2.0 (21st July 2023)"
kind: release-note
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 8eba925c9f5db344cbe254ef7203546868e4f74da64607991058890c22330fcc
---
# Product Version 2.3.2.0 (21st July 2023)

### Feature Enhancements

-   Ability to create  [global/user level parameters](https://kbase.zetaris.com/knowledge/zetaris-environment-variables) to avoid friction while migrating Zetaris environments.
-   Ability to read and write to  Google File stores.
-   Query Plan button in the UI enables users to explore the  Logical/Physical query plans.

#### Major Bug Fixes

-   Snowflake database/tables that have same names across multiple schema are now accessible .
-   The data pipeline schema is now getting auto refreshed in the virtual data mart.
    

#### Minor Bug Fixes:

-   Sorting  in alphabetic order has been introduced for all data objects.
    
-   Postgres data source registration has now been defaulted use  "public" schema.
    
-   Fixed the issue where Virtual data pipelines were not being  saved into datamarts.

-   Special character handling for Glue databases (includes \`).
-   Fix applied to VDP validation wherein addition of a Simple DQ step could override virtual column validations.
