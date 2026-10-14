# Recipe: PDFs

**Status:** 📋 Planned
**Priority:** 10
**Original research:** `docs/plans/archive/quickstart-data-manifest.md` §6
**Target location:** `pdf/`

## Sources

- 🟢 **U.S. federal government works** — IRS forms, GAO reports; public domain by statute (17 U.S.C. §105). Stable URLs, real multi-page structured documents. Note: embedded third-party images/photos may carry their own rights even when the report text doesn't.
- 🟡 **Project Gutenberg** — public-domain books, PDF per title. Free to copy/reformat/redistribute for out-of-copyright works; strip the PG trademark/header for unrestricted use, or a 20% royalty + redistribution terms apply if keeping the PG name attached.
- 🟡 **SEC EDGAR filings** — free, no auth, documented rate limit (10 req/sec, declared User-Agent). Filings are filer-authored, not government-authored — free access ≠ automatic copyright clearance; fine to demo against live, less appropriate to bundle raw filing PDFs into the repo.

## Goal

Lowest-priority category — good for a PDF-ingestion/RAG-style demo but not central to the "get real data queryable in Zetaris" value proposition. Build after the API/file categories are further along.

## Work items

- [ ] `gov_forms/` — IRS/GAO stable URLs, public-domain notice, note on embedded-image caveat
- [ ] `gutenberg/` — pick a title, use the `.../<id>-pdf.pdf` mirror, PG license notice (trademark-strip vs. royalty path)
- [ ] `sec_edgar/` — fetch script respecting the 10 req/sec rate limit and declared User-Agent, README distinguishing "hit the API live" from "bundle filings in the repo" (don't do the latter)

## Open questions / dependencies

- None blocking — self-contained, no live-Zetaris dependency beyond whatever filestore/REST pattern is used to register the PDFs (decide file-vs-REST registration approach when this is picked up)
