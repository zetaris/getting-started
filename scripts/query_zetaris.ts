#!/usr/bin/env -S deno run --no-config --env-file=.env --allow-net --allow-env=ZETARIS* --allow-read
import { zetarisRequest } from "./zetaris_api.ts";

try {
  const args = Deno.args;
  let sql: string;
  if (args[0] === "--file" && args.length === 2) {
    sql = await Deno.readTextFile(args[1]);
  } else if (args.length === 1 && args[0] !== "--file") {
    sql = args[0];
  } else {
    throw new Error(
      'Usage: query_zetaris.ts "SELECT 1" | --file path/to/query.sql',
    );
  }
  if (!sql.trim()) throw new Error("SQL must not be empty.");

  const limit = Number(Deno.env.get("ZETARIS_QUERY_LIMIT") ?? "1000");
  if (!Number.isInteger(limit) || limit < 1) {
    throw new Error("ZETARIS_QUERY_LIMIT must be a positive integer.");
  }
  const engineId = Deno.env.get("ZETARIS_ENGINE_ID");
  const result = await zetarisRequest(
    "/api/proxy/sql-editor/sqls/run-query",
    "POST",
    {
      sql,
      limit,
      ...(engineId ? { engineId } : {}),
    },
  );
  console.log(JSON.stringify(result, null, 2));
} catch (error) {
  console.error(error instanceof Error ? error.message : error);
  Deno.exit(1);
}
