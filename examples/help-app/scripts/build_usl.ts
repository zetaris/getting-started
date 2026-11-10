// Phase 4: register the Postgres datasource, fill the doc and chunk catalogs, then build
// help_usl, run its data quality rules and create help_mart.
// Usage: deno task help:usl [--dry-run] [--rebuild]
//   --dry-run  print the steps and row counts; send nothing, print no credentials
//   --rebuild  REMOVE USL help_usl first (a USL cannot be changed in place)
// The static SQL is in sql/ and is run by the repo's scripts/run_sql.py, which keeps a multi-table
// COMPILE USL whole.
import { loadConfig } from "../core/config.ts";
import {
  batches,
  checkKeyLengths,
  chunksInsert,
  createDatasourceSql,
  docsInsert,
  DS,
} from "../core/catalog.ts";
import { loadKbaseCorpus, loadRepoCorpus } from "../core/corpus.ts";
import { zetarisClient } from "../core/zetaris.ts";
import { ROOT, SKIP } from "./verify.ts";

const dry = Deno.args.includes("--dry-run");
const rebuild = Deno.args.includes("--rebuild");
const cfg = loadConfig();
const z = zetarisClient(cfg, 600_000);
const NS = "lightning.metastore.help_app_usl";
const HERE = new URL("..", import.meta.url).pathname;

const repo = await loadRepoCorpus(ROOT, { skipPrefixes: SKIP });
const kbase = await loadKbaseCorpus(`${HERE}corpus/kbase`);
const docs = [...repo.docs, ...kbase.docs];
const segments = [...repo.segments, ...kbase.segments];
checkKeyLengths(docs, segments);
const dupes = docs.length - new Set(docs.map((d) => d.path)).size;
if (dupes) throw new Error(`${dupes} duplicate doc paths`);
const BATCH = 100;

console.log(`catalog: ${docs.length} docs, ${segments.length} chunks`);
const steps = [
  `register Postgres datasource ${DS} (if missing) and its tables`,
  `fill ${DS}.docs and ${DS}.chunks (only if empty), ${BATCH} rows per INSERT`,
  rebuild ? `REMOVE USL help_usl NAMESPACE ${NS}` : null,
  "sql/01_help_usl_create.sql (compile and activate help_usl)",
  "sql/02_help_dq.sql (RUN DQ)",
  "sql/03_help_mart_create.sql (help_mart)",
  "count every USL table and the mart",
].filter(Boolean);
steps.forEach((s, i) => console.log(`${i + 1}. ${s}`));
if (dry) {
  console.log("dry run: nothing was sent.");
  Deno.exit(0);
}
if (!cfg.pgPassword) {
  console.error("HELP_PG_PASSWORD is not set in .env.local.");
  Deno.exit(1);
}

const q = async (sql: string) => (await z.run(sql, 1000)).rows;
const count = async (t: string) =>
  Number((await q(`SELECT count(*) FROM ${t}`))[0][0]);

// 1. datasource
const sources = (await q("SHOW DATASOURCES")).map((r) => r[0]);
if (!sources.includes(DS)) {
  await q(createDatasourceSql(cfg)); // contains the password: never printed
  await q(`REGISTER DATASOURCE TABLES FROM ${DS}`);
  console.log(`registered ${DS}`);
} else console.log(`${DS} already registered`);

// 2. fill
const have = await count(`${DS}.docs`);
if (have === 0) {
  for (const b of batches(docs, BATCH)) await q(docsInsert(b));
  for (const [i, b] of batches(segments, BATCH).entries()) {
    await q(chunksInsert(b));
    if ((i + 1) % 5 === 0) {
      console.log(`chunks: ${Math.min((i + 1) * BATCH, segments.length)}`);
    }
  }
} else {
  console.log(
    `${DS}.docs already holds ${have} rows; not refilling (Zetaris INSERT only appends). ` +
      `To refill, run TRUNCATE docs, chunks in Postgres first.`,
  );
}
const nd = await count(`${DS}.docs`), nc = await count(`${DS}.chunks`);
console.log(
  `postgres: docs ${nd} (expect ${docs.length}), chunks ${nc} (expect ${segments.length})`,
);
if (nd !== docs.length || nc !== segments.length) {
  console.error("FAIL: catalog counts differ from the corpus.");
  Deno.exit(1);
}

// 3. USL, DQ, mart: the repo's runner
if (rebuild) {
  try {
    await q(`REMOVE USL help_usl NAMESPACE ${NS}`);
  } catch (e) {
    console.log(`remove: ${(e as Error).message.slice(0, 120)}`);
  }
}
for (
  const f of [
    "01_help_usl_create.sql",
    "02_help_dq.sql",
    "03_help_mart_create.sql",
  ]
) {
  console.log(`running sql/${f}`);
  const r = await new Deno.Command("python3", {
    args: [`${ROOT}/scripts/run_sql.py`, "--skip-exists", `${HERE}sql/${f}`],
    stdout: "piped",
    stderr: "piped",
  }).output();
  const out = new TextDecoder().decode(r.stdout) +
    new TextDecoder().decode(r.stderr);
  console.log(out.split("\n").slice(-12).join("\n"));
  if (!r.success) {
    console.error(`FAIL: ${f}`);
    Deno.exit(1);
  }
}

// 4. counts
for (const t of ["docs", "chunks", "pins", "pin_events", "pin_scores"]) {
  console.log(`${NS}.help_usl.${t}: ${await count(`${NS}.help_usl.${t}`)}`);
}
