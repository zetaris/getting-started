// The curated smoke questions. Expected files were written down BEFORE the first run, from a
// look at which files exist, not from search results. A hit is any expected entry that equals the
// file or (for entries ending in "/" or a kbase slug) is contained in it.
export interface SmokeQ {
  id: string;
  group: "sql-example" | "where-is" | "in-scope" | "out-of-scope";
  q: string;
  expect: string[];
}

export const SMOKE: SmokeQ[] = [
  {
    id: "pudl-query",
    group: "sql-example",
    q: "Show me an example SQL query against the PUDL data",
    expect: [
      "examples/pudl-chart/README.md",
      "open_data/parquet_csv/parquet-csv-data-sources.md",
    ],
  },
  {
    id: "rest-view",
    group: "sql-example",
    q: "Give me the SQL to register a REST API source and put a SchemaStore view over it",
    expect: [
      "open_data/rest_apis/HOWTO.md",
      "open_data/rest_apis/rest-api-sources.md",
    ],
  },
  {
    id: "usl-compile",
    group: "sql-example",
    q: "What statements compile and activate a USL?",
    expect: [
      "docs/guides/zetaris-lightning-sql-commands.md",
      "open_data/usl/usl-sources.md",
    ],
  },
  {
    id: "company-dns-rate",
    group: "where-is",
    q: "What is the rate limit for company_dns and how should I behave?",
    expect: [
      "open_data/rest_apis/rest-api-sources.md",
      "open_data/rest_apis/HOWTO.md",
      "docs/guides/zetaris-lightning-sql-companion.md",
    ],
  },
  {
    id: "known-to-fail",
    group: "where-is",
    q: "Where are the known_to_fail sources documented?",
    expect: ["open_data/rest_apis/sql/known_to_fail/README.md"],
  },
  {
    id: "jdbc-settings",
    group: "where-is",
    q: "Which JDBC connection settings do I use?",
    expect: ["docs/connections/"],
  },
  {
    id: "agents-dry-run",
    group: "in-scope",
    q: "What does AGENTS.md say about dry runs before running a create script?",
    expect: ["AGENTS.md", "scripts/HOWTO.md"],
  },
  {
    id: "limit-fragment",
    group: "in-scope",
    q: "Why does a small LIMIT on RUN PIPELINE write only a fragment?",
    expect: ["docs/guides/zetaris-lightning-sql-companion.md", "AGENTS.md"],
  },
  {
    id: "least-privilege",
    group: "in-scope",
    q: "How should I set up an agent that only reads data?",
    expect: ["docs/guides/permissions.md", "AGENTS.md"],
  },
  {
    id: "kb-release",
    group: "in-scope",
    q: "What changed in Zetaris release 2.4.1.0?",
    expect: ["product-version-2.4.1.0-03rd-june-2025"],
  },
  {
    id: "kb-clone",
    group: "in-scope",
    q: "How do I clone a pipeline?",
    expect: ["how-to-clone-pipeline"],
  },
  {
    id: "kb-s3",
    group: "in-scope",
    q: "How do I connect to AWS S3 with an access token?",
    expect: ["how-to-connect-aws-s3-with-access-token"],
  },
  {
    id: "oos-france",
    group: "out-of-scope",
    q: "What is the capital of France?",
    expect: [],
  },
  {
    id: "oos-bread",
    group: "out-of-scope",
    q: "What is a good recipe for sourdough bread?",
    expect: [],
  },
  {
    id: "oos-btc",
    group: "out-of-scope",
    q: "What will the Bitcoin price be next month?",
    expect: [],
  },
];

export function isHit(file: string, expect: string[]): boolean {
  return expect.some((e) => file === e || file.includes(e));
}
