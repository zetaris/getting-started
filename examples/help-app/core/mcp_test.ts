import { assert, assertEquals } from "@std/assert";
import type { AskResult } from "./ask.ts";
import { AskError } from "./ask.ts";
import type { ExampleResult } from "./example.ts";
import { InFlight } from "./limit.ts";
import {
  dispatch,
  mcpResponse,
  type McpRuntime,
  protocolVersion,
  READ_CHARS,
  READ_FILES,
  TOOLS,
} from "./mcp.ts";

function askResult(mode: "search" | "answer"): AskResult {
  return {
    mode,
    sources: [{
      file: "docs/guides/zetaris-lightning-sql-commands.md",
      corpus: "repo",
      section: "CREATE",
      similarity: 0.9,
      score: 0.91,
      excerpt: "CREATE DATASOURCE",
      snippetHtml: "<b>CREATE</b>",
      excerptHtml: "<p>CREATE</p>",
      url: null,
      docHref: "/docs/file",
    }],
    answer: mode === "answer" ? "Register it with CREATE DATASOURCE." : null,
    answerHtml: mode === "answer" ? "<p>Register</p>" : null,
    pastAnswers: [],
    timings: { searchMs: 1, answerMs: null },
  };
}

function exampleResult(): ExampleResult {
  return {
    status: "unverified",
    sql: "CREATE DATASOURCE rest",
    notes: "",
    attempts: [{
      n: 1,
      sql: "CREATE DATASOURCE rest",
      error: null,
      unchecked: true,
    }],
    sources: [],
    reason: "EXPLAIN only checks SELECT or WITH.",
    model: "test",
    ms: 1,
  };
}

function runtime(over: Partial<McpRuntime> = {}): McpRuntime & {
  logged: string[];
} {
  const logged: string[] = [];
  return {
    who: "agent:0123456789abcdef",
    lockId: "agent:0123456789abcdef",
    flight: new InFlight(),
    search: () => Promise.resolve(askResult("search")),
    answer: (_q, fresh) => {
      logged.push(`fresh:${fresh}`);
      return Promise.resolve(askResult("answer"));
    },
    example: () => Promise.resolve(exampleResult()),
    read: (files) =>
      Promise.resolve(files.map((file) => ({
        file,
        title: "Title",
        body: "body",
      }))),
    logSearch: (q, who, surface) => {
      logged.push(`${surface}:${who}:${q}`);
      return Promise.resolve();
    },
    logExample: (_r, request, who) => {
      logged.push(`example:${who}:${request}`);
      return Promise.resolve();
    },
    logged,
    ...over,
  };
}

function rpc(method: string, params: unknown, id: number | undefined = 1) {
  return JSON.stringify({ jsonrpc: "2.0", id, method, params });
}

Deno.test("initialize echoes a dated protocol version and lists the tools", async () => {
  assertEquals(protocolVersion("nope"), "2025-03-26");
  const rt = runtime();
  const init = JSON.parse(
    (await dispatch(
      rpc("initialize", { protocolVersion: "2025-06-18" }),
      rt,
    ))!,
  );
  assertEquals(init.result.protocolVersion, "2025-06-18");
  assertEquals(init.result.serverInfo.name, "zetaris-help");
  const list = JSON.parse((await dispatch(rpc("tools/list", {}, 2), rt))!);
  assertEquals(list.result.tools.map((t: { name: string }) => t.name), [
    "search_help",
    "answer_help",
    "example_sql",
    "read_help",
  ]);
  const answer = TOOLS[1];
  assert(answer.description.includes("search-log"));
  assert(TOOLS[2].description.includes("EXPLAIN"));
  assertEquals(
    await dispatch(
      JSON.stringify({
        jsonrpc: "2.0",
        method: "notifications/initialized",
      }),
      rt,
    ),
    null,
  );
});

Deno.test("search_help returns files without HTML and logs the question", async () => {
  const rt = runtime();
  const res = JSON.parse(
    (await dispatch(
      rpc("tools/call", {
        name: "search_help",
        arguments: { question: "register a REST source" },
      }),
      rt,
    ))!,
  );
  const body = JSON.parse(res.result.content[0].text);
  assertEquals(
    body.sources[0].file,
    "docs/guides/zetaris-lightning-sql-commands.md",
  );
  assertEquals(body.sources[0].excerpt, "CREATE DATASOURCE");
  assertEquals("excerptHtml" in body.sources[0], false);
  assertEquals(res.result.isError, false);
  assertEquals(rt.logged, [
    "search:agent:0123456789abcdef:register a REST source",
  ]);
});

