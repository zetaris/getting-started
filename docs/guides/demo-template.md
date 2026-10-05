# Project demo template

Copy this into your project notes after [choosing a direction](project-paths.md). It records reproducibility, not judging requirements. Support, deadlines, and submission location remain [organizer decisions](hackathon-organizer-checklist.md).

## Question and result

- What question or task does the project address?
- What did the actual result show? Include a small result table, chart, or working interface.
- What remains unverified?

## Sources

| Source and actual path/release | Objects owned by your team | Row grain and relevant time period | Attribution and limitations |
|---|---|---|---|
| Fill in the sources you actually used | Use assigned names | State one row represents what | Record source notes and required attribution |

## Reproduce

1. List required platform access and tool versions without credentials.
2. Identify your assigned team prefix and any approved shared objects.
3. Save the exact setup SQL in dependency order, one complete command per execution unit. Explain which objects already exist and which commands may be skipped on rerun.
4. Save the exact query and a named verification query, with actual expected fields/values from your run.
5. Describe how to run the interface, if any, and how errors appear.
6. Record execution time/date, source release, and bounded output. Label source changes, missing values, uncertain joins, partial date coverage, DQ, and materialization honestly.

## Verification boundary

State separately whether you verified login, SQL execution, external rows, transformations/joins, and the final interface. An offline fixture or a successful CREATE is not a completed end-to-end run.

## Handoff and cleanup

Name a teammate who can reproduce the result and the objects your team owns. Leave shared sources intact. Request administrator approval for shared-instance cleanup and follow the [documented lifecycle limits](troubleshooting.md#cleanup).
