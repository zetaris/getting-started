export const MOCK = "http://127.0.0.1:8899";
export const APPS = {
  /** Zetaris and an LLM both configured (against the mock). */
  full: { port: 8801, url: "http://127.0.0.1:8801" },
  /** Zetaris configured, no LLM: Search only. */
  nollm: { port: 8802, url: "http://127.0.0.1:8802" },
  /** Zetaris unreachable. */
  down: { port: 8803, url: "http://127.0.0.1:8803" },
};

const base = {
  ZETARIS_API_KEY: "e2e-key",
  ZETARIS_ORG_ID: "1",
  MILVUS_HOST_URI: MOCK,
  MILVUS_TOKEN: "t",
};

export function appEnv(kind: keyof typeof APPS): Record<string, string> {
  const env: Record<string, string> = {
    ...base,
    HELP_PORT: String(APPS[kind].port),
    ZETARIS_REST_URL: `${MOCK}/api/v1.0`,
    OLLAMA_URL: "",
    OLLAMA_MODEL: "",
  };
  if (kind === "full") {
    env.OLLAMA_URL = MOCK;
    env.OLLAMA_MODEL = "mock-model";
  }
  // Port 9 (discard) refuses connections: a stable "Zetaris is down".
  if (kind === "down") env.ZETARIS_REST_URL = "http://127.0.0.1:9/api/v1.0";
  return env;
}
