# Available recipes

Start with [PokéAPI](first-dataset.md), then choose another source that fits your project. A recipe marked verified worked in a recorded run. Check it on your instance too.

## Start small

| Source | Try first | Add later |
|---|---|---|
| PokéAPI | Pikachu's abilities. See the [test record](../install/zetaris-installation-test-record.md). | Types, stats, Charizard and union views |

Use your assigned team names on the shared instance.

## Find a recipe

- [REST sources](../../open_data/rest_apis/rest-api-sources.md): nine of the 11 recipes are marked verified. NASA DONKI is unverified; Singapore PM2.5 is known to fail.
- [File sources](../../open_data/parquet_csv/parquet-csv-data-sources.md): NOAA and AWS Public Blockchain are active. Five other recipes, including PUDL, are known to fail. Licence colours don't tell you whether a query works.
- [USL models](../../open_data/usl/HOWTO.md): SIC and SIC/EDGAR setup steps have been checked. The guides also record a foreign-key data-quality failure and open questions about materialisation.

Check the source's size, rate limits, licence and setup steps before running it. Choose one source at a time.

Use `python3 scripts/onboard.py --list` to see recipe IDs, and `plan <id>` to see dependencies. Preview with `--dry-run` before creating objects. See [client scripts](../../scripts/HOWTO.md).

## Leave these for later

| Recipe | Current limit |
|---|---|
| PUDL, Foursquare, Overture, Ookla and GBIF | Known registration or query failures. See the file catalog's issue links. |
| Singapore PM2.5 | Known to fail |
| NASA DONKI | Connector and response format still need checking |
| Singapore housing and Open Food Facts bulk downloads | Fetchers only. Put the files where Zetaris can reach them; bulk delimiter support still needs checking. |
| Large tables and full-dataset scans | Check size and permissions first |
| Kafka | Ingestion still needs checking |
| SQL databases, logs, PDFs and other planned recipes | Not ready for onboarding |

The runner needs an explicit override for known-to-fail recipes. That doesn't fix the source. The [roadmap](../plans/FUTURES.md) lists future work.

## If a source fails

Check [troubleshooting](troubleshooting.md). If PokéAPI fails, fix the connection or choose another verified REST source and follow its setup steps. PUDL is currently blocked, so use another source. Keep failures visible in your demo notes.
