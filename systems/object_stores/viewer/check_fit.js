/* Layout check for the viewer. Paste this whole file into the browser console on
   the rendered page, or run it through any browser driver. It returns a promise
   that resolves to a report; `ok` is true only when nothing overflows or collides.

   For every SVG label it checks that the text stays inside the smallest box that
   holds it, that no two labels overlap, and that no connector line crosses a
   label. For HTML it checks that no box clips its own content and that the page
   does not scroll sideways. It opens each tab in turn, because a hidden tab has
   no layout, and puts the original tab back at the end.

       await checkViewerFit()   // -> { ok, tabs: [...], problems: [...] }
*/
async function checkViewerFit() {
  const tabs = [...document.querySelectorAll('.tab')];
  const original = tabs.find(t => t.getAttribute('aria-selected') === 'true');
  const problems = [], seen = [];
  const R = el => el.getBoundingClientRect();
  const inside = (a, b, tol) => a.left >= b.left - tol && a.right <= b.right + tol && a.top >= b.top - tol && a.bottom <= b.bottom + tol;
  const hit = (a, b) => a.left < b.right && a.right > b.left && a.top < b.bottom && a.bottom > b.top;

  for (const tab of tabs) {
    tab.click();
    await new Promise(r => setTimeout(r, 60));
    const name = tab.id.replace('tab-', '');
    const panel = document.getElementById(tab.getAttribute('aria-controls'));
    seen.push(name);

    for (const svg of panel.querySelectorAll('svg')) {
      const sid = (svg.querySelector('title') || {}).textContent || name + ' svg';
      const sbox = R(svg);
      const boxes = [...svg.querySelectorAll('rect')].filter(r => !r.classList.contains('lane') && R(r).width > 0)
        .map(r => ({ r, b: R(r) })).sort((x, y) => x.b.width * x.b.height - y.b.width * y.b.height);
      const texts = [...svg.querySelectorAll('text')].filter(t => t.textContent.trim());
      const tb = texts.map(t => ({ t, b: R(t) }));

      for (const { t, b } of tb) {
        const label = t.textContent.trim().slice(0, 40);
        const probe = { left: b.left + 1, right: b.left + 2, top: b.top + b.height / 2 - 1, bottom: b.top + b.height / 2 + 1 };
        const home = boxes.find(x => inside(probe, x.b, 0));
        if (home && !inside(b, home.b, 1.5)) problems.push(`${sid}: "${label}" runs outside its box`);
        if (!inside(b, sbox, 1)) problems.push(`${sid}: "${label}" is clipped by the diagram edge`);
      }
      for (let i = 0; i < tb.length; i++) for (let j = i + 1; j < tb.length; j++) {
        const a = tb[i].b, c = tb[j].b;
        const s = (q) => ({ left: q.left + 1, right: q.right - 1, top: q.top + 2, bottom: q.bottom - 2 });
        if (hit(s(a), s(c))) problems.push(`${sid}: "${tb[i].t.textContent.trim().slice(0, 30)}" overlaps "${tb[j].t.textContent.trim().slice(0, 30)}"`);
      }
      for (const ln of svg.querySelectorAll('line.flow, path.flow, line.fk-line, path.fk-line')) {
        const m = ln.getScreenCTM(); if (!m) continue;
        const pts = [];
        if (ln.tagName === 'line') {
          for (let k = 0; k <= 40; k++) { const f = k / 40; pts.push([+ln.getAttribute('x1') + f * (ln.getAttribute('x2') - ln.getAttribute('x1')), +ln.getAttribute('y1') + f * (ln.getAttribute('y2') - ln.getAttribute('y1'))]); }
        } else {
          const L = ln.getTotalLength(); for (let d = 0; d <= L; d += 3) { const p = ln.getPointAtLength(d); pts.push([p.x, p.y]); }
        }
        for (const { t, b } of tb) {
          const inner = { left: b.left + 1, right: b.right - 1, top: b.top + 3, bottom: b.bottom - 3 };
          if (pts.some(([x, y]) => { const px = m.a * x + m.c * y + m.e, py = m.b * x + m.d * y + m.f; return px > inner.left && px < inner.right && py > inner.top && py < inner.bottom; }))
            problems.push(`${sid}: a connector crosses "${t.textContent.trim().slice(0, 30)}"`);
        }
      }
    }

    for (const el of panel.querySelectorAll('*')) {
      if (el.closest('svg, pre, .tbl-wrap, .diagram, .res-wrap, textarea, select')) continue;
      const cs = getComputedStyle(el);
      if (cs.display === 'inline' || cs.overflowX !== 'visible') continue;
      if (el.scrollWidth > el.clientWidth + 1 && el.clientWidth > 0)
        problems.push(`${name}: <${el.tagName.toLowerCase()} class="${el.className}"> content is wider than its box ("${el.textContent.trim().slice(0, 30)}")`);
    }
  }
  if (document.documentElement.scrollWidth > window.innerWidth + 1) problems.push(`page scrolls sideways (${document.documentElement.scrollWidth}px > ${window.innerWidth}px)`);
  if (original) original.click();
  const font = document.fonts.check('16px "Plus Jakarta Sans"');
  if (!font) problems.push('Plus Jakarta Sans did not load');
  return { ok: problems.length === 0, tabs: seen, viewport: window.innerWidth, problems };
}
