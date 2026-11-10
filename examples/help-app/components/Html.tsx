/** Raw HTML. Only ever pass the output of core/markdown.ts renderMarkdown(), which escapes raw
 * HTML and drops unsafe link schemes. This is the one place the app sets innerHTML. */
export function Html(
  { html, class: cls = "md", testid }: {
    html: string;
    class?: string;
    testid?: string;
  },
) {
  return (
    <div
      class={cls}
      data-testid={testid}
      // deno-lint-ignore react-no-danger
      dangerouslySetInnerHTML={{ __html: html }}
    />
  );
}
