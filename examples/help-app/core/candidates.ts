// Candidates: generated examples someone saved for review. Same store as pins (rows through Zetaris
// `INSERT INTO help_pg.<table> SELECT ...`, strings base64-decoded). Nothing is published from here.
import { toBase64 } from "./corpus.ts";
import { AskError } from "./ask.ts";
import {
  checkSql,
  type ExampleStatus,
  MAX_ATTEMPTS,
  MAX_REQUEST,
} from "./example.ts";
import { HEX64, type PinStore } from "./pins.ts";
import { cleanText } from "./security.ts";
import { listDocs } from "./docs.ts";
import type { Zetaris } from "./zetaris.ts";

const b64 = (t: string) => `decode(unbase64('${toBase64(t)}'),'UTF-8')`;
const STATUSES: ExampleStatus[] = ["dry-run passed", "unverified"];
const MAX_SQL = 8000;
const MAX_NOTES = 1500;
const MAX_SOURCES = 10;

export interface CandidateView {
  id: string;
  request: string;
  sql: string;
  status: ExampleStatus;
  attempts: number;
  model: string;
  sources: string[];
  notes: string;
  createdAt: string;
  createdBy: string;
}

export async function candidateIdOf(
  request: string,
  sql: string,
): Promise<string> {
  const data = new TextEncoder().encode(
    `${request.toLowerCase().trim()}\n${sql.trim()}`,
  );
  return [...new Uint8Array(await crypto.subtle.digest("SHA-256", data))]
    .map((b) => b.toString(16).padStart(2, "0")).join("");
}

export function candidateInsertSql(c: {
  id: string;
  request: string;
  sql: string;
  status: ExampleStatus;
  attempts: number;
  model: string;
  sources: string[];
  notes: string;
  who: string;
}): string {
  if (!HEX64.test(c.id)) throw new Error("bad candidate id");
  if (!STATUSES.includes(c.status)) throw new Error("bad status");
  return `INSERT INTO help_pg.candidates SELECT '${c.id}', ${b64(c.request)}, ${
    b64(c.sql)
  }, '${c.status}', ${Number(c.attempts) | 0}, ${b64(c.model)}, ${
    b64(JSON.stringify(c.sources))
  }, ${b64(c.notes)}, current_timestamp(), ${b64(c.who)}`;
}

export interface CandidateInput {
  request: unknown;
  sql: unknown;
  attempts: unknown;
  model: unknown;
  sources: unknown;
  notes: unknown;
  who: unknown;
}

/** Save one candidate. It needs source files (every one must be in the docs catalog). The status
 * is worked out here by checking the SQL again, never taken from the client, so a request cannot
 * label arbitrary SQL "dry-run passed". The same request and SQL saves once. */
export async function saveCandidate(
  store: Pick<PinStore, "run">,
  input: CandidateInput,
  catalog: () => Promise<Set<string>>,
  explain: (sql: string) => Promise<string>,
): Promise<{ id: string; existing: boolean }> {
  const request = cleanText(input.request, MAX_REQUEST);
  const sql = cleanText(input.sql, MAX_SQL);
  const attempts = Number(input.attempts);
  if (
    !request || !sql || !Number.isInteger(attempts) ||
    attempts < 1 || attempts > MAX_ATTEMPTS
  ) {
    throw new AskError(
      "bad_request",
      "A candidate needs a request, its SQL and the attempt count.",
      400,
    );
  }
  const known = await catalog();
  const claimed = Array.isArray(input.sources)
    ? input.sources.map((s) => cleanText(s, 400)).filter((f) => known.has(f))
    : [];
  const sources = [...new Set(claimed)].slice(0, MAX_SOURCES);
  if (sources.length === 0) {
    throw new AskError(
      "bad_request",
      "A generated example is saved with its source files; none were given.",
      400,
    );
  }
  const check = await checkSql(explain, sql);
  const status: ExampleStatus = !check.error && check.unchecked.length === 0
    ? "dry-run passed"
    : "unverified";
  const id = await candidateIdOf(request, sql);
  const found = await store.run(
    `SELECT candidate_id FROM help_pg.candidates WHERE candidate_id = '${id}'`,
    1,
  );
  if (found.rows.length > 0) return { id, existing: true };
  await store.run(
    candidateInsertSql({
      id,
      request,
      sql,
      status,
      attempts,
      model: cleanText(input.model, 100),
      sources,
      notes: cleanText(input.notes, MAX_NOTES),
      who: cleanText(input.who, 100) || "anonymous",
    }),
    1,
  );
  return { id, existing: false };
}

function parseSources(s: string): string[] {
  try {
    const v = JSON.parse(s);
    return Array.isArray(v) ? v.filter((x) => typeof x === "string") : [];
  } catch {
    return [];
  }
}

/** Newest first; `file` keeps only candidates that cite it. */
export async function listCandidates(
  store: Pick<PinStore, "run">,
  file?: string,
): Promise<CandidateView[]> {
  const r = await store.run(
    `SELECT candidate_id, request, sql_text, status, attempts, model, sources, notes, ` +
      `cast(created_at as string), created_by FROM help_pg.candidates ORDER BY created_at DESC`,
    200,
  );
  const all = r.rows.map((x): CandidateView => ({
    id: x[0],
    request: x[1],
    sql: x[2],
    status: x[3] as ExampleStatus,
    attempts: Number(x[4]),
    model: x[5],
    sources: parseSources(x[6]),
    notes: x[7] ?? "",
    createdAt: x[8],
    createdBy: x[9],
  }));
  return file ? all.filter((c) => c.sources.includes(file)) : all;
}

export async function catalogFiles(z: Zetaris): Promise<Set<string>> {
  return new Set((await listDocs(z)).map((d) => d.path));
}
