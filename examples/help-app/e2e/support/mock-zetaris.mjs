// A tiny stand-in for Zetaris, Milvus and Ollama, so the e2e tests need no live stack.
// It answers only what the app asks: SELECT 1, SHOW TABLES, counts, RUN PIPELINE for search and
// for answers, Milvus's count query and Ollama's /api/tags. Test hooks: /__control sets a delay
// for answers or a forced failure.
import { createServer } from "node:http";

const KEY = "e2e-key";
const state = { answerDelayMs: 0, fail: 0, xss: 0, bumpSha: 0, answerRuns: 0, exampleMode: "pass", explainRuns: 0, llmPrompts: [] };
const candidates = new Map();
const pins = new Map(); // pin_id -> row
const events = [];
const b64s = (sql) => [...sql.matchAll(/unbase64\('([A-Za-z0-9+/=]*)'\)/g)].map((m) => Buffer.from(m[1], "base64").toString("utf8"));
const likes = (id) => events.filter((e) => e.pin === id).reduce((n, e) => n + (e.kind === "like" ? 1 : e.kind === "unlike" ? -1 : 0), 0);
const uses = (id) => events.filter((e) => e.pin === id && e.kind === "use").length;
const DOCS = [
  ["AGENTS.md", "repo", "Agent instructions", "agent-rules", "16"],
  ["open_data/rest_apis/HOWTO.md", "repo", "REST APIs HOWTO", "howto", "20"],
  ["scripts/HOWTO.md", "repo", "Scripts HOWTO", "howto", "5"],
  ["open_data/usl/sql/02_sic_edgar_usl_select.sql", "repo", "SIC EDGAR USL select", "sql-example", "1"],
  ["https://kbase.zetaris.com/knowledge/how-to-clone-pipeline", "kbase", "How to clone Pipeline", "how-to", "3"],
];
const sha = (path) => `sha-${path}${state.bumpSha ? "-v2" : ""}`;
const XSS_ANSWER = '<script>window.__pwned=1</script><img src=x onerror="window.__pwned=1"> [click](javascript:window.__pwned=1) **bold ok**';

const passage = (corpus, file, part, section, text, sim) => [
  "q",
  `REPO: ${corpus}\nFILE: ${file}\nPART: ${part}\nSECTION: ${section}\nTEXT: ${text}`,
  String(sim),
];

const SEARCH_ROWS = [
  passage("repo", "open_data/rest_apis/HOWTO.md", 2, "Fast start", "Register the REST API source with CREATE LIGHTNING REST TABLE, then flatten it with a SchemaStore view.", 0.89),
  passage("repo", "open_data/rest_apis/rest-api-sources.md", 0, "Catalog", "Every REST source, its license and its rate limit.", 0.85),
  passage("kbase", "https://kbase.zetaris.com/knowledge/how-to-clone-pipeline", 1, "How to clone Pipeline", "Open the Pipeline tab, choose Clone.", 0.83),
  passage("repo", "AGENTS.md", 4, "Running scripts", "Dry-run first and show the user the statement list.", 0.8),
  passage("repo", "docs/guides/permissions.md", 1, "Least privilege", "An agent that only reads should run as a non-administrator.", 0.78),
  passage("repo", "scripts/HOWTO.md", 3, "Options", "Use --dry-run before any create script.", 0.77),
  passage("repo", "open_data/usl/sql/02_sic_edgar_usl_select.sql", 0, "Checks", "SELECT COUNT(*) FROM company", 0.7),
];
const EXAMPLES = {
  pass: "Counts the docs.\n```sql\nSELECT count(*) FROM lightning.metastore.help_app_usl.help_usl.docs\n```\nDrew from: open_data/usl/sql/02_sic_edgar_usl_select.sql",
  bad: "Counts.\n```sql\nSELECT BADCOL FROM lightning.metastore.help_app_usl.help_usl.docs\n```",
  ddl: "Makes a namespace.\n```sql\nCREATE NAMESPACE IF NOT EXISTS lightning.metastore.zz\n```",
  xss: "Shows text.\n```sql\nSELECT '<script>window.__pwned=1</script>' AS x\n```",
  never: "I cannot write that.",
  notcovered: "Not covered in the supplied files.",
};

