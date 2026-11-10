// Search-only smoke run: the curated questions against the live index, re-ranked at several
// keyword weights. Search results are cached so weights can be compared on identical candidates.
// Usage: deno task help:smoke [--refresh]
import { loadConfig } from "../core/config.ts";
import { type Passage, search } from "../core/query.ts";
import { rerank, topFiles } from "../core/rank.ts";
import { isHit, SMOKE } from "../core/smoke_set.ts";
import { zetarisClient } from "../core/zetaris.ts";

const WEIGHTS = [0, 0.05, 0.1, 0.15, 0.2, 0.3];
const CACHE = new URL("../.cache/smoke-search.json", import.meta.url).pathname;
const refresh = Deno.args.includes("--refresh");

let cached: Record<string, Passage[]> = {};
try {
  if (!refresh) cached = JSON.parse(await Deno.readTextFile(CACHE));
} catch { /* no cache yet */ }

const cfg = loadConfig();
const z = zetarisClient(cfg, 300_000);
for (const s of SMOKE) {
  if (!cached[s.id]) {
    cached[s.id] = await search(cfg, z, s.q, 100);
    console.error(`searched ${s.id}: ${cached[s.id].length} passages`);
  }
}
await Deno.mkdir(new URL("../.cache", import.meta.url).pathname, {
  recursive: true,
});
await Deno.writeTextFile(CACHE, JSON.stringify(cached));

const inScope = SMOKE.filter((s) => s.group !== "out-of-scope");
console.log(
  `\nIn-scope questions: ${inScope.length}. Hit = an expected file in the top 3 files.\n`,
);
console.log("weight  hits  ranks (first expected file, 0 = not in top 20)");
for (const w of WEIGHTS) {
  let hits = 0;
  const ranks: number[] = [];
  for (const s of inScope) {
    const files = topFiles(rerank(s.q, cached[s.id], { weight: w }), 20);
    const idx = files.findIndex((f) => isHit(f.file, s.expect));
    ranks.push(idx + 1);
    if (idx >= 0 && idx < 3) hits++;
  }
  console.log(
    `${w.toFixed(2).padEnd(7)} ${String(hits).padEnd(5)} ${ranks.join(" ")}`,
  );
}

const w = Number(Deno.env.get("SMOKE_WEIGHT") ?? "0.05");
console.log(`\nDetail at weight ${w}:`);
const lows: number[] = [];
for (const s of SMOKE) {
  const files = topFiles(rerank(s.q, cached[s.id], { weight: w }), 3);
  const top = cached[s.id].reduce((m, p) => Math.max(m, p.similarity), 0);
  if (s.group !== "out-of-scope") lows.push(top);
  const mark = s.group === "out-of-scope" ? "oos " : isHit(
      files.map((f) => f.file).find((f) => isHit(f, s.expect)) ?? "",
      s.expect,
    )
    ? "ok  "
    : "MISS";
  console.log(
    `${mark} ${s.id.padEnd(16)} top sim ${top.toFixed(3)}  ${
      files.map((f) => f.file.replace(/^https?:\/\/[^/]+\/(knowledge\/)?/, ""))
        .join(" | ")
    }`,
  );
}
console.log(
  `\nLowest in-scope top similarity: ${Math.min(...lows).toFixed(3)}`,
);
