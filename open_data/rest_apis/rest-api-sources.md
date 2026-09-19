# REST API Data Sources for Zetaris Quick-Starts

A catalog of REST API sources you can point a small Zetaris deployment at directly via `CREATE LIGHTNING REST TABLE` — no file download, the JSON response becomes a queryable table (raw) plus a flattened `SCHEMASTORE` view (tabular). Each entry lists the license, the exact endpoint pattern, a docs link, and the matching onboarding script in `sql/`.

**License key:** 🟢 open, use it freely (read the note for any attribution requirement) · 🟡 open with a condition worth reading before you build on it · 🔴 not included — see the note for why

**About the SQL:** every `CREATE LIGHTNING REST TABLE` statement registers the raw JSON response as a table; every `CREATE SCHEMASTORE VIEW` flattens it into something query-shaped via `LATERAL VIEW explode(...)`. See `HOWTO.md` for the full syntax reference and confirmed gotchas — most importantly that `CREATE SCHEMASTORE CONTAINER` can only be run once per name (no `IF NOT EXISTS` support).

---

## Quick-reference table

| # | Source | Domain | License | Format | Docs | Onboarding script |
|---|---|---|---|---|---|---|
| 1 | SEC EDGAR XBRL Company Facts | Financial/regulatory | 🟡 Ambiguous (see below) | JSON (array-of-structs) | [EDGAR data access](https://www.sec.gov/search-filings/edgar-search-assistance/accessing-edgar-data) · [XBRL frames API](https://www.sec.gov/edgar/sec-api-documentation) | `sql/01_edgar_company_facts.sql` |

---

## 1. 🟡 SEC EDGAR XBRL Company Facts API

- **What it is:** structured financial facts (revenue, and other US-GAAP tags) extracted from public companies' own XBRL-tagged filings, served as JSON per company/concept via `data.sec.gov/api/xbrl/companyconcept/CIK{10-digit-cik}/us-gaap/{tag}.json`.
- **License:** filings are filer-authored, not government-authored — free API access doesn't automatically mean a copyright/license grant over the extracted facts. Same posture as the SEC EDGAR entry in the main manifest (`quickstart-data-manifest.md` §6, which covers raw filing PDFs — this is the same underlying agency/data family, a different access method: structured XBRL facts instead of PDF documents). Practical guidance: query the live API for a demo, don't bulk-redistribute a copy of the extracted data.
- **Access:** free, no authentication, but SEC requires a declared `User-Agent` (blocks default/missing ones) and caps requests at 10/sec — see [SEC's developer FAQ](https://www.sec.gov/os/webmaster-faq#developers).
- **Docs:** [Accessing EDGAR data](https://www.sec.gov/search-filings/edgar-search-assistance/accessing-edgar-data) · [EDGAR company search](https://www.sec.gov/cgi-bin/browse-edgar) (for confirming a company's current CIK)
- **Shape:** a single JSON object per company/concept; the `units.USD` field is an array of structs (`accn`, `end`, `filed`, `form`, `fp`, `frame`, `fy`, `start`, `val`), not parallel arrays — flattens with `LATERAL VIEW explode(units.USD) AS fact` + dot-access, not `posexplode()`.
- **Live-tested (2026-09-18)** against 7 companies (Apple, IBM, Oracle, Walmart, Target, Ford, Tesla) — see `sql/01_edgar_company_facts.sql` for confirmed gotchas (mixed-case field quoting, a possible response-truncation issue worth verifying per source, and the `CREATE SCHEMASTORE CONTAINER` one-time-only limitation).

---

**See also:** `HOWTO.md` for the Zetaris REST onboarding walkthrough, `../parquet_csv/` for the filestore-table pattern, and the main [Zetaris Quick-Start Data Sources](../../quickstart-data-manifest.md) guide for everything else.
