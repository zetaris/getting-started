// Serves the built app (run `deno task build` first). Binds to 127.0.0.1 because there is no
// login; set HELP_HOST to change it, HELP_PORT for the port.
import "../../../scripts/load_env.ts";

const hostname = Deno.env.get("HELP_HOST") ?? "127.0.0.1";
const port = Number(Deno.env.get("HELP_PORT") ?? "8000");

let server: { fetch: (req: Request) => Response | Promise<Response> };
try {
  server = (await import("../_fresh/server.js")).default;
} catch {
  console.error("No build found. Run `deno task build` first.");
  Deno.exit(1);
}
if (hostname !== "127.0.0.1" && hostname !== "localhost") {
  console.warn(
    `Listening on ${hostname}: the app has no login, so anyone who can reach it can use your Zetaris and LLM.`,
  );
}
Deno.serve({ hostname, port }, server.fetch);
