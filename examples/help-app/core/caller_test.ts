import { assertEquals } from "@std/assert";
import { actorToken } from "./actor.ts";
import { caller } from "./caller.ts";

const AGENT = actorToken("agent", "0123456789abcdef");
const PERSON = actorToken("person", "a1b2c3d4e5f67890");

Deno.test("caller uses a valid agent header and otherwise stays anonymous", () => {
  assertEquals(caller(new Headers({ "x-help-actor": AGENT })), AGENT);
  assertEquals(
    caller(new Headers({ "x-help-actor": "agent:not-hex" })),
    "anonymous",
  );
  assertEquals(
    caller(new Headers({ "cookie": `help_actor=${PERSON}` })),
    PERSON,
  );
  assertEquals(caller(new Headers()), "anonymous");
});
