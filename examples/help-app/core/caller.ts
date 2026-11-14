// Who an MCP tool call is stored as. This reads the existing actor header, not a
// credential: there is no token check here. A later authentication change
// replaces this function; the tools keep calling it and can be rejected first.
import { resolveActor } from "./actor.ts";

/** A valid `X-Help-Actor` (`agent:` plus 16 hex digits), else the person cookie, else `anonymous`. */
export function caller(headers: Headers): string {
  return resolveActor(headers);
}
