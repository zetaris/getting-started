# Object store test kit: `systems/object_stores/` and partner packaging plan

**Status:** decisions resolved (see the last section). All six phases are done on branch `systems-object-stores` (29 to 30 October 2026) and await review.

## Goal and scope

Turn the one-off S3-compatible test we ran by hand into a reusable Zetaris tool for testing and documenting how Zetaris stores data on S3-compatible object stores from storage partners.

1. **A home in the repo.** A top-level `systems/` folder for "Zetaris running on, or against, a specific class of system", with `systems/object_stores/` as the first. It holds the documentation, the viewer and everything specific to storing USL data on an object store.
2. **Vendor-neutral by construction.** No partner or product name lives in the repo. The names enter only at build time, from `.env.local`.
3. **A packaging script.** It reads `.env.local`, builds a partner-specific bundle from the repo, checks it for leaks and writes a ZIP under `dist/`.
4. **A generic, Zetaris-branded viewer.** It replaces the partner-styled one. Product names are injected, and the look follows the Zetaris light theme.
5. **Generic docs and settings** for every S3-compatible store, not only the first one we tested.
6. **A conformance report.** One command runs the steps in order and writes a PASS, FAIL or SKIP matrix a partner can send back as a single file.

Out of scope: running the test against any new store (that is what the tool is for), changing platform behavior, publishing the new docs on the Pages site (deferred until this work is done), and the partner results themselves.

## Where we start

Everything below already exists and was run once, end to end, against one store: a probe, a storage-setting helper, a `MATERIALIZE` helper, a bucket verifier, a source-to-Parquet chain verifier, a cleanup tool, a viewer with a live SQL tab, and a hand-built package. What is wrong for reuse:

| Problem | Where | Fix in this plan |
|---|---|---|
| Path-style addressing and the region `us-east-1` are hard-coded in four helpers (`verify_bucket`, `verify_chain`, `cleanup_bucket`, `materialize_usl_table`) | `scripts/s3_compat/` | One shared settings module; `S3_ADDRESSING` and `S3_REGION` |
| `--ca-bundle` exists on most scripts but not on `materialize_usl_table.py` | same | The same module reads `S3_CA_BUNDLE` for every script |
| The package is assembled by a hand-written build script in a scratchpad that rewrites paths and copies files by name | not in the repo | A real packager in the repo; the package keeps the repo's own paths, so nothing is rewritten |
| The package's `scripts/zetaris_sql.py` differs from the repo's (query results carry column names, for the live SQL tab) | `dist/` | Move that change into the repo's `scripts/zetaris_sql.py` so package copies are unmodified |
| The viewer, README, HOWTO and `.env.example` name one vendor and its logo (16 + 12 mentions) | `dist/` | Templates with injected names; generic defaults |
| The viewer's Proof tab holds a baked capture of one real run, with that run's bucket and folder | `dist/` | A placeholder-only example fixture, labeled as an example |
| The viewer's look follows a partner's site | `dist/` | The Zetaris light theme |

## Findings that shape the design

**Zetaris light theme** (read from zetaris.com on 29 October 2026; the site renders dark by default and has a real `data-theme="light"`, which I switched on and looked at):

| Token | Value | Use |
|---|---|---|
| `--z-bg` | `#FFFFFF` | Page |
| `--z-bg-raised` | `#F3F5FE` (Indigo Tint) | Cards, table stripes |
| `--z-bg-sunken` | `#FAFAFC` | Code and result wells |
| `--z-text` / muted / subtle | `#06070D` / `#595E6E` / `#8B90A0` | Text |
| `--z-hairline` / firm | `#E7E7EE` / `#D5D5E0` | Borders |
| `--z-accent` / hover | `#4052F2` / `#2F3EC2` | Primary buttons, links, active tab |
| Indigo soft / mist | `#7C89F7` / `#DBE0FD` | Secondary fills, selection |
| Cyan, violet, lime | `#27A7D2`, `#8B5CF6`, `#C0F961` | Diagram accents only |
| Success / warning / danger | `#15C46B` / `#F0A020` / `#EF4444` | PASS / INFO / FAIL |
| Radii | 8 / 12 / 20 px | Controls / cards / panels |
| Shadow | `0 8px 24px -4px rgba(64,82,242,.18), 0 2px 6px rgba(6,7,13,.2)` | Raised panels |
| Type | Plus Jakarta Sans (H1 800, H2 700, body 400, 1.55 leading); JetBrains Mono for code | |
| Eyebrow | 700, uppercase, 0.16 em tracking, indigo | Section labels |

