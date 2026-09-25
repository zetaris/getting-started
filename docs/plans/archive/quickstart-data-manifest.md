# Zetaris Quick-Start Data Sources

> **Archived — dispersed.** This was the original research manifest behind the repo. Its content has since been folded into [`docs/plans/FUTURES.md`](../FUTURES.md) (roadmap/priority order) and each category's [`docs/plans/recipes/*.md`](../recipes/) file (condensed sourcing, license notes, work items, open questions) — those are now the primary reference for planning unbuilt categories. §2 (Parquet, superseded by `open_data/parquet_csv/`) and §13 (Suggested repo layout, superseded by the repo's actual structure — see the top-level README) are stale and should not be used. Everything else is kept here only as the exhaustive backing reference — full URLs, license text, and citations the condensed recipes intentionally left out.

A collection of real, freely available data sources for trying out Zetaris — streaming, files, APIs, databases, and documents you can point a small Zetaris deployment at and start querying within minutes. Every source below is either fully open or open with a specific condition (attribution, non-commercial use, a free signup). Sources that turned out not to be usable are listed too, with a short note on why, so you don't spend time chasing them later.

**License key:** 🟢 open, use it freely (read the note for any attribution requirement) · 🟡 open with a condition worth reading before you build on it · 🔴 not included — see the note for why

---

## Table of contents

