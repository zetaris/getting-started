// Loads .env.local into the process environment as a side effect of importing
// this module, so import it first. Looks in the repository root, then, when
// this checkout is a git worktree, in the top-level checkout, because a
// gitignored file does not exist in a worktree. Variables already set in the
// environment win. .env.local is the only supported file name.
//
// Needs --allow-read. Setting a variable outside the script's --allow-env list
// is skipped, not an error.

const root = new URL("..", import.meta.url).pathname.replace(/\/$/, "");

function topLevelCheckout(): string | null {
  try {
    const text = Deno.readTextFileSync(`${root}/.git`);
    const match = text.match(/^gitdir:\s*(.+)$/m);
    if (!match) return null;
    const gitdir = match[1].trim().startsWith("/")
      ? match[1].trim()
      : `${root}/${match[1].trim()}`;
    // <top>/.git/worktrees/<name> -> <top>
    return gitdir.replace(/\/\.git\/worktrees\/[^/]+\/?$/, "");
  } catch {
    return null; // a normal checkout has a .git directory, not a file
  }
}

export function envFileCandidates(): string[] {
  const dirs = [root];
  const top = topLevelCheckout();
  if (top && top !== root) dirs.push(top);
  return dirs.map((d) => `${d}/.env.local`);
}

function load(): string | null {
  for (const path of envFileCandidates()) {
    let text: string;
    try {
      text = Deno.readTextFileSync(path);
    } catch {
      continue;
    }
    for (const raw of text.split("\n")) {
      const line = raw.trim();
      if (!line || line.startsWith("#") || !line.includes("=")) continue;
      const i = line.indexOf("=");
      const key = line.slice(0, i).trim();
      let value = line.slice(i + 1).trim();
      if (
        value.length >= 2 && value[0] === value[value.length - 1] &&
        (value[0] === '"' || value[0] === "'")
      ) value = value.slice(1, -1);
      try {
        if (Deno.env.get(key) === undefined) Deno.env.set(key, value);
      } catch {
        // not permitted by --allow-env; the script does not need this variable
      }
    }
    return path;
  }
  return null;
}

export const envFile = load();
