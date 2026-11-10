import ThemeToggle from "../islands/ThemeToggle.tsx";

export function TopBar({ path }: { path: string }) {
  const item = (href: string, label: string) => (
    <a href={href} aria-current={path === href ? "page" : undefined}>{label}</a>
  );
  return (
    <header class="topbar">
      <a class="brand" href="/">
        Zetaris <span>help</span>
      </a>
      <nav class="nav" aria-label="Main">
        {item("/", "Ask")}
        {item("/admin", "Status")}
      </nav>
      <ThemeToggle />
    </header>
  );
}
