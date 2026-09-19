# REST API failure cases

Sources that were investigated and scripted for `open_data/rest_apis/`, but hit a blocking issue that isn't a mistake in the SQL — something in the Zetaris connector, the source API, or the interaction between them. Each one gets its own subdirectory: the original onboarding script (unchanged from its last working state) plus an `ISSUE.md` with the full reproduction steps, evidence, and a root-cause hypothesis for engineering to debug.

These are not included in `sql/`'s main numbered sequence, and are not part of `HOWTO.md`'s "Running the scripts" order. They're kept here rather than deleted so the investigation isn't lost and engineering has a concrete starting point if the underlying issue is ever fixed.

## Index

| Source | Directory | Status | Summary |
|---|---|---|---|
| Singapore data.gov.sg — PM2.5 real-time API | [`singapore_pm25/`](singapore_pm25/) | Blocked | `CREATE LIGHTNING REST TABLE` returned an HTTP 502 on the first (and only) statement run against it. The source API itself is confirmed reachable, requires no special headers or auth, but has a real burst rate limit much tighter than documented — leading hypothesis is the connector issues more than one request per statement (schema introspection, a Data Explorer preview fetch, and/or a retry), tripping that limit. Not confirmed from the Zetaris side. See [`singapore_pm25/ISSUE.md`](singapore_pm25/ISSUE.md). |

## Adding a new failure case

1. Create a subdirectory named after the source (matching the style of its original `sql/NN_name.sql` filename, without the number prefix).
2. Move the source's script into it as-is — don't "fix" it as part of the move, since the point is to preserve the last state that hit the issue.
3. Write an `ISSUE.md` covering: a summary, the environment, what was observed in Zetaris, independent verification against the source API directly (ruling out what it *isn't*), a root-cause hypothesis explicitly marked as unconfirmed where it is, suggested engineering debugging steps, and a recommended action (skip, retry later, or workaround).
4. Add a row to the index table above.
5. Update `../HOWTO.md` and `../rest-api-sources.md` to reflect the source's new status and location.
