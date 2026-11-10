import { assert, assertEquals } from "@std/assert";
import { fromBase64 } from "./corpus.ts";
import { loadConfig } from "./config.ts";
import { ingestSpec, searchSpec, segmentsSql, specJson } from "./specs.ts";

Deno.test("command phrases are escaped so the statement parses, and decode back", () => {
  const spec = searchSpec(loadConfig(), "How do I compile usl and run DQ?");
  const json = specJson(spec);
  assert(!/compile usl/i.test(json) && !/run dq/i.test(json));
  assertEquals(
    JSON.parse(json).nodes[0].prompt,
    "How do I compile usl and run DQ?",
  );
});

Deno.test("segment rows carry base64 text only", () => {
  const sql = segmentsSql([{
    corpus: "repo",
    file: "a.md",
    part: 0,
    section: "S",
    text: "x 'q' \"d\"; RUN DQ\nnext",
  }]);
  assert(!sql.includes("RUN DQ"));
  const b64 = sql.match(/unbase64\('([^']+)'\),'UTF-8'\) as text/)![1];
  assertEquals(fromBase64(b64), "x 'q' \"d\"; RUN DQ\nnext");
});

Deno.test("ingest spec uses the nested form and a 1500 guard", () => {
  const spec = ingestSpec(loadConfig(), "select 1");
  const chunk = spec.nodes[1] as { config: { maxSegmentSizeInChars: number } };
  assertEquals(chunk.config.maxSegmentSizeInChars, 1500);
  assertEquals(spec.nodes.map((n) => n.nodeType), [
    "SQLTable",
    "Chunking",
    "Embedding",
    "VectorStoreSink",
  ]);
});
