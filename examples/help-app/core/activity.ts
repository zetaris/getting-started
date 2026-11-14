// Append-only log of searches and generated examples. Rows go to Postgres through Zetaris
// the same way pins do: strings are base64-decoded, so the question and the SQL are never
// part of the SQL text. A failed insert is reported and swallowed. The search or example
// the person asked for still succeeds.
import { toBase64 } from "./corpus.ts";
import type { ExampleResult } from "./example.ts";
import { cleanQuestion } from "./query.ts";
import { cleanText } from "./security.ts";

const b64 = (t: string) => `decode(unbase64('${toBase64(t)}'),'UTF-8')`;
const ID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

export const SURFACES = ["search", "answer", "docs"] as const;
export type Surface = (typeof SURFACES)[number];

export interface ActivityStore {
  run(sql: string, limit?: number): Promise<unknown>;
}

/** Page 2 and later of the docs results repeat the same search, so they are not logged. */
export function logsDocsSearch(requested: number): boolean {
  return !(Number.isFinite(requested) && requested > 1);
}

export function searchInsertSql(
  id: string,
  question: string,
  who: string,
  surface: Surface,
): string {
  if (!ID.test(id)) throw new Error("bad search id");
  if (!SURFACES.includes(surface)) throw new Error("bad surface");
  return `INSERT INTO help_pg.searches SELECT '${id}', ${b64(question)}, ` +
    `current_timestamp(), ${b64(who)}, '${surface}'`;
}

export function exampleInsertSql(row: {
  id: string;
  request: string;
  sql: string;
  status: ExampleResult["status"];
  attempts: number;
  model: string;
  sources: string;
  who: string;
}): string {
  if (!ID.test(row.id)) throw new Error("bad example id");
  if (row.status !== "dry-run passed" && row.status !== "unverified") {
    throw new Error("bad status");
  }
  const attempts = Math.max(0, row.attempts | 0);
  return `INSERT INTO help_pg.examples SELECT '${row.id}', ${
    b64(row.request)
  }, ${b64(row.sql)}, '${row.status}', ${attempts}, ${b64(row.model)}, ${
    b64(row.sources)
  }, ` +
    `current_timestamp(), ${b64(row.who)}`;
}

export async function logSearch(
  store: ActivityStore,
  question: string,
  who: string,
  surface: Surface,
): Promise<void> {
  const q = cleanQuestion(question);
  if (!q) return;
  try {
    await store.run(searchInsertSql(crypto.randomUUID(), q, who, surface), 1);
  } catch (e) {
    console.log(`search log skipped: ${(e as Error)?.name ?? "error"}`);
  }
}

/** Log one generated example. Call this only when generation returned SQL. */
export async function logExample(
  store: ActivityStore,
  result: ExampleResult,
  request: string,
  who: string,
): Promise<void> {
  if (!result.sql) return;
  try {
    await store.run(
      exampleInsertSql({
        id: crypto.randomUUID(),
        request: cleanText(request, 500),
        sql: cleanText(result.sql, 8000),
        status: result.status,
        attempts: result.attempts.length,
        model: cleanText(result.model, 100),
        sources: JSON.stringify(result.sources.map((s) => s.file)),
        who,
      }),
      1,
    );
  } catch (e) {
    console.log(`example log skipped: ${(e as Error)?.name ?? "error"}`);
  }
}
