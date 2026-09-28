# Recipe: Canada, Australia, Mexico, and Africa open data

**Status:** 📋 Planned
**Priority:** 9
**Original research:** `docs/plans/archive/quickstart-data-manifest.md` §12
**Target location:** `canada/`, `australia/`, `mexico/`, `africa/` (four folders, one combined recipe since each is individually small)

## Sources

- 🟢 **Canada** — Open Government Licence – Canada 2.0 (permissive family, same shape as UK OGL / Singapore SODL). `open.canada.ca` CKAN catalog. Statistics Canada has its own Open Licence (adds a no-re-identification restriction) and a no-key WDS API (50 req/sec system-wide, 25/sec/IP).
- 🟢 **Australia** — CC-BY 3.0 Australia by default (not 4.0 — note the version explicitly). `data.gov.au` catalog; ABS Data API, no key, SDMX-style REST.
- 🟡 **Mexico** — INEGI is 🟢 genuinely clean (free reuse incl. commercial, attribution required, transparency-on-transformation obligation), with its own indicator API. `datos.gob.mx` (the national portal) is 🟡 unresolved — portal errors prevented confirming a blanket license; source through INEGI instead.
- **Africa** — no continent-wide equivalent, three tiers: 🟢 Tier 1 World Bank Open Data (clean CC BY 4.0, no-key API, covers all 54 countries — the recommended default), 🟡 Tier 2 "Open Data for Africa" / Knoema-powered country portals (generic SaaS terms, no platform-wide license — check per instance), 🟡 Tier 3 individual country portals (spot-checked with South Africa's data.gov.za — usable but tells users to check copyright per dataset).

## Goal

Four smaller regional categories, each cleanly no-key/low-friction except where flagged — bundle into one recipe/PR-sized unit of work rather than four separate efforts, but keep them as separate top-level repo folders per §13's layout.

## Work items

- [ ] `canada/statcan_wds/` — no-key WDS API walkthrough, OGL-Canada + StatCan Open Licence notice (with the re-identification restriction called out)
- [ ] `canada/open_canada_catalog/` — CKAN search example
- [ ] `australia/abs_data_api/` — no-key SDMX-style API walkthrough
- [ ] `australia/datagovau_catalog/` — CC-BY 3.0 AU notice, explicit "3.0 not 4.0" callout
- [ ] `mexico/inegi/` — INEGI terms + Banco de Indicadores API walkthrough, explicit note to avoid datos.gob.mx directly
- [ ] `africa/worldbank_api/` — no-key CC-BY 4.0 API, the recommended default
- [ ] `africa/sourcing_notes.md` — the three-tier trust note, so anyone adding a country-specific African source later checks the right tier first

## Open questions / dependencies

- None blocking — all four are self-contained, no-key or low-friction, and don't depend on other recipes landing first
- Checked for a CSV/Parquet pull-forward candidate: none found — StatCan WDS, ABS, INEGI, and World Bank are all JSON/SDMX APIs in the manifest's research, no bulk CSV/Parquet export documented for any of the four