Treatment on the light page: filled indigo pill primary buttons, outlined pill secondary buttons, an indigo uppercase eyebrow above a tight heavy headline, and dark panels for product and code content set into the white page. `website/BRANDING.md` already records the guide's palette, the self-hosted font and the logo rules (unchanged SVGs, no recoloring). The plan reuses `website/assets/brand/zetaris-indigo.svg` and the self-hosted font files unmodified, and bundles the font's license text.

**What a different store can change** (these are the axes to expect, not claims about any named vendor; each has to be verified per store):

- Addressing style (path versus virtual-host) and whether the region name is checked.
- A private or enterprise certificate authority. The probe runs on your machine, but the Zetaris engine host must also trust the chain, and may not.
- Network reachability from the engine host, which can differ from your machine. A passing probe does not prove the engine can reach the store, so the `MATERIALIZE` step is the real test.
- Checksum and chunked-upload behavior (we hit this once: `when_required`), the signature version, multipart limits, batch delete, and list version support.
- Object lock or retention. `cleanup_bucket.py` cannot delete under retention and must say so plainly.
- Rename and commit semantics, which the Hadoop S3A writer depends on. Row counts that match but with missing or duplicate part files would show here.

**One Zetaris behavior to write up for engineering.** `MATERIALIZE USL TABLE` ignores the credentials of the saved storage setting, and needs them inside `optionsBase64`. That may be a bug or by design. The plan adds a short, reproducible write-up in the repo's usual issue format (see `CONTRIBUTING.md`) so engineering can say which. Credentials in the statement may also land in query history.

## Target layout

The package keeps exactly the repo's relative paths, so every command in the docs runs the same in the repo and in a package.

```
systems/
  README.md                          what "systems" means; index of the systems
  object_stores/
    README.md                        what the kit does, the settings table, the run order
    HOWTO.md.tmpl                    end-to-end test, step by step (templated)
    PACKAGE_README.md.tmpl           the README a built package carries (templated)
    settings.json                    the single schema of settings (see below)
    .env.example                     generated from settings.json
    requirements.txt                 jaydebeapi, boto3, pyarrow
    scripts/                         moved from scripts/s3_compat/
      s3_settings.py                 one place that reads settings and builds the client
      probe_s3.py  storage_setting.py  materialize_usl_table.py
      verify_bucket.py  verify_chain.py  cleanup_bucket.py
      serve_viewer.py                moved from the package; renders the viewer at request time
      render.py                      template renderer used by the server and the packager
      settings_docs.py               generates .env.example and the README table; --check finds drift
      package.py                     the packager
      report.py                      runs the steps in order and writes the conformance report
    viewer/
      index.html.tmpl                the four-tab viewer (templated)
      fixtures/verify_chain_example.txt   placeholder-only example output
      assets/                        logo and fonts, copied unmodified from website/assets
    issues/
      ISSUE-01-materialize-ignores-storage-setting.md
```

Stays where it is: `scripts/` (`zetaris_sql.py`, `run_sql.py`, `onboard.py`, `preflight.py`), `open_data/`, `docs/guides/`. The packager selects what the test needs from `open_data/manifest.json` by id, with `requires` resolved the way `onboard.py` does, instead of listing files by name.

## Settings: one schema, four consumers

`systems/object_stores/settings.json` lists every setting once: `name`, `secret` (yes or no), `required`, `default`, `description`. Four things read it, so they cannot drift: the generated `.env.example`, the settings table in the README, the packager's allowlist and secret detection, and the preflight check for these settings.

