// Server-side wiring: config, the Zetaris client and the real AskDeps. Created lazily so the app
// starts (and the status page explains) even when ZETARIS_API_KEY is not set.
import { type AskDeps } from "./ask.ts";
import { type Config, loadConfig } from "./config.ts";
import { InFlight } from "./limit.ts";
import { answer, search } from "./query.ts";
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

export function askDeps(): AskDeps {
  const c = getConfig();
  const z = getZetaris();
  const need = (): Zetaris => {
    if (!z) throw new ZetarisError("no key", "config");
    return z;
  };
  return {
    llmConfigured: Boolean(c.ollamaUrl && c.ollamaModel),
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
