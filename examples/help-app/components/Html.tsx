/** Raw HTML. Only ever pass renderMarkdown() or matchSnippet(), both of which escape the
 * source text. This is the one place the app sets innerHTML. */
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
