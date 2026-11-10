// Pinned answers and likes. Rows go to Postgres through Zetaris `INSERT INTO help_pg.<table> SELECT ...`
// (strings base64-decoded, so nothing typed by a user is ever part of the SQL text). The log is
// append-only: likes are counted from events, nothing is updated. A pinned answer is also embedded,
// as one passage "QUESTION: ... ANSWER: ..." in its own collection, so a similar later question finds it.
import { type Segment, toBase64 } from "./corpus.ts";
import { AskError } from "./ask.ts";
import { USL } from "./docs.ts";
import type { Passage } from "./query.ts";
import { cleanText } from "./security.ts";
import type { SqlResult } from "./zetaris.ts";

export const PIN_BONUS = 0.03;
export const EVENT_KINDS = ["like", "unlike", "use", "retire"] as const;
export type EventKind = (typeof EVENT_KINDS)[number];
export const HEX64 = /^[0-9a-f]{64}$/;

export const MAX_QUESTION = 500;
export const MAX_ANSWER = 8000;
const MAX_SOURCES = 10;
const PASSAGE_CHARS = 1200; // under the 1,500-character Chunking guard, header included

export interface PinStore {
  run(sql: string, limit?: number): Promise<SqlResult>;
  /** Embed one passage into the pins collection (creating the collection if needed). */
  embedPin(seg: Segment): Promise<void>;
  /** Vector search of the pins collection; [] when it does not exist yet. */
  searchPins(question: string): Promise<Passage[]>;
}

export interface PinSource {
  file: string;
  sha: string | null;
}

export type Stale = {
  state: "current" | "changed" | "missing";
  files: string[];
};

export interface PinView {
  pinId: string;
  question: string;
  answer: string;
  origin: string;
  model: string;
  sources: PinSource[];
  pinnedAt: string;
  pinnedBy: string;
  status: string;
  likes: number;
  uses: number;
  stale: Stale;
}

const b64 = (t: string) => `decode(unbase64('${toBase64(t)}'),'UTF-8')`;

/** Lower-case, collapse spaces and drop trailing punctuation, so trivial rewordings pin once. */
export function normalizeQuestion(q: string): string {
  return q.toLowerCase().replace(/\s+/g, " ").trim().replace(/[?.!\s]+$/, "");
}

export async function pinIdOf(
  question: string,
  answer: string,
): Promise<string> {
  const data = new TextEncoder().encode(
    `${normalizeQuestion(question)}\n${answer.trim()}`,
  );
  return [...new Uint8Array(await crypto.subtle.digest("SHA-256", data))]
    .map((b) => b.toString(16).padStart(2, "0")).join("");
}

export function pinPassage(
  pinId: string,
  question: string,
  answer: string,
): Segment {
  return {
    corpus: "pin",
    file: pinId,
    part: 0,
    section: question.slice(0, 120),
    text: `QUESTION: ${question}\nANSWER: ${answer}`.slice(0, PASSAGE_CHARS),
  };
}

export function pinInsertSql(
  p: {
    pinId: string;
    question: string;
    answer: string;
    model: string;
    sources: PinSource[];
    who: string;
  },
): string {
  if (!HEX64.test(p.pinId)) throw new Error("bad pin id");
  return `INSERT INTO help_pg.pins SELECT '${p.pinId}', ${b64(p.question)}, ${
    b64(p.answer)
  }, 'answer', ` +
    `${b64(p.model)}, ${b64("help_index")}, ${
      b64(JSON.stringify(p.sources))
    }, current_timestamp(), ` +
    `${b64(p.who)}, 'current'`;
}

export function eventInsertSql(
  pinId: string,
  kind: EventKind,
  who: string,
): string {
  if (!HEX64.test(pinId)) throw new Error("bad pin id");
  if (!EVENT_KINDS.includes(kind)) throw new Error("bad event kind");
  return `INSERT INTO help_pg.pin_events SELECT '${crypto.randomUUID()}', '${pinId}', '${kind}', ` +
    `current_timestamp(), ${b64(who)}`;
}

/** A pin is stale when a cited file is gone from the catalog or its content hash changed. */
export function staleness(
  sources: PinSource[],
  current: Map<string, string>,
): Stale {
  const missing = sources.filter((s) => !current.has(s.file)).map((s) =>
    s.file
  );
  if (missing.length) return { state: "missing", files: missing };
  const changed = sources.filter((s) =>
    s.sha !== null && current.get(s.file) !== s.sha
  ).map((s) => s.file);
  return changed.length
    ? { state: "changed", files: changed }
    : { state: "current", files: [] };
}

export async function lookupShas(
  store: Pick<PinStore, "run">,
  files: string[],
): Promise<Map<string, string>> {
  const out = new Map<string, string>();
  const uniq = [...new Set(files)];
  if (!uniq.length) return out;
  const r = await store.run(
    `SELECT path, git_sha FROM ${USL}.docs WHERE path IN (${
      uniq.map(b64).join(", ")
    })`,
    uniq.length + 5,
  );
  for (const row of r.rows) out.set(row[0], row[1]);
  return out;
}

function parseSources(json: string): PinSource[] {
  try {
    const v = JSON.parse(json);
    return Array.isArray(v)
      ? v.filter((s) => typeof s?.file === "string").map((s) => ({
        file: s.file,
        sha: typeof s.sha === "string" ? s.sha : null,
      }))
      : [];
  } catch {
    return [];
  }
}

const VIEW_COLS =
  "p.pin_id, p.question, p.answer, p.origin, p.model, p.sources, p.pinned_at, p.pinned_by, p.status, s.likes, s.uses";