Deno.test("answer_help passes fresh and a second call waits", async () => {
  let release: () => void = () => {};
  const gate = new Promise<void>((r) => {
    release = r;
  });
  const rt = runtime({
    answer: async (_q, fresh) => {
      rt.logged.push(`fresh:${fresh}`);
      await gate;
      return askResult("answer");
    },
  });
  const first = dispatch(
    rpc("tools/call", {
      name: "answer_help",
      arguments: { question: "how do I register", fresh: true },
    }),
    rt,
  );
  const second = JSON.parse(
    (await dispatch(
      rpc("tools/call", {
        name: "answer_help",
        arguments: { question: "again" },
      }, 2),
      rt,
    ))!,
  );
  assertEquals(second.result.isError, true);
  assert(second.result.content[0].text.includes("still being written"));
  release();
  const done = JSON.parse((await first)!);
  assertEquals(
    JSON.parse(done.result.content[0].text).answer,
    "Register it with CREATE DATASOURCE.",
  );
  assertEquals(rt.logged[0], "fresh:true");
});

Deno.test("example_sql reports unverified SQL and logs it", async () => {
  const rt = runtime();
  const res = JSON.parse(
    (await dispatch(
      rpc("tools/call", {
        name: "example_sql",
        arguments: { request: "register a REST source" },
      }),
      rt,
    ))!,
  );
  const body = JSON.parse(res.result.content[0].text);
  assertEquals(body.status, "unverified");
  assertEquals(body.sql, "CREATE DATASOURCE rest");
  assertEquals(rt.logged, [
    "example:agent:0123456789abcdef:register a REST source",
  ]);
});

Deno.test("a missing question is a tool error and does not log", async () => {
  const rt = runtime();
  const res = JSON.parse(
    (await dispatch(
      rpc("tools/call", { name: "search_help", arguments: {} }),
      rt,
    ))!,
  );
  assertEquals(res.result.isError, true);
  assertEquals(rt.logged, []);
  const missing = JSON.parse(
    (await dispatch(rpc("nope", {}, 3), rt))!,
  );
  assertEquals(missing.error.code, -32601);
});

Deno.test("POST /api/mcp returns tools/list as JSON and GET is refused", async () => {
  const rt = runtime();
  const res = await mcpResponse(
    new Request("http://127.0.0.1/api/mcp", {
      method: "POST",
      body: rpc("tools/list", {}),
    }),
    rt,
  );
  assertEquals(res.status, 200);
  assertEquals(res.headers.get("content-type"), "application/json");
  assertEquals(res.headers.get("mcp-session-id"), null);
  const body = await res.json();
  assertEquals(body.result.tools.map((t: { name: string }) => t.name), [
    "search_help",
    "answer_help",
    "example_sql",
    "read_help",
  ]);
  const get = await mcpResponse(
    new Request("http://127.0.0.1/api/mcp", { method: "GET" }),
    rt,
  );
  assertEquals(get.status, 405);
});

Deno.test("read_help returns a catalogued file, a miss, and stops at three", async () => {
  const seen: string[][] = [];
  const rt = runtime({
    read: (files) => {
      seen.push(files);
      return Promise.resolve(files.map((file, i) =>
        i === 1
          ? { file, title: null, body: null }
          : { file, title: `T ${file}`, body: "x".repeat(READ_CHARS + 5) }
      ));
    },
  });
  const files = ["a.md", "missing.md", "b.sql", "c.md"];
  const res = JSON.parse(
    (await dispatch(
      rpc("tools/call", { name: "read_help", arguments: { files } }),
      rt,
    ))!,
  );
  const body = JSON.parse(res.result.content[0].text);
  assertEquals(seen, [files.slice(0, READ_FILES)]);
  assertEquals(body.files[0].title, "T a.md");
  assertEquals(body.files[0].body, `${"x".repeat(READ_CHARS)}\n…`);
  assertEquals(body.files[1], { file: "missing.md", title: null, body: null });
  assertEquals(body.files.length, READ_FILES);
  assertEquals(res.result.isError, false);
  assertEquals(rt.logged, []);
});

Deno.test("a failed search is not logged", async () => {
  const rt = runtime({
    search: () => {
      throw new AskError(
        "zetaris_unreachable",
        "Zetaris is not reachable.",
        503,
      );
    },
  });
  const res = JSON.parse(
    (await dispatch(
      rpc("tools/call", {
        name: "search_help",
        arguments: { question: "register a REST source" },
      }),
      rt,
    ))!,
  );
  assertEquals(res.result.content[0].text, "Zetaris is not reachable.");
  assertEquals(rt.logged, []);
});
