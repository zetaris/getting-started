# table_data

Open-source sample datasets shipped in this repo as local Parquet or CSV files,
one folder per project. Unlike the other parquet_csv sources (public S3), these
need no cloud account: copy the folder into the Zetaris containers with
`scripts/copy_local_data.py`, then run the project's create script in `../sql/`.

| Project | Create / select | What it is |
|---|---|---|
| [demo_bank](demo_bank/README.md) | `../sql/10_demo_bank_create.sql` / `_select.sql` | Synthetic retail bank, 11 tables over two databases, plus a USL (`open_data/usl/sql/03_demo_bank_usl_create.sql`) |

Data in this folder is released under the Apache License 2.0, the same as this repository.
