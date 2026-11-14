// Chunking bake-off from docs/planning/help-app/experimental/chunking.md.
// Ingests each splitter into its own Milvus collection and scores the smoke questions.
// Does not drop help_index and does not register or replace help_app.help_search.
//
//   deno task help:chunk-bakeoff
//   deno task help:chunk-bakeoff -- --only windows
import { loadConfig } from "../core/config.ts";
import {
  type Corpus,
  loadKbaseCorpus,
  loadRepoCorpus,
  type Segment,
  splitByMode,
  type SplitMode,
} from "../core/corpus.ts";
import {
  countRows,
  createCollection,
  dropCollection,
  hasCollection,
} from "../core/milvus.ts";
import { type Passage, search } from "../core/query.ts";
import { rerank, topFiles } from "../core/rank.ts";
import { ingestSpec, runPipeline, segmentsSql } from "../core/specs.ts";
import { isHit, SMOKE } from "../core/smoke_set.ts";
import { zetarisClient } from "../core/zetaris.ts";
import { ROOT, SKIP } from "./verify.ts";

const MODES: SplitMode[] = ["current", "windows", "overlap"];
const WEIGHT = 0.05;
const MODEL_PASSAGES = 6;
const PREFIX = "help_chunk_";

const only = Deno.args.includes("--only")
  ? Deno.args[Deno.args.indexOf("--only") + 1]
  : "";
const modes = only ? MODES.filter((m) => m === only) : MODES;
if (modes.length === 0) {
  console.error(`--only must be one of ${MODES.join(", ")}`);
  Deno.exit(1);
}

function collectionName(mode: SplitMode): string {
  const name = `${PREFIX}${mode}`;
  if (!name.startsWith(PREFIX) || name === "help_index") {
    throw new Error(`refusing to touch collection ${name}`);
  }
  return name;
}

/** The activate form and MATERIALIZE in one passage. */
function hasActivateAndMaterialize(text: string): boolean {
  const at = text.search(/ACTIVATE\s+USL\s+TABLE\b/i);
  if (at < 0) return false;
  const window = text.slice(at, at + 800);
  return /\bAS\b/.test(window) && /MATERIALIZE/i.test(text);
}

interface VariantReport {
  mode: SplitMode;
  collection: string;
  segments: number;
  milvusRows: number;
  droppedDuplicates: number;
  hits: number;
  ranks: { id: string; rank: number; hit: boolean; top: string[] }[];
  uslInModelContext: boolean;
  uslInRetrieved: boolean;
  seconds: number;
}

const cfg = loadConfig();
const z = zetarisClient(cfg, 3_600_000);
await z.run("SELECT 1");
console.log("Zetaris reachable. help_index is not modified.");

const reports: VariantReport[] = [];
for (const mode of modes) {
  const t0 = Date.now();
  const split = (corpus: Corpus, file: string, text: string) =>
    splitByMode(corpus, file, text, mode);
  const repo = await loadRepoCorpus(ROOT, { skipPrefixes: SKIP, split });
  let kbase = { docs: [] as typeof repo.docs, segments: [] as Segment[] };
  try {
    kbase = await loadKbaseCorpus("corpus/kbase", split);
  } catch (e) {
    if (!(e instanceof Deno.errors.NotFound)) throw e;
  }
  const seen = new Set<string>();
  const segments: Segment[] = [];
  let droppedDuplicates = 0;
  for (const s of [...repo.segments, ...kbase.segments]) {
    if (seen.has(s.text)) {
      droppedDuplicates++;
      continue;
    }
    seen.add(s.text);
    segments.push({ ...s, part: segments.length });
  }
  // part must restart per file so provenance stays stable; re-number within each file
  // after the duplicate filter, preserving order.
  const partOf = new Map<string, number>();
  for (const s of segments) {
    const n = partOf.get(s.file) ?? 0;
    s.part = n;
    partOf.set(s.file, n + 1);
  }

  const collection = collectionName(mode);
  const variantCfg = { ...cfg, collection };
  console.log(
    `\n${mode}: ${segments.length} segments (${droppedDuplicates} duplicate texts dropped)`,
  );
  const existing = await hasCollection(variantCfg);
  let count = existing ? await countRows(variantCfg) : 0;
  // A count above the segment count means the Chunking guard split at least one
  // segment. The rows are already written, so score them instead of ingesting again.
  if (count >= segments.length) {
    console.log(`${collection} already holds ${count} rows; skipping ingest`);
  } else {
    if (existing) {
      await dropCollection(variantCfg);
      console.log(`dropped ${collection} (${count} rows)`);
    }
    await createCollection(variantCfg);
    const batches: Segment[][] = [];
    for (let i = 0; i < segments.length; i += cfg.batch) {
      batches.push(segments.slice(i, i + cfg.batch));
    }
    for (const [i, batch] of batches.entries()) {
      const t = Date.now();
      await z.run(
        runPipeline(
          "sink",
          100000,
          ingestSpec(cfg, segmentsSql(batch), collection),
        ),
        1,
      );
      console.log(
        `  batch ${i + 1}/${batches.length}: ${batch.length} in ${
          ((Date.now() - t) / 1000).toFixed(1)
        } s`,
      );
    }
    count = await countRows(variantCfg);
    for (let i = 0; i < 12 && count < segments.length; i++) {
      await new Promise((r) => setTimeout(r, 5000));
      count = await countRows(variantCfg);
    }
    console.log(`  milvus rows: ${count}`);
    if (count < segments.length) {
      throw new Error(
        `${collection}: expected ${segments.length} rows, Milvus has ${count}`,
      );
    }
  }

  const ranks: VariantReport["ranks"] = [];
  let hits = 0;
  let uslInModelContext = false;
  let uslInRetrieved = false;
  const inScope = SMOKE.filter((s) => s.group !== "out-of-scope");
  for (const s of inScope) {
    const passages: Passage[] = await search(variantCfg, z, s.q, 100);
    const ranked = rerank(s.q, passages, { weight: WEIGHT });
    const files = topFiles(ranked, 20);
    const idx = files.findIndex((f) => isHit(f.file, s.expect));
    const hit = idx >= 0 && idx < 3;
    if (hit) hits++;
    ranks.push({
      id: s.id,
      rank: idx + 1,
      hit,
      top: topFiles(ranked, 3).map((f) => f.file),
    });
    if (s.id === "usl-compile") {
      uslInRetrieved = passages.some((p) => hasActivateAndMaterialize(p.text));
      uslInModelContext = ranked.slice(0, MODEL_PASSAGES).some((p) =>
        hasActivateAndMaterialize(p.text)
      );
    }
    console.log(
      `  ${hit ? "ok  " : "MISS"} ${s.id.padEnd(16)} rank ${idx + 1 || "-"}`,
    );
  }
  reports.push({
    mode,
    collection,
    segments: segments.length,
    milvusRows: count,
    droppedDuplicates,
    hits,
    ranks,
    uslInModelContext,
    uslInRetrieved,
    seconds: Math.round((Date.now() - t0) / 1000),
  });
}

await Deno.mkdir(".cache", { recursive: true });
const outPath = ".cache/chunk-bakeoff.json";
await Deno.writeTextFile(outPath, JSON.stringify(reports, null, 2));
console.log(`\nwrote ${outPath}`);
console.log("\nmode      segments  hits/12  usl-in-context  seconds");
for (const r of reports) {
  console.log(
    `${r.mode.padEnd(9)} ${String(r.segments).padEnd(9)} ${
      String(r.hits).padEnd(8)
    } ${r.uslInModelContext ? "yes" : "no "}             ${r.seconds}`,
  );
}
