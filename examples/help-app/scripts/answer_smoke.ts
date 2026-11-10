// Answer-mode run: search, re-rank, then answer from the top passages (or whole files for code
// questions). Prints answers for a hand check. Needs OLLAMA_URL and OLLAMA_MODEL.
// Usage: deno task help:answer [id ...]
import { loadConfig } from "../core/config.ts";
import { answer, search } from "../core/query.ts";
import {
  isCodeQuestion,
  pickCodeFiles,
  wholeFileContext,
} from "../core/prompt.ts";
import { rerank, topFiles } from "../core/rank.ts";
import { SMOKE } from "../core/smoke_set.ts";
import { zetarisClient } from "../core/zetaris.ts";

const ROOT = new URL("../../..", import.meta.url).pathname.replace(/\/$/, "");
const cfg = loadConfig();
const z = zetarisClient(cfg, 900_000);
const ids = Deno.args;
for (const s of SMOKE.filter((x) => ids.length === 0 || ids.includes(x.id))) {
  const ranked = rerank(s.q, await search(cfg, z, s.q, 100));
  const files = topFiles(ranked, 12);
  let ctx: { header: string; text: string; similarity: number }[];
  if (isCodeQuestion(s.q)) {
    const whole = await wholeFileContext(
      pickCodeFiles(
        files.filter((f) => f.corpus === "repo").map((f) => f.file),
      ),
      (f) => Deno.readTextFile(`${ROOT}/${f}`).catch(() => null),
      4,
    );
    ctx = whole.map((w) => ({ ...w, similarity: files[0].score }));
  } else {
    ctx = ranked.slice(0, 6).map((p) => ({
      header: `REPO: ${p.corpus}\nFILE: ${p.file}\nSECTION: ${p.section}`,
      text: p.text,
      similarity: p.similarity,
    }));
  }
  const t = performance.now();
  try {
    const a = await answer(cfg, z, s.q, ctx);
    console.log(
      `\n=== ${s.id} (${
        ((performance.now() - t) / 1000).toFixed(0)
      } s, ${ctx.length} contexts)\nQ: ${s.q}\n${a.answer}`,
    );
  } catch (e) {
    console.log(`\n=== ${s.id} ERROR ${(e as Error).message.slice(0, 300)}`);
  }
}
