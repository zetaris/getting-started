/** One page of a list already in memory. `page` is 1-based and clamped. */
export function pageWindow<T>(
  items: readonly T[],
  page: number,
  size = 10,
): { current: number; pages: number; start: number; end: number; items: T[] } {
  const pages = Math.max(1, Math.ceil(items.length / size));
  const current = Number.isFinite(page)
    ? Math.min(pages, Math.max(1, Math.trunc(page)))
    : 1;
  const start = (current - 1) * size;
  const slice = items.slice(start, start + size);
  return { current, pages, start, end: start + slice.length, items: slice };
}
