// One progress line for Search, Answer, and Example. Finished stages stay in a
// hover tooltip so the row above the search box does not grow.

export interface WorkStep {
  label: string;
  at: number;
}

function secs(t0: number, t1: number): string {
  const v = Math.max(0, (t1 - t0) / 1000);
  return `${v.toFixed(v < 10 ? 1 : 0)} s`;
}

export default function WorkStatus(
  { steps, now }: { steps: WorkStep[]; now: number },
) {
  const cur = steps[steps.length - 1];
  const before = steps.slice(0, -1);
  if (!cur) return null;
  return (
    <div
      class="work-status tiptip align-end"
      tabIndex={0}
      role="status"
      aria-live="polite"
      data-testid="status"
    >
      <div class="steps" data-testid="steps">
        <div class="step active">
          <span class="spinner" aria-hidden="true" />
          <span class="step-label">{cur.label}</span>
          <span class="step-time">{secs(steps[0].at, now)}</span>
        </div>
        {before.length > 0 && (
          <div class="tiptip-box" id="step-log" role="tooltip">
            <ol class="step-log">
              {before.map((st, i) => (
                <li
                  key={i}
                  class={/rejected|did not/i.test(st.label) ? "failed" : ""}
                >
                  <span class="tick" aria-hidden="true">
                    {/rejected|did not/i.test(st.label) ? "✗" : "✓"}
                  </span>
                  <span class="step-label">{st.label}</span>
                  <span class="step-time">
                    {secs(st.at, steps[i + 1].at)}
                  </span>
                </li>
              ))}
            </ol>
          </div>
        )}
      </div>
    </div>
  );
}
