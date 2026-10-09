# Organizer checklist

Confirmed for this journey: participants can start a local installation through [Zetaris Cloud](https://www.zetaris.com/cloud), or use an existing platform; the event instance is shared; the objective is open-ended. The [installation guide](../install/updated_zetaris_installation_guide.md#download-and-licensing) covers obtaining the local platform bundle and registry access.

This repo supplies a participant path through [Start here](../../START-HERE.md). The following items require an actual organizer/administrator decision or provisioning step. Documentation cannot create access or validate an unknown deployment.

## Before participants begin

- [ ] Supply the shared instance's actual UI URL and user access through a private channel.
- [ ] Assign each team a unique object prefix and allowed database/container/namespace scope. Provision query/create/read permissions; names alone do not isolate teams.
- [ ] Decide which sources are centrally provisioned read-only and which teams may register themselves. Record their definitions and ownership.
- [ ] Confirm the shared server can reach the starter source and optional fallback. Run the small starter with the **participant role**, not only an administrator.
- [ ] Verify a participant can follow Zetaris Cloud → Start Free → account portal → platform download, obtain the matching configuration and registry sign-in command, and confirm their installation entitlement. Resolve unavailable downloads with Zetaris Support before the event.
- [ ] For JDBC users, supply the endpoint, matching driver JAR, driver class, and any version-specific command reference needed beyond the included starter reference.
- [ ] For HTTP users, confirm supported UI proxy routes and how the numeric org ID is obtained. Do not circulate a shared administrator token.
- [ ] Document compute selection, allowed data volumes, and shared-instance cache/cleanup rules.

## Unresolved event details

| Decision | Current state |
|---|---|
| Support destination | The [event page](https://hackathon.genai.works/event/open-agent-hackathon-2026) links Discord for announcements and post-event activities. Confirm the technical-support destination separately. |
| Submission destination and deadline | The event page lists 27 October 2026, 23:45 UTC as the submission deadline. Follow its current submission instructions. |
| Judging criteria / required deliverables | The event page publishes scoring and official rules. [Demo template](demo-template.md) summarises scoring and provides a reproducibility record; it is not an event rule. |
| Actual access/driver distribution details | Must be supplied for the event; not embedded in this repo |
| Per-team prefixes, permissions, and shared source ownership | Must be assigned and verified by the administrator |

## Verify the handout

- [ ] Check a fresh participant can follow README → Start here → connection → first dataset without an adjacent repository.
- [ ] Exercise both access branches where they will be offered; a local recorded test does not validate the shared deployment.
- [ ] Check the advanced EDGAR/PUDL/NOAA guide is included in the delivered snapshot, and preserve its stated DQ/data limitations.
- [ ] Confirm any application example against a real query response from the event deployment before calling it live-tested.
- [ ] Publish actual support/submission details here and in participant instructions once decided. Keep secrets out of Git.