1. [Streaming — Kafka](#1-streaming--kafka)
2. [Columnar files — Parquet](#2-columnar-files--parquet)
3. [Logs](#3-logs)
4. [JSON / REST APIs](#4-json--rest-apis)
5. [Queryable SQL RDBMS (and one Mongo option)](#5-queryable-sql-rdbms-and-one-mongo-option)
6. [PDFs](#6-pdfs)
7. [Singapore government open data](#7-singapore-government-open-data)
8. [Finding more datasets — Kaggle & data.world](#8-finding-more-datasets--kaggle--dataworld)
9. [NASA open APIs](#9-nasa-open-apis)
10. [data.gov](#10-datagov)
11. [EU and UK government open data](#11-eu-and-uk-government-open-data)
12. [Canada, Australia, Mexico, and Africa](#12-canada-australia-mexico-and-africa)
13. [Suggested repo layout](#13-suggested-repo-layout)
14. [Known limitations and things worth double-checking](#14-known-limitations-and-things-worth-double-checking)

---

## 1. Streaming — Kafka

### 🟢 Option A (start here): self-hosted Apache Kafka via Docker Compose
Run Kafka itself, locally or in CI, via `docker-compose` — no signup, nothing running outside your machine.
- **License:** Apache License 2.0 — https://github.com/apache/kafka/blob/trunk/LICENSE
- **Signup:** none.
- **Why start here:** no account to create, no free-tier terms to keep an eye on. Good default for a first Zetaris + Kafka test.
- **Try it:** `docker-compose.yml` (Kafka + a Python/`kcat` producer streaming rows from one of the Parquet/JSON sources below), with a "produce/consume in 5 minutes" README.

### 🟢 Option B: Aiven for Apache Kafka (hosted, free tier)
Useful once you want to point Zetaris at a real remote broker instead of one running on your own machine.
- **License of the software:** Apache Kafka itself, Apache-2.0 — Aiven runs stock Kafka under the hood.
- **Free tier:** https://aiven.io/free-kafka — no credit card, $0/month, no time limit on the free plan.
- **Signup:** free email signup, no credit card.
- **Limits:** 250 KB/s in and out, 3-day retention, no Kafka Connect, limited regions, auto-suspends on inactivity (reactivate anytime).
- **Good for:** the "try it against a real hosted broker" step, once local Kafka is working.

### 🟡 Option C: Confluent Cloud (hosted, trial credit — not a permanent free tier)
The most common target in official Kafka tutorials, worth knowing about even though it's not a fit for a permanent quick-start dependency.
- **Trial terms:** https://www.confluent.io/get-started/ — $400 of credit for the first 30 days. Signup wants an email (Google/GitHub/business email accepted).
- **Note:** the credit expires, so treat this as an optional "see how Confluent's own quick start works" side trip, not something to build a lasting demo on.

### 🔴 Not included: Upstash Kafka
Upstash deprecated its Kafka product — see their deprecation notice (https://upstash.com/docs/kafka/connect/deprecation) and blog post (https://upstash.com/blog/workflow-kafka).

### 🔴 Not included: Redpanda Serverless
Redpanda's broker is source-available under BSL 1.1 (not fully open source) for self-hosting, and its current Serverless free-tier terms aren't clearly published (the pricing page routes to sales rather than a plain free-tier spec). Aiven (Option B) already covers the "hosted, no credit card" need with clearer terms.

---

## 2. Columnar files — Parquet

**This category now has its own package.** The Parquet/CSV sources — NYC TLC, NOAA GHCN-Daily, Catalyst Cooperative PUDL, Foursquare Open Source Places, Overture Maps, the Common Crawl columnar index, Ookla Speedtest, GBIF, and AWS Public Blockchain Data — live in the standalone **`zetaris-parquet-quickstart/`** package (delivered as a ZIP alongside this guide). It covers the same ground as the rest of this document, plus:

- `parquet-csv-data-sources.md` — the source catalog, with the exact data URL/path and a docs link per source.
- `sql/*.sql` — nine ready-to-run `CREATE LIGHTNING FILESTORE TABLE` scripts, one per source, each with a verification query.
- `HOWTO.md` — the onboarding walkthrough: Zetaris syntax reference, credential handling for public buckets, and how to run and verify each script.

The Citi Bike trip-history dataset (🔴 not included — its license prohibits hosting or distributing "the Data as a stand-alone dataset," per https://citibikenyc.com/data-sharing-policy) is also documented in that package rather than duplicated here.

---

## 3. Logs

### 🟢 NASA-HTTP access logs (Kennedy Space Center HTTP server, 1995)
The classic "two months of HTTP logs" dataset used in log-analytics tutorials since the 1990s (Internet Traffic Archive).
- **Terms:** https://ita.ee.lbl.gov/html/contrib/NASA-HTTP.html — "The traces may be freely redistributed." The page asks that you treat it as general traffic-pattern data rather than digging into individual-host behavior — a privacy courtesy, not a legal restriction.
- **Download:** two gzipped files (July and August 1995) via the FTP links on that page.
- **Good for:** the default "ingest raw web server logs" example — small, standard Common Log Format.

### 🟡 logpai/loghub (HDFS, Hadoop, Spark, Linux, Apache, Android, BGL, Thunderbird, and 15+ more)
The most comprehensive public collection of real system-log datasets for log-parsing and anomaly-detection work (20+ systems, from a few MB to ~30 GB), distributed via Zenodo.
- **License:** https://github.com/logpai/loghub/blob/master/LICENSE — "freely available for research or academic work," conditioned on citing the loghub GitHub repo and the associated paper (Zhu et al., ISSRE'23).
- **Note:** this is a research/academic-use license, not a general commercial grant — fine for engineering demos and tutorials with the citation kept intact, not for repackaging as a standalone data product.
- **Good for:** log-parsing and log-analytics demos specifically, since it mirrors real production log formats at scale.

### 🟢 Elastic's Apache log sample generator (`elastic/examples`)
A small, well-formed Apache-style access-log sample plus a generator, originally built for Kibana/ELK tutorials.
- **License:** Apache License 2.0 — `https://raw.githubusercontent.com/elastic/examples/master/LICENSE`.
- **Note:** the repo was archived (read-only) by Elastic in January 2025 — content and license are still valid, it just won't get new commits.
- **Good for:** a small, fast "5-minute log ingestion" demo alongside the heavier NASA/loghub sets.

---

## 4. JSON / REST APIs

### 🟢 JSONPlaceholder
A fake but fully functional REST API (posts, comments, albums, photos, todos, users) — the standard "learn REST + JSON" target.
- **URL:** `https://jsonplaceholder.typicode.com/`
- **License:** MIT — https://github.com/typicode/jsonplaceholder
- **Signup:** none — zero-config, free to use.
- **Good for:** the "point a JSON/REST connector at something and get a 200 back in 30 seconds" first example.

### 🟢 PokéAPI
A large, well-modeled JSON REST API over structured game data — good for showing nested/relational JSON.
- **URL:** `https://pokeapi.co/`
- **License:** BSD-3-Clause for the code/API — https://github.com/PokeAPI/pokeapi/blob/master/LICENSE.md
- **Signup:** none. Docs (https://pokeapi.co/docs/v2) confirm no authentication is required and all resources are open; formal rate limiting was removed in 2018.
- **Note:** there's a Fair Use Policy — cache responses locally rather than hammering the API, and don't use it as a load-testing target. The underlying Pokémon names/characters are Nintendo trademarks, fine for a technical demo, not for anything Zetaris-branded.
- **Good for:** flattening nested/array JSON — a single Pokémon record has deeply nested stats/moves/abilities.

### 🟡 Open Food Facts
A large, real-world, crowd-sourced product/nutrition database.
- **URL:** `https://world.openfoodfacts.org/`
- **License:** ODbL (Open Database License) — https://forum.openfoodfacts.org/t/conditions-to-use-the-open-food-facts-api/443 — attribution required, and if you combine it into another database you redistribute, that combined database must also be open (share-alike).
- **Signup:** none, but the API requires a custom `User-Agent` header identifying your app, and has per-endpoint rate limits — use the JSONL/CSV export for bulk access rather than the live API.
- **Good for:** a real-world "messy JSON" example (deeply nested, inconsistent fields) — carry the ODbL attribution requirement into your README if you ship a transformed copy of the data.

### 🔴 Not included: REST Countries (restcountries.com)
Used to be the standard no-auth country-reference API, but the current site (https://restcountries.com/ and https://restcountries.com/plans) now requires an API key even on its free tier. If country/ISO reference data is needed, `countries.dev` is a candidate worth vetting separately.

---

## 5. Queryable SQL RDBMS (and one Mongo option)

### 🟢 Option A (start here): self-hosted PostgreSQL via Docker
The actual PostgreSQL engine, run locally or in CI via the official Docker image, pre-loaded with one of the sample schemas below.
- **License:** the PostgreSQL License, a permissive OSI-approved license — https://opensource.org/license/postgresql
- **Docker image:** the official `postgres` image — https://hub.docker.com/_/postgres/
  ```bash
  docker run --name zetaris-quickstart-pg -e POSTGRES_PASSWORD=example -p 5432:5432 -d postgres
  ```
- **Signup:** none — runs entirely on your machine or CI runner.
- **Try it:** a `docker-compose.yml` that starts Postgres, waits for it to be healthy, then loads the Chinook or Pagila DDL/data automatically on first boot (the official image runs any `.sql`/`.sh` file dropped into `/docker-entrypoint-initdb.d/` on first start).
- **Also worth having:** a hosted option (Neon or Aiven below) for the separate "point Zetaris at a real remote database over the network" case — self-hosted and hosted aren't redundant, they exercise different things.

### Self-hosted sample databases (load these locally or in CI)

| Database | License | License URL | Engines | Notes |
|---|---|---|---|---|
| **Chinook** | MIT | https://github.com/lerocha/chinook-database/blob/master/LICENSE.md | SQLite, MySQL, PostgreSQL, SQL Server, Oracle, DB2 | Digital-media-store schema (artists/albums/tracks/invoices) — the most portable option, with DDL for six engines. |
| **Pagila** (Postgres port of MySQL's Sakila) | PostgreSQL License (BSD-style, stated in the repo README) | https://github.com/devrimgunduz/pagila | PostgreSQL | DVD-rental schema, widely used for join-heavy query demos. |
| **AdventureWorks** | MIT | https://github.com/microsoft/sql-server-samples | SQL Server | Microsoft's flagship sample OLTP/DW database; `.bak` files at https://github.com/Microsoft/sql-server-samples/releases/tag/adventureworks |

### 🟢 Hosted, queryable, no-credit-card options

- **Neon (Postgres, serverless)** — https://neon.com/pricing — permanent free tier, no credit card (100 CU-hours/project/month, 0.5 GB storage, 5 GB egress; compute auto-suspends past the limit rather than charging). A good target for loading Chinook/Pagila and querying it remotely.
- **Aiven for MySQL** — https://aiven.io/free-mysql-database — same no-credit-card, permanently-free model as Aiven Kafka above (1 GB storage/RAM, auto-powers-off on inactivity). Good MySQL target for the Chinook MySQL DDL.
- **MongoDB Atlas M0 (free shared cluster)** — limits at https://www.mongodb.com/docs/atlas/reference/free-shared-limitations/ (0.5 GB storage, 500 connections, 100 ops/sec, 10 GB in/out per 7 days). Whether a credit card is required at signup isn't stated on that page either way — confirm this yourself at signup time rather than assuming. MongoDB's own bundled sample datasets (`sample_mflix`, `sample_analytics`, etc.) aren't published under a clear open-source license — they're meant for use inside Atlas tutorials, not for re-hosting elsewhere. For a clean-license Mongo demo, load the ODbL-licensed Open Food Facts JSON (§4) or Chinook (converted to JSON documents) instead.

### 🔴 Not included: "IBM Telco Customer Churn" dataset
A commonly-circulated customer-churn CSV (7,043 rows, columns like `customerID, gender, SeniorCitizen, ... Churn`) that traces back to IBM's "Telco Customer Churn" sample dataset, originally distributed as a Watson Analytics / Cognos Analytics sample and re-uploaded to Kaggle and GitHub many times since.
- IBM's own GitHub repo for this dataset (`IBM/telco-customer-churn-on-icp4d`) licenses the code under Apache-2.0, but that license doesn't extend to the data file itself.
- IBM's community forum has an open, unanswered thread asking about the dataset's copyright and license (https://community.ibm.com/community/user/discussion/copyright-and-license-of-the-telco-customer-churn-dataset).
- License badges on individual Kaggle mirrors (CC0, etc.) are the re-uploader's own claim, not something IBM granted.
- **Bottom line:** no confirmed license exists for this dataset, so it isn't included here. If a churn-style demo dataset is needed, generate synthetic data with the same shape (a `faker`/`numpy` script producing the same columns with fabricated customer IDs) instead — same demo value, no licensing question, and it doubles as a "generate your own test data" example.

**Starter DDL (Chinook, PostgreSQL flavor excerpt):**
```sql
CREATE TABLE "Artist" (
    "ArtistId" INT NOT NULL,
    "Name" VARCHAR(120),
    CONSTRAINT "PK_Artist" PRIMARY KEY ("ArtistId")
);

CREATE TABLE "Album" (
    "AlbumId" INT NOT NULL,
    "Title" VARCHAR(160) NOT NULL,
    "ArtistId" INT NOT NULL,
    CONSTRAINT "PK_Album" PRIMARY KEY ("AlbumId"),
    CONSTRAINT "FK_AlbumArtistId" FOREIGN KEY ("ArtistId")
        REFERENCES "Artist" ("ArtistId")
);
-- Full DDL + data: https://github.com/lerocha/chinook-database/tree/master/ChinookDatabase/DataSources
```

---

## 6. PDFs

### 🟢 U.S. federal government works (public domain by statute — 17 U.S.C. §105)
- **IRS tax forms** — e.g., `https://www.irs.gov/pub/irs-pdf/f1040.pdf`. U.S. federal government works aren't subject to copyright.
- **GAO reports** — e.g., `https://www.gao.gov/assets/gao-26-900644.pdf`. GAO's copyright page (https://www.gao.gov/copyright) states its products "are not protected by copyright law in the United States and may be copied and distributed in their entirety without permission." Note: some embedded images/photos may carry third-party rights — that covers the report text and structure, not necessarily every embedded image.
- **Good for:** PDF-ingestion / RAG-style demos — stable URLs, real multi-page structured documents (tables, headers, footnotes) to test a PDF parser against.

### 🟡 Project Gutenberg (public-domain books, PDF format available per title)
- **License:** https://www.gutenberg.org/policy/license.html — free to copy, reformat, and redistribute for works no longer under U.S. copyright. If you charge a fee for access to the text, or keep Project Gutenberg's name/trademark attached, a 20% royalty is owed to the Project Gutenberg Literary Archive Foundation and specific redistribution terms apply. Strip the PG trademark/header and the text is unrestricted public domain.
- **Good for:** a free "here's a public-domain PDF to test your parser on" example — pick any title from https://www.gutenberg.org/ and use its `.../<id>-pdf.pdf` mirror where available.

### 🟡 SEC EDGAR filings
- **Access:** https://www.sec.gov/search-filings/edgar-search-assistance/accessing-edgar-data — free, no authentication, bulk access permitted at a documented rate limit (10 req/sec, declared User-Agent, no botnets).
- **Note:** SEC filings are authored by the filing companies, not the government itself, so free access doesn't automatically mean a copyright/license grant over the filer-authored content. Good for a "hit a real government API and parse a real PDF" demo; less appropriate to bundle raw filing PDFs into a repo.

---

## 7. Singapore government open data

Singapore's public-sector data is unusually well-organized: one umbrella license covers almost everything, and most of it is JSON or PDF. There's no native Parquet or Kafka feed and no open remote-SQL endpoint — noted below as a gap rather than skipped over.

### 🟢 The license underneath all of it: Singapore Open Data Licence (SODL) v1.0
- **URL:** https://data.gov.sg/open-data-licence (mirrored at https://www.onemap.gov.sg/legal/opendatalicence.html, https://datamall.lta.gov.sg/content/datamall/en/SingaporeOpenDataLicence.html, and https://www.sla.gov.sg/singapore-open-data-licence/ — same text, reused across agencies)
- **Terms:** a worldwide, perpetual, royalty-free, non-exclusive license to copy, adapt, and exploit the data commercially or non-commercially, including sub-licensing/redistribution — genuinely CC-BY-equivalent.
- **Attribution required:** a conspicuous notice naming the dataset, the source, and linking the license, e.g. *"Contains information from {dataset} accessed on {date} from {source} which is made available under the terms of the Singapore Open Data Licence version 1.0."*
- **Excludes:** personal data, third-party IP embedded in a dataset, and anything implying government endorsement. Data is "as is."
- **Good example of:** what a clean open-data license looks like, worth pointing new users to as a reference.

### 🟢 data.gov.sg — the general-purpose portal (JSON, CSV, GeoJSON, KML, PDF)
- **API:** https://guide.data.gov.sg/developer-guide/api-overview and https://guide.data.gov.sg/developer-guide/dataset-apis/download-dataset — public REST API, no key needed to test (unauthenticated calls capped at 5 requests/minute; a free self-serve key raises the limit).
- **Formats:** most tabular datasets are CSV, JSON, or Excel; some are GeoJSON/KML; some resources are PDF directly through the same download API.
- **Real-time example APIs (JSON, no key needed):** weather forecasts, PSI/air-quality readings, rainfall/tide/temperature station readings — good for a live JSON polling demo without standing up Kafka.
- **Good for:** the JSON section's "real government API, zero friction" example, and the PDF section's "structured government report" example (SingStat publications like the Yearbook of Statistics live at singstat.gov.sg and are also cataloged through data.gov.sg under the SODL).

### 🟡 LTA DataMall — real-time and static transport data (bus arrivals, train service alerts, traffic, car park availability)
- **Terms:** https://datamall.lta.gov.sg/content/datamall/en/api-terms-of-service.html — the data itself is under the SODL; the API access layer has its own Terms of Service on top.
- **Signup:** free "Request for API Access" form (name, email, contact number, company/organization, stated purpose) at https://datamall.lta.gov.sg/content/datamall/en/request-for-api.html. No fee is mentioned.
- **Rate cap:** 10,000,000 calls/day.
- **Note:** the API Terms of Service is separate from the SODL data license — redistributing *derived API responses* is more constrained than redistributing the underlying open datasets. Fine for a live-demo connector; don't bulk-archive and redistribute raw API responses as a standalone dataset.
- **Good for:** the best real-time JSON example with a genuine streaming/polling flavor.

### 🟢 OneMap (Singapore Land Authority) — geocoding, routing, and geospatial layers
- **License:** same SODL — https://www.onemap.gov.sg/legal/opendatalicence.html
- **API signup:** free registration at https://www.onemap.gov.sg/apidocs/register; API Terms of Service at https://www.onemap.gov.sg/legal/apitermsofservice.html.
- **Good for:** pairing with LTA transport data — join bus-stop coordinates (OneMap) against live bus arrivals (LTA DataMall).

### Where this fits, and the honest gaps
- **JSON/REST (§4):** data.gov.sg real-time APIs, LTA DataMall, and OneMap all fit directly.
- **PDF (§6):** SingStat publications and any data.gov.sg-cataloged PDF resource fit directly, and the SODL gives an explicit redistribution right (with attribution) — safer to bundle than SEC filings.
- **Parquet (§2):** no native Parquet source. If you want a Singapore-flavored Parquet example, pull a data.gov.sg CSV and add a CSV→Parquet conversion step, same pattern as NOAA GHCN, citing the SODL attribution requirement on the converted file.
- **Kafka (§1) and queryable SQL (§5):** nothing found — Singapore's government portals are file/API-download oriented, not exposed as a live broker or an open remote-queryable database.

---

## 8. Finding more datasets — Kaggle & data.world

Neither of these platforms is itself a data source with a license — both are hosting/discovery layers where individual uploaders attach their own license claim to whatever they post. Treat anything found this way as a starting point to verify independently, not as pre-cleared.

### 🟡 Kaggle — usable, with one thing to check every time
- **Platform terms:** uploaders retain ownership of what they post and pick a license from a standard list (CC0, CC BY, CC BY-SA, CC BY-NC, GPL, ODbL, "Other" with a description, or "Unknown"). Kaggle doesn't vouch for the accuracy of an uploader's license claim.
- **Signup:** a free account is required to download most datasets (no credit card). Browsing/searching doesn't require login.
- **Formats:** CSV and JSON are most common; many datasets also ship as SQLite, and Parquet uploads are supported too.
- **The one rule that matters:** a license badge on a Kaggle listing is the uploader's own claim — it's only trustworthy when either (a) the uploader is the original, authoritative source (an official agency's own Kaggle "Organization" account, or a company publishing its own data), or (b) you can independently trace the underlying upstream source and confirm its license yourself, the same way every other source in this guide was checked. A random re-upload with a confident-looking license badge doesn't meet that bar on its own.
- **Good for:** a discovery index — a place to search for more datasets in a given shape — and for datasets that trace back to a verifiable primary source.

### 🔴 Not included: data.world
data.world was acquired by ServiceNow in 2025, and its Open Data Community was formally retired on July 13, 2026 — the retirement notice (https://data.world/datasets/open-data) states community datasets are no longer downloadable and associated data is being deleted, with no replacement or archive provided. What remains is ServiceNow's enterprise data-catalog product (demo-only, custom pricing), not a source of open datasets.

---

## 9. NASA open APIs

api.nasa.gov covers 15 distinct APIs under one umbrella, most of it public domain, with a mix of "no key at all" and "free key, generous limits" access.

### 🟢 The license underneath most of it: NASA content is a U.S. federal government work
- **URL:** https://www.nasa.gov/nasa-brand-center/images-and-media/ — "NASA content (images, audio, video, and 3D model files) is generally not subject to copyright in the United States" (the same 17 U.S.C. §105 basis as the IRS/GAO entries in §6).
- **Exceptions to know about:**
  - **Trademarks:** the NASA Insignia, Logotype, identifiers, and imagery are not public domain and need separate approval for commercial use.
  - **Third-party-licensed material:** NASA occasionally hosts externally copyrighted content and marks it as such — check individual asset metadata rather than assuming every asset behind an API response is NASA's own.
  - **Personnel likeness:** current employees'/astronauts' names and images can't be used on commercial products or implied endorsements without authorization.
  - NASA's social-media policy (https://www.nasa.gov/nasa-policies-and-guidelines-for-digital-and-social-media/) has language about AI-generated content, but it's narrowly about user comments submitted to NASA's own social channels — it doesn't restrict using NASA's API data or imagery in a data pipeline.

### 🟢 api.nasa.gov — the main portal (13 of the 15 APIs below)
- **Signup:** https://api.nasa.gov/assets/html/authentication.html — built on `api.data.gov`, the general U.S. government API key service; free, no credit card. `DEMO_KEY` works with no signup for initial testing.
- **Rate limits:** `DEMO_KEY` — 30 requests/hour, 50/day per IP. A free registered key — 1,000 requests/hour, shared across all api.nasa.gov endpoints.
- **Standout APIs** (full list of 15 in NASA's `nasa/api-docs` GitHub repo):

| API | What it returns | Good for |
|---|---|---|
| **APOD** (Astronomy Picture of the Day) | JSON metadata + an image/video URL, one record per day back to 1995 | Simplest "hit an API, get JSON back" demo |
| **Mars Rover Photos** | JSON listing of Curiosity/Opportunity/Spirit photos by sol/camera, each with an image URL | Nested/relational JSON with a large corpus |
| **NeoWs** (Near Earth Object Web Service) | Structured asteroid data by date range, or single-object lookup | The most tabular/relational-shaped JSON here — flattens cleanly into a SQL table |
| **DONKI** (space weather) | CME, solar flare, geomagnetic storm events as JSON, queryable by date range | Time-series-shaped JSON — good to replay into the self-hosted Kafka setup from §1 |
| **EONET** (Earth Observatory Natural Event Tracker) | Natural events (wildfires, storms, volcanoes) as GeoJSON | Real-world GeoJSON without a map-data license question |
| **EPIC** | Daily full-disc Earth imagery from the DSCOVR satellite, JSON metadata + image assets | Similar shape to APOD, different subject |
| **Patents** / **TechPort** | NASA's patent portfolio and technology-development project records, as JSON | A structured government dataset that isn't geospatial or weather |
| **InSight Mars Weather** | Per-sol Mars surface weather from the InSight lander | Not recommended as a "live data" example — the InSight mission ended in December 2022, so this endpoint reflects a closed dataset, not a live feed. Fine as a static/historical example. |

### 🟢 NASA Image and Video Library — separate API, no key at all
- **Endpoint:** `https://images-api.nasa.gov` (`/search`, `/asset/{nasa_id}`, `/metadata/{nasa_id}`, `/captions/{nasa_id}`), backing the public images.nasa.gov site.
- **Signup:** none — outside the api.nasa.gov key system entirely.
- **License:** same NASA-content baseline as above, with the same trademark/third-party/personnel-likeness exceptions.
- **Good for:** the zero-friction NASA example — no signup step before moving to a real api.nasa.gov key.

### 🟡 Externally-operated NASA science archives (Caltech/JPL, under contract to NASA)
- **NASA Exoplanet Archive** (`https://exoplanetarchive.ipac.caltech.edu`) and **SSD/CNEOS** (`http://ssd-api.jpl.nasa.gov`) — operated by Caltech/JPL under contract to NASA, no API key needed.
- **Terms:** https://exoplanetarchive.ipac.caltech.edu/docs/acknowledge.html — no usage restriction found, only a requested (not required) citation acknowledging Caltech's operation of the archive.
- **Good for:** structured scientific data with no key needed anywhere.

---

## 10. data.gov

data.gov is an index, not a data owner — most sources elsewhere in this guide (NOAA GHCN in §2, the IRS/GAO PDFs in §6, NASA's APIs in §9) are catalogued through it.

### 🟡 What data.gov actually is
- **URL:** https://data.gov/privacy-policy/ — states plainly that data.gov functions as an index and that once data is downloaded from an agency's own site, responsibility for its quality/timeliness sits with that agency.
- **License, by contributor type** (https://resources.data.gov/licensing-resources/ and https://data.gov/privacy-policy/):
  - **Federal agency data:** public domain under 17 U.S.C. §105, the same basis as the IRS/GAO/NASA entries above.
  - **State, local, and tribal government data:** not automatically public domain — data.gov's own page says these "may have different licensing terms" and need checking per dataset.
- **Practical rule:** federal-agency sources are confirmed public domain with no per-dataset check needed; treat state/local hits as candidates to verify individually.

### 🟢 The catalog/search API
- **URL:** https://resources.data.gov/catalog-api/ — the new v4 API (`https://api.gsa.gov/technology/datagov/v4/`) requires an API key via the `X-Api-Key` header, issued through the same `api.data.gov` service used for the NASA APIs in §9 — one free key works across both. `DEMO_KEY` also works here, at the same 30 requests/hour.
- **What it returns:** metadata (titles, descriptions, resource URLs, organization, format, filters) — a discovery layer pointing at the actual agency-hosted file or API.
- **Good for:** a `search_datagov.py` helper that queries the catalog for a keyword ("parquet," "kafka," "climate") and returns candidate dataset URLs.

### 🟢 Two concrete datasets reachable through it
- **USAspending.gov** (federal contract/grant/award spending data), operated by Treasury's Bureau of the Fiscal Service. API at `https://api.usaspending.gov/` needs no key. Backend license: CC0-1.0 — https://github.com/fedspendingtransparency/usaspending-api/blob/master/LICENSE. A large, genuinely relational dataset (awards, recipients, agencies, sub-awards) — a strong alternative to Chinook/Pagila in §5 when a real-government-data example is wanted.
- **U.S. Census Bureau API** (`api.census.gov`) — population/economic/demographic data, public domain under the same basis. The Bureau now requires an API key for all requests, and some reporting suggests key activation is gated to "approved email domains" — worth confirming directly at signup, since it's not clear from the signup page itself whether a personal email address still works.

---

## 11. EU and UK government open data

Same pattern as Singapore (§7): a small number of umbrella licenses reused across agencies.

### European Union

**🟡 data.europa.eu — the EU-wide catalog**
- **URL:** https://data.europa.eu/en/copyright-notice — the portal's own editorial content is CC BY 4.0, and its metadata (the catalog records) is CC0-1.0. Individual cataloged datasets carry their own licenses, and content involving identifiable private individuals, third-party works, or industrial property (patents, trademarks, logos) is excluded from the blanket reuse policy — check the specific dataset.

**🟢 Eurostat REST API — no key, no registration**
- **Access:** fully public and free, SDMX/REST format, CORS-enabled, e.g. `GET ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/{dataset}?geo=PL`.
- **License:** Eurostat's "Copyright notice and free re-use of data" policy is generally understood to align with the EU's CC-BY 4.0 framework — the policy page itself (`ec.europa.eu/eurostat/about/policies/copyright`) is worth reading directly before relying on that as a hard confirmation.
- **Good for:** the easiest zero-friction JSON API in this guide — no signup, real statistical data.

**🟢 Copernicus Sentinel satellite data**
- **License:** the Sentinel Data Legal Notice (sentinels.copernicus.eu) — "free, full and open access" with reproduction, distribution, public communication, adaptation, and combination with other data all explicitly permitted, commercial use included. Required attribution: `"Copernicus Sentinel data [Year]"` for unmodified data, `"Contains modified Copernicus Sentinel data [Year]"` for anything derived.
- **Good for:** Parquet/GeoParquet-friendly geospatial data — Sentinel is distributed as SAFE/COG/Zarr and converts cleanly, and several third-party mirrors already publish Sentinel indices in Parquet.

### United Kingdom

**🟢 The license underneath almost all of it: Open Government Licence v3.0 (OGL)**
- **URL:** https://spdx.org/licenses/OGL-UK-3.0.html — permits copying, publishing, distributing, transmitting, and adapting the information, commercially or non-commercially, combined with your own product. Attribution required. SPDX confirms compatibility with CC BY 4.0.
- **Excludes:** personal data, information not obtained through official disclosure, public-sector logos/crests/Royal Arms, military insignia, third-party rights the publisher doesn't hold, and patents/trademarks/design rights/identity documents.

**🟢 data.gov.uk** — the UK's CKAN-based catalog, OGL-licensed by default, free to search with no key required for the catalog itself.

**🟢 ONS (Office for National Statistics)** — OGL-licensed, confirmed at https://www.ons.gov.uk/methodology/geography/licences. A few product lines carry extra conditions (Northern Ireland postcode data needs a separate commercial license from Land and Property Services; postcode products carry a Royal Mail copyright notice; UPRN products carry GeoPlace attribution requirements) — check the specific resource.

**🟡 Companies House API — permissive, but not on the OGL**
- Companies House data is released under the statutory basis of the Companies Act 2006 and the Copyright, Designs and Patents Act 1988 / Database Regulations — a different legal mechanism from OGL, confirmed as just as permissive in practice by Companies House's own Service Owner for Get Company Information: "Companies House imposes no rules or requirements on how the information on the public register is used."
- **Signup:** free API key via the Companies House Developer Hub (register a user account, then register an application). No fee is mentioned, consistent with the rest of this section.
- **Good for:** a large, real, relational dataset (UK company register — names, addresses, officers, filing history), a strong SQL-section (§5) candidate alongside USAspending.gov (§10). Worth noting specifically that it's not OGL so it doesn't get mislabeled.

**🟢 Transport for London (TfL) Unified API**
- **License:** OGL v2.0 with TfL-specific amendments — https://tfl.gov.uk/corporate/terms-and-conditions/transport-data-service — commercial use and redistribution permitted. Required attribution: `"Powered by TfL Open Data"`, plus an Ordnance Survey copyright notice where OS-derived data is involved.
- **Signup:** free `app_key` via the TfL API Portal (api-portal.tfl.gov.uk); 500 requests/minute per feed.
- **Note:** scraping the Oyster, Congestion Charging, and Santander Cycles *websites* directly is prohibited by the terms — that's about not circumventing the API, not a restriction on using the API itself.
- **Good for:** live bus/tube arrival data — a strong candidate to replay into the self-hosted Kafka setup, same pattern as DONKI (§9) and LTA DataMall (§7).

---

## 12. Canada, Australia, Mexico, and Africa

### 🟢 Canada
- **License:** Open Government Licence – Canada 2.0 — https://spdx.org/licenses/OGL-Canada-2.0.html — same permissive family as the UK's OGL (§11) and Singapore's SODL (§7): commercial and non-commercial use, copying, modification, and redistribution all permitted, attribution required, standard exclusions for personal information/third-party rights/official symbols.
- **Catalog:** `open.canada.ca` — CKAN-based, OGL-Canada by default.
- **Statistics Canada (StatCan):** its own "Statistics Canada Open Licence" — https://www.statcan.gc.ca/en/terms-conditions/open-licence — same permissive shape, with an added restriction: don't combine StatCan data with other sources to re-identify individuals.
- **Web Data Service (WDS) API:** https://www.statcan.gc.ca/en/developers/wds/user-guide — no key or registration needed, JSON over HTTPS, rate-limited at 50 requests/sec system-wide and 25/sec per IP. Example: `GET https://www150.statcan.gc.ca/t1/wds/rest/getChangedCubeList/2017-12-07`.

### 🟢 Australia
- **License:** Creative Commons Attribution 3.0 Australia by default — https://data.gov.au/data/about — note this is the 3.0 Australia port, not CC-BY 4.0 like most other sources in this guide. Still genuinely permissive; some individual datasets specify their own license instead, so check per-dataset.
- **Australian Bureau of Statistics (ABS) Data API:** https://www.abs.gov.au/statistics/application-programming-interfaces-apis/data-api-user-guide/using-api — no API key required, SDMX-style REST syntax, e.g. `/data/ABS,CPI,1.0.0/M1.AUS.Q?startPeriod=2019&endPeriod=2019-Q1`.

### 🟡 Mexico
- **INEGI (national statistics/geography institute) — 🟢 genuinely clean:** https://www.inegi.org.mx/inegi/terminos.html — confirms free reuse including commercial exploitation, attribution required (*"Source: INEGI, [product name]"*), a transparency obligation to disclose your own transformations. INEGI also publishes its own indicator API (`API del Banco de Indicadores`, inegi.org.mx/servicios/api_indicadores.html).
- **datos.gob.mx (the national portal) — 🟡 unresolved:** the portal has returned errors on repeated fetch attempts, so a portal-wide license statement couldn't be confirmed the way it could for data.gov, data.gov.uk, open.canada.ca, and data.gov.au. Source Mexican data through INEGI (and similarly-verified agencies) rather than assuming datos.gob.mx carries one blanket license.

### Africa — no continent-wide equivalent; three tiers to know about
There's no single "data.gov.africa." Being explicit about the tiers matters here more than anywhere else in this guide.

- **🟢 Tier 1 — World Bank Open Data:** https://data.worldbank.org/summary-terms-of-use — genuinely clean CC BY 4.0, explicit permission to copy, distribute, adapt, display, or include the data in other products commercially or non-commercially, attribution format specified (*"The World Bank: [Dataset name]: [Data source]"*). The API (`https://api.worldbank.org/v2/...`) needs no key at all, e.g. `https://api.worldbank.org/v2/country/ng/indicator/NY.GDP.MKTP.CD?format=json` for Nigeria's GDP. Not African-specific, but the most reliably licensed way to get real African economic/development data, covering all 54 countries with one consistent license — the recommended default here.
- **🟡 Tier 2 — "Open Data for Africa" (Knoema-powered, used by the African Development Bank and many individual country/regional portals — Kenya, the East African Community, AFRISTAT, and others):** the platform's own terms of use (https://opendataforafrica.org/legal/termsofuse) are generic SaaS/user-content terms, not a data-reuse license. Same structural issue as Kaggle in §8 — a shared hosting layer with no platform-wide license; the real terms (if any) belong to whichever government body runs that specific country instance. Check the specific country/agency page rather than treating "it's on opendataforafrica.org" as clearance.
- **🟡 Tier 3 — country portals**, spot-checked with South Africa: `data.gov.za` doesn't offer a blanket license — its about page (http://data.gov.za/about.html) says data is usable "in both commercial and non-commercial ways" but tells users to "check copyright with the data source before starting commercial projects," dataset by dataset.
- **Recommended default:** lead with World Bank Open Data for anything Africa-related that needs a firm license underneath it; treat opendataforafrica.org-hosted and individual country portals as candidates to verify per instance.

---

## 13. Suggested repo layout

```
zetaris-quickstart-data/
├── README.md                     # top-level: what this repo is, license table for all sources
├── kafka/
│   ├── docker-compose.yml        # local Kafka (Apache-2.0), zero signup
│   ├── producer_nyc_trips.py     # replays NYC TLC parquet rows as Kafka events
│   └── README.md                 # + Aiven/Confluent Cloud "hosted" walkthroughs
├── parquet/                       # → the zetaris-parquet-quickstart/ package (see §2):
│   │                              #   parquet-csv-data-sources.md (catalog + direct URLs + docs links),
│   │                              #   sql/*.sql (9 onboarding scripts), HOWTO.md (syntax + setup notes).
│   │                              #   Drop that package's contents in here, or keep it as a sibling
│   │                              #   top-level folder — either works, just don't duplicate it.
├── logs/
│   ├── nasa_http/                # download script + sample DDL/grok pattern
│   ├── loghub/                   # download script, citation notice, "research use" banner
│   └── apache_sample/            # elastic/examples-derived sample (Apache-2.0)
├── json/
│   ├── jsonplaceholder/          # curl/REST examples
│   ├── pokeapi/                  # nested JSON flattening example
│   └── openfoodfacts/            # ODbL attribution notice + bulk export instructions
├── sql/
│   ├── postgres_docker/           # docker-compose.yml, self-hosted Postgres (PostgreSQL License), auto-loads chinook/pagila on first boot
│   ├── chinook/                  # MIT — DDL for 6 engines
│   ├── pagila/                   # PostgreSQL license
│   ├── adventureworks/           # MIT — SQL Server .bak
│   └── hosted/                   # Neon + Aiven MySQL + Atlas M0 setup guides
├── pdf/
│   ├── gov_forms/                # IRS/GAO stable URLs, public-domain notice
│   ├── gutenberg/                # public-domain book PDFs, PG license notice
│   └── sec_edgar/                # EDGAR fetch script, access-vs-copyright note
├── singapore/
│   ├── datagovsg/                # JSON + PDF pulls via the initiate/poll-download API, SODL attribution notice
│   ├── lta_datamall/              # free-signup instructions, bus-arrival JSON polling demo
│   └── onemap/                   # free-signup instructions, geocoding example paired with LTA data
├── nasa/
│   ├── apod_and_mars_photos/      # DEMO_KEY quickstart, then free api.data.gov key walkthrough
│   ├── donki_to_kafka/            # replays DONKI space-weather events into the kafka/ producer from §1
│   ├── eonet_geojson/             # natural-events GeoJSON, paired with singapore/onemap and parquet/overture
│   └── images_api/                # images-api.nasa.gov, no-key search example
├── datagov/
│   ├── search_datagov.py           # catalog-API keyword search helper (shares the api.data.gov key from nasa/)
│   ├── usaspending/                # CC0, no-key federal spending API — SQL-section alternative to Chinook/Pagila
│   └── census/                     # api.census.gov walkthrough + the email-domain note from §10
├── eu/
│   ├── eurostat/                   # no-key REST example
│   └── copernicus_sentinel/        # attribution-string helper ("Copernicus Sentinel data [Year]"), parquet conversion notes
├── uk/
│   ├── datagovuk_and_ons/          # OGL v3.0 notice, catalog search example
│   ├── companies_house/            # free API key walkthrough, explicit "not OGL" license note, SQL-section candidate
│   └── tfl_to_kafka/               # free app_key walkthrough, replays bus/tube arrivals into the kafka/ producer from §1
├── canada/
│   ├── statcan_wds/                 # no-key WDS API walkthrough, OGL-Canada + StatCan Open Licence notice
│   └── open_canada_catalog/         # open.canada.ca CKAN search example
├── australia/
│   ├── abs_data_api/                # no-key SDMX-style API walkthrough
│   └── datagovau_catalog/           # CC-BY 3.0 AU notice (the older CC version, not 4.0)
├── mexico/
│   └── inegi/                       # INEGI terms + Banco de Indicadores API — recommended over datos.gob.mx directly
├── africa/
│   ├── worldbank_api/               # no-key CC-BY 4.0 API — the recommended default for Africa-wide data
│   └── sourcing_notes.md            # the three-tier trust note from §12 (World Bank vs. opendataforafrica.org vs. country portals)
├── platform_sourcing_notes.md      # Kaggle verification rule + data.world note (§8)
└── LICENSE-NOTES.md               # the full per-source license table from this guide
```

---

## 14. Known limitations and things worth double-checking

A short list of items where the guide's own confidence is lower than the rest — worth a quick check yourself before depending on them in a live demo:

- **MongoDB Atlas M0 credit-card requirement** — not confirmed either way in official docs; check at signup.
- **Redpanda Serverless pricing** — current free-tier terms aren't clearly published; Aiven Kafka is the safer hosted default for now.
- **Country reference data** — restcountries.com now requires an API key; `countries.dev` is a candidate for a replacement, not yet checked.
- **SEC EDGAR & NYC TLC** — both freely accessible, but licensing status is non-trivial; point to the source rather than re-hosting a copy, as §13's layout already does.
- **Kaggle finds** — any specific Kaggle-hosted dataset you add later still needs its own license trace (§8's rule) before it goes in.
- **LTA DataMall / OneMap signup eligibility** — the request forms don't state whether non-Singapore applicants are accepted; worth a test signup before assuming international access works.
- **Singapore's Parquet/Kafka/SQL gap** — no native source in those three categories (§7); the practical path is a CSV→Parquet conversion or replaying an LTA DataMall feed into Kafka.
- **InSight Mars Weather (§9)** — the mission ended in December 2022, so this endpoint reflects historical, not live, data.
- **Exoplanet Archive / SSD-CNEOS citation (§9)** — a requested citation, not a hard license condition, based on the acknowledgment page rather than a formal terms-of-use document.
- **Census Bureau "approved email domains" (§10)** — the Census API's key-activation email-domain gating isn't confirmed to accept personal email addresses; test before assuming.
- **Eurostat's copyright policy text (§11)** — the policy page itself is worth reading directly; this section's CC-BY-4.0 alignment is based on data.europa.eu's own policy and third-party corroboration rather than that specific page.
- **Companies House and TfL free-tier confirmation (§11)** — both appear to be free with no fee mentioned, but neither has an explicit "this is free" statement the way Aiven or Neon does.
- **datos.gob.mx (§12)** — the Mexican national portal's license terms couldn't be independently confirmed; source through INEGI instead.
- **"Open Data for Africa" instances (§12)** — the shared platform's terms don't establish a license; a specific country instance may have its own clear terms and would need its own check.
- **Australia's CC-BY 3.0 vs. 4.0 (§12)** — data.gov.au's blanket default is the older 3.0 Australia port; some individual datasets may specify 4.0 instead. Not a practical problem, just worth citing the right version.
- ~~Zetaris onboarding SQL — two open items (credential-less S3 reads, HTTPS `PATH` support)~~ — **resolved**, see `open_data/parquet_csv/HOWTO.md` and `docs/plans/recipes/00-parquet-csv.md`: no credential-less S3 reads (real IAM keys required), and HTTPS `PATH` is not supported (`s3a://`/`wasb://`-style paths only).
