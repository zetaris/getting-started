// MCP for a coding agent, served by the help app at POST /api/mcp. Tool handlers
// do not read a credential. They ask the caller for an actor id and then call
// the same functions as the browser.
import type { AskResult } from "./ask.ts";
import { AskError, toAskError } from "./ask.ts";
import type { ExampleResult } from "./example.ts";
import type { InFlight } from "./limit.ts";

const BUSY =
  "Your previous answer or example is still being written. Wait for it, then try again.";

export interface McpRuntime {
  who: string;
  /** Answer and example lock. An agent id does not share a browser session's lock. */
  lockId: string;
  flight: InFlight;
  search(question: string): Promise<AskResult>;
  answer(question: string, fresh: boolean): Promise<AskResult>;
  example(request: string): Promise<ExampleResult>;
  /** Catalogued file text. A miss is title and body null. No disk read for an unknown path. */
  read(files: string[]): Promise<HelpFile[]>;
  logSearch(
    question: string,
    who: string,
    surface: "search" | "answer",
  ): Promise<void>;
  logExample(
    result: ExampleResult,
    request: string,
    who: string,
  ): Promise<void>;
}

export const TOOLS = [
  {
    name: "search_help",
    description:
      "Search the Zetaris help index. No model call. Returns matching files with excerpts and paths. Use this to look up a command or a document.",
    inputSchema: {
      type: "object",
      properties: {
        question: { type: "string", description: "What you want to find." },
      },
      required: ["question"],
    },
  },
  {
    name: "answer_help",
    description:
      "Answer a Zetaris help question. A close pinned answer is returned and the model is not called, unless fresh is true. Slower than search. Writes a search-log row.",
    inputSchema: {
      type: "object",
      properties: {
        question: { type: "string", description: "The question to answer." },
        fresh: {
          type: "boolean",
          description:
            "Write a new answer even when a close pinned answer exists.",
        },
      },
      required: ["question"],
    },
  },
  {
    name: "example_sql",
    description:
      "Write a new Zetaris SQL example from this repo's scripts. The SQL is generated. EXPLAIN checks SELECT and WITH only; other commands are unverified. Nothing is executed.",
    inputSchema: {
      type: "object",
      properties: {
        request: {
          type: "string",
          description: "What the example should do.",
        },
      },
      required: ["request"],
    },
  },
  {
    name: "read_help",
    description:
      "Read up to 3 catalogued help files. Pass file values from search_help. Returns each file's title and text, or a miss when it is not in the catalog. No model call.",
    inputSchema: {
      type: "object",
      properties: {
        files: {
          type: "array",
          items: { type: "string" },
          description:
            "Repo paths or knowledge-base URLs from search_help, at most 3.",
        },
      },
      required: ["files"],
    },
  },
] as const;

/** How many files one read_help call opens. */
export const READ_FILES = 3;
/** Characters of each file returned. A longer file is cut and marked. */
export const READ_CHARS = 20_000;

export interface HelpFile {
  file: string;
  title: string | null;
  body: string | null;
}

/** One JSON-RPC message in, one line out, or null when the client sent a notification. */
export async function dispatch(
  raw: string,
  rt: McpRuntime,
): Promise<string | null> {
  let msg: Rpc;
  try {
    msg = JSON.parse(raw) as Rpc;
  } catch {
    return line({
      jsonrpc: "2.0",
      id: null,
      error: { code: -32700, message: "Parse error" },
    });
  }
  if (!msg || typeof msg !== "object" || Array.isArray(msg)) {
    return line({
      jsonrpc: "2.0",
      id: null,
      error: { code: -32600, message: "Invalid request" },
    });
  }
  const id = msg.id;
  const notify = id === undefined;
  if (msg.jsonrpc !== "2.0" || typeof msg.method !== "string") {
    if (notify) return null;
    return line({
      jsonrpc: "2.0",
      id: id ?? null,
      error: { code: -32600, message: "Invalid request" },
    });
  }
  try {
    const result = await call(msg.method, msg.params, rt);
    if (notify) return null;
    return line({ jsonrpc: "2.0", id, result });
  } catch (e) {
    if (notify) return null;
    if (e instanceof RpcError) {
      return line({
        jsonrpc: "2.0",
        id,
        error: { code: e.code, message: e.message },
      });
    }
    const err = toAskError(e);
    if (msg.method === "tools/call") {
      return line({
        jsonrpc: "2.0",
        id,
        result: {
          content: [{ type: "text", text: err.message }],
          isError: true,
        },
      });
    }
    return line({
      jsonrpc: "2.0",
      id,
      error: { code: -32603, message: err.message },
    });
  }
}

async function call(
  method: string,
  params: unknown,
  rt: McpRuntime,
): Promise<unknown> {
  if (method === "initialize") {
    const requested = (params as { protocolVersion?: string } | undefined)
      ?.protocolVersion;
    return {
      protocolVersion: protocolVersion(requested),
      capabilities: { tools: { listChanged: false } },
      serverInfo: { name: "zetaris-help", version: "0.1.0" },
      instructions:
        "Search with search_help before calling the model. read_help returns the text of files from that list. answer_help may return a pinned answer. example_sql returns generated SQL that is not executed.",
    };
  }
  if (method === "ping" || method === "notifications/initialized") return {};
  if (method === "tools/list") return { tools: TOOLS };
  if (method === "tools/call") return await toolCall(params, rt);
  throw new RpcError(-32601, `Unknown method ${method}.`);
}

