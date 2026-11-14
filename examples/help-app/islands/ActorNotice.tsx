import { useSignal } from "@preact/signals";
import { useEffect } from "preact/hooks";

const KEY = "help_actor";

function seen(): boolean {
  return /(?:^|; )help_actor_seen=/.test(document.cookie);
}

/** The one-time notice, then a restore of the person id if the cookie was cleared. */
export default function ActorNotice() {
  const open = useSignal(false);

  useEffect(() => {
    if (!seen()) {
      open.value = true;
      return;
    }
    const id = readId();
    void fetch("/api/actor", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(id ? { id } : {}),
    }).then((res) => res.json()).then((body) => {
      if (typeof body?.id === "string") writeId(body.id);
    }).catch(() => {});
  }, []);

  async function cont() {
    const res = await fetch("/api/actor", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: "{}",
    });
    const body = await res.json().catch(() => null);
    if (typeof body?.id === "string") writeId(body.id);
    open.value = false;
  }

  if (!open.value) return null;
  return (
    <div class="actor-notice" role="region" aria-label="Browser id">
      <p>
        This app stores a random id in a cookie on this browser so repeat pin
        actions, searches, and examples can be tied together. It is not a name.
        Clearing cookies starts a new id.
      </p>
      <button
        type="button"
        class="btn"
        data-testid="actor-continue"
        onClick={cont}
      >
        Continue
      </button>
    </div>
  );
}

function readId(): string {
  try {
    return localStorage.getItem(KEY) ?? "";
  } catch {
    return "";
  }
}

function writeId(id: string) {
  try {
    localStorage.setItem(KEY, id);
  } catch { /* storage blocked */ }
}
