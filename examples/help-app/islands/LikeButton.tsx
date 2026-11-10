import { useSignal } from "@preact/signals";
import { useEffect } from "preact/hooks";
import { likedSet, postEvent, saveLiked } from "./prefs.ts";

/** Like or unlike a pinned answer. This browser remembers which pins it liked, so one browser
 * toggles its own like; the count comes from the event log. */
export default function LikeButton(
  { pinId, likes }: { pinId: string; likes: number },
) {
  const count = useSignal(likes);
  const liked = useSignal(false);
  const busy = useSignal(false);
  const error = useSignal("");
  useEffect(() => {
    liked.value = likedSet().has(pinId);
  }, []);
  async function click() {
    busy.value = true;
    error.value = "";
    try {
      const r = await postEvent(pinId, liked.value ? "unlike" : "like");
      const s = likedSet();
      if (liked.value) s.delete(pinId);
      else s.add(pinId);
      saveLiked(s);
      liked.value = !liked.value;
      count.value = r.likes;
    } catch (e) {
      error.value = (e as Error).message;
    } finally {
      busy.value = false;
    }
  }
  return (
    <span class="like">
      <button
        type="button"
        class="btn ghost"
        disabled={busy.value}
        aria-pressed={liked.value}
        data-testid="like"
        onClick={click}
      >
        {liked.value ? "Liked" : "Like"} ·{" "}
        <span data-testid="likes">{count.value}</span>
      </button>
      {error.value && (
        <span class="lead" role="alert" style="margin-left:8px">
          {error.value}
        </span>
      )}
    </span>
  );
}