async function views(
  store: Pick<PinStore, "run">,
  where: string,
  limit: number,
): Promise<PinView[]> {
  const r = await store.run(
    `SELECT ${VIEW_COLS} FROM ${USL}.pins p JOIN ${USL}.pin_scores s ON s.pin_id = p.pin_id ${where} ` +
      `ORDER BY s.likes DESC, p.pinned_at DESC`,
    limit,
  );
  const rows = r.rows.map((x) => ({ x, sources: parseSources(x[5]) }));
  const current = await lookupShas(
    store,
    rows.flatMap((r) => r.sources.map((s) => s.file)),
  );
  return rows.map(({ x, sources }) => ({
    pinId: x[0],
    question: x[1],
    answer: x[2],
    origin: x[3],
    model: x[4],
    sources,
    pinnedAt: x[6],
    pinnedBy: x[7] || "anonymous",
    status: x[8],
    likes: Number(x[9]),
    uses: Number(x[10]),
    stale: staleness(sources, current),
  }));
}

/** Every current pin, most liked first. */
export const listPins = (store: Pick<PinStore, "run">, limit = 200) =>
  views(store, "WHERE p.status = 'current'", limit);

export async function pinExists(
  store: Pick<PinStore, "run">,
  pinId: string,
): Promise<boolean> {
  if (!HEX64.test(pinId)) return false;
  const r = await store.run(
    `SELECT count(*) FROM ${USL}.pins WHERE pin_id = '${pinId}'`,
    1,
  );
  return Number(r.rows[0]?.[0]) > 0;
}

async function scores(
  store: Pick<PinStore, "run">,
  pinId: string,
): Promise<{ likes: number; uses: number }> {
  const r = await store.run(
    `SELECT likes, uses FROM ${USL}.pin_scores WHERE pin_id = '${pinId}'`,
    1,
  );
  return {
    likes: Number(r.rows[0]?.[0] ?? 0),
    uses: Number(r.rows[0]?.[1] ?? 0),
  };
}

export interface PinInput {
  question: unknown;
  answer: unknown;
  model: unknown;
  sources: unknown;
  who: unknown;
}

/** Pin an answer. The same question and answer pin once. Cited files are checked against the
 * catalog and recorded with their current hash, so a client cannot invent sources. */
export async function createPin(
  store: PinStore,
  input: PinInput,
): Promise<{ pinId: string; existing: boolean; likes: number }> {
  const question = cleanText(input.question, MAX_QUESTION);
  const answer = cleanText(input.answer, MAX_ANSWER);
  if (!question || !answer) {
    throw new AskError(
      "bad_request",
      "A pin needs a question and an answer.",
      400,
    );
  }
  const who = cleanText(input.who, 100) || "anonymous";
  const model = cleanText(input.model, 100);
  const claimed = Array.isArray(input.sources)
    ? input.sources.map((s) => cleanText((s as { file?: unknown })?.file, 400))
      .filter(Boolean).slice(0, MAX_SOURCES)
    : [];
  const pinId = await pinIdOf(question, answer);
  if (await pinExists(store, pinId)) {
    return { pinId, existing: true, likes: (await scores(store, pinId)).likes };
  }
  const shas = await lookupShas(store, claimed);
  const sources: PinSource[] = [...new Set(claimed)].filter((f) => shas.has(f))
    .map((f) => ({
      file: f,
      sha: shas.get(f)!,
    }));
  // Embed first: a vector with no row is ignored by searches, a row with no vector would never be found.
  await store.embedPin(pinPassage(pinId, question, answer));
  await store.run(
    pinInsertSql({ pinId, question, answer, model, sources, who }),
    1,
  );
  return { pinId, existing: false, likes: 0 };
}

export async function addEvent(
  store: PinStore,
  input: { pinId: unknown; kind: unknown; who: unknown },
): Promise<{ likes: number; uses: number }> {
  const pinId = typeof input.pinId === "string" ? input.pinId : "";
  const kind = EVENT_KINDS.find((k) => k === input.kind);
  if (!HEX64.test(pinId) || !kind) {
    throw new AskError(
      "bad_request",
      "Send {pinId, kind: like | unlike | use}.",
      400,
    );
  }
  if (kind === "retire") {
    throw new AskError(
      "bad_request",
      "Retiring a pin is not available in the app.",
      400,
    );
  }
  if (!(await pinExists(store, pinId))) {
    throw new AskError("not_found", "That pinned answer does not exist.", 404);
  }
  await store.run(
    eventInsertSql(pinId, kind, cleanText(input.who, 100) || "anonymous"),
    1,
  );
  return await scores(store, pinId);
}

export interface PastAnswer extends PinView {
  similarity: number;
  score: number;
}

/** Search the pins collection and rank: similarity plus 0.03 x ln(1 + likes). Only pins whose
 * similarity reaches the threshold are shown. */
export async function findPast(
  store: PinStore,
  question: string,
  threshold: number,
  bonus = PIN_BONUS,
  limit = 3,
): Promise<PastAnswer[]> {
  const hits = (await store.searchPins(question)).filter((p) =>
    p.similarity >= threshold && HEX64.test(p.file)
  );
  if (!hits.length) return [];
  const sim = new Map<string, number>();
  for (const h of hits) {
    sim.set(h.file, Math.max(sim.get(h.file) ?? 0, h.similarity));
  }
  const found = await views(
    store,
    `WHERE p.status = 'current' AND p.pin_id IN (${
      [...sim.keys()].map((i) => `'${i}'`).join(", ")
    })`,
    50,
  );
  return found
    .map((v) => {
      const similarity = sim.get(v.pinId)!;
      return {
        ...v,
        similarity: Number(similarity.toFixed(3)),
        score: similarity + bonus * Math.log(1 + v.likes),
      };
    })
    .sort((a, b) => b.score - a.score)
    .slice(0, limit);
}
