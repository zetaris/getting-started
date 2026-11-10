import { page } from "fresh";
import { HttpError } from "fresh";
import { define } from "../../utils.ts";
import { DocsShell } from "../../components/DocsShell.tsx";
import { DocView } from "../../components/DocView.tsx";
import { docChunks, docHref, listDocs, openDoc } from "../../core/docs.ts";
import { toAskError } from "../../core/ask.ts";
import { docIo, getZetaris } from "../../core/server.ts";

export const handler = define.handlers({
  async GET(ctx) {
    const z = getZetaris(30_000);
    if (!z) {
      throw new HttpError(
        503,
        "Zetaris is not configured: set ZETARIS_API_KEY in .env.local.",
      );
    }
    try {
      const doc = await openDoc(z, docIo, "repo", ctx.params.path);
      if (!doc) throw new HttpError(404, "That file is not in the index.");
      return page({
        doc,
        chunks: await docChunks(z, doc.row.path),
        rows: await listDocs(z),
      });
    } catch (e) {
      if (e instanceof HttpError) throw e;
      throw new HttpError(502, toAskError(e).message);
    }
  },
});

export default define.page<typeof handler>(function Doc({ data }) {
  return (
    <DocsShell rows={data.rows} current={docHref(data.doc.row.path)}>
      <DocView doc={data.doc} chunks={data.chunks} />
    </DocsShell>
  );
});
