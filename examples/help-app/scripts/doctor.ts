// Prerequisite check for the help app. Read-only: it connects, it does not create or change
// anything, and it never prints a key, password or token (only whether each is set).
// Usage: deno task help:doctor
import { loadConfig } from "../core/config.ts";
import { countRows, hasCollection } from "../core/milvus.ts";
import { toAskError } from "../core/ask.ts";
import { zetarisClient, ZetarisError } from "../core/zetaris.ts";

type Level = "ok" | "warn" | "fail";
const rows: { level: Level; name: string; detail: string }[] = [];
const add = (level: Level, name: string, detail: string) =>
  rows.push({ level, name, detail });

// 1. Deno
const [major, minor] = Deno.version.deno.split(".").map(Number);
if (major > 2 || (major === 2 && minor >= 9)) {
  add("ok", "Deno", Deno.version.deno);
} else {
  add("fail", "Deno", `${Deno.version.deno}: 2.9 or later is needed.`);
}

// 2. Settings (names only)
const cfg = loadConfig();
const need = (name: string, level: Level, why: string) => {
  if (Deno.env.get(name)) add("ok", name, "set");
  else add(level, name, `not set in .env.local: ${why}`);
};
need(
  "ZETARIS_API_KEY",
  "fail",
  "create a key in the Zetaris GUI (REST access).",
);
need(
  "HELP_PG_PASSWORD",
  "warn",
  "only needed for `help:usl` and Pinned/Candidates.",
);
need("OLLAMA_URL", "warn", "only needed for Answer and Example modes.");
need("OLLAMA_MODEL", "warn", "only needed for Answer and Example modes.");

// 3. Zetaris
let z: ReturnType<typeof zetarisClient> | null = null;
try {
  z = zetarisClient(cfg, 20_000);
} catch (e) {
  if (!(e instanceof ZetarisError)) throw e;
}
if (z) {
  try {
    const r = await z.run("SELECT 1", 1);
    if (r.rows[0]?.[0] === "1") {
      add("ok", "Zetaris REST", "SELECT 1 returned 1");
    } else add("fail", "Zetaris REST", "SELECT 1 returned something else.");
    try {
      const ds = await z.run("SHOW DATASOURCES", 100);
      const has = ds.rows.some((x) => x[0] === "help_pg");
      add(
        has ? "ok" : "warn",
        "Datasource help_pg",
        has
          ? "registered"
          : "not registered yet: `deno task help:usl` does it.",
      );
    } catch { /* optional */ }
  } catch (e) {
    add("fail", "Zetaris REST", toAskError(e).message);
  }
} else {
  add("fail", "Zetaris REST", "skipped: no API key.");
}

// 4. Milvus (the collection need not exist before the first ingest)
try {
  if (await hasCollection(cfg)) {
    add("ok", "Milvus", `${cfg.collection}: ${await countRows(cfg)} rows`);
  } else {
    add(
      "ok",
      "Milvus",
      `reachable; ${cfg.collection} does not exist yet (the ingest creates it).`,
    );
  }
} catch {
  add(
    "fail",
    "Milvus",
    "cannot reach it with MILVUS_HOST_URI and MILVUS_TOKEN; is it running?",
  );
}

// 5. Postgres: a TCP connect. HELP_PG_HOST is the name the Zetaris containers use, which this
// machine may not resolve, so localhost is tried too.
async function tcp(host: string, port: number): Promise<boolean> {
  try {
    const c = await Promise.race([
      Deno.connect({ hostname: host, port }),
      new Promise<never>((_, rej) =>
        setTimeout(() => rej(new Error("timeout")), 3000)
      ),
    ]);
    c.close();
    return true;
  } catch {
    return false;
  }
}
const pgPort = Number(cfg.pgPort);
const pgUp = (await tcp("127.0.0.1", pgPort)) ||
  (await tcp(cfg.pgHost, pgPort));
add(
  pgUp ? "ok" : "warn",
  "Postgres",
  pgUp
    ? `port ${pgPort} accepts connections`
    : `nothing on port ${pgPort}: start compose/docker-compose.postgres.yml (needed for help:usl, Pinned and Candidates).`,
);

// 6. LLM (optional)
if (cfg.ollamaUrl && cfg.ollamaModel) {
  try {
    const res = await fetch(`${cfg.ollamaUrl.replace(/\/$/, "")}/api/tags`, {
      signal: AbortSignal.timeout(5000),
    });
    const names: string[] = ((await res.json()).models ?? []).map((
      m: { name: string },
    ) => m.name);
    add(
      names.includes(cfg.ollamaModel) ? "ok" : "warn",
      "LLM",
      names.includes(cfg.ollamaModel)
        ? `${cfg.ollamaModel} is listed`
        : `the server does not list ${cfg.ollamaModel}.`,
    );
  } catch {
    add(
      "warn",
      "LLM",
      "this machine cannot reach it (the Zetaris containers may still).",
    );
  }
}

// 7. Local files
const exists = (p: string) => Deno.stat(p).then(() => true, () => false);
add(
  (await exists("corpus/kbase/manifest.json")) ? "ok" : "warn",
  "Kbase snapshot",
  (await exists("corpus/kbase/manifest.json"))
    ? "present"
    : "missing: `deno task help:fetch-kbase`, or ingest with --no-kbase.",
);
add(
  (await exists("_fresh")) ? "ok" : "warn",
  "App build",
  (await exists("_fresh")) ? "built" : "not built yet: `deno task build`.",
);

const mark = { ok: "PASS", warn: "WARN", fail: "FAIL" };
for (const r of rows) console.log(`${mark[r.level]}  ${r.name}: ${r.detail}`);
const fails = rows.filter((r) => r.level === "fail").length;
const warns = rows.filter((r) => r.level === "warn").length;
console.log(`\n${fails} failed, ${warns} warnings.`);
if (fails > 0) {
  console.log(
    "Fix the FAIL lines first: nothing else will work until they pass.",
  );
  Deno.exit(1);
}
