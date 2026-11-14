// Statements for the engineering review export. The script prints them and, only with --yes,
// runs the RUN EXPORT lines. Schema statements are never run here.
import { USL } from "./docs.ts";

const DATE = /^\d{4}-\d{2}-\d{2}$/;
const SAFE = /^[A-Za-z0-9_.:/-]+$/;

export const REVIEW = [
  { table: "pin_reception", date: "pinned_date", prefix: "pin_reception" },
  { table: "pin_event_log", date: "event_date", prefix: "pin_event_log" },
  { table: "search_log", date: "asked_date", prefix: "search_log" },
  { table: "example_log", date: "created_date", prefix: "example_log" },
] as const;

export function schemaStatements(): string[] {
  return [
    `CREATE TABLE IF NOT EXISTS searches (
  search_id text PRIMARY KEY,
  question text,
  asked_at timestamp,
  who text,
  surface text
)`,
    `CREATE TABLE IF NOT EXISTS examples (
  example_id text PRIMARY KEY,
  request text,
  sql_text text,
  status text,
  attempts integer,
  model text,
  sources text,
  created_at timestamp,
  who text
)`,
    `REGISTER DATASOURCE TABLE "searches" FROM help_pg`,
    `REGISTER DATASOURCE TABLE "examples" FROM help_pg`,
  ];
}

export function datesQuery(table: string, column: string): string {
  return `SELECT DISTINCT ${column} FROM ${USL}.${table} WHERE ${column} IS NOT NULL`;
}

/** One RUN EXPORT per date. A date that is not yyyy-mm-dd is skipped. */
export function exportStatements(
  dates: Record<string, string[]>,
  base: string,
  storageId: string,
): string[] {
  const root = base.replace(/\/$/, "");
  if (!SAFE.test(root) || !SAFE.test(storageId)) {
    throw new Error(
      "HELP_EXPORT_PATH and HELP_EXPORT_STORAGE_ID must be plain paths.",
    );
  }
  const out: string[] = [];
  for (const spec of REVIEW) {
    for (const date of dates[spec.table] ?? []) {
      if (!DATE.test(date)) continue;
      const path = `${root}/${spec.prefix}/dt=${date}/`;
      out.push(
        `RUN EXPORT TO STORAGE (
  query = 'SELECT * FROM ${USL}.${spec.table} WHERE ${spec.date} = ''${date}''',
  path = '${path}',
  format = 'parquet',
  saveMode = 'overwrite',
  storageSettingId = '${storageId}'
)`,
      );
    }
  }
  return out;
}
