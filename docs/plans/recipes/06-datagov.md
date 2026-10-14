# Recipe: data.gov

**Status:** 📋 Planned
**Priority:** 6
**Original research:** `docs/plans/archive/quickstart-data-manifest.md` §10
**Target location:** `datagov/`

## Sources

- data.gov itself is an index, not a data owner — license depends on contributor type: federal-agency data is public domain (17 U.S.C. §105, no per-dataset check needed); state/local/tribal data needs per-dataset verification.
- 🟢 **Catalog/search API** — v4 API via `api.data.gov` (`X-Api-Key`), same key service as NASA's APIs (§9) — one free key covers both; `DEMO_KEY` works at 30 req/hr.
- 🟢 **USAspending.gov** — federal contract/grant/award spending, no key, CC0-1.0. Large, genuinely relational — a strong real-government alternative to Chinook/Pagila in the SQL recipe.
- 🟡 **U.S. Census Bureau API** — population/economic/demographic data, public domain, but now requires an API key and possibly gates activation to "approved email domains" (unconfirmed — §14 open item).

## Goal

A discovery layer plus two concrete, well-licensed datasets — reuses the REST/JSON recipe's key-handling pattern (shared `api.data.gov` key with NASA) rather than introducing a new auth flow.

## Work items

- [ ] `search_datagov.py` — catalog-API keyword search helper (reuses the NASA-recipe's `api.data.gov` key)
- [ ] `usaspending/` — no-key walkthrough, flagged as the SQL recipe's "real government data" alternative to Chinook/Pagila
- [ ] `census/` — walkthrough with the email-domain-gating caveat called out explicitly; test with a personal email address before writing this up as "just works"

## Open questions / dependencies

- Census Bureau key-activation email-domain gating — confirm directly at signup before publishing the walkthrough
- Shares its API key with the NASA recipe (§4) — sequence so whichever ships first documents the shared-key setup once, and the second just links to it
- Checked for a CSV/Parquet pull-forward candidate: none found — USAspending and Census are both JSON APIs in the manifest's research; USAspending does publish downloadable bulk archive files on its own site in reality, but that's outside what's documented here and would need fresh verification before promoting
