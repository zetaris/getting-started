# Recipe: Singapore government open data

**Status:** 📋 Planned
**Priority:** 5
**Original research:** `docs/plans/archive/quickstart-data-manifest.md` §7
**Target location:** `singapore/`

## Sources

- 🟢 **Singapore Open Data Licence (SODL) v1.0** — the umbrella license underneath almost everything below; CC-BY-equivalent, worldwide/perpetual/royalty-free, attribution required (named template in the manifest).
- 🟢 **data.gov.sg** — general-purpose portal, CSV/JSON/GeoJSON/KML/PDF, public REST API, no key needed to test (5 req/min unauthenticated, self-serve key raises it). Real-time JSON examples (weather, PSI/air-quality, rainfall/tide/temperature) — a live-polling demo without needing Kafka.
- 🟡 **LTA DataMall** — real-time transport data (bus arrivals, train alerts, traffic, car parks). Free signup form, no fee mentioned, 10M calls/day. API ToS is separate from the SODL — fine for a live connector, don't bulk-archive raw responses.
- 🟢 **OneMap** (Singapore Land Authority) — geocoding/routing/geospatial, same SODL, free registration. Pairs with LTA DataMall (bus-stop coordinates + live arrivals).

## Goal

Singapore is a geographically distinct but well-organized bundle: one license, mostly JSON/PDF, explicit gaps in Parquet/Kafka/SQL. Treat it as a REST/JSON-recipe consumer with a documented "honest gap" story rather than trying to force a native Parquet/Kafka/SQL example.

The HDB Resale Flat Prices CSV has a fetcher tracked under priority 0. It saves the file locally; there is no Zetaris SQL registration because the local file is not yet available through a supported remote `PATH`. This recipe covers the JSON/REST side while that gap remains open.

## Work items

- [ ] `datagovsg/` — real-time JSON polling examples (weather, PSI/air-quality, rainfall/tide/temperature) + PDF pulls via the initiate/poll-download API, SODL attribution notice baked into the README template (the CSV/tabular pull is handled by the Parquet/CSV recipe — link to it rather than duplicating)
- [ ] `lta_datamall/` — signup walkthrough, bus-arrival JSON polling demo
- [ ] `onemap/` — signup walkthrough, geocoding example paired with LTA data
- [ ] Document the remaining gaps in the folder README: no current Zetaris Parquet/CSV registration, Kafka source, or open remote-SQL source. Link to the fetch-only data.gov.sg work in the Parquet/CSV recipe.

## Open questions / dependencies

- LTA DataMall / OneMap signup eligibility for non-Singapore applicants isn't stated in the request forms — test a signup before committing to this walkthrough as "no friction"
