import { define } from "../utils.ts";
import { TopBar } from "../components/TopBar.tsx";
import AskBox from "../islands/AskBox.tsx";
import { EXAMPLES } from "../core/examples.ts";
import { getConfig } from "../core/server.ts";

export default define.page(function Home() {
  const cfg = getConfig();
  const llm = Boolean(cfg.ollamaUrl && cfg.ollamaModel);
  return (
    <>
      <TopBar path="/" />
      <main id="main">
        <h1>Ask the Zetaris docs</h1>
        <p class="lead">
          Searches this repository's docs and SQL scripts, and the Zetaris
          Knowledge base, through Zetaris pipelines.
        </p>
        <AskBox llmConfigured={llm} examples={EXAMPLES} />
      </main>
    </>
  );
});
