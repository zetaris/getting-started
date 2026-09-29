# Known-to-fail sources

Sources that were investigated and scripted for `open_data/rest_apis/`, but hit a blocking issue that isn't a mistake in the SQL — something in the Zetaris connector, the source API, or the interaction between them. Each source's onboarding script (unchanged from its last working state) sits here alongside an `ISSUE.md` with the full reproduction steps, evidence, and a root-cause hypothesis for engineering to debug.

These are not included in `sql/rate_limited/` or `sql/non_rate_limited/`, and are not part of `HOWTO.md`'s "Running the scripts" order. They're kept here rather than deleted so the investigation isn't lost and engineering has a concrete starting point if the underlying issue is ever fixed.

## Index

| Source | Script | Status | Summary |
|---|---|---|---|
| Singapore data.gov.sg — PM2.5 real-time API | [`04_singapore_pm25_create.sql`](04_singapore_pm25_create.sql) | Known to fail | `CREATE LIGHTNING REST TABLE` returned an HTTP 502 on the first (and only) statement run against it. The source API itself is reachable, requires no special headers or auth, but has a real burst rate limit much tighter than documented — leading hypothesis is the connector issues more than one request per statement (schema introspection, a Data Explorer preview fetch, and/or a retry), tripping that limit. Not confirmed from the Zetaris side. See [`ISSUE.md`](ISSUE.md). |

## Adding a new known-to-fail source

1. Move the source's script pair here as-is — don't "fix" it as part of the move, since the point is to preserve the last state that hit the issue.
2. Write (or extend) `ISSUE.md` covering: a summary, the environment, what was observed in Zetaris, independent verification against the source API directly (ruling out what it *isn't*), a root-cause hypothesis explicitly marked as unconfirmed where it is, suggested engineering debugging steps, and a recommended action (skip, retry later, or workaround).
3. Add a row to the index table above.
4. Update `../../HOWTO.md` and `../../rest-api-sources.md` to reflect the source's new status and location.
