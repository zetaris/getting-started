import { useSignal } from "@preact/signals";
import { useEffect } from "preact/hooks";

const KEY = "help_theme";

function current(): "light" | "dark" {
  const set = document.documentElement.dataset.theme;
  if (set === "light" || set === "dark") return set;
  return matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark";
}

/** Light/dark switch. Starts from the system setting; a click stores the choice in this browser only. */
export default function ThemeToggle() {
  const theme = useSignal<"light" | "dark">("dark");
  useEffect(() => {
    theme.value = current();
  }, []);
  function toggle() {
    const next = current() === "light" ? "dark" : "light";
    document.documentElement.dataset.theme = next;
    theme.value = next;
    try {
      localStorage.setItem(KEY, next);
    } catch { /* storage blocked: the choice lasts for this page only */ }
  }
  return (
    <button
      type="button"
      class="theme-toggle"
      onClick={toggle}
      aria-label={`Switch to ${
        theme.value === "light" ? "dark" : "light"
      } mode`}
      title="Switch between light and dark mode"
    >
      <span aria-hidden="true">{theme.value === "light" ? "☾" : "☀"}</span>
    </button>
  );
}
