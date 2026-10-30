# ISSUE-01: `MATERIALIZE USL TABLE` does not use the credentials of its storage setting

**Status:** open, reproduced on Zetaris Lightning 2.4.3.1 on 29 October 2026, against one S3-compatible store. Reported here for Zetaris engineering to say whether this is a defect or intended.

## Summary

`MATERIALIZE USL TABLE ... TO STORAGE (...)` accepts `storageSettingId` but then writes without the setting's credentials. The statement fails at write time with:

```
org.apache.hadoop.fs.s3a.auth.NoAuthWithAWSException: No AWS Credentials provided by DefaultAWSCredentialsProviderChain
```

The statement parses, the table is found, and the failure comes back as one result row (`Error` and the message), not as an SQL error, so a script that only checks for an exception reports success.

It works only when the S3 credentials, the endpoint and `useS3PathStyleAccess` are placed **inside the `optionsBase64` JSON**. That puts the keys in the statement text, where the instance may keep them in query history.

## Reproduction

A storage setting of type `S3` was created with `POST /storage-setting` (`storage_setting.py create`), holding the access key, secret key, endpoint and path-style flag. The USL table `lightning.metastore.usl_demo.sic_edgar_usl.sic_code` (1,005 rows) was then materialized with each variant of `materialize_usl_table.py --variant <name>`:

| Variant | Where the credentials are | Result |
|---|---|---|
| `setting-id` | Only in the saved setting, referenced by `storageSettingId` (the manual's example) | `Error`: `NoAuthWithAWSException` |
| `inline` | Also as extra top-level options (`awsAccessKeyId`, `awsSecretAccessKey`, `s3Endpoint`, `useS3PathStyleAccess`) | `Error`: `NoAuthWithAWSException` |
| `inline-hadoop` | Also as top-level `fs.s3a.*` options | Parse error: `extraneous input 'key' expecting {')', ','}`. A dotted option name is not accepted at the top level |
| `options-json-hadoop` | Inside `optionsBase64`, with `fs.s3a.*` names | `Error`: `NoAuthWithAWSException` |
| `options-json` | Inside `optionsBase64`, with `awsAccessKeyId`, `awsSecretAccessKey`, `s3Endpoint`, `useS3PathStyleAccess` | **`SUCCESS`**, Parquet written and read back, row counts equal at every stage |

Re-run with the dry run first (`--dry-run` prints the statement with the credentials masked), for example:

```bash
.venv/bin/python systems/object_stores/scripts/storage_setting.py create --name repro
.venv/bin/python systems/object_stores/scripts/materialize_usl_table.py \
  lightning.metastore.usl_demo.sic_edgar_usl.sic_code --setting-id <id> --variant setting-id
```

Observed in an earlier run and not repeated for this write-up: the REST export `POST /usl/{uslId}/tables/{table}/export` with `storageId` does use the saved setting's credentials, and chooses its own sub-path (`materialized/usl/<id>/<TABLE>/`) below the setting's path.

## What this is NOT

- **Not wrong keys, endpoint or bucket.** The same values succeed in the `options-json` variant, and the probe (`probe_s3.py`) reaches the store with them.
- **Not a TLS or network failure.** The error is an authentication-provider error from the S3A client, not a connection error, and the working variant uses the same host.
- **Not the saved setting being invalid.** The REST export uses it successfully (see above).
- **Not something the working variant only does for one table.** `options-json` materialized both `sic_code` and `company`. The failing variants were run only on `sic_code`.

## Root-cause hypothesis (unconfirmed)

The writer builds its Hadoop configuration from the options in `optionsBase64` only, and does not load the storage setting's credentials into it for `MATERIALIZE`, so S3A falls back to the default provider chain, finds nothing, and raises `NoAuthWithAWSException`. The REST export path may build its configuration from the setting, which would explain why it works. The top-level options being ignored, and dotted names being a parse error, fit the same picture: only the JSON blob reaches the writer.

This is a guess from the error and the variants above, not a diagnosis.

## Suggested engineering debugging steps

1. Compare how the `MATERIALIZE` writer and the REST export build the Hadoop configuration, and whether either reads the storage setting by id.
2. Check whether `storageSettingId` is read at all in the `MATERIALIZE` path, for example by passing an id that does not exist and seeing whether the statement is rejected.
3. Check which keys in the options are copied into the configuration, and whether `useS3PathStyleAccess` and `s3Endpoint` are mapped to `fs.s3a.path.style.access` and `fs.s3a.endpoint`.
4. Return write failures as SQL errors, or at least with a result status a client can test, instead of a successful query with an `Error` row.

## Recommended action

- **For now:** use `--variant options-json`. Use an access key that can be rotated, because the key is in the statement, and tell users that the instance may keep the statement in query history.
- **Ask engineering** whether `MATERIALIZE` should honor the saved setting, as the manual's example implies. If it should, this is a defect and the working variant is a workaround. If not, the manual's example should be corrected.
