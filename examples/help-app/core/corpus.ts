// Corpus: walk the repo's Markdown, describe each file, and cut it into segments.
// Pure functions where possible so they can be unit tested without a Zetaris stack.

export type Corpus = "repo" | "kbase";

export interface Segment {
  corpus: Corpus;
  file: string;
  part: number;
  section: string;
  text: string;
}

export interface DocInfo {
  corpus: Corpus;
  path: string;
  title: string;
  kind: string;
  bytes: number;
  gitSha: string;
  chunkCount: number;
}

/** Segment text the pipeline receives. The Chunking node adds a header of about 150 characters,
 * so text stays well under the 1,500-character guard set on that node. */
export const TARGET = 1000;
export const MAX_TEXT = 1300;
const OVERLAP = 100;
const MIN_SECTION = 400;

const TOP_LEVEL_SKIP = new Set(["dist", "site", "tmp", "reports"]);

export interface WalkOptions {
  /** Repo-relative path prefixes to leave out (for example the example's own kbase snapshot). */
  skipPrefixes?: string[];
}

/** Every `*.md` under `root`, as repo-relative paths, sorted. Skips node_modules, dot
 * directories, and the top-level dist, site, tmp and reports folders. */
export async function walkMarkdown(
  root: string,
  opts: WalkOptions = {},
): Promise<string[]> {
  const out: string[] = [];
  const skip = opts.skipPrefixes ?? [];
  async function visit(rel: string): Promise<void> {
    for await (const entry of Deno.readDir(rel ? `${root}/${rel}` : root)) {
      const path = rel ? `${rel}/${entry.name}` : entry.name;
      if (entry.name.startsWith(".")) continue;
      if (entry.isDirectory) {
        if (entry.name === "node_modules") continue;
        if (!rel && TOP_LEVEL_SKIP.has(entry.name)) continue;
        if (skip.some((p) => `${path}/`.startsWith(p))) continue;
        await visit(path);
      } else if (entry.isFile && entry.name.endsWith(".md")) {
        if (skip.some((p) => path.startsWith(p))) continue;
        out.push(path);
      }
    }
  }
  await visit("");
  return out.sort();
}

export function titleOf(path: string, text: string): string {
  const m = text.match(/^#\s+(.+?)\s*$/m);
  return m ? m[1].replace(/[`*]/g, "") : path.split("/").pop()!;
}

export function kindOf(path: string): string {
  const name = path.split("/").pop()!;
  if (/^(AGENTS|CLAUDE|CONTRIBUTING)\.md$/.test(name)) return "agent-rules";
  if (name === "HOWTO.md") return "howto";
  if (/(^|[-_])(data-)?sources?\.md$|catalog/i.test(name)) return "catalog";
  if (path.startsWith("docs/guides/")) return "guide";
  if (path.startsWith("docs/plans/")) return "plan";
  if (path.startsWith("docs/connections/") || path.startsWith("systems/")) {
    return "reference";
  }
  if (/^(README|START-HERE)\.md$/.test(name)) return "guide";
  return "other";
}

/** The git blob id of the content, computed in-process so no git binary is needed. */
export async function gitBlobSha(bytes: Uint8Array): Promise<string> {
  const header = new TextEncoder().encode(`blob ${bytes.length}\0`);
  const all = new Uint8Array(header.length + bytes.length);
  all.set(header);
  all.set(bytes, header.length);
  const digest = await crypto.subtle.digest("SHA-1", all);
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

export function toBase64(text: string): string {
  const bytes = new TextEncoder().encode(text);
  let binary = "";
  for (let i = 0; i < bytes.length; i += 0x8000) {
    binary += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  }
  return btoa(binary);
}

export function fromBase64(b64: string): string {
  const binary = atob(b64);
  return new TextDecoder().decode(
    Uint8Array.from(binary, (c) => c.charCodeAt(0)),
  );
}

interface Unit {
  text: string;
  fence: boolean;
}
interface Section {
  heading: string;
  units: Unit[];
}

/** Break a document into sections at headings of level 1 to 3 (outside code fences), and each
 * section into units: a paragraph, or a whole fenced block. */
function toSections(text: string): Section[] {
  const sections: Section[] = [{ heading: "", units: [] }];
  let para: string[] = [];
  let fence: string[] | null = null;
  let heading = "";
  const flush = () => {
    const t = para.join("\n").trim();
    if (t) sections[sections.length - 1].units.push({ text: t, fence: false });
    para = [];
  };
  for (const line of text.split("\n")) {
    if (fence) {
      fence.push(line);
      if (/^\s*(```|~~~)/.test(line)) {
        sections[sections.length - 1].units.push({
          text: fence.join("\n"),
          fence: true,
        });
        fence = null;
      }
      continue;
    }
    if (/^\s*(```|~~~)/.test(line)) {
      flush();
      fence = [line];
      continue;
    }
    const h = line.match(/^(#{1,6})\s+(.+?)\s*#*\s*$/);
    if (h) {
      const level = h[1].length;
      heading = h[2].replace(/[`*]/g, "");
      if (level <= 3) {
        flush();
        sections.push({ heading, units: [] });
      }
    }
    if (line.trim() === "") flush();
    else para.push(line);
  }
  if (fence) {
    sections[sections.length - 1].units.push({
      text: fence.join("\n"),
      fence: true,
    });
  }
  flush();
  return sections.filter((s) => s.units.length > 0);
}

