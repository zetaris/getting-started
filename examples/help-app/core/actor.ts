// Anonymous ids for people and agents. A person id is a first-party cookie set only after the
// notice. An agent sends its own id. Neither is a name, and a value that is not one of these
// two shapes is stored as anonymous.

const HEX16 = /^[0-9a-f]{16}$/;
const TOKEN = /^(person|agent):([0-9a-f]{16})$/;
const YEAR = 60 * 60 * 24 * 365;

export type ActorKind = "person" | "agent";

export function actorToken(kind: ActorKind, id: string): string {
  if (!HEX16.test(id)) throw new Error("bad actor id");
  return `${kind}:${id}`;
}

/** Accept only `person:` or `agent:` plus 16 hex digits. */
export function parseActor(
  raw: string,
): { kind: ActorKind; id: string } | null {
  const m = TOKEN.exec(raw.trim());
  if (!m) return null;
  return { kind: m[1] as ActorKind, id: m[2] };
}

/** `person a1b2c3d4`. A legacy name or `anonymous` is returned unchanged. */
export function actorLabel(raw: string): string {
  const a = parseActor(raw);
  return a ? `${a.kind} ${a.id.slice(0, 8)}` : (raw || "anonymous");
}

export function mintPerson(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(8));
  const id = [...bytes].map((b) => b.toString(16).padStart(2, "0")).join("");
  return actorToken("person", id);
}

export function readCookie(header: string | null, name: string): string | null {
  if (!header) return null;
  const m = header.match(new RegExp(`(?:^|; )${name}=([^;]*)`));
  return m ? decodeURIComponent(m[1]) : null;
}

/** The person cookie, when it is a valid person token. An agent token in that cookie is ignored. */
export function personFromCookie(header: string | null): string | null {
  const a = parseActor(readCookie(header, "help_actor") ?? "");
  return a?.kind === "person" ? actorToken("person", a.id) : null;
}

export function actorCookie(token: string): string {
  return `help_actor=${token}; Path=/; HttpOnly; SameSite=Lax; Max-Age=${YEAR}`;
}

export function seenCookie(): string {
  return `help_actor_seen=1; Path=/; SameSite=Lax; Max-Age=${YEAR}`;
}

/** Who a write is stored as. A valid agent header wins and is not written into the person cookie.
 * Anything else uses the person cookie, or `anonymous`. */
export function resolveActor(headers: Headers): string {
  const agent = parseActor(headers.get("x-help-actor") ?? "");
  if (agent?.kind === "agent") return actorToken("agent", agent.id);
  return personFromCookie(headers.get("cookie")) ?? "anonymous";
}

/** Decide the person id a POST /api/actor stores. A valid person cookie is kept. A posted person
 * id is restored only after the notice cookie is already set. Otherwise a new id is minted,
 * which is also what Continue does. */
export function actorDecision(
  headers: Headers,
  postedId: unknown,
): { id: string; cookies: string[] } {
  const existing = personFromCookie(headers.get("cookie"));
  const id = existing ??
    (readCookie(headers.get("cookie"), "help_actor_seen")
      ? restored(postedId)
      : null) ??
    mintPerson();
  return { id, cookies: [actorCookie(id), seenCookie()] };
}

function restored(postedId: unknown): string | null {
  if (typeof postedId !== "string") return null;
  const a = parseActor(postedId);
  return a?.kind === "person" ? actorToken("person", a.id) : null;
}
