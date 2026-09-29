# Failure case: Singapore data.gov.sg PM2.5 API — HTTP 502 on `CREATE LIGHTNING REST TABLE`

**Status:** Known to fail — kept out of `sql/rate_limited/` and `sql/non_rate_limited/`. Not required for this package's goals (the other sources already cover the JSON-shape range needed); kept here as a flagged item for engineering to debug rather than dropped silently.

**Source script:** [`04_singapore_pm25_create.sql`](04_singapore_pm25_create.sql) (unchanged from its last working state, moved here as-is)

**Reported by:** Michael Hay, 2026-09-19

---

## Summary

Running the first `CREATE LIGHTNING REST TABLE` statement in `04_singapore_pm25_create.sql` against a live Zetaris SQL Workspace returned an HTTP 502, with no other query run beforehand in that session. The underlying API is confirmed reachable and returning valid data via direct `curl` testing, and confirmed not to require any special header or authentication. The leading hypothesis is that the source API's real-world rate limit is far stricter than documented, and that Zetaris's `CREATE LIGHTNING REST TABLE` path (and/or the Data Explorer's background preview of a newly-created source) issues more than one HTTP request for what appears to be a single SQL statement — but this has **not** been confirmed by inspecting Zetaris's own request logs, and is flagged here specifically so engineering can check that from the inside.

## Environment

- Zetaris AI Data Gateway (`cloud.zetaris.com`), SQL Workspace
- Statement run: the first `CREATE LIGHTNING REST TABLE pm25_readings_20260918 FROM SG_DATAGOVSG_REST REQUEST(...)` in `04_singapore_pm25_create.sql`
- Endpoint: `https://api-open.data.gov.sg/v2/real-time/api/pm25?date=2026-09-18`
- No prior query had been run against this endpoint or this Lightning database in the session

## What was observed in Zetaris

- The `CREATE LIGHTNING REST TABLE` statement returned **HTTP 502**.
- The Zetaris SQL Workspace's own query result panel showed **"Success ... No rows returned"** for the statement itself (expected for a DDL statement) — the 502 surfaced separately, as a red `HTTP 502` badge in the Data Explorer sidebar, associated with the newly-created `SG_DATAGOVSG_REST` entry under **File Source & API**.
- This suggests the 502 came from an asynchronous or secondary action (e.g. the Data Explorer trying to preview/sample the new source's schema for display), not necessarily from the synchronous `CREATE TABLE` call itself — the DDL appeared to complete despite the 502 being shown.

## Independent verification of the source API (via `curl`, outside Zetaris)

All testing below was done directly against `https://api-open.data.gov.sg/v2/real-time/api/pm25`, independent of Zetaris, to isolate whether the problem is the API or the Zetaris connector.

**1. The API is reachable and returns valid data:**
```
curl -s "https://api-open.data.gov.sg/v2/real-time/api/pm25?date=2026-09-18" | python3 -m json.tool
```
Returns a well-formed 200 response with 24 hourly readings across 5 regions — no issue with the endpoint or the date parameter in isolation.

**2. No special header, User-Agent, or authentication is required:**

| Request | Result |
|---|---|
| GET, default curl User-Agent | 200 |
| GET, empty User-Agent (`-A ""`) | 200 |
| GET, `Java/17.0.1` User-Agent (mimicking a JVM-based HTTP client) | 200 |
| GET, `Apache-HttpClient/4.5.13 (Java/17.0.1)` User-Agent | 200 |
| GET, explicit `Accept: application/json` | 200 |

This rules out a missing-header or authentication cause for any failure against this endpoint.

**3. `HEAD` requests return 403, but this is unrelated to the 502 seen in Zetaris:**

`curl -I` (a `HEAD` request) against the same URL returns `403` with `x-amzn-errortype: MissingAuthenticationTokenException` — an AWS API Gateway response indicating the route isn't configured for `HEAD`. `CREATE LIGHTNING REST TABLE` in this script specifies `method "get"`, so this shouldn't be in play, but it's recorded here in case it's relevant to how Zetaris's connector probes an endpoint (e.g. a `HEAD` preflight before the real `GET`, which would explain a spurious failure even though the actual data-fetching `GET` works fine).

**4. The real rate limit is much tighter than documented, and recovers quickly:**

The endpoint's docs state a limit of "5 requests/minute." Repeated `curl` testing found the actual behavior is a burst limiter:

```
try 1: HTTP:200
try 2: HTTP:200
try 3: HTTP:200
try 4: HTTP:200
try 5: HTTP:200
try 6: HTTP:429
try 7: HTTP:429
try 8: HTTP:429
```
(each request 1 second apart)

Recovery: a 30-second pause after hitting 429 was sufficient for the next request to return 200 again. The burst window appears to be on the order of single-digit seconds, not the 60-second window the "5 requests/minute" phrasing implies.

## Root-cause hypothesis

**Update (2026-09-19) — a related but NOT equivalent finding from a different source, and why it doesn't fully explain this one:** while testing NASA NeoWs (`sql/05`) the same day, a plain `SELECT` against an already-successfully-created REST-backed view failed with a clean `429`, with NASA's own error body passed straight through by Zetaris (`OVER_RATE_LIMIT`, the exact text NASA's API returns). That's solid proof that a Lightning REST table re-issues a live HTTP request on every query that touches it, not just once at `CREATE` time — see `../../HOWTO.md`, "Troubleshooting / FAQ", for that writeup.

**However, this Singapore case returned a 502, not a 429** — a materially different signature. If the same "repeated request hits the source's rate limit, and the resulting status gets relayed through" mechanism were at play here exactly as it was for NASA, the expected result would be a passed-through `429` with data.gov.sg's own rate-limit error body, the same way NASA's `429` came through intact. A `502` instead suggests something upstream of a clean HTTP response — a dropped connection, a timeout, or a malformed response Zetaris's HTTP client couldn't parse — which is a different failure mode than "the API responded with 429 and that got surfaced as-is." **Do not treat this case as solved by the NASA finding.** The general "repeat requests per query" mechanism is now well-evidenced and almost certainly still relevant here (extra requests are still the most likely reason a strict-limit source like this one fails at all), but the *specific* reason it shows up as a 502 here versus a 429 elsewhere remains an open question, and is exactly the kind of detail that needs Zetaris's own connector logs to resolve, not further inference from a different source's different error.

A single visible SQL statement does not necessarily correspond to a single HTTP request reaching the source API. Plausible sources of multiple requests behind one `CREATE LIGHTNING REST TABLE` statement:

1. **Schema introspection at table-creation time** — the connector may fetch the endpoint once to infer the response schema, separately from fetching the actual data.
2. **Data Explorer background preview** — the sidebar's "File Source & API" panel may independently query the new source to populate a preview, asynchronously from the DDL statement's own execution.
3. **Automatic retry on a transient error** — if the connector retries once (or more) on a non-200 response without backoff, a single real 429 could turn into two or more requests in quick succession, compounding the problem rather than recovering from it.
4. **A `HEAD` preflight before the real `GET`** — if the connector issues a `HEAD` check first (see point 3 above, which independently returns 403 from this API for unrelated reasons), that's an extra request per statement, and a non-200 preflight response could itself be surfaced as a 502 if not handled as advisory-only.
5. **A connection-level failure specific to this endpoint under load** (new, prompted by the 502-vs-429 discrepancy above) — this endpoint sits behind Cloudflare in front of an AWS API Gateway; it's possible that under its very tight rate limit, this particular stack drops the connection or times out rather than returning a clean 429 the way NASA's backend does, and Zetaris's client surfaces that as a 502. This would mean the 502 is a property of *this source's* infrastructure reacting differently to being rate-limited, not a Zetaris-side inconsistency in relaying errors.

None of these have been confirmed by inspecting Zetaris's own connector behavior or request logs — that inspection is exactly what's needed from engineering to move this from a hypothesis to a diagnosis.

## What this is NOT

- Not a missing `User-Agent` or `Accept` header (ruled out directly, see table above).
- Not an authentication requirement (the API is fully public, no key in any form is accepted or required).
- Not a malformed endpoint URL — the identical `?param=value` query-string pattern works without issue for at least one other source in this package (Open Food Facts, `sql/03`, uses `?fields=...` successfully), so query strings in the `endpoint` value are not inherently a problem for Zetaris's REST connector.
- Only one *statement* was run against this source in the reported session — but per the update above, that no longer means only one HTTP request reached the endpoint. This point in the original writeup undersold how easily a single visible action can fan out into several real requests.

## If revisiting this source

Try `CACHE TABLE <logical_datasource_name>.<raw_table_name>;` (e.g. `CACHE TABLE sg_datagovsg_rest.pm25_readings_20260918;`) immediately after the `CREATE LIGHTNING REST TABLE` statement, before anything else touches the table — see `../../HOWTO.md`, "Troubleshooting / FAQ", for the full rationale. This is unconfirmed to actually prevent repeat HTTP calls for a Lightning REST table, but it's the most promising lead so far and costs nothing to try before assuming the source is unusable.

## Suggested engineering debugging steps

1. **Inspect the connector's actual outbound request count** for a single `CREATE LIGHTNING REST TABLE` statement against a REST source — confirm whether it's exactly one `GET`, or whether schema introspection / Data Explorer preview / retry logic adds more.
2. **Check whether a `HEAD` request is issued** as part of connecting to or validating a REST source, given this specific API 403s on `HEAD` while working fine on `GET`.
3. **Check retry/backoff behavior** on a non-2xx response from a REST source — if the connector retries immediately without backoff on a 429, that would explain how a single statement compounds into a repeated rate-limit trip rather than a single isolated failure.
4. **Consider surfacing the real upstream status code** (429, in this case) to the user instead of a generic 502, so a rate-limited source is distinguishable at a glance from an actually-broken one.
5. **Consider a configurable request delay/backoff option** for REST sources known to have strict rate limits, so a script like this one could specify "wait N ms between requests" rather than relying on the source recovering on its own.

## Recommended action for this package

Skip this source. The other 8 REST sources in this package already cover the JSON-shape range this package set out to test (array-of-structs at various nesting depths, a flat non-array nested struct, a top-level array, and two SDMX-family formats) — Singapore's PM2.5 API was a useful additional example of the "fixed struct instead of an inner array" shape, but that shape is not unique to it and isn't blocking anything else in this package's goals. Revisit if:

- Engineering confirms and fixes a connector-side cause (see debugging steps above), or
- A future demo specifically needs this data source and is willing to work around the rate limit manually (e.g. retrying with a deliberate delay, or pre-fetching and caching the response outside Zetaris).

## References

- Script: [`04_singapore_pm25_create.sql`](04_singapore_pm25_create.sql)
- `../../HOWTO.md`, "Troubleshooting / FAQ" — the general "`CREATE LIGHTNING REST TABLE` ... returned an HTTP 502" entry links back here for the full writeup
- `../../rest-api-sources.md` — source catalog entry updated to reflect this status
