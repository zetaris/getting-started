document.querySelectorAll('.assistant-launcher').forEach(panel => {
  const prompts = JSON.parse(panel.dataset.prompts);
  const code = panel.querySelector('.starter-prompt code');
  panel.querySelector('#prompt-protocol').addEventListener('change', event => {
    const prompt = prompts[event.target.value];
    code.textContent = prompt;
    const encoded = encodeURIComponent(prompt);
    panel.querySelector('[data-assistant="codex"]').href = `codex://threads/new?prompt=${encoded}`;
    panel.querySelector('[data-assistant="cursor"]').href = `cursor://anysphere.cursor-deeplink/prompt?text=${encoded}`;
    panel.querySelector('[data-assistant="claude"]').href = `claude://code/new?q=${encoded}`;
  });
});

document.querySelectorAll('pre').forEach(pre => {
  const code = pre.querySelector('code');
  if (!code) return;
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'copy-button';
  button.textContent = 'Copy';
  button.setAttribute('aria-label', 'Copy code to clipboard');
  button.addEventListener('click', async () => {
    try {
      await navigator.clipboard.writeText(code.textContent);
      button.textContent = 'Copied';
    } catch {
      const range = document.createRange();
      range.selectNodeContents(code);
      const selection = window.getSelection();
      selection.removeAllRanges();
      selection.addRange(range);
      button.textContent = 'Select and copy';
    }
    setTimeout(() => { button.textContent = 'Copy'; }, 2200);
  });
  pre.append(button);
});
