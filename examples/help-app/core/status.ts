// Connectivity and index checks for the status page. Every check is independent and never throws:
// a failure becomes `ok: false` with a short message. No URLs, keys or SQL text are returned.
import type { Config } from "./config.ts";
import { countRows } from "./milvus.ts";
import { toAskError } from "./ask.ts";
import type { Zetaris } from "./zetaris.ts";

export interface Check {
  name: string;
  ok: boolean;
  detail: string;
}

export interface StatusReport {
  checkedAt: string;
  checks: Check[];
  usl: { table: string; rows: number | null }[];
  lastIngest: { at: string; segments: number; model: string } | null;
}

const USL = "lightning.metastore.help_app_usl.help_usl";
// `search` and `answers` are left out: a SELECT on them runs a pipeline (the LLM, for answers).
export const USL_TABLES = [
  "docs",
  "chunks",
  "pins",
  "pin_events",
  "pin_scores",
];

/** An error whose message was written here and is safe to show. Anything else gets the generic text. */
class Safe extends Error {}

async function guard(name: string, fn: () => Promise<string>): Promise<Check> {
  try {
    return { name, ok: true, detail: await fn() };
  } catch (e) {
    return {
      name,
      ok: false,
      detail: e instanceof Safe ? e.message : toAskError(e).message,
    };
  }
}

export async function gatherStatus(
  cfg: Config,
  z: Zetaris | null,
  readManifest: () => Promise<string | null>,
  fetchTags: (url: string) => Promise<string[]> = defaultTags,
): Promise<StatusReport> {
  const checks: Check[] = [];
  const usl: StatusReport["usl"] = [];
  if (!z) {
    checks.push({
      name: "Zetaris",
      ok: false,
      detail: "ZETARIS_API_KEY is not set in .env.local.",
    });
  } else {
    checks.push(
      await guard("Zetaris", async () => {
        const r = await z.run("SELECT 1", 1);
        if (r.rows[0]?.[0] !== "1") {
          throw new Safe("unexpected result from SELECT 1");
        }
        return "reachable, SELECT 1 returned 1";
      }),
    );
    checks.push(
      await guard("Relations", async () => {
        const r = await z.run(`SHOW TABLES IN ${cfg.container}`, 50);
        const names = r.rows.map((x) => x[0].replace(`${cfg.container}.`, ""));
        for (const need of ["help_search"]) {
          if (!names.includes(need)) {
            throw new Safe(`${need} is missing; run help:ingest`);
          }
        }
        return names.join(", ");
      }),
    );
    for (const t of USL_TABLES) {
      try {
        const r = await z.run(`SELECT count(*) FROM ${USL}.${t}`, 1);
        usl.push({ table: t, rows: Number(r.rows[0][0]) });
      } catch {
        usl.push({ table: t, rows: null });
      }
    }
    checks.push({
      name: "USL help_usl",
      ok: usl.every((u) => u.rows !== null),
      detail: usl.every((u) => u.rows !== null)
        ? "every table answers a count"
        : "some tables did not answer; run help:usl",
    });
  }
  checks.push(
    await guard("Vector index", async () => {
      let n: number;
      try {
        n = await countRows(cfg);
      } catch {
        throw new Safe(
          `cannot read collection ${cfg.collection}; check MILVUS_HOST_URI and that Milvus is running`,
        );
      }
      return `${cfg.collection}: ${n} rows`;
    }),
  );
  if (!cfg.ollamaUrl || !cfg.ollamaModel) {
    checks.push({
      name: "LLM",
      ok: false,
      detail:
        "not configured (Search only). Set OLLAMA_URL and OLLAMA_MODEL for Answer mode.",
    });
  } else {
    checks.push(
      await guard("LLM", async () => {
        let tags: string[];
        try {
          tags = await fetchTags(cfg.ollamaUrl);
        } catch {
          throw new Safe(
            `model ${cfg.ollamaModel} is configured, but this machine cannot reach the LLM server ` +
              `(the Zetaris containers may still).`,
          );
        }
        if (!tags.includes(cfg.ollamaModel)) {
          throw new Safe(`the LLM server does not list ${cfg.ollamaModel}`);
        }
        return `${cfg.ollamaModel} is available`;
      }),
    );
  }
  let lastIngest: StatusReport["lastIngest"] = null;
  try {
    const m = JSON.parse((await readManifest()) ?? "null");
    if (m) lastIngest = { at: m.at, segments: m.segments, model: m.model };
  } catch { /* no manifest yet */ }
  return { checkedAt: new Date().toISOString(), checks, usl, lastIngest };
}

async function defaultTags(url: string): Promise<string[]> {
  const res = await fetch(`${url.replace(/\/$/, "")}/api/tags`, {
    signal: AbortSignal.timeout(5000),
  });
  if (!res.ok) throw new Error(String(res.status));
  const j = await res.json();
  return (j.models ?? []).map((m: { name: string }) => m.name);
}
