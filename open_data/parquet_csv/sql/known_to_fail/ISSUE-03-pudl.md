# Failure case: Catalyst Cooperative PUDL — dotted S3 bucket name rejected by `CREATE LIGHTNING FILESTORE TABLE`

**Status:** Known to fail — kept out of `sql/`'s main sequence. Not required for this package's goals (the other six sources already cover the Parquet/CSV onboarding pattern needed); kept here as a flagged item for engineering to debug rather than dropped silently.

**Source script:** [`03_pudl_create.sql`](03_pudl_create.sql) (unchanged from its last working state, moved here as-is)

**Reported by:** Michael Hay

---

## Summary

`CREATE LIGHTNING FILESTORE TABLE` against PUDL's public S3 bucket fails. The bucket name itself, `pudl.catalyst.coop`, contains dots — every other source in this package uses a bucket name with no dots (`noaa-ghcn-pds`, `overturemaps-us-west-2`, `ookla-open-data`, `gbif-open-data-us-east-1`, `aws-public-blockchain`) or an S3-compatible endpoint rather than AWS S3 directly (Foursquare, via Source Cooperative). PUDL is the one source in this catalog with a dotted bucket name, and it's the one that fails — confirmed reproducible against the `PATH` as written in `03_pudl_create.sql`:

```
PATH "s3a://pudl.catalyst.coop/stable/core_eia__codes_energy_sources.parquet"
```

**Exact Zetaris error text is not yet captured in this writeup** — if you hit this again, paste the literal error message here so engineering has it verbatim, not just the causal summary below.

## What this is NOT

- **Not a missing-data or access-permission problem.** The same files are directly downloadable from the bucket outside Zetaris (e.g. `aws s3 cp` or a plain `curl`/browser request against the public URL) — the data exists, is public, and is reachable. This is specifically about Zetaris's own S3 filestore connector rejecting the path, not about the source being broken or unavailable.
- **Not resolved by `useS3PathStyleAccess "true"`**, which is already set in `03_pudl_create.sql`. Path-style addressing (`https://s3.region.amazonaws.com/bucket-name/key`, as opposed to virtual-hosted-style `https://bucket-name.s3.region.amazonaws.com/key`) is the standard S3-client fix for exactly this class of problem — a dotted bucket name breaks TLS SNI/certificate matching under virtual-hosted-style addressing — but it does not appear to fix this case in Zetaris.

## Root-cause hypothesis

Zetaris's `CREATE LIGHTNING FILESTORE TABLE` / S3 connector does not accept a literal `.` character in the bucket-name portion of `PATH`, independent of the `useS3PathStyleAccess` setting. This is a narrower, more specific claim than "Zetaris can't read this bucket at all" — every other option in the script (`inferSchema`, `isS3BucketPublic`, `s3Endpoint`) matches the pattern already confirmed working for NOAA and the other sources; the bucket name is the one structural difference. Not yet confirmed by inspecting Zetaris's own connector code or logs — that's exactly what would move this from a hypothesis to a diagnosis.

## A contradiction worth flagging directly to whoever owns Zetaris engineering contact

[`docs/install/zetaris-installation-test-record.md`](../../../../docs/install/zetaris-installation-test-record.md) §6 claims this exact script (`03_pudl_create.sql`, `CREATE LIGHTNING DATABASE PUDL_S3` + `CREATE LIGHTNING FILESTORE TABLE pudl_eia_energy_sources` with the same `PATH`) succeeded, dated 2026-09-24, and that `SELECT * FROM PUDL_S3.pudl_eia_energy_sources LIMIT 10` returned 10 real rows. That record has not been independently re-verified as inaccurate — it's possible something changed between that test and this one (a Zetaris version or connector update, a different deployment/region, or a transient state), not necessarily that the original record was wrong. This discrepancy is itself worth reporting alongside the dotted-bucket-name finding: either the fix regressed, or there's an environment difference worth understanding. See that file's own annotation for the current state of that specific claim.

## Recommended action for this package

Skip `CREATE LIGHTNING FILESTORE TABLE` for this bucket. The other six Parquet/CSV sources already demonstrate the onboarding pattern this package exists to show. If PUDL's specific dataset is needed for a demo:

- Download the target Parquet file(s) directly (confirmed to work) and re-host them somewhere Zetaris can register without a dotted bucket name — a self-hosted S3-compatible bucket with a plain name, or a different storage location entirely.
- Revisit this source directly if Zetaris engineering confirms and fixes dotted-bucket-name handling, or clarifies why the installation test record's earlier run succeeded against the identical path.

## Suggested engineering debugging steps

1. **Reproduce directly against a minimal dotted-name bucket** — confirm whether the failure is specific to `pudl.catalyst.coop` or any bucket name containing a `.`, to rule out something else about this specific bucket (region, ACL nuance, object key characters) being the real cause.
2. **Compare behavior with `useS3PathStyleAccess "true"` vs `"false"`** against the same dotted bucket name — if both fail identically, that rules out path-style addressing as the fix and narrows the search to how Zetaris parses or validates the bucket-name segment of `PATH` itself.
3. **Reconcile against the installation test record** (§6, 2026-09-24) — if that run genuinely succeeded against the identical statement, something changed since then; check connector version history or deployment config differences between that test environment and the one this failure was reproduced in.
4. **Surface a clearer error** if the root cause is confirmed to be dot-rejection specifically — a generic connection failure is much harder to diagnose from the user side than an explicit "bucket names containing `.` are not supported" message.

## References

- Script: [`03_pudl_create.sql`](03_pudl_create.sql)
- [`docs/install/zetaris-installation-test-record.md`](../../../../docs/install/zetaris-installation-test-record.md) §6 — the earlier, contradictory successful-run record
- `../../parquet-csv-data-sources.md` — source catalog entry updated to reflect this status
