import { assert, assertEquals } from "@std/assert";
import { gatherStatus } from "./status.ts";
import type { Config } from "./config.ts";
import type { Zetaris } from "./zetaris.ts";
import { ZetarisError } from "./zetaris.ts";

const cfg = {
  container: "help_app",
  collection: "c",
  milvusHostUri: "http://127.0.0.1:1", // refused: the index check must fail, not throw
  milvusToken: "t",
  ollamaUrl: "",
  ollamaModel: "",
} as unknown as Config;

const fakeZ = (fail = false): Zetaris => ({
  run: (sql: string) => {
    if (fail) return Promise.reject(new ZetarisError("down", "unreachable"));
    if (sql.startsWith("SHOW TABLES")) {
      return Promise.resolve({
        rows: [["help_app.help_search", "help_app", "Pipeline"]],
        headers: [],
      });
    }
    return Promise.resolve({ rows: [["1"]], headers: [] });
  },
});

Deno.test("a healthy Zetaris and an unreachable index give per-check results, never a throw", async () => {
  const r = await gatherStatus(cfg, fakeZ(), () => Promise.resolve(null));
  const by = Object.fromEntries(r.checks.map((c) => [c.name, c]));
  assert(by["Zetaris"].ok);
  assert(by["Relations"].ok);
  assert(!by["Vector index"].ok);
  assert(!by["LLM"].ok && by["LLM"].detail.includes("Search only"));
  assertEquals(r.usl.length, 5);
});

Deno.test("an unreachable Zetaris is reported with the clear message", async () => {
  const r = await gatherStatus(cfg, fakeZ(true), () => Promise.resolve(null));
  const z = r.checks.find((c) => c.name === "Zetaris")!;
  assert(!z.ok && z.detail.includes("not reachable"));
});

Deno.test("no API key is reported, and the last ingest is read from the manifest", async () => {
  const r = await gatherStatus(
    cfg,
    null,
    () =>
      Promise.resolve(
        JSON.stringify({ at: "2026-01-01T00:00:00Z", segments: 5, model: "m" }),
      ),
  );
  assert(r.checks[0].detail.includes("ZETARIS_API_KEY"));
  assertEquals(r.lastIngest?.segments, 5);
});

Deno.test("the LLM check lists the configured model", async () => {
  const c = { ...cfg, ollamaUrl: "http://x", ollamaModel: "m1" } as Config;
  const ok = await gatherStatus(
    c,
    null,
    () => Promise.resolve(null),
    () => Promise.resolve(["m1"]),
  );
  assert(ok.checks.find((x) => x.name === "LLM")!.ok);
  const missing = await gatherStatus(
    c,
    null,
    () => Promise.resolve(null),
    () => Promise.resolve(["z"]),
  );
  assert(!missing.checks.find((x) => x.name === "LLM")!.ok);
  const down = await gatherStatus(
    c,
    null,
    () => Promise.resolve(null),
    () => Promise.reject(new Error("x")),
  );
  assert(
    down.checks.find((x) => x.name === "LLM")!.detail.includes("cannot reach"),
  );
});
