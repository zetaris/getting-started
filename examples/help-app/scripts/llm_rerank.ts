// LLM rerank experiment from docs/planning/help-app/experimental/llm-rerank.md.
// One search of help_index per smoke question, then the keyword order and one
// Zetaris LLM call per model arm. Does not change rank.ts or the Search page.
//
//   deno task help:llm-rerank
import { loadConfig } from "../core/config.ts";
import { answer, search } from "../core/query.ts";
import { rerank, topFiles } from "../core/rank.ts";
import { isHit, SMOKE } from "../core/smoke_set.ts";
import { zetarisClient } from "../core/zetaris.ts";

const WEIGHT = 0.05;
const BATCH = 20;
const CLIP = 400;
const CACHE = ".cache/llm-rerank.json";

const EMBEDDING = /embed|e5-|bge-|minilm|nomic/i;

interface Tag {
  name: string;
  size: number;
}

interface Call {
  parseOk: boolean;
  order: number[];
  seconds: number;
  rank: number;
  hit: boolean;
  /** Seconds counted in the latency table. A garbled reply uses the keyword arm. */
  latencySeconds: number;
}

interface Report {
  smallModel: string | null;
  tags: { name: string; gib: number }[];
  questions: {
    id: string;
    keywordRank: number;
    keywordHit: boolean;
    inBatch: boolean;
    arms: Record<string, Call>;
  }[];
}

function parseOrder(text: string, n: number): number[] | null {
  const lines = text.split(/\n/).map((s) => s.trim()).filter(Boolean);
  if (lines.length === 0) return null;
  const nums: number[] = [];
  for (const line of lines) {
    const m = line.match(/^(?:passage\s+)?(\d{1,2})$/i);
    if (!m) return null;
    const k = Number(m[1]);
    if (k < 1 || k > n || nums.includes(k)) return null;
    nums.push(k);
  }
  return nums;
}

function fileRank(files: string[], expect: string[]): number {
  const seen: string[] = [];
  for (const f of files) if (!seen.includes(f)) seen.push(f);
  return seen.findIndex((f) => isHit(f, expect)) + 1;
}

async function tags(url: string): Promise<Tag[]> {
  const res = await fetch(`${url.replace(/\/$/, "")}/api/tags`, {
    signal: AbortSignal.timeout(8000),
  });
  if (!res.ok) throw new Error(`Ollama tags HTTP ${res.status}`);
  const body = await res.json();
  return (body.models ?? []).map((m: { name?: string; size?: number }) => ({
    name: String(m.name ?? ""),
    size: Number(m.size ?? 0),
  })).filter((m: Tag) => m.name);
}

function smallestOther(list: Tag[], current: string): string | null {
  const mine = list.find((m) =>
    m.name === current || m.name.startsWith(`${current}:`)
  );
  const ceiling = mine?.size ?? Number.POSITIVE_INFINITY;
  const rest = list.filter((m) =>
    m.name !== current && !m.name.startsWith(`${current}:`) &&
    !EMBEDDING.test(m.name) &&
    m.size > 0 && m.size < ceiling
  );
  rest.sort((a, b) => a.size - b.size);
  return rest[0]?.name ?? null;
}

const promptFor = (n: number) =>
  `Order the ${n} passages for the question. Reply with the passage numbers, best first, one number per line, and nothing else.`;

let saved: Report = { smallModel: null, tags: [], questions: [] };
try {
  saved = JSON.parse(await Deno.readTextFile(CACHE));
} catch { /* first run */ }

