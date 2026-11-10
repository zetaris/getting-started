// Example-mode bake-off: runs the same requests against one model and prints, per request, the
// dry-run result at attempt 1, after repair, the attempts and the wall-clock time.
// Usage: deno task help:bakeoff --model gpt-oss:120b [--only 1,2]
// Needs Zetaris and the LLM. Nothing is written to the instance (EXPLAIN only).
import { exampleDeps } from "../core/server.ts";
import { generateExample } from "../core/example.ts";

const REQUESTS = [
  "Same as the SIC and EDGAR check, but list companies whose sic is 7372 with the reference description",
  "Count companies per sic_description_edgar in the sic_edgar_usl, largest first",
  "Which SIC codes in the sic_code table have no company in the sic_edgar_usl?",
  "List the companies in the sic_edgar_usl whose entity_name starts with A",
  "Count the files per kind in the help_usl docs table",
  "Show the 10 files with the most chunks in the help_usl chunks table",
  "Count likes per pinned question by joining pin_events and pins in help_usl",
  "Count companies per two-digit SIC prefix in the sic_edgar_usl",
  "Show the five longest sic_code descriptions in the sic_edgar_usl",
  "List docs in help_usl larger than 20000 bytes with their title",
];

const args = Deno.args;
const model = args[args.indexOf("--model") + 1];
if (args.indexOf("--model") === -1 || !model) {
  console.error("Usage: deno task help:bakeoff --model <name> [--only 1,2]");
  Deno.exit(2);
}
const oi = args.indexOf("--only");
const only = oi === -1 ? null : args[oi + 1].split(",").map(Number);
const deps = exampleDeps(model);
let first = 0, repaired = 0, total = 0, secs = 0;
for (const [i, req] of REQUESTS.entries()) {
  if (only && !only.includes(i + 1)) continue;
  total++;
  try {
    const r = await generateExample(deps, req);
    const at1 = r.attempts[0]?.error === null;
    if (at1) first++;
    if (r.status === "dry-run passed") repaired++;
    secs += r.ms / 1000;
    console.log(
      `${i + 1}. ${r.status} attempts=${r.attempts.length} ${
        (r.ms / 1000).toFixed(0)
      }s${at1 ? "" : ` first-error: ${r.attempts[0]?.error?.slice(0, 110)}`}`,
    );
  } catch (e) {
    console.log(`${i + 1}. ERROR ${(e as Error).message.slice(0, 120)}`);
  }
}
console.log(
  `\nmodel ${model}: pass at attempt 1 ${first}/${total}; dry-run passed within 3 attempts ${repaired}/${total}; total ${
    secs.toFixed(0)
  }s`,
);
