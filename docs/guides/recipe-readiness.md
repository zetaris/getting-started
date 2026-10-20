# Cookbooks

Choose a task and follow its cookbook. Verified means it worked in a recorded run; check it on your instance too.

## Start small

| Task | Cookbook | What you need |
|---|---|---|
| Query the supplied NY Taxi and TPCDS tables | [First SQL commands](../connections/lightning-recipe-reference.md) | Login and query permission |
| Connect PokéAPI and find Pikachu's abilities | [PokéAPI cookbook](first-dataset.md) | Creation permission, team names and API access from Zetaris |

Run recipes on your own local or AWS Zetaris instance.

## Find a recipe

- [REST cookbook](../../open_data/rest_apis/HOWTO.md): connect, flatten and query API data, including SIC industry classifications. The [REST catalog](../../open_data/rest_apis/rest-api-sources.md) records readiness; NASA DONKI is unverified and Singapore PM2.5 is known to fail.
- [File cookbook](../../open_data/parquet_csv/HOWTO.md): register and query files such as NOAA weather and AWS Public Blockchain. Check the [file catalog](../../open_data/parquet_csv/parquet-csv-data-sources.md) for failures, size and licensing.
- [USL cookbook](../../open_data/usl/HOWTO.md): build SIC and SIC/EDGAR models. The [model catalog](../../open_data/usl/usl-sources.md) records a foreign-key data-quality failure and open materialisation questions.

Check size, rate limits, licence and setup before adding each source.

Using scripts? See [client scripts](../../scripts/HOWTO.md) for recipe IDs, dependency planning and a dry-run before creating objects.

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

Known-to-fail recipes require an explicit runner override; they remain failures. See the [roadmap](../plans/FUTURES.md) for planned work.

## If a source fails

Use [troubleshooting](troubleshooting.md) before retrying. If a source is blocked, choose another verified recipe. Record unresolved failures in your demo notes.
