// A tiny stand-in for Zetaris, Milvus and Ollama, so the e2e tests need no live stack.
// It answers only what the app asks: SELECT 1, SHOW TABLES, counts, RUN PIPELINE for search and
// for answers, Milvus's count query and Ollama's /api/tags. Test hooks: /__control sets a delay
// for answers or a forced failure.
import { createServer } from "node:http";

const KEY = "e2e-key";
const state = { answerDelayMs: 0, fail: 0 };

const passage = (corpus, file, part, section, text, sim) => [
  "q",
  `REPO: ${corpus}\nFILE: ${file}\nPART: ${part}\nSECTION: ${section}\nTEXT: ${text}`,
  String(sim),
];

const SEARCH_ROWS = [
  passage("repo", "open_data/rest_apis/HOWTO.md", 2, "Fast start", "Register the REST API source with CREATE LIGHTNING REST TABLE, then flatten it with a SchemaStore view.", 0.89),
  passage("repo", "open_data/rest_apis/rest-api-sources.md", 0, "Catalog", "Every REST source, its license and its rate limit.", 0.85),
  passage("kbase", "https://kbase.example.test/knowledge/how-to-clone-pipeline", 1, "How to clone Pipeline", "Open the Pipeline tab, choose Clone.", 0.83),
  passage("repo", "AGENTS.md", 4, "Running scripts", "Dry-run first and show the user the statement list.", 0.8),
  passage("repo", "docs/guides/permissions.md", 1, "Least privilege", "An agent that only reads should run as a non-administrator.", 0.78),
  passage("repo", "scripts/HOWTO.md", 3, "Options", "Use --dry-run before any create script.", 0.77),
];

function send(res, status, body) {
  res.writeHead(status, { "content-type": "application/json" });
  res.end(JSON.stringify(body));
}

createServer((req, res) => {
  let raw = "";
  req.on("data", (c) => (raw += c));
  req.on("end", async () => {
    const url = new URL(req.url, "http://x");
    if (url.pathname === "/__control") {
      state.answerDelayMs = Number(url.searchParams.get("answerDelayMs") ?? 0);
      state.fail = Number(url.searchParams.get("fail") ?? 0);
      return send(res, 200, state);
    }
    if (url.pathname === "/api/tags") return send(res, 200, { models: [{ name: "mock-model" }] });
    if (url.pathname === "/v2/vectordb/entities/query") {
      return send(res, 200, { code: 0, data: [{ "count(*)": 42 }] });
    }
    if (url.pathname.endsWith("/sql-editor/sqls/run")) {
      if (req.headers.authorization !== `Bearer ${KEY}`) return send(res, 401, { msg: "bad key" });
      const { sql } = JSON.parse(raw);
      if (state.fail) {
        // The text includes SQL on purpose: the app must never show it.
        return send(res, state.fail, { msg: `Error running query: ${sql.slice(0, 60)} LEAKED_SQL_TEXT` });
      }
      if (sql.startsWith("SELECT 1")) return send(res, 200, { headers: ["1"], data: [["1"]] });
      if (sql.startsWith("SHOW TABLES")) {
        return send(res, 200, { data: [["help_app.help_search", "help_app", "Pipeline"], ["help_app.help_answer", "help_app", "Pipeline"]] });
      }
      if (sql.startsWith("SELECT count(*)")) return send(res, 200, { data: [["7"]] });
      if (sql.includes("RUN PIPELINE ON 'llm_answer'")) {
        if (state.answerDelayMs) await new Promise((r) => setTimeout(r, state.answerDelayMs));
        return send(res, 200, { data: [["q", "Register the source with CREATE LIGHTNING REST TABLE (open_data/rest_apis/HOWTO.md).", "ctx"]] });
      }
      if (sql.includes("RUN PIPELINE ON 'vs_search'")) {
        const empty = sql.includes("nothingmatchesthis");
        return send(res, 200, { headers: ["prompt", "content", "similarity"], data: empty ? [] : SEARCH_ROWS });
      }
      return send(res, 400, { msg: "mock: unsupported statement" });
    }
    send(res, 404, { msg: "not found" });
  });
}).listen(Number(process.env.MOCK_PORT ?? 8899), "127.0.0.1");