/** Cut one oversized unit into pieces of at most TARGET characters. Fenced code is cut at line
 * boundaries; long prose uses TARGET-character windows every TARGET - OVERLAP characters. */
function splitUnit(u: Unit): string[] {
  if (u.text.length <= MAX_TEXT) return [u.text];
  const pieces: string[] = [];
  if (u.fence) {
    let cur = "";
    for (const line of u.text.split("\n")) {
      if (line.length > TARGET) {
        if (cur) pieces.push(cur);
        cur = "";
        pieces.push(...windows(line));
        continue;
      }
      if (cur && cur.length + line.length + 1 > TARGET) {
        pieces.push(cur);
        cur = line;
      } else cur = cur ? `${cur}\n${line}` : line;
    }
    if (cur) pieces.push(cur);
    return pieces;
  }
  return windows(u.text);
}

function windows(text: string): string[] {
  const out: string[] = [];
  for (let i = 0; i < text.length; i += TARGET - OVERLAP) {
    out.push(text.slice(i, i + TARGET));
    if (i + TARGET >= text.length) break;
  }
  return out;
}

function pack(units: Unit[]): string[] {
  const out: string[] = [];
  let cur = "";
  for (const u of units) {
    for (const piece of splitUnit(u)) {
      if (cur && cur.length + piece.length + 2 > TARGET) {
        out.push(cur);
        cur = piece;
      } else cur = cur ? `${cur}\n\n${piece}` : piece;
    }
  }
  if (cur) out.push(cur);
  return out;
}

/** Heading-aware segments: sections packed up to about 1,000 characters, very small sections
 * carried into the next one, oversized paragraphs and code blocks cut as described above. */
export function splitDocument(
  corpus: Corpus,
  file: string,
  text: string,
): Segment[] {
  const sections = toSections(text);
  const out: Segment[] = [];
  let carry: Unit[] = [];
  let carryHeading = "";
  const emit = (heading: string, parts: string[]) => {
    for (const t of parts) {
      const trimmed = t.trim();
      if (trimmed) {
        out.push({
          corpus,
          file,
          part: out.length,
          section: heading,
          text: trimmed,
        });
      }
    }
  };
  sections.forEach((s, i) => {
    const heading = carry.length ? carryHeading : s.heading;
    const units = [...carry, ...s.units];
    const size = units.reduce((n, u) => n + u.text.length, 0);
    if (size < MIN_SECTION && i < sections.length - 1) {
      if (!carry.length) carryHeading = s.heading;
      carry = units;
      return;
    }
    carry = [];
    emit(heading, pack(units));
  });
  return out;
}

export interface Corpusload {
  docs: DocInfo[];
  segments: Segment[];
}

export async function loadRepoCorpus(
  root: string,
  opts: WalkOptions = {},
): Promise<Corpusload> {
  const files = await walkMarkdown(root, opts);
  const docs: DocInfo[] = [];
  const segments: Segment[] = [];
  for (const path of files) {
    const bytes = await Deno.readFile(`${root}/${path}`);
    const text = new TextDecoder().decode(bytes);
    const segs = splitDocument("repo", path, text);
    segments.push(...segs);
    docs.push({
      corpus: "repo",
      path,
      title: titleOf(path, text),
      kind: kindOf(path),
      bytes: bytes.length,
      gitSha: await gitBlobSha(bytes),
      chunkCount: segs.length,
    });
  }
  return { docs, segments };
}
