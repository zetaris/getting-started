import "./load_env.ts";
import postgres from "postgres";

async function main(): Promise<void> {
  const host = Deno.env.get("PGHOST");
  const database = Deno.env.get("PGDATABASE");
  const username = Deno.env.get("PGUSER");
  const password = Deno.env.get("PGPASSWORD");
  if (!host || !database || !username || !password) {
    throw new Error("Set PGHOST, PGDATABASE, PGUSER, and PGPASSWORD in .env.local.");
  }

  const port = Number(Deno.env.get("PGPORT") ?? "5432");
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error("PGPORT must be an integer between 1 and 65535.");
  }
  const sslmode = Deno.env.get("PGSSLMODE") ?? "disable";
  if (sslmode !== "disable" && sslmode !== "verify-full") {
    throw new Error("PGSSLMODE must be disable or verify-full.");
  }

  const sql = postgres({
    host,
    port,
    database,
    username,
    password,
    ssl: sslmode === "verify-full" ? "verify-full" : false,
    max: 1,
    connect_timeout: 10,
    fetch_types: false,
    connection: { statement_timeout: 10000 },
  });
  const started = performance.now();
  try {
    const rows = await sql`SELECT 1 AS ping`;
    if (rows[0]?.ping !== 1) {
      throw new Error("Unexpected response to SELECT 1.");
    }
    console.log(
      `PostgreSQL connection OK (${
        Math.round(performance.now() - started)
      } ms).`,
    );
  } finally {
    await sql.end({ timeout: 1 });
  }
}

main().catch((error: unknown) => {
  const password = Deno.env.get("PGPASSWORD");
  const message = error instanceof Error
    ? error.message
    : "Unknown connection error";
  console.error(
    `PostgreSQL ping failed: ${
      password ? message.replaceAll(password, "[redacted]") : message
    }`,
  );
  Deno.exit(1);
});
