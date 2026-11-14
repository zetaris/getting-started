import { assert, assertEquals, assertThrows } from "@std/assert";
import { exportStatements, schemaStatements } from "./export.ts";

Deno.test("the dry-run lists parquet overwrites for each dated review table", () => {
  const sql = exportStatements(
    {
      pin_reception: ["2026-11-13"],
      pin_event_log: ["2026-11-13"],
      search_log: ["2026-11-13", "nope"],
      example_log: [],
    },
    "s3a://bucket/help",
    "setting1",
  );
  assertEquals(sql.length, 3);
  for (const prefix of ["pin_reception", "pin_event_log", "search_log"]) {
    assert(sql.some((s) => s.includes(`/${prefix}/dt=2026-11-13/`)));
  }
  assert(sql.every((s) => s.includes("format = 'parquet'")));
  assert(sql.every((s) => s.includes("saveMode = 'overwrite'")));
  assert(!sql.some((s) => s.includes("example_log")));
  assert(!sql.some((s) => s.includes("nope")));
});

Deno.test("a quote in the export path is refused", () => {
  assertThrows(() => exportStatements({}, "s3a://bucket/'x", "setting1"));
});

Deno.test("schema statements name the new tables and are not exports", () => {
  const sql = schemaStatements();
  assert(sql.some((s) => s.includes("CREATE TABLE IF NOT EXISTS searches")));
  assert(sql.some((s) => s.includes("CREATE TABLE IF NOT EXISTS examples")));
  assert(sql.some((s) => s.includes('REGISTER DATASOURCE TABLE "searches"')));
  assert(sql.every((s) => !s.startsWith("RUN EXPORT")));
});
