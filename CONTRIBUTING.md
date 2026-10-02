# Contributing

This repo's value is in the detail: every source is traceable to a real license, every script has actually been run, and every documented limitation was hit live, not guessed. These conventions exist to keep that true as more people add to it.

## Before you start

- **Read the package's own docs first.** Each `open_data/*/` package has a `HOWTO.md` (onboarding walkthrough) and a `*-data-sources.md` or `*-sources.md` catalog (per-source license, path, and test status). Match its existing pattern rather than inventing a new one.
- **`docs/guides/zetaris-lightning-sql-companion.md`** is the running list of confirmed Zetaris SQL gotchas and platform limitations. Skim it before writing new SQL — you may be about to rediscover something already documented there.
- **`docs/plans/FUTURES.md`** is the roadmap and priority order. If you're picking up a new category, check it first; don't start on a lower-priority item on the assumption a higher one is done without confirming its live-test status.

## Adding a new data source

1. **Verify the license yourself.** Read the actual license page or terms, not just a badge or a registry's one-line license field. If a registry's license field links to something ambiguous (a code-sample repo, not a data-licensing document), say so explicitly in the catalog entry rather than picking the more convenient reading.
2. **Ship it as a `_create.sql` / `_select.sql` pair**, following the existing numeric-prefix naming in that package's `sql/` directory (e.g. `sql/NN_<name>_create.sql`). The create script registers the logical database and the table(s); the select script has a verification query plus a handful of analytical example queries. Keep script IDs stable once assigned — gaps from retired sources are intentional, not something to fill in.
3. **Give the create script a header comment** stating the source, license, format, docs links, and a listing command to confirm the current path/partition/release before running (most sources here are date- or version-partitioned).
4. **Run it against a real Zetaris instance before claiming it works.** Add the source to the package's catalog table with the correct status:
   - **Verified** — the create script's statements and the select script's queries, including the analytical ones, actually ran successfully against a live instance.
   - **Unverified** — written and believed correct, but not yet run live. This is the default for a new, untested source — don't mark something Verified because the SQL looks right.
   - **Known to fail** — it was run and hit a real blocking issue. See the next section.
