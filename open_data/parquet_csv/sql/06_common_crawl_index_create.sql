-- =============================================================================
-- Source:   Common Crawl columnar index (cc-index) -- metadata index, NOT the
--           raw crawled page content
-- License:  Common Crawl Terms of Use -- the index itself (Common Crawl's own
--           generated metadata) is the safe part to demo; crawled page
--           content carries separate third-party rights. See
--           parquet-csv-data-sources.md #6 before extending this beyond the
--           index table. https://commoncrawl.org/terms-of-use/
-- Format:   Parquet (native)
-- Docs:     https://commoncrawl.org/columnar-index
--           https://github.com/commoncrawl/cc-index-table/blob/main/README.md
-- Before running: confirm the current crawl ID (a new one ships monthly) --
--   aws s3 ls --no-sign-request s3://commoncrawl/cc-index/table/cc-main/warc/
-- =============================================================================
--
-- CAVEAT: this bucket is public/anonymous, but Zetaris always signs S3
-- requests -- CONFIRMED (see HOWTO.md sec 2): a real AWS IAM key pair is
-- required below (a free-tier account with s3:GetObject/s3:ListBucket is
-- enough), even though the bucket itself doesn't require one.
-- The crawl ID (CC-MAIN-2025-33 below) is a MOVING TARGET -- confirm the
-- current one with the listing command above before an event.
--
-- PREREQUISITE: CC_INDEX_S3 must be registered as a logical database before
-- the table below can reference it in FROM -- see HOWTO.md sec 1.
CREATE LIGHTNING DATABASE CC_INDEX_S3 DESCRIBE BY "Common Crawl columnar index S3 filestore source";

-- ! FORBIDDEN
CREATE LIGHTNING FILESTORE TABLE common_crawl_index FROM CC_INDEX_S3 FORMAT PARQUET OPTIONS (
  PATH "s3a://commoncrawl/cc-index/table/cc-main/warc/crawl=CC-MAIN-2025-33/subset=warc/",
  inferSchema "true",
  isS3BucketPublic "true",
  useS3PathStyleAccess "true",
  s3Endpoint "s3.us-east-1.amazonaws.com"
);

-- Next: verify with sql/06_common_crawl_index_select.sql
