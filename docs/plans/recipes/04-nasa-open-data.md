# Recipe: NASA open APIs

**Status:** 📋 Planned
**Priority:** 4
**Manifest reference:** `quickstart-data-manifest.md` §9
**Target location:** `nasa/`

## Sources

- 🟢 **api.nasa.gov** — 13 of 15 APIs, `DEMO_KEY` works with no signup (30 req/hr, 50/day), free registered key raises to 1,000 req/hr. Standouts: **APOD** (simplest JSON demo), **Mars Rover Photos** (large nested/relational corpus), **NeoWs** (most tabular-shaped, flattens cleanly to SQL), **DONKI** (time-series, good Kafka-replay candidate later), **EONET** (GeoJSON, no map-license question), **EPIC**, **Patents/TechPort**. **InSight Mars Weather** is historical only (mission ended Dec 2022) — static example, not "live data."
- 🟢 **NASA Image and Video Library** — separate API, `images-api.nasa.gov`, no key at all — zero-friction entry point before touching the keyed APIs.
- 🟡 **Exoplanet Archive / SSD-CNEOS** — Caltech/JPL-operated under contract to NASA, no key, citation requested (not required).
- License baseline: U.S. federal government work, not copyrighted (17 U.S.C. §105) — except NASA trademarks/insignia, third-party-marked assets, and personnel likeness, which stay restricted.

## Goal

Build on the REST/JSON recipe's pattern with a richer, better-documented API family — a strong "no key at all → DEMO_KEY → real free key" progression that's good for a self-contained demo without needing any of the government-portal signup uncertainty other categories carry.

## Work items

- [ ] `apod_and_mars_photos/` — DEMO_KEY quickstart, then free api.data.gov key walkthrough
- [ ] `eonet_geojson/` — GeoJSON natural events; note pairing potential with `singapore/onemap` and the Parquet/CSV Overture Maps source
- [ ] `images_api/` — no-key search example against `images-api.nasa.gov`
- [ ] `donki_to_kafka/` — build the DONKI puller now, but defer the actual Kafka replay step until the Kafka recipe is unblocked (see `docs/plans/recipes/11-kafka-streaming.md`); ship the JSON-only version first
- [ ] Carry the trademark/third-party-asset/personnel-likeness caveats into the top-level README's license table, not just this folder's

## Open questions / dependencies

- `donki_to_kafka/`'s streaming half is blocked on the Kafka recipe being unblocked — don't let that block shipping the non-streaming NASA APIs first
- Checked for a CSV/Parquet pull-forward candidate (per the Parquet/CSV recipe's harvesting pass): none found — every NASA source in the manifest is a JSON API, no bulk CSV/Parquet export is documented. NASA's Earthdata Cloud program does host large Parquet/Zarr holdings on AWS in reality, but that's outside what this manifest researched — would need fresh discovery (license, exact bucket/path) before it could be added anywhere, not a promotion of existing content
