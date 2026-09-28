const baseUrl = (Deno.env.get("ZETARIS_BASE_URL") ?? "http://localhost:3000")
  .replace(/\/$/, "");
const orgId = Deno.env.get("ZETARIS_ORG_ID");

if (!orgId || !/^\d+$/.test(orgId)) {
  throw new Error("Set ZETARIS_ORG_ID to the numeric organization ID.");
}
if (!/^https?:\/\/[^/]+$/.test(baseUrl)) {
  throw new Error("ZETARIS_BASE_URL must be an HTTP(S) origin without a path.");
}

async function request(
  path: string,
  token: string,
  method = "GET",
  body?: unknown,
): Promise<unknown> {
  let response: Response;
  try {
    response = await fetch(`${baseUrl}${path}`, {
      method,
      headers: {
        Authorization: `Bearer ${token}`,
        "X-Org-ID": orgId!,
        "X-Request-ID": crypto.randomUUID(),
        ...(body === undefined ? {} : { "Content-Type": "application/json" }),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
      signal: AbortSignal.timeout(30_000),
    });
  } catch (error) {
    throw new Error(
      `Cannot reach ${baseUrl}: ${
        error instanceof Error ? error.message : error
      }`,
    );
  }
  if (!response.ok) {
    const detail = response.headers.get("content-type")?.includes("text/html")
      ? "The server returned an HTML page; check the API route."
      : (await response.text()).slice(0, 500);
    throw new Error(
      `${method} ${path} failed: HTTP ${response.status} ${detail}`,
    );
  }
  return response.status === 204 ? null : await response.json();
}

export async function zetarisRequest(
  path: string,
  method = "GET",
  body?: unknown,
): Promise<unknown> {
  let token = Deno.env.get("ZETARIS_API_TOKEN");
  if (!token) {
    const username = Deno.env.get("ZETARIS_USERNAME");
    const password = Deno.env.get("ZETARIS_PASSWORD");
    if (!username || !password) {
      throw new Error(
        "Set ZETARIS_API_TOKEN or both ZETARIS_USERNAME and ZETARIS_PASSWORD.",
      );
    }
    let response: Response;
    try {
      response = await fetch(`${baseUrl}/api/auth/login`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Request-ID": crypto.randomUUID(),
        },
        body: JSON.stringify({ username, password }),
        signal: AbortSignal.timeout(30_000),
      });
    } catch (error) {
      throw new Error(
        `Cannot reach ${baseUrl}: ${
          error instanceof Error ? error.message : error
        }`,
      );
    }
    if (!response.ok) {
      throw new Error(`Zetaris login failed: HTTP ${response.status}`);
    }
    const login = await response.json();
    const idToken = login?.idToken ?? login?.token ?? login?.accessToken ??
      JSON.stringify(login).match(
        /[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}/,
      )?.[0];
    if (typeof idToken !== "string" || !idToken) {
      throw new Error("Zetaris login did not return an access token.");
    }
    token = idToken;
  }
  if (!token) throw new Error("Zetaris API token is empty.");
  return await request(path, token, method, body);
}
