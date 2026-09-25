# Recipe: UK government open data

**Status:** 📋 Planned
**Priority:** 8
**Original research:** `docs/plans/archive/quickstart-data-manifest.md` §11 (United Kingdom subsection)
**Target location:** `uk/`

## Sources

- 🟢 **Open Government Licence v3.0 (OGL)** — the umbrella license for almost all of it; permissive, attribution required, standard exclusions (personal data, crests/insignia, third-party rights, IP).
- 🟢 **data.gov.uk** — CKAN-based catalog, OGL by default, no key for the catalog itself.
- 🟢 **ONS** — OGL-licensed; a few product lines (NI postcode data, Royal Mail postcode notices, UPRN/GeoPlace attribution) carry extra conditions — check per resource.
- 🟡 **Companies House API** — permissive but *not* OGL (Companies Act 2006 / Copyright, Designs and Patents Act 1988 basis instead); free API key via the Developer Hub. Strong relational SQL-recipe candidate alongside USAspending.gov.
- 🟢 **Transport for London (TfL) Unified API** — OGL v2.0 + TfL amendments, commercial use/redistribution permitted, specific attribution string required. Free `app_key`, 500 req/min/feed. Good Kafka-replay candidate later (same pattern as DONKI and LTA DataMall).

## Goal

Pairs a straightforward catalog/statistics pattern (data.gov.uk, ONS) with two richer sources: Companies House (a SQL-recipe-worthy relational dataset) and TfL (a REST/JSON source with future streaming potential).

## Work items

- [ ] `datagovuk_and_ons/` — OGL v3.0 notice, catalog search example
- [ ] `companies_house/` — free API key walkthrough, explicit "this is not OGL" note in the README so it doesn't get mislabeled; flag as a candidate to cross-list in the SQL recipe
- [ ] `tfl_to_kafka/` — build the JSON polling half now; defer the actual Kafka replay until the Kafka recipe is unblocked (see `docs/plans/recipes/11-kafka-streaming.md`)

## Open questions / dependencies

- `tfl_to_kafka/`'s streaming half shares the same Kafka-recipe dependency as the NASA DONKI recipe — sequence both against whichever Kafka work happens first
- Checked for a CSV/Parquet pull-forward candidate: none found — data.gov.uk/ONS, Companies House, and TfL are all catalog/API-shaped in the manifest's research, no bulk CSV/Parquet export documented
- Companies House and TfL both appear to be free with no fee mentioned anywhere in their docs, but neither has an explicit "this is free" statement the way Aiven or Neon does — confirm at signup before writing either walkthrough as a flat "no cost"
