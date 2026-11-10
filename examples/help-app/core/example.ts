// Example mode: retrieve the closest example scripts, ask the model for a new example inspired by
// them, then check it with the instance's own analyzer (`EXPLAIN`, which parses and resolves a query
// without running it). A failed check goes back to the model with the error, at most 3 attempts.
// Only queries (SELECT / WITH) can be checked this way; anything else stays "unverified".
// The label is "dry-run passed" or "unverified", never "verified" (that word is CONTRIBUTING.md's).
import { AskError } from "./ask.ts";
import { type Ranked, rerank, topFiles } from "./rank.ts";
import { wholeFileContext } from "./prompt.ts";
import type { Passage } from "./query.ts";
import { cleanText } from "./security.ts";
import { docHref } from "./docs.ts";

export const MAX_ATTEMPTS = 3;
export const MAX_REQUEST = 500;
const MAX_ERROR = 300;
const MAX_SQL = 8000;
const SQL_FILES = 3;
const GOTCHA_PASSAGES = 2;

export type ExampleStatus = "dry-run passed" | "unverified";

export interface Attempt {
  n: number;
  sql: string;
  /** What the check reported, or why it could not run; null when this attempt passed. */
  error: string | null;
}

export interface ExampleSource {
  file: string;
  docHref: string | null;
}

export interface ExampleResult {
  status: ExampleStatus;
  sql: string;
  notes: string;
  attempts: Attempt[];
  sources: ExampleSource[];
  /** Why it is unverified, when it is. */
  reason: string | null;
  model: string;
  ms: number;
}

export interface CheckResult {
  /** A message to feed back for a repair; null when every statement passed or none could be checked. */
  error: string | null;
  /** Statements the check cannot run (anything that is not a query). */
  unchecked: string[];
}

export interface ExampleDeps {
  search(q: string, limit: number): Promise<Passage[]>;
  readFile(f: string): Promise<string | null>;
  /** One model call: the full instruction and the context rows; returns the model's text. */
  llm(prompt: string, contexts: Ctx[]): Promise<string>;
  /** Check one query with EXPLAIN; throws on a parse error, returns the plan text otherwise. */
  explain(sql: string): Promise<string>;
  model: string;
}

type Ctx = { header: string; text: string; similarity: number };

/** Split a script into statements at `;`, ignoring quotes and comments. */
export function splitStatements(sql: string): string[] {
  const out: string[] = [];
  let cur = "";
  let i = 0;
  while (i < sql.length) {
    const c = sql[i];
    if (c === "'" || c === '"' || c === "`") {
      let j = i + 1;
      while (j < sql.length && sql[j] !== c) j++;
      cur += sql.slice(i, j + 1);
      i = j + 1;
    } else if (c === "-" && sql[i + 1] === "-") {
      while (i < sql.length && sql[i] !== "\n") i++;
    } else if (c === "/" && sql[i + 1] === "*") {
      const j = sql.indexOf("*/", i + 2);
      i = j === -1 ? sql.length : j + 2;
    } else if (c === ";") {
      if (cur.trim()) out.push(cur.trim());
      cur = "";
      i++;
    } else {
      cur += c;
      i++;
    }
  }
  if (cur.trim()) out.push(cur.trim());
  return out;
}

export function isQuery(stmt: string): boolean {
  return /^(select|with)\b/i.test(stmt.trim());
}

const COMMANDS =
  /^(create|drop|alter|insert|update|delete|activate|compile|materialize|refresh|run|show|describe|desc|set|use|cache|uncache|truncate|grant|revoke|merge|verify|register|load|add|remove)\b/i;

/** A statement that does something rather than asks something; EXPLAIN is not used on these. */
export function isCommand(stmt: string): boolean {
  return COMMANDS.test(stmt.trim());
}

/** The first ```sql block of a reply (or the first fenced block), and the text around it. */
export function extractSql(
  text: string,
): { sql: string; notes: string } | null {
  const m = text.match(/```(?:sql|SQL)?[ \t]*\n([\s\S]*?)```/);
  if (!m) return null;
  const sql = m[1].trim().slice(0, MAX_SQL);
  if (!sql) return null;
  const notes = (text.slice(0, m.index) + text.slice(m.index! + m[0].length))
    .trim().slice(0, 1500);
  return { sql, notes };
}

/** Run EXPLAIN on every query in the script. A parse error throws from `explain`; an analysis
 * error (unknown table or column) comes back inside the plan text. */
export async function checkSql(
  explain: (sql: string) => Promise<string>,
  sql: string,
): Promise<CheckResult> {
  const stmts = splitStatements(sql);
  if (stmts.length === 0) {
    return { error: "No SQL statement found.", unchecked: [] };
  }
  const unchecked: string[] = [];
  for (const s of stmts) {
    if (isCommand(s)) {
      unchecked.push(s.split(/\s+/).slice(0, 3).join(" ").toUpperCase());
      continue;
    }
    let plan: string;
    try {
      plan = await explain(s);
    } catch (e) {
      return { error: errorLine((e as Error).message), unchecked };
    }
    const bad = plan.match(
      /(AnalysisException|ParseException|Exception)[^\n]*/,
    );
    if (bad) return { error: errorLine(bad[0]), unchecked };
  }
  return { error: null, unchecked };
}

function errorLine(msg: string): string {
  const flat = msg.replace(/org\.[\w.]+(Exception|Error):?\s*/g, "")
    .replace(/\s+/g, " ").trim();
  return cleanText(flat, MAX_ERROR) || "The statement was rejected.";
}

