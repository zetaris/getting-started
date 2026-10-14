# Recipe: Streaming — Kafka

**Status:** ⏸ Deferred — do not start until verification below is done
**Priority:** 11 (last, intentionally)
**Original research:** `docs/plans/archive/quickstart-data-manifest.md` §1
**Target location:** `kafka/`

## Why this is deferred

Do not start Kafka or other streaming recipes until a Zetaris installation can ingest from a Kafka broker. The [local installation](../../install/updated_zetaris_installation_guide.md) has been tested, but Kafka ingestion has not. A broker needs more resources than a file table or REST call, and the host must have enough capacity for both Zetaris and Kafka. Confirm ingestion before scaffolding the recipe.

## Sources (for when this is picked up)

- 🟢 **Self-hosted Kafka via Docker Compose** (start here) — Apache-2.0, no signup. `docker-compose.yml` + a producer replaying rows from a Parquet/JSON source, "produce/consume in 5 minutes" README.
- 🟢 **Aiven for Apache Kafka** (hosted free tier) — no card, $0/month, no time limit; 250 KB/s in/out, 3-day retention, no Kafka Connect. Good "point Zetaris at a real remote broker" step once local works.
- 🟡 **Confluent Cloud** — $400/30-day trial credit, not a permanent free tier; optional side trip, not a lasting demo dependency.
- 🔴 Not included: Upstash Kafka (deprecated), Redpanda Serverless (BSL 1.1, unclear free-tier terms).

## Planned producers (once unblocked)

- DONKI space-weather replay (pairs with `nasa/donki_to_kafka/`, built JSON-only for now — see the NASA recipe)
- TfL bus/tube arrival replay (pairs with `uk/tfl_to_kafka/`, same story)
- LTA DataMall replay (pairs with the Singapore recipe, if picked up)

## Work items — blocked, do not start

- [ ] **Verification gate:** confirm Zetaris (either hobby-edition candidate) can actually ingest from a Kafka topic — this is a precondition, not a work item to do alongside the rest
- [ ] Once unblocked: `docker-compose.yml` for local Kafka + one producer + README
- [ ] Once unblocked: Aiven hosted walkthrough
- [ ] Once unblocked: wire up the deferred NASA/TfL/LTA producers from their respective recipes

## Open questions / dependencies

- The install itself is no longer the blocker (`docs/install/updated_zetaris_installation_guide.md`, local docker-compose tested and working) — the remaining hard dependency is confirming Kafka-source ingestion works within that install's resource envelope, which hasn't been attempted
- If Kafka ingestion turns out not to be feasible within the hobby-edition footprint, this recipe may need to be re-scoped (e.g., "produce to Kafka" demo without a Zetaris-side consumer) rather than dropped outright — revisit once the verification gate resolves