function send(res, status, body) {
  res.writeHead(status, { "content-type": "application/json" });
  res.end(JSON.stringify(body));
}

createServer((req, res) => {
  let raw = "";
  req.on("data", (c) => (raw += c));
  req.on("end", async () => {
    const url = new URL(req.url, "http://x");
    if (url.pathname === "/__state") return send(res, 200, { ...state, pins: pins.size, events: events.length, candidates: candidates.size });
    if (url.pathname === "/__control") {
      state.answerDelayMs = Number(url.searchParams.get("answerDelayMs") ?? 0);
      state.fail = Number(url.searchParams.get("fail") ?? 0);
      state.xss = Number(url.searchParams.get("xss") ?? 0);
      state.bumpSha = Number(url.searchParams.get("bumpSha") ?? 0);
      state.exampleMode = url.searchParams.get("exampleMode") ?? "pass";
      if (url.searchParams.get("reset") === "1") {
        pins.clear();
        events.length = 0;
        state.answerRuns = 0;
        state.explainRuns = 0;
        state.llmPrompts.length = 0;
        candidates.clear();
      }
      return send(res, 200, { ...state, pins: pins.size, events: events.length });
    }
    if (url.pathname === "/api/tags") return send(res, 200, { models: [{ name: "mock-model" }] });
    if (url.pathname === "/v2/vectordb/collections/list") return send(res, 200, { code: 0, data: ["help_pins"] });
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
      if (sql.startsWith("SELECT path, corpus, title, kind, chunk_count")) return send(res, 200, { data: DOCS });
      if (sql.startsWith("SELECT part, section, char_count")) return send(res, 200, { data: [["0", "Intro", "400"], ["1", "Details", "900"]] });
      if (sql.startsWith("SELECT path, git_sha")) {
        const want = b64s(sql);
        return send(res, 200, { data: DOCS.filter((d) => want.includes(d[0])).map((d) => [d[0], sha(d[0])]) });
      }
      if (sql.startsWith("SELECT count(*) FROM") && sql.includes(".pins WHERE pin_id")) {
        return send(res, 200, { data: [[pins.has(sql.match(/'([0-9a-f]{64})'/)[1]) ? "1" : "0"]] });
      }
      if (sql.startsWith("SELECT likes, uses")) {
        const id = sql.match(/'([0-9a-f]{64})'/)[1];
        return send(res, 200, { data: [[String(likes(id)), String(uses(id))]] });
      }
      if (sql.startsWith("INSERT INTO help_pg.pins")) {
        const id = sql.match(/SELECT '([0-9a-f]{64})'/)[1];
        const [q, a, model, , sources, who] = b64s(sql);
        pins.set(id, { id, q, a, model, sources, who, at: pins.size + 1 });
        return send(res, 200, { data: [] });
      }
      if (sql.startsWith("INSERT INTO help_pg.pin_events")) {
        const m = sql.match(/SELECT '[^']+', '([0-9a-f]{64})', '(\w+)'/);
        events.push({ pin: m[1], kind: m[2], who: b64s(sql)[0] });
        return send(res, 200, { data: [] });
      }
      if (sql.startsWith("SELECT p.pin_id")) {
        const inList = sql.match(/IN \(([^)]*)\)/)?.[1];
        const ids = inList ? [...inList.matchAll(/'([0-9a-f]{64})'/g)].map((m) => m[1]) : [...pins.keys()];
        const rows = ids.filter((i) => pins.has(i)).map((i) => {
          const p = pins.get(i);
          return [i, p.q, p.a, "answer", p.model, p.sources, `2026-01-0${Math.min(p.at, 9)} 10:00:00`, p.who, "current", String(likes(i)), String(uses(i))];
        }).sort((x, y) => Number(y[9]) - Number(x[9]));
        return send(res, 200, { data: rows });
      }
      if (sql.startsWith("EXPLAIN ")) {
        state.explainRuns++;
        if (sql.includes("BADCOL")) {
          return send(res, 200, { data: [["== Physical Plan ==\norg.apache.spark.sql.AnalysisException: [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column with name `BADCOL` cannot be resolved."]] });
        }
        return send(res, 200, { data: [["== Physical Plan ==\nScan"]] });
      }
      if (sql.startsWith("SELECT candidate_id FROM help_pg.candidates")) {
        const id = sql.match(/'([0-9a-f]{64})'/)[1];
        return send(res, 200, { data: candidates.has(id) ? [[id]] : [] });
      }
      if (sql.startsWith("INSERT INTO help_pg.candidates")) {
        const id = sql.match(/SELECT '([0-9a-f]{64})'/)[1];
        const [request, sqlText, model, sources, notes, who] = b64s(sql);
        const status = sql.match(/, '(dry-run passed|unverified)', (\d+)/);
        candidates.set(id, { id, request, sqlText, model, sources, notes, who, status: status[1], attempts: status[2] });
        return send(res, 200, { data: [] });
      }
      if (sql.startsWith("SELECT candidate_id, request")) {
        const rows = [...candidates.values()].reverse().map((c) => [c.id, c.request, c.sqlText, c.status, c.attempts, c.model, c.sources, c.notes, "2026-01-02 10:00:00", c.who]);
        return send(res, 200, { data: rows });
      }
      if (sql.startsWith("SELECT count(*)")) return send(res, 200, { data: [["7"]] });
      if (sql.includes("RUN PIPELINE ON 'llm_answer'") && sql.includes("Write ONE new example")) {
        state.llmPrompts.push("generate");
        const m = state.exampleMode;
        const text = m === "repair" || m === "alwaysbad" ? EXAMPLES.bad : (EXAMPLES[m] ?? EXAMPLES.pass);
        return send(res, 200, { data: [["q", text, "ctx"]] });
      }
      if (sql.includes("RUN PIPELINE ON 'llm_answer'") && sql.includes("rejected by the SQL checker")) {
        if (state.answerDelayMs) await new Promise((r) => setTimeout(r, state.answerDelayMs));
        state.llmPrompts.push(sql.includes("BADCOL") ? "repair-with-error" : "repair");
        const text = state.exampleMode === "repair" ? EXAMPLES.pass : EXAMPLES.bad;
        return send(res, 200, { data: [["q", text, "ctx"]] });
      }
      if (sql.includes("RUN PIPELINE ON 'llm_answer'")) {
        state.answerRuns++;
        if (state.answerDelayMs) await new Promise((r) => setTimeout(r, state.answerDelayMs));
        const text = state.xss ? XSS_ANSWER : "Register the source with `CREATE LIGHTNING REST TABLE` (open_data/rest_apis/HOWTO.md).";
        return send(res, 200, { data: [["q", text, "ctx"]] });
      }
      if (sql.includes("RUN PIPELINE ON 'sink'")) return send(res, 200, { data: [] }); // embedding a pin
      if (sql.includes("RUN PIPELINE ON 'vs_search'") && sql.includes("help_pins")) {
        // Pins are found for questions that mention "register"; others score below the threshold.
        const sim = sql.includes("register") ? 0.9 : 0.5;
        const rows = [...pins.values()].map((p) => ["q", `REPO: pin\nFILE: ${p.id}\nPART: 0\nSECTION: ${p.q}\nTEXT: QUESTION: ${p.q}`, String(sim)]);
        return send(res, 200, { headers: ["prompt", "content", "similarity"], data: rows });
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
