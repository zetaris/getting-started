// Per-browser preferences. Storage can be blocked, so every access is guarded.
const NAME = "help_name";
const LIKED = "help_liked";

export function getName(): string {
  try {
    return localStorage.getItem(NAME) ?? "";
  } catch {
    return "";
  }
}

export function setName(v: string) {
  try {
    localStorage.setItem(NAME, v.slice(0, 100));
  } catch { /* ignore */ }
}

export function likedSet(): Set<string> {
  try {
    return new Set(JSON.parse(localStorage.getItem(LIKED) ?? "[]"));
  } catch {
    return new Set();
  }
}

export function saveLiked(s: Set<string>) {
  try {
    localStorage.setItem(LIKED, JSON.stringify([...s]));
  } catch { /* ignore */ }
}

export async function postEvent(
  pinId: string,
  kind: "like" | "unlike" | "use",
) {
  const res = await fetch("/api/pin-event", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ pinId, kind, who: getName() }),
  });
  const body = await res.json().catch(() => null);
  if (!res.ok || body?.error) {
    throw new Error(body?.error?.message ?? `HTTP ${res.status}`);
  }
  return body as { likes: number; uses: number };
}
