#!/usr/bin/env -S deno run --no-config --env-file=.env --allow-net --allow-env=ZETARIS*
// Check authenticated API access by listing the Lightning databases visible to
// this account. Prints the count and does not submit SQL.
import { zetarisRequest } from "./zetaris_api.ts";

try {
  const databases = await zetarisRequest(
    "/api/proxy/lightning-database/databases",
  );
  if (!Array.isArray(databases)) {
    throw new Error("Unexpected database-list response.");
  }
  console.log(
    `Zetaris connection OK. Visible Lightning databases: ${databases.length}.`,
  );
} catch (error) {
  console.error(error instanceof Error ? error.message : error);
  Deno.exit(1);
}
