// Rows for the Postgres doc and chunk catalogs, written through Zetaris `INSERT INTO ... SELECT`
// with base64-decoded strings (quotes and newlines cannot break the statement).
import { type DocInfo, type Segment, toBase64 } from "./corpus.ts";

export const DS = "help_pg";
export const MAX_PATH = 400;
export const MAX_ID = 500;
const MAX_TITLE = 400;
const MAX_SECTION = 400;

const str = (t: string) => `decode(unbase64('${toBase64(t)}'),'UTF-8')`;
const num = (n: number) => {
  if (!Number.isInteger(n)) throw new Error(`not an integer: ${n}`);
  return String(n);
};

export const chunkId = (s: Pick<Segment, "file" | "part">) =>
  `${s.file}#${s.part}`;

/** Fail early on keys the USL's varchar columns cannot hold. */
export function checkKeyLengths(docs: DocInfo[], segments: Segment[]): void {
  for (const d of docs) {
    if (d.path.length > MAX_PATH) {
      throw new Error(`path too long (${d.path.length}): ${d.path}`);
    }
  }
  for (const s of segments) {
    if (chunkId(s).length > MAX_ID) {
      throw new Error(`chunk id too long: ${chunkId(s)}`);
    }
  }
}

export function docsInsert(docs: DocInfo[]): string {
  const rows = docs.map((d) =>
    `SELECT ${str(d.path)}, ${str(d.corpus)}, ${
      str(d.title.slice(0, MAX_TITLE))
    }, ${str(d.kind)}, ` +
    `CAST(${num(d.bytes)} AS BIGINT), ${str(d.gitSha)}, CAST(${
      num(d.chunkCount)
    } AS INT)`
  );
  return `INSERT INTO ${DS}.docs ${rows.join("\nUNION ALL\n")}`;
}

export function chunksInsert(segments: Segment[]): string {
  const rows = segments.map((s) =>
    `SELECT ${str(chunkId(s))}, ${str(s.file)}, CAST(${num(s.part)} AS INT), ` +
    `${str(s.section.slice(0, MAX_SECTION))}, CAST(${
      num(s.text.length)
    } AS INT), ${str(s.text)}`
  );
  return `INSERT INTO ${DS}.chunks ${rows.join("\nUNION ALL\n")}`;
}

export function batches<T>(items: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += size) {
    out.push(items.slice(i, i + size));
  }
  return out;
}

/** The datasource registration statement. Contains the password: never print or log it. */
export function createDatasourceSql(
  c: {
    pgHost: string;
    pgPort: string;
    pgDb: string;
    pgUser: string;
    pgPassword: string;
  },
): string {
  for (const [k, v] of Object.entries(c)) {
    if (/["\\]/.test(v)) {
      throw new Error(`${k} must not contain quotes or backslashes`);
    }
  }
  return `CREATE DATASOURCE ${DS} DESCRIBE BY "Help app catalog and pin log" OPTIONS (` +
    `jdbcdriver "org.postgresql.Driver", ` +
    `jdbcurl "jdbc:postgresql://${c.pgHost}:${c.pgPort}/${c.pgDb}", ` +
    `username "${c.pgUser}", password "${c.pgPassword}")`;
}
