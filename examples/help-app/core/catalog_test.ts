import { assert, assertEquals, assertThrows } from "@std/assert";
import {
  batches,
  checkKeyLengths,
  chunkId,
  chunksInsert,
  createDatasourceSql,
  docsInsert,
} from "./catalog.ts";
import type { DocInfo, Segment } from "./corpus.ts";

const doc: DocInfo = {
  corpus: "repo",
  path: "a/b.md",
  title: `It's "quoted"`,
  kind: "guide",
  bytes: 12,
  gitSha: "abc",
  chunkCount: 2,
};
const seg: Segment = {
  corpus: "repo",
  file: "a/b.md",
  part: 1,
  section: "S",
  text: "x'y\nz",
};

Deno.test("inserts carry base64 values only, so no raw quotes reach the statement", () => {
  const d = docsInsert([doc]);
  const c = chunksInsert([seg]);
  assert(d.startsWith("INSERT INTO help_pg.docs SELECT"));
  assert(c.startsWith("INSERT INTO help_pg.chunks SELECT"));
  assert(!d.includes(`It's`) && !c.includes("x'y"));
  assert(c.includes("CAST(5 AS INT)")); // char_count of "x'y\nz"
});

Deno.test("rows are joined with UNION ALL and batches split evenly", () => {
  assertEquals(docsInsert([doc, doc]).split("UNION ALL").length, 2);
  assertEquals(batches([1, 2, 3, 4, 5], 2), [[1, 2], [3, 4], [5]]);
  assertEquals(chunkId(seg), "a/b.md#1");
});

Deno.test("keys longer than the USL columns are refused", () => {
  assertThrows(() => checkKeyLengths([{ ...doc, path: "p".repeat(401) }], []));
  assertThrows(() => checkKeyLengths([], [{ ...seg, file: "f".repeat(499) }]));
  checkKeyLengths([doc], [seg]);
});

Deno.test("datasource statement refuses values that would break the quoting", () => {
  const ok = {
    pgHost: "h",
    pgPort: "1",
    pgDb: "d",
    pgUser: "u",
    pgPassword: "p",
  };
  assert(createDatasourceSql(ok).includes('password "p"'));
  assertThrows(() => createDatasourceSql({ ...ok, pgPassword: 'a"b' }));
});