const cfg = loadConfig();
if (!cfg.ollamaUrl || !cfg.ollamaModel) {
  console.error("OLLAMA_URL and OLLAMA_MODEL are required.");
  Deno.exit(1);
}
let listed: Tag[] = [];
try {
  listed = await tags(cfg.ollamaUrl);
} catch (e) {
  console.log(
    `could not list models from this machine: ${(e as Error).message}`,
  );
}
const small = smallestOther(listed, cfg.ollamaModel);
saved.tags = listed.map((t) => ({
  name: t.name,
  gib: Math.round(t.size / 1e8) / 10,
}));
saved.smallModel = small;
console.log(`answer model: ${cfg.ollamaModel}`);
console.log(
  small
    ? `small model: ${small}`
    : "no smaller non-embedding model listed; that arm is skipped",
);

const z = zetarisClient(cfg, 180_000);
await z.run("SELECT 1");
const questions = SMOKE.filter((s) => s.group !== "out-of-scope");
const models = [cfg.ollamaModel, ...(small ? [small] : [])];

for (const s of questions) {
  let row = saved.questions.find((q) => q.id === s.id);
  if (!row) {
    const found = await search(cfg, z, s.q, 100);
    const ranked = rerank(s.q, found, { weight: WEIGHT });
    const keywordRank = fileRank(
      topFiles(ranked, 20).map((f) => f.file),
      s.expect,
    );
    const batch = ranked.slice(0, BATCH);
    row = {
      id: s.id,
      keywordRank,
      keywordHit: keywordRank >= 1 && keywordRank <= 3,
      inBatch: batch.some((p) => isHit(p.file, s.expect)),
      arms: {},
    };
    saved.questions.push(row);
    await Deno.mkdir(".cache", { recursive: true });
    await Deno.writeTextFile(CACHE, JSON.stringify(saved));
    console.log(`searched ${s.id}: keyword rank ${keywordRank || "-"}`);
  }
}

for (const model of models) {
  const modelCfg = { ...cfg, ollamaModel: model };
  for (const s of questions) {
    const row = saved.questions.find((q) => q.id === s.id)!;
    if (row.arms[model]) {
      console.log(`cached ${model} ${s.id}`);
      continue;
    }
    const found = await search(cfg, z, s.q, 100);
    const ranked = rerank(s.q, found, { weight: WEIGHT });
    const batch = ranked.slice(0, BATCH);
    const passages = batch.map((p, i) => ({
      header: `PASSAGE ${
        i + 1
      }\nREPO: ${p.corpus}\nFILE: ${p.file}\nSECTION: ${p.section}`,
      text: p.text.slice(0, CLIP),
      similarity: p.similarity,
    }));
    const t0 = performance.now();
    let reply = "";
    try {
      reply =
        (await answer(modelCfg, z, s.q, passages, promptFor(batch.length)))
          .answer;
    } catch (e) {
      reply = "";
      console.log(
        `  ${model} ${s.id} call failed: ${(e as Error).message.slice(0, 160)}`,
      );
    }
    const seconds = Math.round((performance.now() - t0) / 100) / 10;
    const order = parseOrder(reply, batch.length);
    const parseOk = order !== null;
    let rank = 0;
    if (parseOk) {
      const files = order.map((n) => batch[n - 1].file);
      for (let i = 0; i < batch.length; i++) {
        if (!order.includes(i + 1)) files.push(batch[i].file);
      }
      rank = fileRank(files, s.expect);
    }
    const hit = parseOk && rank >= 1 && rank <= 3;
    row.arms[model] = {
      parseOk,
      order: order ?? [],
      seconds,
      rank,
      hit,
      latencySeconds: parseOk ? seconds : 0,
    };
    await Deno.writeTextFile(CACHE, JSON.stringify(saved));
    console.log(
      `  ${parseOk ? "ok  " : "GARBLE"} ${model} ${s.id} rank ${
        rank || "-"
      } in ${seconds}s`,
    );
  }
}

const summary = models.map((model) => {
  const calls = saved.questions.map((q) => q.arms[model]).filter(Boolean);
  const hits = calls.filter((c) => c.hit).length;
  return { model, hits, calls: calls.length };
});
console.log(JSON.stringify({ small, summary }, null, 2));
