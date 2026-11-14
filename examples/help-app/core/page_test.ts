import { assertEquals } from "@std/assert";
import { pageWindow } from "./page.ts";

Deno.test("pages of ten, clamped to the list", () => {
  const items = Array.from({ length: 25 }, (_, i) => i + 1);
  const first = pageWindow(items, 1);
  assertEquals(first.current, 1);
  assertEquals(first.pages, 3);
  assertEquals(first.items, items.slice(0, 10));
  assertEquals(first.start, 0);
  assertEquals(first.end, 10);
  const last = pageWindow(items, 9);
  assertEquals(last.current, 3);
  assertEquals(last.items, [21, 22, 23, 24, 25]);
  assertEquals(pageWindow([], 1).items, []);
  assertEquals(pageWindow(items, Number.NaN).current, 1);
});
