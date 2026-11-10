// The only direct Milvus call the example makes: the sink does not create its collection, so
// the ingest script does, through Milvus's REST API. It also counts rows to check an ingest.
import type { Config } from "./config.ts";

async function call(cfg: Config, path: string, body: unknown) {
  const res = await fetch(`${cfg.milvusHostUri}/v2/vectordb${path}`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${cfg.milvusToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(60_000),
  });
  const out = await res.json();
  if (!res.ok || out.code !== 0) {
    throw new Error(`Milvus ${path}: ${JSON.stringify(out).slice(0, 300)}`);
  }
  return out;
}

export async function hasCollection(cfg: Config): Promise<boolean> {
  const out = await call(cfg, "/collections/list", {});
  return (out.data as string[]).includes(cfg.collection);
}

export async function dropCollection(cfg: Config): Promise<void> {
  await call(cfg, "/collections/drop", { collectionName: cfg.collection });
}

export function collectionBody(cfg: Config) {
  return {
    collectionName: cfg.collection,
    schema: {
      autoID: false,
      enableDynamicField: true,
      fields: [
        {
          fieldName: "id",
          dataType: "VarChar",
          isPrimary: true,
          elementTypeParams: { max_length: "65535" },
        },
        {
          fieldName: "vector",
          dataType: "FloatVector",
          elementTypeParams: { dim: String(cfg.dim) },
        },
      ],
    },
    indexParams: [{
      fieldName: "vector",
      metricType: "COSINE",
      indexName: "vec_idx",
      indexType: "AUTOINDEX",
    }],
  };
}

export async function createCollection(cfg: Config): Promise<void> {
  await call(cfg, "/collections/create", collectionBody(cfg));
}

export async function countRows(cfg: Config): Promise<number> {
  const out = await call(cfg, "/entities/query", {
    collectionName: cfg.collection,
    filter: 'id != ""',
    outputFields: ["count(*)"],
  });
  return Number(out.data[0]["count(*)"]);
}