| Setting | Secret | Default | Notes |
|---|---|---|---|
| `S3_ENDPOINT_URL`, `S3_BUCKET` | no | none | Required |
| `S3_ACCESS_KEY`, `S3_SECRET_KEY` | **yes** | none | Required; never printed, never packaged |
| `S3_PREFIX` | no | `usl-test-<login>` | Your own folder in the bucket |
| `S3_REGION` | no | `us-east-1` | New |
| `S3_ADDRESSING` | no | `path` | New; `path` or `virtual`; also drives `useS3PathStyleAccess` |
| `S3_CA_BUNDLE` | no | Python's CA file | New; for a private CA; verification is never turned off |
| `S3_STORAGE_SETTING_ID` | no | none | Optional |
| `S3_STORE_VENDOR`, `S3_STORE_PRODUCT` | no | empty, shown as "S3 object store" | New; display only |
| `PACKAGE_PARTNER` | no | none | New; slug for the ZIP name; `[a-z0-9-]` only |
| `PACKAGE_LOGO` | no | none | New; local path to a partner-supplied logo file |
| `PACKAGE_DENY_WORDS` | no | none | New; comma list of words that must not appear in the package |

## Templates and name injection

- **Token syntax** `{{STORE_PRODUCT}}`, `{{STORE_VENDOR}}`, `{{STORE_NAME}}` (vendor and product joined, or "S3 object store" when both are empty). Used in the viewer, README, HOWTO and `.env.example`.
- **One renderer** (`render.py`): a pure function from template text and a settings dict to text. It fails the build if any token is left unresolved or any `{{` remains.
- **Two callers.** `package.py` renders once and bakes the result into the static viewer and docs. `serve_viewer.py` renders at request time from `.env.local`, so editing `S3_STORE_PRODUCT` and reloading renames the page without a rebuild. Templates are never shipped or served raw.
- **Injection safety.** Values are HTML-escaped in markup, JSON-encoded inside script blocks (with `</script>` escaped), and used in a file name only after the slug check. Tokens appear only in prose and labels, never inside a command someone will copy, so a hostile value cannot become a shell or SQL command.
- **Logo.** The viewer carries the Zetaris logo, unmodified. A partner logo appears only if `PACKAGE_LOGO` points to a file supplied for this purpose, and then only in the built package. No third-party mark is ever committed.
- **Spelling.** American English in everything written here, per your standing preference. `website/BRANDING.md` asks for Australian spelling on the site; this kit is documentation and tooling, so I am treating that rule as the site's, not the kit's (see decisions).

## Viewer redesign

Four tabs as today: analysis of the USL, topology (logical, physical and ERD), proof and recipe, live SQL.

- **Look.** Zetaris light theme from the table above, as CSS custom properties on `:root`, so a dark theme later is a token change. Plus Jakarta Sans and JetBrains Mono from the bundled font files, with system fallbacks, so the ZIP works offline.
- **Generic text.** "S3 object store" everywhere, with the product name injected where a specific name reads better (the physical topology box and the recipe header).
- **Proof tab.** The captured run becomes `fixtures/verify_chain_example.txt`, using `<bucket>` and `<your folder>`, with a banner reading "Example output. Times and sizes will differ on your run." The recipe's commands, paths and expected output are regenerated from the repo's real paths, so they stay correct after the move.
- **Live SQL tab** is unchanged in behavior: read-only by default, loopback only, one statement, `X-SIC-Viewer` header.
- **Quality bar, as before.** A programmatic text-fit check over every SVG label, plus screenshots at desktop and phone width, before the viewer is called done. This becomes a script in the repo, so it runs on every change to the template.

## Packager: `package.py`

```bash
python3 systems/object_stores/scripts/package.py --dry-run     # prints what would be built
python3 systems/object_stores/scripts/package.py               # builds dist/<name>/ and the ZIP
```

1. Read `.env.local`, take **only** the allowlisted non-secret settings from `settings.json`, and ignore everything else. Collect the secret values separately, in memory, for the leak check.
2. Resolve the file list: `systems/object_stores/`, the helper scripts from `scripts/`, the SQL for `company_dns`, the EDGAR sources and `sic_edgar_usl` (from the manifest), `docs/guides/` for the SQL references, and `requirements.txt`.
3. Render the templates; generate `.env.example` from the schema, with the partner's addressing and region as defaults and every secret blank.
4. Write `dist/<name>/` and then the ZIP `zetaris-<partner>-object-store-test-<YYYYMMDD>.zip`. Entries are sorted and timestamps fixed, so the same inputs give the same bytes. Add `MANIFEST.txt` and `SHA256SUMS` at the root.
5. **Leak check, which fails the build and deletes the ZIP:**
   - No `.env.local`, `.venv`, `__pycache__`, `.DS_Store`, swap or editor files.
   - No secret value from `.env.local` (any value of six characters or more) appears in any file.
   - No bucket name, endpoint host or login name from `.env.local` appears in any file.
   - No unresolved `{{`.
   - None of the `PACKAGE_DENY_WORDS` appears. Use it so a build for one partner cannot carry another partner's name.
