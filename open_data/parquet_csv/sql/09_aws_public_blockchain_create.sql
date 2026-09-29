-- =============================================================================
-- Source:   AWS Public Blockchain Data (Bitcoin, Ethereum, + 8 other chains)
-- License:  UNRESOLVED -- the registry's License field links to an MIT-
--           licensed code-SAMPLE repo, not a data-licensing document. No
--           independent statement that the blockchain data itself is
--           CC0/public-domain was found. Treat this as "point at it live for
--           a demo, don't re-host a copy." See parquet-csv-data-sources.md #9
--           before using this for anything
--           beyond a live query demo.
--           https://registry.opendata.aws/aws-public-blockchain/
-- Format:   Parquet, snappy-compressed, date-partitioned (native)
-- Docs:     https://github.com/aws-solutions-library-samples/guidance-for-digital-assets-on-aws/blob/main/analytics/README.md
-- Before running: confirm today's partition actually has data --
--   aws s3 ls --no-sign-request s3://aws-public-blockchain/v1.0/btc/transactions/
-- =============================================================================
--
-- CAVEAT: this bucket is public/anonymous. The table options below use
-- Zetaris's public-bucket configuration and the us-east-2 S3 endpoint, so
-- this script does not need AWS credential values.
-- The date partition (2026-09-01 below) is a MOVING TARGET -- this dataset
-- updates daily. Confirm the current date's partition exists with the
-- listing command above before an event -- very recent dates can lag behind
-- real time by a day or more.
--
-- PREREQUISITE: AWS_BLOCKCHAIN_S3 must be registered as a logical database
-- before the tables below can reference it in FROM -- see HOWTO.md sec 1.
CREATE LIGHTNING DATABASE AWS_BLOCKCHAIN_S3 DESCRIBE BY "AWS Public Blockchain Data S3 filestore source";

CREATE LIGHTNING FILESTORE TABLE btc_transactions FROM AWS_BLOCKCHAIN_S3 FORMAT PARQUET OPTIONS (
  PATH "s3a://aws-public-blockchain/v1.0/btc/transactions/date=2026-09-01/",
  inferSchema "true",
  isS3BucketPublic "true",
  useS3PathStyleAccess "true",
  s3Endpoint "s3.us-east-2.amazonaws.com"
);

-- Ethereum equivalent (also has blocks/, logs/, token_transfers/, traces/,
-- and contracts/ prefixes under v1.0/eth/ if you want a richer demo):
CREATE LIGHTNING FILESTORE TABLE eth_transactions FROM AWS_BLOCKCHAIN_S3 FORMAT PARQUET OPTIONS (
  PATH "s3a://aws-public-blockchain/v1.0/eth/transactions/date=2026-09-01/",
  inferSchema "true",
  isS3BucketPublic "true",
  useS3PathStyleAccess "true",
  s3Endpoint "s3.us-east-2.amazonaws.com"
);

-- Next: verify with sql/09_aws_public_blockchain_select.sql
