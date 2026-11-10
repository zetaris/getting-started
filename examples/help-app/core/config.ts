// Configuration, all from the environment (the repo's .env.local). Nothing here is a real
// host, token or model name.
import "../../../scripts/load_env.ts";

const DIMENSIONS: Record<string, number> = {
  "e5-small-v2": 384,
  "bge-small-en-v1.5": 384,
  "all-minilm-l6-v2": 384,
};

function env(name: string, fallback = ""): string {
  return Deno.env.get(name) ?? fallback;
}

export function loadConfig() {
  const model = env("HELP_EMBEDDING_MODEL", "e5-small-v2").toLowerCase();
  const dim = DIMENSIONS[model];
  if (!dim) {
    throw new Error(
      `HELP_EMBEDDING_MODEL must be one of ${
        Object.keys(DIMENSIONS).join(", ")
      }.`,
    );
  }
  const batch = Number(env("HELP_BATCH", "100"));
  if (!Number.isInteger(batch) || batch < 1 || batch > 500) {
    throw new Error("HELP_BATCH must be an integer from 1 to 500.");
  }
  return {
    zetarisUrl: env("ZETARIS_REST_URL", "http://localhost:8888/api/v1.0")
      .replace(/\/$/, ""),
    apiKey: env("ZETARIS_API_KEY"),
    orgId: env("ZETARIS_ORG_ID", "1"),
    milvusUri: env("MILVUS_URI", "http://host.docker.internal:19530"),
    milvusHostUri: env("MILVUS_HOST_URI", "http://127.0.0.1:19530").replace(
      /\/$/,
      "",
    ),
    milvusToken: env("MILVUS_TOKEN", "root:Milvus"),
    collection: env("HELP_COLLECTION", "help_index"),
    embeddingModel: model,
    dim,
    container: env("HELP_CONTAINER", "help_app"),
    batch,
    ollamaUrl: env("OLLAMA_URL"),
    ollamaModel: env("OLLAMA_MODEL"),
  };
}

export type Config = ReturnType<typeof loadConfig>;
