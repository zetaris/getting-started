// Ingest the repo's Markdown into Milvus through Zetaris pipelines.
//   deno task help:ingest --dry-run   print what would run, change nothing
//   deno task help:ingest [--yes]     drop and recreate the collection, ingest, verify, register
// Safe to run twice: the collection is recreated and the counts are checked. A non-empty
// collection is only dropped with --yes.
import { loadRepoCorpus, type Segment } from "../core/corpus.ts";
import { loadConfig } from "../core/config.ts";
import {
  collectionBody,
  countRows,
  createCollection,
  dropCollection,
  hasCollection,
} from "../core/milvus.ts";
import {
  answerSpec,
  ingestSpec,
  registerRelation,
  runPipeline,
  searchSpec,
  segmentsSql,
} from "../core/specs.ts";
import { zetarisClient } from "../core/zetaris.ts";
import { ROOT, SKIP } from "./verify.ts";

const dryRun = Deno.args.includes("--dry-run");
const yes = Deno.args.includes("--yes");
const cfg = loadConfig();

// Known questions and a file that must come back in the top 3 (a cheap check after ingest).
const KNOWN: [string, string][] = [
  [
    "What does AGENTS.md say about dry runs before running a create script?",
    "AGENTS.md",
  ],
  ["How do I onboard a REST API source?", "open_data/rest_apis/HOWTO.md"],
];

function mask(spec: ReturnType<typeof ingestSpec>) {
  const copy = JSON.parse(JSON.stringify(spec));
  copy.nodes[3].config.token = "<token>";
  const sql: string = copy.nodes[0].sqlExpression;
  copy.nodes[0].sqlExpression = `${sql.split("\nunion all\n")[0]}\n... (${
    sql.split("\nunion all\n").length
  } rows in this batch)`;
  return copy;
}

const { docs, segments } = await loadRepoCorpus(ROOT, { skipPrefixes: SKIP });
const batches: Segment[][] = [];
for (let i = 0; i < segments.length; i += cfg.batch) {
  batches.push(segments.slice(i, i + cfg.batch));
}
console.log(
  `corpus: ${docs.length} files, ${segments.length} segments, ${batches.length} batches of up to ${cfg.batch}`,
);

if (dryRun) {
  console.log(`\n1. Milvus (${cfg.milvusHostUri}): drop and create collection`);
  console.log(JSON.stringify(collectionBody(cfg), null, 2));
  console.log(
    `\n2. For each batch, on Zetaris: RUN PIPELINE ON 'sink' LIMIT 100000 SPEC ...`,
  );
  console.log(
    JSON.stringify(mask(ingestSpec(cfg, segmentsSql(batches[0]))), null, 2),
  );
  console.log(
    `\n3. Verify: Milvus count must equal ${segments.length}; ${KNOWN.length} known questions.`,
  );
  console.log(
    `4. Register ${cfg.container}.help_search${
      cfg.ollamaUrl ? " and help_answer" : " (no OLLAMA_URL, so no help_answer)"
    }.`,
  );
  console.log("\ndry run: nothing was sent.");
  Deno.exit(0);
}

const z = zetarisClient(cfg, 3_600_000);
await z.run("SELECT 1");
console.log("Zetaris reachable.");

if (await hasCollection(cfg)) {
  const n = await countRows(cfg);
  if (n > 0 && !yes) {
    console.error(
      `Collection ${cfg.collection} already holds ${n} rows. Re-run with --yes to drop and recreate it.`,
    );
    Deno.exit(1);
  }
  await dropCollection(cfg);
  console.log(`dropped ${cfg.collection} (${n} rows)`);
}
await createCollection(cfg);
console.log(`created ${cfg.collection} (${cfg.dim} dimensions, COSINE)`);

const t0 = Date.now();
for (const [i, batch] of batches.entries()) {
  const t = Date.now();
  // LIMIT 100000 is deliberate: a small LIMIT on a sink run silently writes only fragments.
  await z.run(
    runPipeline("sink", 100000, ingestSpec(cfg, segmentsSql(batch))),
    1,
  );
  console.log(
    `batch ${i + 1}/${batches.length}: ${batch.length} segments in ${
      ((Date.now() - t) / 1000).toFixed(1)
    } s`,
  );
}

const count = await countRows(cfg);
console.log(`milvus rows: ${count}, segments: ${segments.length}`);
let ok = count === segments.length;
if (!ok) console.error(`FAIL: ${segments.length - count} segments missing.`);

for (const [q, file] of KNOWN) {
  const r = await z.run(runPipeline("vs_search", 3, searchSpec(cfg, q)), 3);
  const files = r.rows.map((row) => row[1].match(/FILE: (\S+)/)?.[1] ?? "?");
  const hit = files.includes(file);
  console.log(
    `${hit ? "ok  " : "FAIL"} "${q.slice(0, 50)}" -> ${files.join(", ")}`,
  );
  ok &&= hit;
}

// Saved relations. Never SELECT from an ingest relation: it would re-run the ingest.
try {
  await z.run(
    `CREATE PIPELINE CONTAINER ${cfg.container} DESCRIPTION 'Help app RAG pipelines'`,
  );
} catch (e) {
  if (!/exist/i.test(String(e))) throw e;
}
const relations: [string, unknown][] = [
  ["help_search", searchSpec(cfg, "How do I register a REST source?")],
];
if (cfg.ollamaUrl && cfg.ollamaModel) {
  relations.push([
    "help_answer",
    answerSpec(cfg, "How do I register a REST source?"),
  ]);
}
for (const [name, spec] of relations) {
  try {
    await z.run(`DROP PIPELINE RELATION ${cfg.container}.${name}`);
  } catch { /* not there yet */ }
  await z.run(registerRelation(cfg.container, spec));
  console.log(`registered ${cfg.container}.${name}`);
}
const rows =
  (await z.run(`SELECT * FROM ${cfg.container}.help_search`, 200)).rows.length;
console.log(`SELECT * FROM ${cfg.container}.help_search -> ${rows} rows`);
ok &&= rows === 100;

await Deno.mkdir(".cache", { recursive: true });
await Deno.writeTextFile(
  ".cache/ingest-manifest.json",
  JSON.stringify(
    {
      at: new Date().toISOString(),
      collection: cfg.collection,
      model: cfg.embeddingModel,
      segments: segments.length,
      milvusRows: count,
      seconds: Math.round((Date.now() - t0) / 1000),
      docs: docs.map(({ path, gitSha, chunkCount }) => ({
        path,
        gitSha,
        chunkCount,
      })),
    },
    null,
    2,
  ),
);
console.log(ok ? "\nok" : "\nFAILED: see above");
Deno.exit(ok ? 0 : 1);