6. Print a summary: file count, size, the ZIP path and the result of each check. Print values only for non-secret settings.

The packager only writes under `dist/`, which is already gitignored.

## Phases

| # | Phase | Result | Done when |
|---|---|---|---|
| 0 | Decisions | The decisions below | Done: all seven answered |
| 1 | Move and settings | `git mv scripts/s3_compat systems/object_stores/scripts`; `s3_settings.py`; `S3_REGION`, `S3_ADDRESSING`, `S3_CA_BUNDLE` honored by every script; `zetaris_sql.py` column names upstreamed; imports fixed | The existing run (probe, materialize, verify chain) passes from the new location, with defaults unchanged |
| 2 | Schema and docs | `settings.json`; generated `.env.example` and settings table; README and HOWTO as templates with no vendor name; the `ISSUE-01` write-up; `systems/README.md` | A grep for vendor and product names across `systems/` is empty; a generated `.env.example` matches the schema |
| 3 | Renderer and viewer | `render.py`; `index.html.tmpl` in the Zetaris light theme; `serve_viewer.py` renders at request time; example fixture; text-fit check script | Text-fit check passes; screenshots at desktop and phone width reviewed; renaming via `.env.local` changes the page on reload |
| 4 | Packager | `package.py` with dry run, deterministic ZIP and leak checks | Unit tests below pass, and a build with no `S3_STORE_*` set is fully generic |
| 5 | Acceptance | Build a package for a made-up partner, unzip it into an empty folder, and walk its HOWTO from step 1 on a clean Zetaris instance, as a partner would | Chain ends `CHAIN OK` and `cleanup_bucket.py` ends `CLEAN` |
| 6 | Conformance report | `report.py` (details below), packaged with the kit | A report is generated against the first store, and its checks agree with what the individual scripts print |

**Changes made while doing phase 2.** `render.py` was built in phase 2 instead of phase 3, because the templates could not be tested without it. The HOWTO and package README templates already name `serve_viewer.py` and `viewer/index.html`, which phase 3 adds, so they point at files that do not exist yet; nothing should be merged or packaged before phase 3. The preflight check for the S3 settings, listed as a fourth consumer of the schema, moves to phase 4, where the packager needs it. `settings_docs.py --check` also fails if a script reads a setting name that is not in `settings.json`, which keeps the schema honest.

**Changes made while doing phase 3.**

