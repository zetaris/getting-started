import { define } from "../utils.ts";
import { TopBar } from "../components/TopBar.tsx";
import AskBox from "../islands/AskBox.tsx";
import { getConfig } from "../core/server.ts";

export default define.page(function Home() {
  const cfg = getConfig();
  const llm = Boolean(cfg.ollamaUrl && cfg.ollamaModel);
  return (
    <>
      <TopBar path="/" />
      <main id="main">
        <h1 class="sr-only">Search the Zetaris docs</h1>
        <AskBox llmConfigured={llm} model={cfg.ollamaModel} />
      </main>
    </>
  );
});
