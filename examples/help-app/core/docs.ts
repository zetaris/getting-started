// The Docs browser's data: the catalog comes from help_usl.docs through Zetaris, and a file can be
// opened only if it is in that catalog, so a request path is never used to reach the disk directly.
import { toBase64 } from "./corpus.ts";
import { slugOf } from "./slug.ts";
import type { Zetaris } from "./zetaris.ts";

export const USL = "lightning.metastore.help_app_usl.help_usl";
export const KBASE_BASE = "https://kbase.zetaris.com/knowledge/";

export interface DocRow {
  path: string;
  corpus: string;
  title: string;
  kind: string;
  chunkCount: number;
}

export interface ChunkRow {
  part: number;
  section: string;
  chars: number;
}

const b64 = (t: string) => `decode(unbase64('${toBase64(t)}'),'UTF-8')`;

/** A repo-relative Markdown or SQL path with no way out of the repo. */
export function validRepoPath(p: string): boolean {
  if (!p || p.length > 400) return false;
  if (p.startsWith("/") || p.includes("\\") || p.includes("\0")) return false;
  if (p.split("/").some((seg) => seg === ".." || seg === "." || seg === "")) {
    return false;
  }
  return /\.(md|sql)$/.test(p);
}

export const validSlug = (s: string) =>
  /^[A-Za-z0-9][A-Za-z0-9._-]{0,200}$/.test(s);

export const kbaseUrl = (slug: string) => `${KBASE_BASE}${slug}`;
/** The file slug of a Kbase URL: the snapshot file name, safe in a path. The URL itself may hold
 * `/` or `%2F` (for example "creation-/-deletion"), which a route segment cannot carry. */
export const kbaseSlug = (url: string) => slugOf(url);

/** The in-app link for a catalog path or Kbase URL. */
export function docHref(path: string): string {
  return path.startsWith(KBASE_BASE)
    ? `/docs/kbase/${encodeURIComponent(kbaseSlug(path))}`
    : `/docs/${path.split("/").map(encodeURIComponent).join("/")}`;
}

let cache: { at: number; rows: DocRow[] } | null = null;
const TTL_MS = 60_000;

export function clearDocsCache() {
  cache = null;
}

export async function listDocs(
  z: Pick<Zetaris, "run">,
  now = Date.now(),
): Promise<DocRow[]> {
  if (cache && now - cache.at < TTL_MS) return cache.rows;
  const r = await z.run(
    `SELECT path, corpus, title, kind, chunk_count FROM ${USL}.docs ORDER BY corpus, kind, path`,
    2000,
  );
  const rows = r.rows.map((x) => ({
    path: x[0],
    corpus: x[1],
    title: x[2] || x[0],
    kind: x[3],
    chunkCount: Number(x[4]),
  }));
  cache = { at: now, rows };
  return rows;
}

export interface DocFilter {
  q?: string;
  corpus?: string;
  kind?: string;
}

export function filterDocs(rows: DocRow[], f: DocFilter): DocRow[] {
  const q = (f.q ?? "").trim().toLowerCase();
  return rows.filter((d) =>
    (!f.corpus || d.corpus === f.corpus) && (!f.kind || d.kind === f.kind) &&
    (!q || d.path.toLowerCase().includes(q) ||
      d.title.toLowerCase().includes(q))
  );
}

/** corpus -> kind -> docs, both levels sorted. */
export function groupDocs(
  rows: DocRow[],
): { corpus: string; kinds: { kind: string; docs: DocRow[] }[] }[] {
  const out = new Map<string, Map<string, DocRow[]>>();
  for (const d of rows) {
    const k = out.get(d.corpus) ?? new Map<string, DocRow[]>();
    k.set(d.kind, [...(k.get(d.kind) ?? []), d]);
    out.set(d.corpus, k);
  }
  return [...out].sort(([a], [b]) => a.localeCompare(b)).map((
    [corpus, kinds],
  ) => ({
    corpus,
    kinds: [...kinds].sort(([a], [b]) => a.localeCompare(b)).map((
      [kind, docs],
    ) => ({ kind, docs })),
  }));
}

export async function docChunks(
  z: Pick<Zetaris, "run">,
  path: string,
): Promise<ChunkRow[]> {
  const r = await z.run(
    `SELECT part, section, char_count FROM ${USL}.chunks WHERE path = ${
      b64(path)
    } ORDER BY part`,
    500,
  );
  return r.rows.map((x) => ({
    part: Number(x[0]),
    section: x[1] ?? "",
    chars: Number(x[2]),
  }));
}

/** Remove a Kbase file's `---` header. */
export function stripFrontMatter(raw: string): string {
  const m = raw.match(/^---\n[\s\S]*?\n---\n/);
  return m ? raw.slice(m[0].length) : raw;
}

export interface DocFile {
  row: DocRow;
  body: string;
  isSql: boolean;
}

export interface DocIo {
  /** Read a repo file by repo-relative path; null when missing or outside the repo. */
  readRepo(path: string): Promise<string | null>;
  readKbase(slug: string): Promise<string | null>;
}

/** Open a doc: it must be in the catalog, which is the allowlist. null when it is not. */
export async function openDoc(
  z: Pick<Zetaris, "run">,
  io: DocIo,
  kind: "repo" | "kbase",
  key: string,
): Promise<DocFile | null> {
  if (kind === "repo" ? !validRepoPath(key) : !validSlug(key)) return null;
  const row = (await listDocs(z)).find((d) =>
    kind === "repo"
      ? d.path === key
      : d.path.startsWith(KBASE_BASE) && kbaseSlug(d.path) === key
  );
  if (!row) return null;
  const raw = kind === "repo"
    ? await io.readRepo(key)
    : await io.readKbase(key);
  if (raw === null) return null;
  return {
    row,
    body: kind === "kbase" ? stripFrontMatter(raw) : raw,
    isSql: key.endsWith(".sql"),
  };
}
