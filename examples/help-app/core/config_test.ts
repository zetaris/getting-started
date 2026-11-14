import { assertEquals } from "@std/assert";
import { candidatesEnabled } from "./config.ts";

function withFlag(value: string | undefined, check: () => void) {
  const previous = Deno.env.get("HELP_CANDIDATES");
  try {
    if (value === undefined) Deno.env.delete("HELP_CANDIDATES");
    else Deno.env.set("HELP_CANDIDATES", value);
    check();
  } finally {
    if (previous === undefined) Deno.env.delete("HELP_CANDIDATES");
    else Deno.env.set("HELP_CANDIDATES", previous);
  }
}

Deno.test("candidates are off unless HELP_CANDIDATES is 1", () => {
  withFlag(undefined, () => assertEquals(candidatesEnabled(), false));
  withFlag("0", () => assertEquals(candidatesEnabled(), false));
  withFlag("true", () => assertEquals(candidatesEnabled(), false));
  withFlag("1", () => assertEquals(candidatesEnabled(), true));
});
