import { candidatesEnabled } from "../core/config.ts";
import ActorNotice from "../islands/ActorNotice.tsx";
import ThemeToggle from "../islands/ThemeToggle.tsx";

export function TopBar({ path }: { path: string }) {
  const item = (href: string, label: string) => (
    <a
      href={href}
      aria-current={path === href || (href !== "/" && path.startsWith(href))
        ? "page"
        : undefined}
    >
      {label}
    </a>
  );
  return (
    <>
      <ActorNotice />
      <header class="topbar">
        <a class="brand" href="/">
          Zetaris <span>help</span>
        </a>
        <nav class="nav" aria-label="Main">
          {item("/", "Search")}
          {item("/docs", "Docs")}
          {item("/pins", "Pinned")}
          {candidatesEnabled() && item("/candidates", "Candidates")}
          {item("/admin", "Status")}
        </nav>
        <div class="topbar-end">
          <ThemeToggle />
        </div>
      </header>
    </>
  );
}
