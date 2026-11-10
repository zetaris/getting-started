import { define } from "../utils.ts";

// Applies a stored theme before first paint so a reload does not flash the wrong one.
const THEME_SCRIPT =
  `try{var t=localStorage.getItem("help_theme");if(t==="light"||t==="dark")document.documentElement.dataset.theme=t}catch(e){}`;

// A fixed string with no user input, so setting it as raw HTML is safe.
const themeScript = (
  <script
    // deno-lint-ignore react-no-danger
    dangerouslySetInnerHTML={{ __html: THEME_SCRIPT }}
  />
);

export default define.page(function App({ Component }) {
  return (
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>Zetaris help</title>
        {themeScript}
      </head>
      <body>
        <a class="skip" href="#main">Skip to content</a>
        <Component />
      </body>
    </html>
  );
});
