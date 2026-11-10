export function StatusBadge(
  { ok, labels = ["OK", "Problem"] }: {
    ok: boolean;
    labels?: [string, string];
  },
) {
  return (
    <span class={`pill ${ok ? "good" : "bad"}`}>
      {ok ? labels[0] : labels[1]}
    </span>
  );
}
