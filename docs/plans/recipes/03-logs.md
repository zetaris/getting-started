# Recipe: Logs

**Status:** 📋 Planned
**Priority:** 3
**Manifest reference:** `quickstart-data-manifest.md` §3
**Target location:** `logs/`

## Sources

- 🟢 **NASA-HTTP access logs** (Kennedy Space Center, 1995) — freely redistributable, two gzipped files (Jul/Aug 1995), standard Common Log Format. Default "ingest raw web logs" example.
- 🟡 **logpai/loghub** — 20+ real system-log datasets (HDFS, Hadoop, Spark, Linux, Apache, Android, BGL, Thunderbird, ...), via Zenodo. Research/academic-use license — requires citing the loghub repo + the ISSRE'23 paper; fine for demos, not for repackaging as a standalone product.
- 🟢 **Elastic's Apache log sample generator** (`elastic/examples`) — Apache-2.0, small and fast. Repo is archived (read-only since Jan 2025) but license/content still valid.

## Goal

A low-complexity category that reuses the filestore-table pattern already proven in Parquet/CSV (these are flat files, not a new Zetaris DDL shape) — mostly download scripts + DDL, good candidate to build quickly once the filestore syntax is settled.

## Work items

- [ ] `nasa_http/` — download script for the two gzipped files, a DDL to register as a filestore table, a grok/parse pattern reference for Common Log Format
- [ ] `loghub/` — download script, explicit citation notice + "research use" banner in the README
- [ ] `apache_sample/` — pull from `elastic/examples`, note the archived-repo status
- [ ] Verify each against a live Zetaris instance using the same filestore-table pattern as Parquet/CSV

## Open questions / dependencies

- Depends on Parquet/CSV's two open items (credential-less S3 access, HTTPS `PATH` support) being resolved first, since these are also file-based sources using the same DDL
