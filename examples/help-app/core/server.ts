// Server-side wiring: config, the Zetaris client and the real AskDeps. Created lazily so the app
// starts (and the status page explains) even when ZETARIS_API_KEY is not set.
import { type AskDeps } from "./ask.ts";
import { createCollection, hasCollection } from "./milvus.ts";
import { findPast, type PinStore } from "./pins.ts";
import { type Config, loadConfig } from "./config.ts";
import { InFlight } from "./limit.ts";
import { answer, parsePassage, search } from "./query.ts";
import { ingestSpec, runPipeline, searchSpec, segmentsSql } from "./specs.ts";
import { type Zetaris, zetarisClient, ZetarisError } from "./zetaris.ts";

// Paths are relative to the working directory (the app folder, where the deno tasks run), not to
// import.meta.url, which points inside _fresh/ in the built server.
const appDir = () => Deno.cwd();
const repoRoot = () => `${Deno.cwd()}/../..`;
const ASK_TIMEOUT_MS = 120_000;

let cfg: Config | null = null;
export function getConfig(): Config {
  return cfg ??= loadConfig();
}

/** The Zetaris client for asks, or null when no API key is set. */
export function getZetaris(timeoutMs = ASK_TIMEOUT_MS): Zetaris | null {
  try {
    return zetarisClient(getConfig(), timeoutMs);
  } catch (e) {
    if (e instanceof ZetarisError && e.kind === "config") return null;
    throw e;
  }
}

export const inFlight = new InFlight();

/** The pin store over Zetaris (rows) and Milvus (the pins collection), or null without an API key. */
export function pinStore(): PinStore | null {
  const z = getZetaris();
  if (!z) return null;
  const c = getConfig();
  const pc = { ...c, collection: c.pinsCollection };
  let known = false; // the collection exists (once seen, it stays)
  const ensure = async (create: boolean) => {
    if (known) return true;
    if (!(await hasCollection(pc))) {
      if (!create) return false;
      await createCollection(pc);
    }
    return known = true;
  };
  return {
    run: (sql, limit) => z.run(sql, limit),
    async embedPin(seg) {
      await ensure(true);
      await z.run(
        runPipeline("sink", 100000, ingestSpec(pc, segmentsSql([seg]))),
        1,
      );
    },
    async searchPins(question) {
      if (!(await ensure(false))) return [];
      const r = await z.run(
        runPipeline("vs_search", 10, searchSpec(pc, question)),
        10,
      );
      return r.rows.map(parsePassage);
    },
  };
}

export function askDeps(): AskDeps {
  const c = getConfig();
  const z = getZetaris();
  const pins = pinStore();
  const need = (): Zetaris => {
    if (!z) throw new ZetarisError("no key", "config");
    return z;
  };
  return {
    llmConfigured: Boolean(c.ollamaUrl && c.ollamaModel),
    pastAnswers: pins ? (q) => findPast(pins, q, c.pinThreshold) : undefined,
    search: (q, limit) => search(c, need(), q, limit),
    answer: async (q, contexts) =>
      (await answer(c, need(), q, contexts)).answer,
    readFile: (f) => Deno.readTextFile(`${repoRoot()}/${f}`).catch(() => null),
  };
}

export function readIngestManifest(): Promise<string | null> {
  return Deno.readTextFile(`${appDir()}/.cache/ingest-manifest.json`).catch(
    () => null,
  );
}

/** File reads for the Docs browser. The catalog check happens before these are called; the
 * resolved path is also confirmed to stay inside its root (a symlink must not lead out). */
async function readInside(root: string, rel: string): Promise<string | null> {
  try {
    const base = await Deno.realPath(root);
    const full = await Deno.realPath(`${base}/${rel}`);
    if (!full.startsWith(`${base}/`)) return null;
    return await Deno.readTextFile(full);
  } catch {
    return null;
  }
}

export const docIo = {
  readRepo: (path: string) => readInside(repoRoot(), path),
  readKbase: (slug: string) =>
    readInside(`${appDir()}/corpus/kbase`, `${slug}.md`),
};