// What the pilot showed the model gets wrong; short, because the model reads it every time.
const CHECKLIST = `Checklist (known mistakes):
- Use only syntax that appears in the supplied files. Do not invent keywords.
- "source" is a reserved word; do not use it as a column or alias.
- In SQL strings write [0-9], never \\d.
- Use only table and column names that appear in the files or the request.
- No trailing semicolon after the last statement is needed; one statement per query.`;

export function generatePrompt(request: string): string {
  return `Request: ${request}

Write ONE new example in Zetaris Lightning SQL, inspired by the supplied example files. ` +
    `Do not copy a file; change the table, filter or columns to fit the request, and use only syntax ` +
    `shown in the supplied files. Reply with a short note (two sentences at most), then the SQL in a ` +
    `single \`\`\`sql block, then one line "Drew from:" listing the FILE names you used.\n\n${CHECKLIST}`;
}

export function repairPrompt(
  request: string,
  sql: string,
  error: string,
): string {
  return `Request: ${request}

Your previous example was rejected by the SQL checker.

Previous SQL:
\`\`\`sql
${sql}
\`\`\`

Checker message: ${error}

Fix it. Change only what the message requires, keep to syntax shown in the supplied files, and ` +
    `reply as before: a short note, one \`\`\`sql block, one "Drew from:" line.\n\n${CHECKLIST}`;
}

const GUIDE = /(docs\/guides\/|HOWTO\.md$|companion)/i;

/** Context for generation: whole example scripts with their headers, plus the best guide passages. */
export async function exampleContext(
  ranked: Ranked[],
  readFile: (f: string) => Promise<string | null>,
): Promise<{ ctx: Ctx[]; files: string[] }> {
  const repo = topFiles(ranked, 40).filter((f) => f.corpus === "repo");
  const sqlFiles = repo.filter((f) => f.file.endsWith(".sql")).map((f) =>
    f.file
  )
    .slice(0, SQL_FILES);
  const sim = ranked[0]?.similarity ?? 0;
  const whole = await wholeFileContext(sqlFiles, readFile, SQL_FILES, true);
  const ctx: Ctx[] = whole.map((w) => ({ ...w, similarity: sim }));
  const gotchas = ranked.filter((p) =>
    p.corpus === "repo" && GUIDE.test(p.file)
  )
    .slice(0, GOTCHA_PASSAGES);
  for (const p of gotchas) {
    ctx.push({
      header: `FILE: ${p.file}\nSECTION: ${p.section}`,
      text: p.text,
      similarity: p.similarity,
    });
  }
  const files = [...new Set([...sqlFiles, ...gotchas.map((p) => p.file)])];
  return { ctx, files };
}

export function cleanRequest(r: unknown): string {
  const t = typeof r === "string"
    // deno-lint-ignore no-control-regex
    ? r.replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/g, " ")
      .replace(/\s+/g, " ").trim().slice(0, MAX_REQUEST)
    : "";
  if (!t) {
    throw new AskError(
      "empty_question",
      "Describe the example you want first.",
      400,
    );
  }
  return t;
}

export async function generateExample(
  deps: ExampleDeps,
  requestRaw: unknown,
  onStage: (s: string) => void = () => {},
): Promise<ExampleResult> {
  const request = cleanRequest(requestRaw);
  const t0 = performance.now();
  onStage("retrieving");
  const passages = await deps.search(request, 100);
  const { ctx, files } = await exampleContext(
    rerank(request, passages),
    deps.readFile,
  );
  if (files.length === 0 || ctx.length === 0) {
    throw new AskError(
      "not_found",
      "No example scripts matched that request, so nothing was generated. Try naming a source or a table.",
      404,
    );
  }
  const attempts: Attempt[] = [];
  let prompt = generatePrompt(request);
  let reason: string | null = null;
  let final: { sql: string; notes: string } | null = null;
  let passed = false;
  for (let n = 1; n <= MAX_ATTEMPTS; n++) {
    onStage(
      n === 1 ? "generating" : `repairing (attempt ${n} of ${MAX_ATTEMPTS})`,
    );
    const text = await deps.llm(prompt, ctx);
    const got = extractSql(text);
    if (!got) {
      attempts.push({
        n,
        sql: "",
        error: "The model did not return a SQL block.",
      });
      prompt = generatePrompt(request);
      reason = "The model did not return a SQL block.";
      continue;
    }
    final = got;
    onStage("checking");
    const check = await checkSql(deps.explain, got.sql);
    if (check.error) {
      attempts.push({ n, sql: got.sql, error: check.error });
      reason = check.error;
      prompt = repairPrompt(request, got.sql, check.error);
      continue;
    }
    if (check.unchecked.length > 0) {
      attempts.push({
        n,
        sql: got.sql,
        error: `Not checked: ${
          [...new Set(check.unchecked)].join(", ")
        } cannot be dry-run.`,
      });
      reason = `Contains statements the checker cannot run (${
        [...new Set(check.unchecked)].join(", ")
      }). Only queries can be dry-run.`;
      break;
    }
    attempts.push({ n, sql: got.sql, error: null });
    passed = true;
    reason = null;
    break;
  }
  if (!final) {
    throw new AskError(
      "zetaris_error",
      "The model did not return an example. Try again or rephrase the request.",
      502,
    );
  }
  return {
    status: passed ? "dry-run passed" : "unverified",
    sql: final.sql,
    notes: final.notes,
    attempts,
    sources: files.map((f) => ({ file: f, docHref: docHref(f) })),
    reason: passed ? null : reason,
    model: deps.model,
    ms: Math.round(performance.now() - t0),
  };
}
