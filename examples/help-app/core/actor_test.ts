import { assert, assertEquals } from "@std/assert";
import {
  actorDecision,
  actorLabel,
  actorToken,
  parseActor,
  resolveActor,
} from "./actor.ts";

const PERSON = actorToken("person", "a1b2c3d4e5f67890");
const AGENT = actorToken("agent", "0123456789abcdef");

Deno.test("actor tokens accept only person or agent plus 16 hex", () => {
  assertEquals(parseActor(PERSON), { kind: "person", id: "a1b2c3d4e5f67890" });
  assertEquals(parseActor(AGENT)?.kind, "agent");
  assertEquals(parseActor("person:abc"), null);
  assertEquals(parseActor("user:a1b2c3d4e5f67890"), null);
  assertEquals(parseActor("Ann"), null);
  assertEquals(actorLabel(PERSON), "person a1b2c3d4");
  assertEquals(actorLabel("Ann"), "Ann");
});

Deno.test("a bad agent header is not stored", () => {
  const headers = new Headers({
    "x-help-actor": "agent:not-hex",
    "cookie": `help_actor=${PERSON}`,
  });
  assertEquals(resolveActor(headers), PERSON);
  assertEquals(
    resolveActor(new Headers({ "x-help-actor": AGENT })),
    AGENT,
  );
  assertEquals(resolveActor(new Headers()), "anonymous");
});

Deno.test("the person id is minted only after the notice, and a posted id restores", () => {
  const first = actorDecision(new Headers(), undefined);
  assert(parseActor(first.id)?.kind === "person");
  assert(first.cookies.some((c) => c.startsWith("help_actor=")));
  assert(first.cookies.some((c) => c.startsWith("help_actor_seen=")));

  const posted = actorToken("person", "fedcba9876543210");
  const early = actorDecision(
    new Headers(),
    posted,
  );
  assert(early.id !== posted);

  const restored = actorDecision(
    new Headers({ cookie: "help_actor_seen=1" }),
    posted,
  );
  assertEquals(restored.id, posted);

  const kept = actorDecision(
    new Headers({ cookie: `help_actor=${PERSON}` }),
    posted,
  );
  assertEquals(kept.id, PERSON);
});