- The viewer keeps the `sic_edgar_usl` USL as its subject, as agreed. Only the object-store wording and branding became generic.
- Zetaris logo and Plus Jakarta Sans are served from `website/assets/` (the server's allowlist names exactly three files) instead of being copied into `viewer/assets/`, so the repo carries no second copy. The packager will copy them into the package in phase 4, where the server finds them under `viewer/assets/` first.
- A fourth token, `{{STORE_LABEL}}`, was added: the name cut to 24 characters, for diagram boxes. Column headers in the diagrams are fixed text so a long name cannot overflow them.
- The partner-logo slot is in the template (hidden); filling it from `PACKAGE_LOGO` is phase 4. The in-browser "Add logo" uploader of the old viewer was removed, so no third-party mark is ever stored by the page.
- `serve_viewer.py` now sends a Content-Security-Policy that blocks loading anything from another site, and hides the driver's harmless SLF4J warning, which the HOWTO had already said it did.
- Layout is verified by `viewer/check_fit.js`, run in a browser, not by a script in the repo, to avoid a headless-browser dependency. Browser automation in the packager can adopt it later. `scripts/check_viewer.py` covers what needs no browser, including WCAG contrast of the text colors; it found one failing derived color (the amber), which was darkened.
- The recipe on the Proof tab duplicates the HOWTO as HTML. `check_viewer.py` now checks that the two give the same commands (see "After phase 6").

**Changes made while doing phase 4.**

- `settings.json` gained a `bake` field. Only `S3_STORE_VENDOR`, `S3_STORE_PRODUCT`, `S3_ADDRESSING` and `S3_REGION` may be written into a package; `settings_docs.py` rejects a baked secret. Every other value in `.env.local` is collected for the leak check and never copied.
- The packager parses the env file itself and never puts its values in `os.environ`, so a build cannot leak a setting into a child process.
- The leak check runs twice: on the files in memory before anything is written, and on the ZIP read back from disk afterwards. If either fails, nothing is left behind. It reports the setting name and the file, never the value. Values shorter than 5 characters (6 for secrets) are reported as skipped, because they match ordinary words.
- The partner logo is a `<!--partner-logo-->` marker in the viewer template. Only `assets/partner/logo.<svg|png|jpg|webp>` is accepted, the file is checked by signature and size (512 KB), and the server serves it from `viewer/assets/` only, with a sandboxing Content-Security-Policy.
- Repository-only files stay out of packages: `package.py`, `settings_docs.py`, `check_viewer.py`, `check_fit.js` and the tests.
- The S3 preflight check moved here from phase 2: `scripts/preflight.py --s3` reads the required settings from `settings.json`, makes no network call, and never prints a value.
- 40 standard-library tests cover the renderer and the packager. With the leak check disabled in memory, seven of them fail, so they are not vacuous.
- Checked against the earlier hand-built package: every SQL script and both guides are byte-identical, nothing is missing, and the only changes are the intended ones.
- Finding: the example user agent quoted in the repo's own help text (`zetaris dev@zetaris.com`) is flagged if someone uses it as a real value, because it appears in the repo's scripts. That is correct behavior, and it matches the rule that the user agent must be a real contact.

**Phase 5 results (29 October 2026, Zetaris 2.4.3.1).** A package was built for a made-up partner with no store names (zero vendor names in it), unzipped into an empty folder, and its HOWTO followed from step 1 with a fresh venv. The instance had the phase 1 objects, so the teardown from step 14 ran first. Acceptance was met: step 11 ended `CHAIN OK` (10 objects, 52,699 bytes, all stages PASS) and the cleanup ended `CLEAN` with the bucket empty. The viewer was served from the package and ran a live query.

The walkthrough found five problems, all fixed and re-verified on a rebuilt package:

1. **`python3` for scripts that need `boto3`.** The HOWTO ran `storage_setting.py` and `materialize_usl_table.py` with `python3`, but both import the S3 helper, which imports `boto3`, which is only in the venv. A partner who had not activated the venv got a traceback on the first command of step 9. The HOWTO and recipe now use `.venv/bin/python` for the S3 scripts, say which commands need the venv, and a missing `boto3` now prints "Use the venv from step 2".
2. **Default storage setting name.** `s3-compat` was not unique, so a second person, or a second run, got `HTTP 400 already exists`. The default is now `s3-compat-<your folder>`, and the HOWTO explains `--name`.
3. **`--skip-exists` was overstated.** Dependencies skip "already exists" by themselves; only the named target needs the flag. Leftover REST tables after a teardown do no harm. Both warnings were corrected.
4. **Step 4 expected output was wrong.** It lacked the `ZETARIS_USER_AGENT` line and the INFO block appears twice. A check now compares the HOWTO's 26 expected lines with the real preflight output, label by label and in order, and they match.
5. **The server's startup lines did not appear when its output was piped.** Both now flush.

**Tested behavior: a second `MATERIALIZE` replaces, it does not append.** For `sic_code` (1 file) and `company` (7 files) the object count and the row count were identical after a second run into an uncleared folder, and the chain still passed. The HOWTO and README no longer tell people to clear before a re-run; they say when clearing is still useful (files from tables no longer written).

Confirmed as documented: the macOS Java stub is bypassed by the scripts, the S3 preflight passes with no network call, and a fresh partner folder needs no `.env.local` beyond what the example generates.

Not tested: a store that needs `virtual` addressing or a private CA (only one store was available), and a run from a truly empty Zetaris (the Data Explorer leftovers remained).

**Phase 6 results (30 October 2026, Zetaris 2.4.3.1).** `report.py` is built, tested and was run from an unzipped package against the first store: 18 PASS, 1 INFO, result PASS, with the cleanup deleting 10 objects (52,699 bytes) and the folder left empty. Its numbers agree with the individual scripts, because it calls the same functions (`probe_attempts`, `materialize.build`, the chain functions, `list_prefix` and `delete_keys`).

- **Design as built.** Orchestration lives in `report.py`; the probe loop and the storage-setting request were turned into functions (`probe_attempts`, `create_body`) with the CLI output unchanged. The leak-check helpers moved from `package.py` to a shared `leaks.py`, because `package.py` is repository-only and the report runs on a partner's machine. A failure that makes later steps meaningless stops them (recorded as SKIP with the reason); the verdict is PASS, FAIL (a required check failed) or INCOMPLETE (a required check was skipped).
- **Differences from the plan.** The file name is `reports/<store>-<date>-<time>.json`, not `<partner>-<date>`, because a partner package has no partner setting and the plan says the store is named only by its display name. `--store-only` was added so a partner can test the bucket before Zetaris is available. The storage setting the report creates is removed again automatically, since it is the report's own scaffolding.
- **Safe to send.** Every string in the report goes through the redactor, and the finished files are scanned again; if a value from `.env.local` is still found, nothing is written (exit 2). Checked independently on real runs against 24 values, including the old env files: no hits. A hostile-content test of the viewer's loader (markup in every field) produced no elements and ran no script.
- **What this store reported.** Batch delete works, no object lock is configured, versioning was never enabled, and every region name was accepted (so the store most likely ignores the region).
- **Failure path on the real store.** A nonexistent bucket gives FAIL with a one-line reason, TLS correctly PASS (the store answered), everything else SKIP, Zetaris never contacted, and the bad name appears in neither file.
- **Tests.** 34 new tests with a fake S3 client and a fake Zetaris channel (74 in all, run with the venv). With the redactor, the final guard, the cleanup scoping or the verdict logic disabled, tests fail in each case.
- **Viewer.** The Proof tab loads a report JSON chosen by the user, in the browser only, built with `textContent`; bad files (not JSON, wrong kind, wrong schema version, too large, incomplete) show a clear message.

Still not covered, because only one store was available: a store that needs `virtual` addressing, a private CA, object lock or versioning enabled, or no batch delete. The tests cover those branches with fakes; a real store would confirm them.

**Open item (closed).** The recipe HTML and `HOWTO.md.tmpl` could drift apart. A check now compares their commands; see "After phase 6".

Phases 1 to 4 can be reviewed and committed separately, and phase 6 follows the same way. Each is small enough for one pull request.

### Phase 6: conformance report

Because the report is built before we have seen a second store, it records what we already know to vary and leaves room for what we don't.

- **Orchestration, not new logic.** `report.py` calls the existing scripts' functions in order (probe, storage setting, `MATERIALIZE` for each table, chain verification, cleanup) and records each outcome. It stops at the first failure that makes later steps meaningless and marks the rest SKIP, with the reason.
- **Checks.** TLS trust; addressing style that worked; region accepted; put, get and delete; list; batch delete (with the single-delete fallback noted); retention or object lock detected; storage setting created; `MATERIALIZE` per table; Parquet readable; row counts equal at every stage of the chain; cleanup `CLEAN`. Anything unexpected goes in a free-text "observations" field, since the unknowns are the point.
- **Output.** `reports/<partner>-<YYYYMMDD>.json` (machine readable, with a schema version) and `.md` (readable), both written to a `reports/` folder in the working directory, which phase 6 adds to `.gitignore` so a report can never be committed by accident. The JSON is the contract; the Markdown is rendered from it.
- **Safe to send.** The report holds no secret, bucket name, endpoint host or login name. It uses the same leak check as the packager, and fails if one appears. It records the store only by the injected display name.
- **Destructive steps.** Cleanup in the report run stays a dry run unless `--cleanup` is given, and it still touches only the user's own folder.
- **Viewer.** The Proof tab can load a report file the user chooses, so the same page shows a real run without anyone editing the example fixture. The fixture stays the default.

### After phase 6 (30 October 2026)

Changes made after the first package was run by a partner colleague and the first real problems were found. All are on the same branch.

- **Report in the viewer.** `serve_viewer.py` serves the newest `reports/<name>-<date>-<time>.json` at `GET /api/report/latest`, and the Proof tab loads it on open and when the browser tab regains focus. The route accepts only that file name pattern, no symlinks, at most 1 MB, a valid report, and checks the content against every `.env.local` value again before sending (409, with no value in the reply, if one is found). The file picker remains for the static page. A choice made by hand turns auto-load off for that page. Tests use a real server on a free port; disabling the leak check makes them fail.
- **Report is its own HOWTO step.** The report is step 14 and the clean up is step 15, because the report needs the USL and the teardown removes it. Step 14 lists what to check first, what PASS, FAIL, INCOMPLETE and exit code 2 mean, and what to send. The viewer recipe follows the same order.
- **Install hint.** The preflight and the JDBC error named `scripts/requirements.txt`, which a package does not hold. `requirements_file()` in `scripts/zetaris_sql.py` names the file that exists.
- **A regression of mine, and the guard.** While fixing the hint I deleted five constants from `scripts/zetaris_sql.py` (the REST default URL among them) and shipped it; the partner's first preflight crashed with `NameError`. The tests use fake channels and never read them. `test_package.py` now checks every Python file in a built package for names a function reads but the module never defines, using `symtable`, and fails on exactly that case.
- **A rebuild no longer deletes the person's files.** The packager removed the whole unzipped folder before writing it, which also removed a partner's `.env.local` and `.venv` during testing. It now keeps `.env.local`, `.venv` and `reports/` and removes only what it built.
- **Dangling paths.** `package.py` fails the build if a shipped document, script or message names a `scripts/`, `systems/`, `open_data/`, `docs/`, `website/`, `reports/` or `examples/` path the package does not hold (SQL comments, `MANIFEST.txt` and one named fallback are exempt). It found that the kit README and `settings.json` named repository-only files (the packager, the drift check, the tests, `website/assets`). Those parts of the README are now marked `<!--repo-only-->` and removed from the package, and `settings.json` and the generated `.env.example` header no longer name a maintainer script.
- **Recipe and HOWTO agree.** `check_viewer.py` compares them: every command in the HOWTO's bash blocks must appear in the recipe, and every `python3` or `.venv/bin/` command in a recipe copy box must be in the HOWTO. Changing a flag on one side makes it fail. Descriptions around the commands can still differ; only commands are compared.

What the checks do not cover: wording around the commands, output samples, and any instruction that is not a command in a bash block.

## Verification

- **Unit tests** (no network, no instance): the renderer (unresolved token, escaping, `</script>`, default name); the packager's file selection, deterministic ZIP, and each leak check with a seeded secret, a seeded bucket name and a seeded deny word.
- **Regression against today's package.** Build with the values that produced the current hand-built package under `dist/` and compare it to that folder. The only differences should be the intended ones: names, theme, paths, example fixture.
- **No-leak proof.** After a build, run the README's `unzip -l` check and a recursive search for each value in `.env.local`.
- **Run, not just read.** Phase 5 is the real test: the instructions are followed literally, on a clean instance, in an empty folder.
- **Repo scrub.** A final search of the repo (working tree, worktrees and history of the new branch) for any partner or product name.

## Risks and unknowns

- **Only one store has been tested.** Anything said here about other stores is a list of things to check, not results.
- **`MATERIALIZE` overwrite versus append is unverified.** The docs say to clear your folder first. Phase 5 should test a second run without clearing, so we can state the behavior instead of avoiding it.
- **Engine-side network and trust** can fail where the probe passes. The docs must say so up front and point to the `MATERIALIZE` step as the real test.
- **Object lock** can make cleanup impossible. The tool reports it; it never retries or works around it.
- **A bucket shared by several people** relies on the per-user folder. It is a convention, not isolation, and the docs should say that.
- **Logo and trademark use.** Only a partner-supplied file, only in that partner's own build, never committed. The Zetaris logo and font are used unmodified.
- **Credentials in SQL.** The materialize statement carries them. The docs keep the advice to use a rotatable key.

## Decisions (resolved)

1. **Where the generic scripts live.** Move `scripts/s3_compat/` into `systems/object_stores/scripts/`. No copy is left in `scripts/`.
2. **Naming vendors in the repo.** The repo stays vendor-neutral. Names live only in `.env.local` and the built package. No committed results matrix.
3. **Themes.** Light only for version 1, with tokens set up so dark is a token change later.
4. **Spelling.** American English for the kit.
5. **Packager home.** `systems/object_stores/scripts/package.py`.
6. **Conformance report.** Included in this work as phase 6, not deferred.
7. **Pages site.** Deferred until this work is done.

One consequence of decision 1: any doc or script elsewhere in the repo that points to `scripts/s3_compat/` must be updated in phase 1, and the repo search at the end of phase 1 should find no remaining reference.
