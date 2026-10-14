# Recipe: EU government open data

**Status:** 📋 Planned
**Priority:** 7
**Original research:** `docs/plans/archive/quickstart-data-manifest.md` §11 (European Union subsection)
**Target location:** `eu/`

## Sources

- 🟡 **data.europa.eu** — EU-wide catalog; portal's own editorial content CC BY 4.0, metadata CC0-1.0, but individual datasets carry their own licenses — check per dataset, and note the carve-out for identifiable individuals / third-party works / industrial property.
- 🟢 **Eurostat REST API** — no key, no registration, SDMX/REST, CORS-enabled. License understood to align with CC-BY 4.0 but the policy page itself is worth reading directly before treating that as confirmed (§14 open item). Zero-friction JSON API.
- 🟢 **Copernicus Sentinel satellite data** — "free, full and open access," commercial use included, specific attribution strings required for unmodified vs. modified data. Parquet/GeoParquet-friendly — several third-party mirrors already publish Sentinel indices in Parquet.

## Goal

Eurostat gives a zero-friction REST/JSON example. The Copernicus Sentinel Parquet angle has been pulled forward — see below — leaving this recipe focused on Eurostat plus the remaining Copernicus documentation (attribution strings, licensing) that isn't itself a Zetaris table.

The Sentinel-2 candidate is `portolan-mirrors/sentinel-2-catalog`, a third-party GeoParquet STAC mirror hosted on Source Cooperative. It is not scripted. Confirm the current path and license before adding it to the Parquet/CSV catalog. This recipe retains Copernicus attribution guidance and Eurostat documentation.

## Work items

- [ ] `eurostat/` — no-key REST example, README noting the copyright-policy-page caveat rather than asserting CC-BY 4.0 as fully confirmed
- [ ] `copernicus_sentinel/` — attribution-string helper (unmodified vs. modified variants) and a pointer to the pulled-forward Sentinel-2 GeoParquet source in the Parquet/CSV recipe, rather than re-implementing it here

## Open questions / dependencies

- Read Eurostat's actual copyright policy page before finalizing the license claim in the README (currently "generally understood to align," not independently confirmed)
- The Sentinel-2 GeoParquet pull-forward still needs its exact current path confirmed against Source Cooperative before it's scripted (tracked in the Parquet/CSV recipe, not duplicated here) — and being a third-party mirror rather than an official source, worth re-checking it's still maintained when this is picked up
