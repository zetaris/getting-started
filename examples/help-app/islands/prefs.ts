// Per-browser preferences. Storage can be blocked, so every access is guarded.
const LIKED = "help_liked";

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
    body: JSON.stringify({ pinId, kind }),
  });
  const body = await res.json().catch(() => null);
  if (!res.ok || body?.error) {
    throw new Error(body?.error?.message ?? `HTTP ${res.status}`);
  }
  return body as { likes: number; uses: number };
}
