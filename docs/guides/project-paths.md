# Choose what to build

Start after [your first dataset](first-dataset.md) returns real rows. These are optional project directions, not event requirements. Use a source that fits your question and check [readiness](recipe-readiness.md) before adding it.

## Analyze a question

Begin with the PUDL energy-code aggregation in the starter, or the analytical examples in a matching `_select.sql` after creating their dependencies.

1. Write one question the available fields can actually answer.
2. Inspect the fields and row grain, then filter or aggregate.
3. Save the SQL and real output. Compare a few rows with the source before drawing a conclusion.
4. Explain one finding and one limitation.

Possible extension: compare fuel-unit categories in the reference codes. This does not measure electricity generation. To study generation, first register and verify the optional generator table and inspect its fields; do not infer a generation metric from reference codes.

Done means your query answers the stated question with an inspected result, not just a table screenshot.

## Combine sources into a data product

Choose a second source and describe the join key, row grain, and missing-match behavior before joining. Avoid matching companies and utilities by name alone.

Existing paths:

- [VDM and USL in the SQL companion](zetaris-sql-companion.md): concepts, consumption, and known limits. VDM creation is described as GUI work; a queryable table is not itself a VDM.
- [EDGAR+SIC USL contrast](../../open_data/usl/HOWTO.md): simple lifecycle followed by relationships and DQ. The package is marked pending final confirmation.
- [EDGAR/PUDL/NOAA walkthrough](create-edgar-pudl-noaa-usl.md): source registration, schema/key checks, caching, compile, activation, and a joined query. Its recorded weather window is partial and its DQ result is unverified.

These guides use fixed sample names. On the shared instance, replace databases, SchemaStore containers, namespaces, model names, and **all** references consistently with your assigned names. Use an existing shared source only when the administrator confirms its definition and your read permissions. Do not execute cleanup blocks on shared objects.

Done means the joined output has the intended grain and you can explain duplicates, unmatched rows, period coverage, and any unverified DQ or materialization step.

## Build an application or chart

Use [the small PUDL chart example](../../examples/pudl-chart/README.md) to move from one query to a local HTML chart through the existing Python HTTP helper. It does not need a frontend framework or hosting account. It validates its input and keeps platform credentials in the local Python process.

Start with the verified starter table. Change the query to answer your own question, then decide what interaction or presentation helps a reader use the result. Browser-only code must not contain platform credentials; a deployed app requires its own approved server-side access and authentication design.

Done means real query data appears in the interface and errors are visible. An offline response fixture verifies rendering only, not platform access.

## Finish

Use the [demo template](demo-template.md). Save the setup and query, identify your actual source/release, and state your limits. The [organizer checklist](hackathon-organizer-checklist.md) records event details still needing confirmation.