class RpcError extends Error {
  constructor(public code: number, message: string) {
    super(message);
  }
}

async function toolCall(params: unknown, rt: McpRuntime): Promise<unknown> {
  const name = (params as { name?: unknown })?.name;
  const args = (params as { arguments?: unknown })?.arguments ?? {};
  if (typeof name !== "string" || !args || typeof args !== "object") {
    throw new AskError("bad_request", "Send a tool name and arguments.", 400);
  }
  const bag = args as Record<string, unknown>;
  let text: string;
  if (name === "search_help") {
    text = await runSearch(rt, needString(bag.question, "question"));
  } else if (name === "answer_help") {
    text = await runAnswer(
      rt,
      needString(bag.question, "question"),
      bag.fresh === true,
    );
  } else if (name === "example_sql") {
    text = await runExample(rt, needString(bag.request, "request"));
  } else if (name === "read_help") {
    text = await runRead(rt, needFiles(bag.files));
  } else {
    throw new AskError("not_found", `Unknown tool ${name}.`, 404);
  }
  return { content: [{ type: "text", text }], isError: false };
}

export async function runSearch(
  rt: McpRuntime,
  question: string,
): Promise<string> {
  const result = await rt.search(question);
  await rt.logSearch(question, rt.who, "search");
  return JSON.stringify(projectAsk(result));
}

export async function runAnswer(
  rt: McpRuntime,
  question: string,
  fresh: boolean,
): Promise<string> {
  const release = rt.flight.tryStart(rt.lockId);
  if (!release) throw new AskError("busy", BUSY, 429);
  try {
    const result = await rt.answer(question, fresh);
    await rt.logSearch(question, rt.who, "answer");
    return JSON.stringify(projectAsk(result));
  } finally {
    release();
  }
}

export async function runExample(
  rt: McpRuntime,
  request: string,
): Promise<string> {
  const release = rt.flight.tryStart(rt.lockId);
  if (!release) throw new AskError("busy", BUSY, 429);
  try {
    const result = await rt.example(request);
    await rt.logExample(result, request, rt.who);
    return JSON.stringify(projectExample(result));
  } finally {
    release();
  }
}

export async function runRead(
  rt: McpRuntime,
  files: string[],
): Promise<string> {
  const wanted = files.slice(0, READ_FILES);
  const docs = await rt.read(wanted);
  return JSON.stringify({
    files: docs.map((d) => ({
      file: d.file,
      title: d.title,
      body: d.body === null ? null : clip(d.body),
    })),
  });
}

function clip(body: string): string {
  if (body.length <= READ_CHARS) return body;
  return `${body.slice(0, READ_CHARS)}\n…`;
}

function needFiles(value: unknown): string[] {
  if (
    !Array.isArray(value) || value.length === 0 ||
    value.some((v) => typeof v !== "string" || !v.trim())
  ) {
    throw new AskError("bad_request", "Send {files: string[]}.", 400);
  }
  return value.map((v) => (v as string).trim());
}

function needString(value: unknown, name: string): string {
  if (typeof value !== "string" || !value.trim()) {
    throw new AskError("bad_request", `Send {${name}: string}.`, 400);
  }
  return value;
}

/** Echo a dated protocol version. Anything else stays on a version this server speaks. */
export function protocolVersion(requested: string | undefined): string {
  return requested && /^\d{4}-\d{2}-\d{2}$/.test(requested)
    ? requested
    : "2025-03-26";
}

function projectAsk(result: AskResult) {
  return {
    mode: result.mode,
    answer: result.answer,
    sources: result.sources.map((s) => ({
      file: s.file,
      section: s.section,
      score: s.score,
      excerpt: s.excerpt,
      docHref: s.docHref,
    })),
    pastAnswers: result.pastAnswers.map((p) => ({
      question: p.question,
      answer: p.answer,
      similarity: p.similarity,
      likes: p.likes,
      uses: p.uses,
    })),
  };
}

function projectExample(result: ExampleResult) {
  const last = result.attempts[result.attempts.length - 1];
  return {
    status: result.status,
    sql: result.sql,
    notes: result.notes,
    reason: result.reason,
    model: result.model,
    attempts: result.attempts.length,
    lastError: last?.error ?? null,
    sources: result.sources.map((s) => s.file),
  };
}

const MAX_BODY = 16_384;

/** One POST is one JSON-RPC message. GET is refused: the server does not push messages. No session id. */
export async function mcpResponse(
  req: Request,
  rt: McpRuntime,
): Promise<Response> {
  if (req.method !== "POST") {
    return new Response("Method not allowed", {
      status: 405,
      headers: { allow: "POST" },
    });
  }
  const raw = await req.text();
  if (raw.length > MAX_BODY) {
    return jsonRpc(413, {
      jsonrpc: "2.0",
      id: null,
      error: { code: -32600, message: "That request is too large." },
    });
  }
  const out = await dispatch(raw, rt);
  if (!out) return new Response(null, { status: 202 });
  return jsonRpc(200, out);
}

function jsonRpc(status: number, body: unknown): Response {
  const text = typeof body === "string" ? body : JSON.stringify(body);
  return new Response(text, {
    status,
    headers: {
      "content-type": "application/json",
      "cache-control": "no-store",
    },
  });
}

function line(msg: unknown): string {
  return JSON.stringify(msg);
}

interface Rpc {
  jsonrpc?: string;
  id?: number | string | null;
  method?: string;
  params?: unknown;
}
