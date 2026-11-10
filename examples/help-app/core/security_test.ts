import { assert, assertEquals } from "@std/assert";
import { cleanText, sameOrigin } from "./security.ts";

const req = (headers: Record<string, string>) =>
  new Request("http://127.0.0.1:8000/api/pins", { method: "POST", headers });

Deno.test("same-origin requests and requests with no Origin pass; cross-site ones do not", () => {
  assert(sameOrigin(req({ host: "127.0.0.1:8000" })));
  assert(
    sameOrigin(
      req({ origin: "http://127.0.0.1:8000", host: "127.0.0.1:8000" }),
    ),
  );
  assert(
    !sameOrigin(
      req({ origin: "https://evil.example", host: "127.0.0.1:8000" }),
    ),
  );
  assert(
    !sameOrigin(
      req({ origin: "http://127.0.0.1:9999", host: "127.0.0.1:8000" }),
    ),
  );
  assert(!sameOrigin(req({ origin: "not a url", host: "127.0.0.1:8000" })));
});

Deno.test("cleanText caps length, drops control characters, ignores non-strings", () => {
  assertEquals(cleanText("  a\u0000b  ", 10), "a b");
  assertEquals(cleanText("x".repeat(50), 5), "xxxxx");
  assertEquals(cleanText(5, 5), "");
});
