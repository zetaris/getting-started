# Hackathon user journey implementation plan

## Goal and scope

Align this repository with a participant journey of prerequisites → connection → one small verified dataset → a chosen project direction → a reproducible demo. The objective remains open-ended. Support both an existing instance and local installation, as confirmed by the user on 1 October 2026.

Use only material in `getting-started`. An installation guide is not a platform distribution or an issued account. Preserve the existing local USL HOWTO edit and EDGAR/PUDL/NOAA guide. Do not change source registration semantics, silently execute multi-statement files, invent platform UI controls, or promote recorded tests into fresh live proof.

## Implementation

- [x] Add `START-HERE.md` with explicit prerequisites, both access paths, a connection route choice, and a small starter.
- [x] Add a first-dataset guide using the existing PUDL energy-code registrations and a bounded query, with PokéAPI as the JSON alternative. Document statement selection and partial reruns.
- [x] Add a connection route guide and a Cursor prompt based on the existing Codex guide. Make missing driver/reference dependencies explicit. Document numeric org-ID discovery using a real authenticated request, with an administrator fallback.
- [x] Add optional analysis, data-product, and application paths with completion signals. Include a small chart example using the existing Python HTTP client and explicit response validation.
- [x] Add one readiness index that links existing source catalogs and recorded evidence, separating active, unverified, known-to-fail, and planned work.
- [x] Add troubleshooting, confirmed shared-instance guidance, an organizer checklist, and a demo template. Event access, support, and judging rules remain decisions for the organizer.
- [x] Make README the short front door, align both source HOWTOs with the starter, fix stale REST counts and the public-S3 AWS-key claim in `.env.example`, and surface the existing advanced guide.
- [x] Check links, source alignment, Python syntax and example behavior, and diffs. Record verification limits below.

## Decisions requiring organizer input

- Both local and existing-instance access must be supported: confirmed.
- Shared event instance: confirmed. Require an assigned team prefix and permissions. Local installation remains supported, without assuming permission to edit another team's objects.
- Support contact, deadline, submission location, and judging requirements: explicitly unresolved. Discord may be used later, but no channel has been supplied. The demo template is a suggested artifact, not an event rule.
- Platform/driver distribution and command-reference delivery: external dependencies; the repo cannot issue access.
- Live acceptance: requires an available authorized instance and a real HTTP query response. Offline checks cannot establish this.

## Verification record

Implemented on `codex/hackathon-user-journey`.

- 177 local documentation links and anchors checked across 19 documents; all resolved.
- Starter filestore DDL compared with the existing PUDL recipe; it matches after substituting the example team database name.
- Current CREATE pair counts checked: 11 REST, seven Parquet/CSV.
- Python renderer syntax checked. Manual offline inputs covered three supported response shapes and six empty/invalid cases, plus HTML escaping and explicit null-unit rendering. These checks do not prove HTTP compatibility or source access.
- `git diff --check` passed.
- A separate read-only review found no material issues in the onboarding instructions, team safeguards, links, or chart validation/escaping.

No platform installation, account provisioning, live SQL, real HTTP response compatibility, DQ, or materialization was verified during this change. Those acceptance steps need the actual event deployment and participant permissions. Existing recorded platform tests remain in their original documents.

The existing EDGAR/PUDL/NOAA guide and local USL HOWTO link are included unchanged so the delivered branch contains the advanced example it links to. No adjacent repository assets were copied. Original registration scripts and query helpers retain their behavior.
