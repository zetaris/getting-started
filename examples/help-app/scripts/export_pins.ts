// Pull the review tables out to date-prefixed Parquet.
// Usage: deno task help:export-pins            (prints statements, writes nothing)
//        deno task help:export-pins -- --yes   (writes; needs HELP_EXPORT_PATH and
//                                               HELP_EXPORT_STORAGE_ID)
// Schema statements are printed and are not run. Apply those on Postgres and in
// Zetaris only after a go-ahead, then rebuild the help USL.
import { loadConfig } from "../core/config.ts";
import {
  datesQuery,
  exportStatements,
  REVIEW,
  schemaStatements,
} from "../core/export.ts";
import { zetarisClient, ZetarisError } from "../core/zetaris.ts";

const yes = Deno.args.includes("--yes");

console.log("-- Schema. Not run by this task.");
for (const sql of schemaStatements()) console.log(sql + "\n");

let cfg;
try {
  cfg = loadConfig();
} catch (e) {
  console.error((e as Error).message);
  Deno.exit(1);
}
if (!cfg.apiKey) {
  console.error(
    "Zetaris is not configured: set ZETARIS_API_KEY in .env.local and restart.",
  );
  Deno.exit(1);
}

const z = zetarisClient(cfg, 60_000);
const dates: Record<string, string[]> = {};
try {
  for (const spec of REVIEW) {
    const r = await z.run(datesQuery(spec.table, spec.date), 10_000);
    dates[spec.table] = r.rows.map((row) => row[0]).filter(Boolean);
  }
} catch (e) {
  const kind = e instanceof ZetarisError ? e.kind : "error";
  console.error(
    `Could not read the review tables (${kind}). Activate the help USL after the schema statements above.`,
  );
  Deno.exit(1);
}

const base = Deno.env.get("HELP_EXPORT_PATH") ?? "";
const storageId = Deno.env.get("HELP_EXPORT_STORAGE_ID") ?? "";
if (yes && (!base || !storageId)) {
  console.error(
    "A write needs HELP_EXPORT_PATH and HELP_EXPORT_STORAGE_ID. Neither is printed.",
  );
  Deno.exit(1);
}

let statements: string[] = [];
if (base && storageId) {
  try {
    statements = exportStatements(dates, base, storageId);
  } catch (e) {
    console.error((e as Error).message);
    Deno.exit(1);
  }
} else if (!yes) {
  console.log(
    "-- Set HELP_EXPORT_PATH and HELP_EXPORT_STORAGE_ID to print the export paths.",
  );
}

if (statements.length === 0) {
  console.log("-- No dated rows to export.");
} else if (!yes) {
  console.log("-- Dry run. Nothing is written.");
  for (const sql of statements) console.log(sql + "\n");
} else {
  for (const sql of statements) {
    await z.run(sql, 10);
    const path = sql.match(/path = '([^']+)'/)?.[1] ?? "(path)";
    console.log(path);
  }
}
