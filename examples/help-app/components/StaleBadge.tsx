import type { Stale } from "../core/pins.ts";

export function StaleBadge({ stale }: { stale: Stale }) {
  if (stale.state === "current") return null;
  const text = stale.state === "missing"
    ? "A cited file is gone"
    : "A cited file has changed";
  return (
    <span class="pill warn" title={stale.files.join(", ")} data-testid="stale">
      {text}: re-check this answer
    </span>
  );
}
