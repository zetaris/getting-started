// Pipeline spec templates. Specs go to Zetaris as `RUN PIPELINE ON '<node>' LIMIT n SPEC {...}`
// or `REGISTER PIPELINE RELATION CONTAINER <c> SPEC {...}`.
import { type Segment, toBase64 } from "./corpus.ts";
import type { Config } from "./config.ts";

// Pilot findings (Zetaris 2.4.3.1): settings use the nested `strategy`/`provider` + `config`
// form, the Chunking node is only a guard here (the text is already cut), and the Milvus sink
// uses the chunk text as its primary key, which the REPO/FILE/PART header keeps unique.

/** One `select` per segment with every text value base64-encoded, so quotes, semicolons and
 * newlines in the Markdown cannot break the statement. Columns become the chunk header. */
export function segmentsSql(segments: Segment[]): string {
  const row = (s: Segment) =>
    `select '${s.corpus}' as repo, ` +
    `decode(unbase64('${toBase64(s.file)}'),'UTF-8') as file, ` +
    `'${s.part}' as part, ` +
    `decode(unbase64('${toBase64(s.section)}'),'UTF-8') as section, ` +
    `decode(unbase64('${toBase64(s.text)}'),'UTF-8') as text`;
  return segments.map(row).join("\nunion all\n");
}

export function ingestSpec(
  cfg: Config,
  sql: string,
  collection = cfg.collection,
) {
  return {
    name: "help_ingest",
    description: "Markdown segments, Chunking guard, Embedding, Milvus",
    nodes: [
      {
        nodeType: "SQLTable",
        name: "src",
        sources: [],
        columns: [],
        properties: [],
        sqlExpression: sql,
      },
      {
        nodeType: "Chunking",
        name: "chunk",
        strategy: "GenericText",
        config: { maxSegmentSizeInChars: 1500, maxOverlapSizeInChars: 0 },
        sources: ["src"],
        columns: [],
        properties: [],
      },
      {
        nodeType: "Embedding",
        name: "emb",
        provider: "Local",
        config: { localEmbeddingModelName: cfg.embeddingModel },
        sources: ["chunk"],
        columns: [],
        properties: [],
      },
      {
        nodeType: "VectorStoreSink",
        name: "sink",
        provider: "Milvus",
        config: {
          uri: cfg.milvusUri,
          token: cfg.milvusToken,
          collectionName: collection,
          milvusBatchSize: 100,
        },
        sources: ["emb"],
        columns: [],
        properties: [],
      },
    ],
  };
}

export function searchNode(cfg: Config, question: string) {
  return {
    nodeType: "VectorStoreSearch",
    name: "vs_search",
    vectorStoreProvider: "Milvus",
    vectorStoreConfig: {
      uri: cfg.milvusUri,
      token: cfg.milvusToken,
      collectionName: cfg.collection,
    },
    embeddingProvider: "Local",
    embeddingConfig: { localEmbeddingModelName: cfg.embeddingModel },
    prompt: question,
    sources: [],
    columns: [],
    properties: [],
  };
}

/** Search only. The question is fixed inside the node: sources are ignored and placeholders
 * are not substituted, so a different question needs a new spec. */
export function searchSpec(
  cfg: Config,
  question: string,
  name = "help_search",
) {
  return {
    name,
    description: "Search the help index; the question is fixed in the node",
    nodes: [searchNode(cfg, question)],
  };
}

export function answerSpec(
  cfg: Config,
  question: string,
  name = "help_answer",
) {
  return {
    name,
    description: "Search, then answer from the passages",
    nodes: [
      searchNode(cfg, question),
      {
        nodeType: "LLM",
        name: "llm_answer",
        provider: "Ollama",
        config: {
          ollamaUrl: cfg.ollamaUrl,
          ollamaModelName: cfg.ollamaModel,
        },
        prompt:
          `${question} Use only the contexts. If they do not contain what is asked, say so.`,
        topN: 12,
        minScore: 0.0,
        sources: ["vs_search"],
        columns: [],
        properties: [],
      },
    ],
  };
}

// In the pilot build, a spec whose text contains a command phrase such as "compile usl" or
// "run dq" failed to parse ("no viable alternative at input 'RUN PIPELINE'"). Writing the
// first letter as a JSON escape passes parsing. See the companion guide, section 9.5.
const COMMAND_PHRASE =
  /\b(compile|activate|run|show|register)(\s+)(usl|dq)\b/gi;

/** Serialize a spec for the SQL statement, escaping the first letter of any such phrase. */
export function specJson(spec: unknown): string {
  return JSON.stringify(spec).replace(
    COMMAND_PHRASE,
    (_m, verb: string, space: string, noun: string) =>
      `\\u00${verb.charCodeAt(0).toString(16).padStart(2, "0")}${
        verb.slice(1)
      }${space}${noun}`,
  );
}

export const runPipeline = (node: string, limit: number, spec: unknown) =>
  `RUN PIPELINE ON '${node}' LIMIT ${limit} SPEC ${specJson(spec)}`;

export const registerRelation = (container: string, spec: unknown) =>
  `REGISTER PIPELINE RELATION CONTAINER ${container} SPEC ${specJson(spec)}`;