5. **Register it in `open_data/manifest.json`.** One entry per create script: `id`, `kind` (`rest`, `filestore` or `usl`), `script`, `status` (matching the catalog), a one-line `summary`, and `requires`, the ids of any sources that must exist first (for example a USL model lists the sources it activates from, and a source that reuses another's database lists that source). Run `python3 scripts/onboard.py --check`; it fails on a missing script, an unknown or circular dependency, or a create script that isn't listed. This is the one place dependency order is recorded, so don't repeat it in prose.
6. **Update the package's `HOWTO.md`** if the new source needs anything the existing walkthrough doesn't already cover (a new auth pattern, a new storage option, etc.).

## Documenting a source that doesn't work

Don't delete a source just because it failed — a reproducible failure with a clear writeup is useful to the next person (and to whoever owns the Zetaris engineering relationship). Follow the `known_to_fail/` pattern already used in `open_data/rest_apis/sql/known_to_fail/` and `open_data/parquet_csv/sql/known_to_fail/`:

1. Move the source's script pair into that package's `sql/known_to_fail/` directory **unchanged** — don't "fix" it as part of the move. The point is to preserve the exact state that hit the issue.
2. Write an `ISSUE-NN-<name>.md` next to it (matching the script's own numeric prefix and name), covering:
   - **Summary** — what fails, and at which step (table registration, caching, or query time are all different failure shapes worth distinguishing).
   - **What this is NOT** — rule out the obvious wrong explanations (missing data, a config typo, a known unrelated issue) with evidence.
   - **Root-cause hypothesis** — explicitly marked unconfirmed where it is. Don't present a guess as a diagnosis.
   - **Suggested engineering debugging steps** — concrete, reproducible next steps for whoever picks this up, not just "investigate further."
   - **Recommended action** — skip, retry later, or a workaround, if one exists.
3. Add a row to that `known_to_fail/README.md`'s index table.
4. Update the package's `HOWTO.md` and catalog doc to reflect the new status and location — remove it from any "suggested order" and point to the new path.
5. If you find a contradiction with an existing record (e.g. an installation test record claiming an earlier successful run of the same statement), don't silently overwrite the old claim or ignore the new one — add an explicit "contradicted by a later run, not yet reconciled" note and flag it for whoever owns the Zetaris engineering relationship.

## Archiving a completed or superseded plan

`docs/plans/` holds active work; `docs/plans/archive/` holds plans that are done, superseded, or never started but no longer being pursued. When a plan's work is confirmed shipped (not just "mostly done"):

1. `git mv` it into `docs/plans/archive/`.
2. Add a banner at the very top: `> **Archived — <status>.**` where `<status>` is honest about what actually happened — `done`, `stable`, `superseded`, or `not started` are all valid; don't write `done` for something with real open items left.
3. Fix the plan's own relative links for the new depth, and fix its top-of-file status line if it's gone stale.
4. Update every other doc that linked to the old path — `docs/plans/FUTURES.md`, the main `README.md`, and any package doc that referenced it.

## After moving or renaming any file

This repo cross-links constantly (catalogs to scripts, scripts to HOWTOs, HOWTOs to the companion guide, and so on). After any move, rename, or deletion, check for broken relative markdown links repo-wide before considering the change done. A quick one-off check:

```bash
python3 - <<'EOF'
import re, os
for root, dirs, files in os.walk('.'):
    dirs[:] = [d for d in dirs if d != '.git']
    for f in files:
        if not f.endswith('.md'):
            continue
        path = os.path.join(root, f)
        text = open(path, encoding='utf-8', errors='ignore').read()
        base = os.path.dirname(path)
        for m in re.finditer(r'\]\(([^)]+)\)', text):
            link = m.group(1).split('#')[0]
            if link and not link.startswith(('http://', 'https://', 'mailto:')):
                full = os.path.normpath(os.path.join(base, link))
                if not os.path.exists(full):
                    print(path, '->', link)
EOF
```

Also grep for bare (non-link) references to the old path in `.sql`, `.ts`, `.py`, and `.json` files — a script's own header comments or a `deno.json` task can reference a path without it ever appearing as a markdown link.

## Adding a confirmed SQL gotcha or platform limitation

If you hit a real, reproducible Zetaris behavior that isn't already in `docs/guides/zetaris-lightning-sql-companion.md` — a syntax limitation, an unexpected error shape, a caching quirk — add it there rather than letting it live only in a commit message or your own notes. Say what you confirmed live versus what's still a hypothesis, and link back to the script or `ISSUE-NN-*.md` that demonstrates it.

## Scripts in `scripts/`

Keep the Deno/TypeScript and Python versions of a helper in sync — same environment variables, same validation, same behavior — and document both together in `scripts/HOWTO.md` rather than documenting one language and leaving the other implicit. Not every script needs both languages (a few are intentionally one-off), but say so explicitly in the doc when that's the case.

## Keeping the main README focused

`README.md` is a map, not a manual. Package-level and script-level getting-started detail belongs in that package's own `HOWTO.md` (or `scripts/HOWTO.md`) — link to it from the README rather than duplicating it there. If you find yourself writing more than a couple of sentences in the README about how to use something, that detail probably belongs in the subordinate doc instead.

## Secrets and generated data

- Never commit `.env.local`, API tokens, or real credentials. `.env.example` documents the variables a script needs; `.env.local` is the one env file the scripts read, and it is gitignored.
- Don't commit anything written to `tmp/cache/` — it's gitignored precisely because fetch scripts write real downloaded data there.
- A test-mode or public-bucket credential is fine to document in a script's own comments (e.g. "no AWS credentials needed, this bucket is public"); a live token or password is never fine to commit.

## Commit messages and PRs

Explain *why*, not just *what* — especially for anything that changes a documented status (marking a source Verified or Known to fail, archiving a plan). If your change was driven by a live test, say so; a reader should be able to tell a confirmed result from a plausible-looking guess by reading the commit message or PR description alone.
