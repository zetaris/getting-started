import { define } from "../../utils.ts";
import { logExample, logSearch } from "../../core/activity.ts";
import { parseActor } from "../../core/actor.ts";
import { ask, AskError } from "../../core/ask.ts";
import { caller } from "../../core/caller.ts";
import { generateExample } from "../../core/example.ts";
import { mcpResponse, type McpRuntime } from "../../core/mcp.ts";
import {
  askDeps,
  exampleDeps,
  getConfig,
  getZetaris,
  inFlight,
} from "../../core/server.ts";

export const handler = define.handlers({
  GET(ctx) {
    return mcpResponse(ctx.req, runtime(ctx));
  },
  async POST(ctx) {
    return await mcpResponse(ctx.req, runtime(ctx));
  },
});

function runtime(
  ctx: { req: Request; state: { sessionId: string } },
): McpRuntime {
  const who = caller(ctx.req.headers);
  const lockId = parseActor(who)?.kind === "agent" ? who : ctx.state.sessionId;
  return {
    who,
    lockId,
    flight: inFlight,
    search: (question) => ask(askDeps(), { question, mode: "search" }),
    answer: (question, fresh) =>
      ask(askDeps(), { question, mode: "answer", fresh }),
    example: async (request) => {
      const c = getConfig();
      if (!c.ollamaUrl || !c.exampleModel) {
        throw new AskError(
          "llm_not_configured",
          "Example mode needs OLLAMA_URL and OLLAMA_MODEL (or HELP_EXAMPLE_MODEL) in .env.local.",
          400,
        );
      }
      if (!getZetaris()) {
        throw new AskError(
          "zetaris_config",
          "Zetaris is not configured: set ZETARIS_API_KEY in .env.local and restart.",
          503,
        );
      }
      return await generateExample(exampleDeps(), request);
    },
    logSearch: async (question, actor, surface) => {
      const z = getZetaris();
      if (z) await logSearch(z, question, actor, surface);
    },
    logExample: async (result, request, actor) => {
      const z = getZetaris();
      if (z) await logExample(z, result, request, actor);
    },
  };
}
