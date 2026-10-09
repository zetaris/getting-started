(() => {
  const system = window.matchMedia('(prefers-color-scheme: dark)');
  let preference = 'system';
  try {
    const saved = localStorage.getItem('zetaris-colour-theme');
    if (['light', 'dark', 'system'].includes(saved)) preference = saved;
  } catch { /* Use the system preference when storage is unavailable. */ }
  const apply = () => {
    document.documentElement.dataset.theme = preference === 'system'
      ? (system.matches ? 'dark' : 'light') : preference;
    const button = document.getElementById('theme-toggle');
    if (button) {
      const label = document.documentElement.dataset.theme === 'dark'
        ? 'Switch to light mode' : 'Switch to dark mode';
      button.setAttribute('aria-label', label);
      button.title = label;
    }
  };
  apply();
  system.addEventListener('change', () => { if (preference === 'system') apply(); });
  document.addEventListener('DOMContentLoaded', () => {
    apply();
    document.getElementById('theme-toggle').addEventListener('click', () => {
      preference = document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark';
      apply();
      try { localStorage.setItem('zetaris-colour-theme', preference); } catch { /* The current page still updates. */ }
    });
  });
})();
