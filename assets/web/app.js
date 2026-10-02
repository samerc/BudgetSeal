'use strict';
// BudgetSeal Web Companion — single-page app served by the phone.
// No inline handlers anywhere (the CSP forbids inline scripts): clicks are
// routed through data-action attributes, forms wire their own listeners.

(() => {

// ── i18n ──────────────────────────────────────────────────────────────────────

let STR = {};
let LOCALE = 'en';

/** Translated string with {param} substitution; the key itself when missing. */
function t(key, params) {
  let s = STR[key] ?? key;
  if (params) for (const [k, v] of Object.entries(params)) s = s.split(`{${k}}`).join(String(v));
  return s;
}

async function loadStrings(lang) {
  try {
    const r = await fetch(`/assets/locale_${lang}.json`);
    if (r.ok) STR = await r.json();
  } catch (_) { /* keep English fallbacks in the markup */ }
}

function applyI18n(root = document) {
  root.querySelectorAll('[data-i18n]').forEach(el => { el.textContent = t(el.dataset.i18n); });
  root.querySelectorAll('[data-i18n-label]').forEach(el => {
    el.setAttribute('aria-label', t(el.dataset.i18nLabel));
    el.title = t(el.dataset.i18nLabel);
  });
}

/** Intl locale: Western digits unless the phone uses Arabic-Indic ones. */
function intlLocale() {
  return LOCALE === 'ar' && !NUM.arabicDigits ? 'ar-u-nu-latn' : LOCALE;
}

// ── Config from the phone (language, accent, number format) ──────────────────

const NUM = {
  thousands: ',', decimal: '.', parens: false, arabicDigits: false,
  symbols: { USD: '$', EUR: '€', GBP: '£', JPY: '¥' },
};

async function loadConfig() {
  let cfg = null;
  try {
    const r = await fetch('/auth/config');
    if (r.ok) cfg = await r.json();
  } catch (_) { /* offline: defaults */ }
  LOCALE = cfg?.locale || 'en';
  document.documentElement.lang = LOCALE;
  document.documentElement.dir = LOCALE === 'ar' ? 'rtl' : 'ltr';
  if (cfg?.accent) {
    const s = document.documentElement.style;
    s.setProperty('--acc-deep', safeHex(cfg.accent.deep));
    s.setProperty('--acc-bright', safeHex(cfg.accent.bright));
    s.setProperty('--acc-lfill', safeHex(cfg.accent.lightFill));
    s.setProperty('--acc-dfill', safeHex(cfg.accent.darkFill));
  }
  if (cfg?.number) Object.assign(NUM, cfg.number);
  await loadStrings(LOCALE);
  applyI18n();
}

// ── Formatting (mirrors formatAmount() in the app) ───────────────────────────

const ZERO_DEC = new Set(['BIF', 'CLP', 'DJF', 'GNF', 'ISK', 'JPY', 'KMF', 'KRW', 'PYG', 'RWF', 'UGX', 'UYI', 'VND', 'VUV', 'XAF', 'XOF', 'XPF']);
const THREE_DEC = new Set(['BHD', 'IQD', 'JOD', 'KWD', 'LYD', 'OMR', 'TND']);
const SPACED = new Set(['ل.ل', 'د.إ', 'CHF', '﷼']);

function decimalsFor(cur) {
  const c = (cur || '').toUpperCase();
  return ZERO_DEC.has(c) ? 0 : THREE_DEC.has(c) ? 3 : 2;
}

function numStr(abs, d) {
  const [i, f] = abs.toFixed(d).split('.');
  let s = i.replace(/\B(?=(\d{3})+(?!\d))/g, NUM.thousands) + (f ? NUM.decimal + f : '');
  if (NUM.arabicDigits) s = s.replace(/[0-9]/g, x => '٠١٢٣٤٥٦٧٨٩'[x]);
  return s;
}
function wrapNeg(s, neg) { return !neg ? s : NUM.parens ? `(${s})` : `-${s}`; }
function needsSpace(sym) {
  return SPACED.has(sym) || (sym.length > 2 && !sym.startsWith('$') && !sym.startsWith('€'));
}

/**
 * "$1,234.50", "ل.ل -1,200,000", "(€5.00)" — the user's separators. The
 * result is a left-to-right isolate (LRI…PDI), with a mark after an Arabic
 * symbol, so the sign and digits never get reordered on an Arabic page or
 * next to an Arabic currency symbol.
 */
function fmt(value, cur) {
  const v = Number(value) || 0;
  const d = decimalsFor(cur);
  const neg = v < 0 && Math.abs(v) >= 0.5 * 10 ** -d;
  const s = numStr(Math.abs(v), d);
  let out;
  if (!cur) out = wrapNeg(s, neg);
  else {
    const sym = NUM.symbols?.[cur];
    const mark = sym && /[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]/.test(sym) ? '\u200E' : '';
    if (sym) out = needsSpace(sym) ? `${sym}${mark} ${wrapNeg(s, neg)}` : wrapNeg(sym + mark + s, neg);
    else out = `${cur} ${wrapNeg(s, neg)}`;
  }
  return `\u2066${out}\u2069`;
}

/** Signed by type: income "+$5", expense "-$5", transfer "$5". */
function fmtSigned(amount, cur, type) {
  const abs = Math.abs(Number(amount) || 0);
  if (type === 'expense') return fmt(-abs, cur);
  if (type === 'income') return `\u2066+${fmt(abs, cur)}\u2069`;
  return fmt(abs, cur);
}

function fmtPlain(v, d = 2) { return wrapNeg(numStr(Math.abs(v), d), v < 0); }

function toDate(iso) { return iso instanceof Date ? iso : new Date(iso); }

function fmtDate(iso, withYear) {
  const d = toDate(iso);
  if (isNaN(d)) return '';
  const now = new Date();
  return d.toLocaleDateString(intlLocale(), {
    day: 'numeric', month: 'short',
    year: withYear || d.getFullYear() !== now.getFullYear() ? 'numeric' : undefined,
  });
}

/** Day header: Today / Yesterday / "Monday 28 September". */
function fmtDay(iso) {
  const d = toDate(iso);
  const today = dayKey(new Date());
  const y = new Date(); y.setDate(y.getDate() - 1);
  if (dayKey(d) === today) return t('common_today');
  if (dayKey(d) === dayKey(y)) return t('common_yesterday');
  return d.toLocaleDateString(intlLocale(), {
    weekday: 'long', day: 'numeric', month: 'long',
    year: d.getFullYear() !== new Date().getFullYear() ? 'numeric' : undefined,
  });
}

/** Local calendar day "YYYY-MM-DD" (never UTC: toISOString shifts the day). */
function dayKey(d = new Date()) {
  d = toDate(d);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

function monthLabel(y, m) {
  return new Date(y, m, 1).toLocaleDateString(intlLocale(), { month: 'long', year: 'numeric' });
}
function monthShort(m) {
  return new Date(2024, m, 1).toLocaleDateString(intlLocale(), { month: 'short' });
}

function freqLabel(f, n) {
  n = Number(n) || 1;
  if (n === 1) return t(`freq_${f}`);
  const k = { daily: 'freq_every_n_days', weekly: 'freq_every_n_weeks', monthly: 'freq_every_n_months', yearly: 'freq_every_n_years' }[f];
  return k ? t(k, { n }) : f;
}

/** Monthly equivalent of a recurring amount (for subscription totals). */
function perMonth(r) {
  const n = Math.max(1, Number(r.interval) || 1);
  const a = Number(r.amount) || 0;
  return { daily: a * 30.44, weekly: a * 4.345, monthly: a, yearly: a / 12 }[r.frequency] / n || 0;
}

/** Parses "1,234.56", "1.234,56", "12,50" like parseLooseAmount() in the app. */
function parseAmount(s) {
  s = String(s ?? '').trim().replace(/\s/g, '').replace(/[٠-٩]/g, d => '٠١٢٣٤٥٦٧٨٩'.indexOf(d));
  if (!s) return NaN;
  const lastComma = s.lastIndexOf(','), lastDot = s.lastIndexOf('.');
  if (lastComma > -1 && lastDot > -1) {
    s = lastComma > lastDot ? s.replace(/\./g, '').replace(',', '.') : s.replace(/,/g, '');
  } else if (lastComma > -1) {
    const tail = s.length - lastComma - 1;
    s = (tail === 3 && s.indexOf(',') === lastComma && s.length > 4) ? s.replace(',', '') : s.replace(',', '.');
  }
  const v = Number(s);
  return Number.isFinite(v) ? v : NaN;
}

function amountInputValue(v, cur) {
  if (v == null || v === '') return '';
  return Number(v).toFixed(decimalsFor(cur)).replace(/\.?0+$/, m => (m.startsWith('.') ? '' : m)).replace('.', NUM.decimal);
}

// ── Escaping & colors ─────────────────────────────────────────────────────────

function esc(s) {
  return String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}
function safeHex(v) { return /^#[0-9A-Fa-f]{6}$/.test(v || '') ? v : /^#[0-9A-Fa-f]{3}$/.test(v || '') ? '#' + v.slice(1).split('').map(c => c + c).join('') : '#90A4AE'; }

function isDark() {
  const th = document.documentElement.dataset.theme;
  return th === 'dark' || (th !== 'light' && matchMedia('(prefers-color-scheme: dark)').matches);
}

function mix(hex, target, a) {
  const n = parseInt(safeHex(hex).slice(1), 16);
  const r = n >> 16, g = (n >> 8) & 255, b = n & 255;
  const m = c => Math.round(c * (1 - a) + target * a);
  return `rgb(${m(r)},${m(g)},${m(b)})`;
}
/** AppColors.pastel(): lighten in light mode, darken in dark mode. */
function pastel(hex, light = 0.55, dark = 0.35) { return isDark() ? mix(hex, 0, dark) : mix(hex, 255, light); }
/** Glyph color on a pastel fill (the inverse direction). */
function pastelInk(hex) { return isDark() ? mix(hex, 255, 0.5) : mix(hex, 0, 0.6); }

function isEmoji(s) { return !!s && s !== 'category' && [...s].length <= 3 && /[^\x00-\x7F]/.test(s); }

/** The app's category icon: its PNG, else the emoji, else the first letter. */
function catChip(c, cls = '') {
  if (!c || (!c.name && !c.categoryName)) {
    return `<span class="chip-icon ${cls}" style="background:var(--container);color:var(--text-2)">${IC.tag}</span>`;
  }
  const name = c.name ?? c.categoryName;
  const icon = c.icon ?? c.categoryIcon;
  const file = c.iconFile ?? c.categoryIconFile;
  const color = safeHex(c.colorHex ?? c.categoryColor);
  let inner;
  if (file) inner = `<img src="/icons/${encodeURIComponent(file)}" alt="" loading="lazy">`;
  else if (isEmoji(icon)) inner = esc(icon);
  else inner = `<span style="color:${pastelInk(color)}">${esc((name || '?').charAt(0).toUpperCase())}</span>`;
  return `<span class="chip-icon ${cls}" style="background:${pastel(color)}">${inner}</span>`;
}

function transferChip(cls = '') {
  return `<span class="chip-icon ${cls}" style="background:var(--accent-fill);color:var(--accent)">${IC.transfer}</span>`;
}

// ── Icons (inline SVG, stroke = currentColor) ────────────────────────────────

const svg = (p, w = 20) => `<svg width="${w}" height="${w}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${p}</svg>`;
const IC = {
  plus: svg('<path d="M12 5v14M5 12h14"/>'),
  edit: svg('<path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/>'),
  trash: svg('<path d="M3 6h18M8 6V4h8v2M19 6l-1 14H6L5 6"/>'),
  copy: svg('<rect width="13" height="13" x="9" y="9" rx="2"/><path d="M5 15H4a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h10a1 1 0 0 1 1 1v1"/>'),
  download: svg('<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><path d="m7 10 5 5 5-5"/><path d="M12 15V3"/>'),
  search: svg('<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>'),
  left: svg('<path d="m15 18-6-6 6-6"/>'),
  right: svg('<path d="m9 18 6-6-6-6"/>'),
  back: svg('<path d="M19 12H5M12 19l-7-7 7-7"/>'),
  transfer: svg('<path d="m16 3 4 4-4 4"/><path d="M20 7H4"/><path d="m8 21-4-4 4-4"/><path d="M4 17h16"/>'),
  tag: svg('<path d="M12 2H2v10l9.3 9.3a2.4 2.4 0 0 0 3.4 0l6.6-6.6a2.4 2.4 0 0 0 0-3.4Z"/><path d="M7 7h.01"/>'),
  check: svg('<path d="M20 6 9 17l-5-5"/>'),
  alert: svg('<circle cx="12" cy="12" r="10"/><path d="M12 8v4M12 16h.01"/>'),
  envelope: svg('<rect width="20" height="16" x="2" y="4" rx="3"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>'),
  wallet: svg('<path d="M19 7V4a1 1 0 0 0-1-1H5a2 2 0 0 0 0 4h15a1 1 0 0 1 1 1v4h-3a2 2 0 0 0 0 4h3a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1"/><path d="M3 5v14a2 2 0 0 0 2 2h15a1 1 0 0 0 1-1v-4"/>'),
  bank: svg('<path d="M3 21h18M3 10h18M5 6l7-3 7 3M4 10v11M20 10v11M8 14v3M12 14v3M16 14v3"/>'),
  cash: svg('<rect width="20" height="12" x="2" y="6" rx="2"/><circle cx="12" cy="12" r="2"/><path d="M6 12h.01M18 12h.01"/>'),
  card: svg('<rect width="20" height="14" x="2" y="5" rx="2"/><path d="M2 10h20"/>'),
  plane: svg('<path d="M17.8 19.2 16 11l3.5-3.5C21 6 21.5 4 21 3c-1-.5-3 0-4.5 1.5L13 8 4.8 6.2c-.5-.1-.9.1-1.1.5l-.3.5c-.2.5-.1 1 .3 1.3L9 12l-2 3H4l-1 1 3 2 2 3 1-1v-3l3-2 3.5 5.3c.3.4.8.5 1.3.3l.5-.2c.4-.3.6-.7.5-1.2z"/>'),
  repeat: svg('<path d="m17 2 4 4-4 4"/><path d="M3 11v-1a4 4 0 0 1 4-4h14"/><path d="m7 22-4-4 4-4"/><path d="M21 13v1a4 4 0 0 1-4 4H3"/>'),
  receipt: svg('<path d="M4 2v20l2-1 2 1 2-1 2 1 2-1 2 1 2-1 2 1V2l-2 1-2-1-2 1-2-1-2 1-2-1-2 1Z"/><path d="M16 8h-6a2 2 0 1 0 0 4h4a2 2 0 1 1 0 4H8M12 17.5v-11"/>'),
  grid: svg('<rect width="18" height="18" x="3" y="3" rx="2"/><path d="M3 9h18M3 15h18M9 3v18"/>'),
  target: svg('<circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/>'),
  chart: svg('<path d="M21 21H4a1 1 0 0 1-1-1V3"/><path d="m7 15 4-4 3 3 6-6"/>'),
};
const TYPE_ICON = { bank: IC.bank, cash: IC.cash, credit: IC.card, wallet: IC.wallet };

// ── API ───────────────────────────────────────────────────────────────────────

const state = {
  token: sessionStorage.getItem('bs_token'),
  route: location.hash || '#/',
  theme: lsGet('bs_theme') || 'system',
  baseCurrency: 'USD',
  lastRender: 0,
};
const cache = {};

function lsGet(k) { try { return localStorage.getItem(k); } catch (_) { return null; } }
function lsSet(k, v) { try { localStorage.setItem(k, v); } catch (_) { /* private mode */ } }

/** JSON request; shows a localized toast and returns null on any failure. */
async function api(path, opts = {}) {
  const hasBody = opts.body != null;
  const headers = {
    ...(hasBody ? { 'Content-Type': 'application/json' } : {}),
    ...(state.token ? { Authorization: `Bearer ${state.token}` } : {}),
  };
  let res;
  try {
    res = await fetch(path, { ...opts, headers, body: hasBody ? JSON.stringify(opts.body) : undefined });
  } catch (_) {
    setConnection(false);
    if (!opts.quiet) toast(t('web_offline_short'), true);
    return null;
  }
  setConnection(true);
  if (res.status === 401) { sessionExpired(); return null; }
  if (!res.ok) {
    if (opts.quiet) return null;
    const err = await res.json().catch(() => ({}));
    if (res.status === 429) toast(t('web_err_too_many'), true);
    else if (res.status >= 500) toast(t('common_something_went_wrong'), true);
    else if (/exchange rate/i.test(err.error || '')) toast(t('web_err_no_rate'), true);
    else toast(LOCALE === 'en' && err.error ? err.error : t('web_err_request'), true);
    return null;
  }
  try { return await res.json(); } catch (_) { return {}; }
}

async function refs(force) {
  if (force || !cache.accounts || !cache.categories) {
    const [a, c] = await Promise.all([api('/api/accounts', { quiet: true }), api('/api/categories', { quiet: true })]);
    if (a) cache.accounts = a.items || [];
    if (c) cache.categories = c.items || [];
  }
  return { accounts: cache.accounts || [], categories: cache.categories || [] };
}
function invalidate() { for (const k of Object.keys(cache)) delete cache[k]; }

// ── Toast & dialogs ───────────────────────────────────────────────────────────

let toastTimer = null;
function toast(msg, isErr = false, action = null) {
  document.querySelectorAll('.toast').forEach(el => el.remove());
  clearTimeout(toastTimer);
  const el = document.createElement('div');
  el.className = `toast${isErr ? ' error' : ''}`;
  el.setAttribute('role', 'status');
  el.innerHTML = `<span class="t-icon">${isErr ? IC.alert : IC.check}</span><span>${esc(msg)}</span>`;
  if (action) {
    const b = document.createElement('button');
    b.className = 'btn btn-sm btn-ghost';
    b.textContent = action.label;
    b.addEventListener('click', () => { action.run(); el.remove(); });
    el.appendChild(b);
  }
  document.body.appendChild(el);
  requestAnimationFrame(() => el.classList.add('show'));
  toastTimer = setTimeout(() => {
    el.classList.remove('show');
    setTimeout(() => el.remove(), 300);
    action?.expire?.();
  }, action ? 5000 : 2600);
}

let modalReturnFocus = null;

/**
 * Opens a dialog. `onSubmit` returns true (or a promise of true) to close.
 * Enter submits (except in textareas), Esc cancels, Tab stays inside.
 */
function openModal({ title, body, submit, onSubmit, danger = false, narrow = false, extra = null, onOpen = null }) {
  closeModal();
  modalReturnFocus = document.activeElement;
  const o = document.createElement('div');
  o.className = 'modal-overlay';
  o.id = 'modal-overlay';
  o.innerHTML = `
    <form class="modal${narrow ? ' narrow' : ''}" role="dialog" aria-modal="true" aria-labelledby="modal-title" novalidate>
      <h2 class="modal-title" id="modal-title">${esc(title)}</h2>
      ${body}
      <div class="hp-field" aria-hidden="true"><input type="text" name="website" tabindex="-1" autocomplete="off"></div>
      <div class="modal-actions">
        ${extra ? `<button type="button" class="btn btn-ghost" data-modal="extra">${esc(extra.label)}</button><span class="spacer"></span>` : ''}
        <button type="button" class="btn btn-ghost" data-modal="cancel">${esc(t('common_cancel'))}</button>
        ${submit ? `<button type="submit" class="btn ${danger ? 'btn-danger' : 'btn-primary'}" data-modal="ok">${esc(submit)}</button>` : ''}
      </div>
    </form>`;
  document.body.appendChild(o);
  const form = o.querySelector('form');
  const ok = o.querySelector('[data-modal="ok"]');
  o.querySelector('[data-modal="cancel"]').addEventListener('click', closeModal);
  o.addEventListener('mousedown', e => { if (e.target === o && !form.dataset.dirty) closeModal(); });
  form.addEventListener('input', () => { form.dataset.dirty = '1'; });
  if (extra) o.querySelector('[data-modal="extra"]').addEventListener('click', () => extra.run(form));

  let busy = false;
  form.addEventListener('submit', async e => {
    e.preventDefault();
    if (busy || !onSubmit) return;
    busy = true;
    const label = ok?.innerHTML;
    if (ok) { ok.disabled = true; ok.innerHTML = `<span class="spinner"></span>`; }
    let close = false;
    try { close = await onSubmit(form); } catch (err) { toast(t('common_something_went_wrong'), true); }
    busy = false;
    if (close) closeModal();
    else if (ok?.isConnected) { ok.disabled = false; ok.innerHTML = form.dataset.okLabel || label; }
  });
  form.addEventListener('keydown', e => {
    if (e.key === 'Escape') { e.preventDefault(); closeModal(); return; }
    if (e.key === 'Enter' && e.target.tagName === 'TEXTAREA') return;
    if (e.key === 'Enter' && e.target.tagName === 'BUTTON') return;
    if (e.key !== 'Tab') return;
    const f = [...form.querySelectorAll('input:not([tabindex="-1"]):not([type=hidden]):not(:disabled),select:not(:disabled),textarea,button:not(:disabled)')]
      .filter(el => el.offsetParent !== null);
    if (!f.length) return;
    if (e.shiftKey && document.activeElement === f[0]) { e.preventDefault(); f[f.length - 1].focus(); }
    else if (!e.shiftKey && document.activeElement === f[f.length - 1]) { e.preventDefault(); f[0].focus(); }
  });
  onOpen?.(form);
  setTimeout(() => {
    const first = form.querySelector('[autofocus]') || form.querySelector('.input:not(:disabled)');
    (first || ok)?.focus();
  }, 30);
  return form;
}

function closeModal() {
  const o = document.getElementById('modal-overlay');
  if (!o) return;
  o.remove();
  modalReturnFocus?.focus?.();
}

function confirmDialog(title, msg, label, danger = true) {
  return new Promise(resolve => {
    let done = false;
    openModal({
      title, narrow: true, danger, submit: label || t('common_delete'),
      body: `<p class="modal-text">${esc(msg)}</p>`,
      onSubmit: () => { done = true; resolve(true); return true; },
    });
    const o = document.getElementById('modal-overlay');
    new MutationObserver((_, obs) => {
      if (!document.body.contains(o)) { obs.disconnect(); if (!done) resolve(false); }
    }).observe(document.body, { childList: true });
  });
}

// ── Shared bits of markup ─────────────────────────────────────────────────────

function setContent(html) {
  const el = document.getElementById('content');
  el.innerHTML = html;
  state.lastRender = Date.now();
}

function skeleton(rows = 6) {
  return `<div class="card skel">${Array.from({ length: rows }, (_, i) => `
    <div class="skel-row"><span class="skel-circle"></span><div style="flex:1;display:flex;flex-direction:column;gap:8px">
      <span class="skel-bar" style="width:${46 + ((i * 37) % 30)}%"></span><span class="skel-bar" style="width:${22 + ((i * 23) % 18)}%"></span>
    </div><span class="skel-bar" style="width:70px"></span></div>`).join('')}</div>`;
}

function emptyState(icon, title, sub, action) {
  return `<div class="empty">
    <div class="empty-icon">${icon}</div>
    <div class="empty-title">${esc(title)}</div>
    ${sub ? `<p class="empty-sub">${esc(sub)}</p>` : ''}
    ${action ? `<button class="btn btn-tonal" data-action="${action.action}">${IC.plus}${esc(action.label)}</button>` : ''}
  </div>`;
}

function pageHead(title, sub, actions = '') {
  return `<div class="page-head">
    <div><h1 class="page-title">${esc(title)}</h1>${sub ? `<div class="page-sub">${sub}</div>` : ''}</div>
    <div class="page-actions">${actions}</div>
  </div>`;
}

/** Ready-to-assign banner (the brand element): base currency big, others as chips. */
function rtaBanner(unallocated, base, withButton) {
  const entries = Object.entries(unallocated || {}).filter(([c, v]) => c === base || Math.abs(v) >= 0.005);
  const main = unallocated?.[base] ?? 0;
  const others = entries.filter(([c]) => c !== base);
  return `<div class="rta">
    <div class="rta-body">
      <div class="rta-label">${esc(t('web_rta'))}</div>
      <div class="rta-amount num${main < 0 ? ' neg' : ''}">${esc(fmt(main, base))}</div>
      ${others.length ? `<div class="rta-more">${others.map(([c, v]) => `<span class="rta-chip num">${esc(fmt(v, c))}</span>`).join('')}</div>` : ''}
    </div>
    ${withButton ? `<a class="btn btn-ink" href="#/envelopes">${esc(t('web_rta_assign'))}</a>` : ''}
  </div>`;
}

/** One transaction row, like the app's TxTile. */
function txRow(tx, base, opts = {}) {
  const isTransfer = tx.type === 'transfer';
  const chip = isTransfer ? transferChip() : catChip(tx);
  const arrow = document.documentElement.dir === 'rtl' ? '←' : '→';
  const title = tx.note || (isTransfer ? `${tx.accountName || ''} ${arrow} ${tx.destinationAccountName || ''}` : tx.categoryName) || t(`type_${tx.type}`);
  const subParts = [];
  if (opts.showDate) subParts.push(fmtDate(tx.date));
  if (!isTransfer && tx.note && tx.categoryName) subParts.push(tx.categoryName);
  if (isTransfer && tx.note) subParts.push(`${tx.accountName || ''} ${arrow} ${tx.destinationAccountName || ''}`);
  else if (!isTransfer) subParts.push(tx.accountName || '');
  const cur = tx.lineCurrency || tx.accountCurrency || tx.currency;
  const amt = tx.lineCount > 1 ? tx.amount : (tx.lineAmount ?? tx.amount);
  const shownCur = tx.lineCount > 1 ? tx.currency : cur;
  let amountSub = '';
  if (isTransfer && tx.destinationCurrency && tx.destinationCurrency !== tx.currency) {
    amountSub = `<div class="row-amount-sub num">${arrow} ${esc(fmt(tx.amount * tx.exchangeRateToBase, tx.destinationCurrency))}</div>`;
  } else if (shownCur !== base) {
    const rate = tx.lineExchangeRate ?? tx.exchangeRateToBase;
    amountSub = rate && Math.abs(rate - 1) > 0.001
      ? `<div class="row-amount-sub num">${esc(fmt(amt * rate, base))}</div>`
      : `<div class="row-amount-sub"><span class="tag warn">${esc(t('web_tx_no_rate'))}</span></div>`;
  }
  const cls = tx.type === 'income' ? 'income' : tx.type === 'expense' ? 'expense' : '';
  return `<div class="row clickable" data-action="edit-tx" data-id="${esc(tx.id)}" tabindex="0">
    ${chip}
    <div class="row-main">
      <div class="row-title">${esc(title)}${tx.lineCount > 1 ? ` <span class="tag">${esc(t('web_tx_split', { n: tx.lineCount }))}</span>` : ''}</div>
      <div class="row-sub">${esc(subParts.filter(Boolean).join(' · '))}</div>
    </div>
    ${opts.actions ? `<div class="row-actions">
      <button class="icon-btn" data-action="dup-tx" data-id="${esc(tx.id)}" title="${esc(t('web_duplicate'))}" aria-label="${esc(t('web_duplicate'))}">${IC.copy}</button>
      <button class="icon-btn danger" data-action="del-tx" data-id="${esc(tx.id)}" title="${esc(t('common_delete'))}" aria-label="${esc(t('common_delete'))}">${IC.trash}</button>
    </div>` : ''}
    <div class="row-end">
      <div class="row-amount ${cls}">${esc(fmtSigned(amt, shownCur, tx.type))}</div>
      ${amountSub}
    </div>
  </div>`;
}

// ── Auth ──────────────────────────────────────────────────────────────────────

let pin = '';
let pinBusy = false;

function initAuth() {
  const dots = () => document.querySelectorAll('.pin-dot');
  const update = () => {
    dots().forEach((d, i) => d.classList.toggle('filled', i < pin.length));
    if (pin.length === 4) submitPin();
  };
  const press = n => { if (!pinBusy && pin.length < 4) { pin += n; update(); } };
  document.querySelectorAll('.num-btn[data-num]').forEach(b => b.addEventListener('click', () => press(b.dataset.num)));
  document.getElementById('del-btn').addEventListener('click', () => { pin = pin.slice(0, -1); update(); });
  document.addEventListener('keydown', e => {
    if (document.getElementById('auth-screen').classList.contains('hidden')) return;
    if (/^[0-9]$/.test(e.key)) press(e.key);
    else if (e.key === 'Backspace') { pin = pin.slice(0, -1); update(); }
  });

  async function submitPin() {
    pinBusy = true;
    const entered = pin;
    let data = null, status = 0;
    try {
      const r = await fetch('/auth/pin', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ pin: entered }) });
      status = r.status;
      data = await r.json().catch(() => null);
    } catch (_) { /* unreachable */ }
    pin = '';
    pinBusy = false;
    if (data?.token) {
      state.token = data.token;
      sessionStorage.setItem('bs_token', data.token);
      document.getElementById('auth-error').textContent = '';
      update();
      enterApp();
      return;
    }
    const box = document.getElementById('pin-dots');
    box.classList.add('error');
    let msg;
    if (!status) msg = t('web_offline_short');
    else if (data?.isLockout) msg = t('web_auth_locked', { n: data.retryInMinutes ?? 30 });
    else if (data?.attemptsLeft != null) msg = t('web_auth_wrong_left', { n: data.attemptsLeft });
    else msg = t('web_auth_incorrect');
    document.getElementById('auth-error').textContent = msg;
    setTimeout(() => { box.classList.remove('error'); update(); }, 700);
  }
}

function showAuth(message) {
  document.getElementById('auth-screen').classList.remove('hidden');
  document.getElementById('main-layout').classList.add('hidden');
  document.getElementById('auth-error').textContent = message || '';
  stopConnectionCheck();
  closeModal();
}

function sessionExpired() {
  state.token = null;
  sessionStorage.removeItem('bs_token');
  invalidate();
  showAuth(t('web_auth_expired'));
}

function enterApp() {
  document.getElementById('auth-screen').classList.add('hidden');
  document.getElementById('main-layout').classList.remove('hidden');
  navigate(location.hash || '#/');
  refs();
  startConnectionCheck();
}

// ── Router ────────────────────────────────────────────────────────────────────

const routes = {
  '#/': renderHome,
  '#/transactions': () => renderTransactions(),
  '#/envelopes': renderBudget,
  '#/accounts': renderAccounts,
  '#/categories': renderCategories,
  '#/recurring': () => renderRecurring(false),
  '#/subscriptions': () => renderRecurring(true),
  '#/reports': renderReports,
  '#/bulk': renderBulk,
  '#/goals': renderGoals,
};

function navigate(hash, quiet = false) {
  const route = hash || '#/';
  const changed = route !== state.route;
  state.route = route;
  const acct = route.match(/^#\/accounts\/([\w-]+)$/);
  const base = acct ? '#/accounts' : route;
  const navBase = base === '#/bulk' ? '#/transactions' : base;
  document.querySelectorAll('.nav-link').forEach(a => a.classList.toggle('active', a.dataset.route === navBase));
  toggleSidebar(false);
  if (changed && !quiet) window.scrollTo(0, 0);
  if (acct) return renderTransactions({ accountId: acct[1], quiet });
  if (base !== '#/transactions') txView = null;
  if (base !== '#/bulk') bulk = null;
  return (routes[base] || renderHome)(quiet);
}

function refresh(quiet = false) { invalidate(); navigate(state.route, quiet); }

window.addEventListener('hashchange', () => navigate(location.hash));

// ── Home ──────────────────────────────────────────────────────────────────────

async function renderHome(quiet) {
  if (!quiet) setContent(pageHead(t('web_nav_home'), '') + skeleton(5));
  const d = await api('/api/dashboard');
  if (!d || state.route !== '#/' && state.route !== '') return;
  const { household = {}, accounts = [], envelopes = [], unallocated = {}, recentTransactions = [] } = d;
  const base = household.baseCurrency || 'USD';
  state.baseCurrency = base;
  cache.accounts = cache.accounts || accounts;

  // Net worth per currency — never summed across currencies.
  const worth = {};
  accounts.forEach(a => { worth[a.currency] = (worth[a.currency] || 0) + a.balance; });
  const worthOthers = Object.entries(worth).filter(([c]) => c !== base);

  const acctHtml = accounts.length
    ? `<div class="acct-strip">${accounts.map(a => `
        <a class="card acct-card" href="#/accounts/${esc(a.id)}">
          <div class="acct-card-top">${a.isTravel ? IC.plane : (TYPE_ICON[a.type] || IC.wallet)}<span>${esc(a.name)}</span></div>
          <div class="acct-bal num${a.balance < 0 ? ' neg' : ''}">${esc(fmt(a.balance, a.currency))}</div>
        </a>`).join('')}</div>`
    : `<div class="card">${emptyState(IC.wallet, t('web_acct_empty_title'), t('web_acct_empty_sub'), { action: 'add-account', label: t('web_acct_add') })}</div>`;

  const envHtml = envelopes.length
    ? `<div class="card card-flush">${envelopes.slice(0, 6).map(e => envMini(e)).join('')}</div>`
    : `<div class="card">${emptyState(IC.envelope, t('web_env_empty_title'), t('web_env_empty_sub'))}</div>`;

  const recentHtml = recentTransactions.length
    ? `<div class="card card-flush list">${recentTransactions.map(tx => txRow(tx, base, { showDate: true })).join('')}</div>`
    : `<div class="card">${emptyState(IC.receipt, t('web_tx_empty_title'), t('web_tx_empty_sub'), { action: 'add-tx', label: t('web_tx_add') })}</div>`;

  setContent(`
    ${pageHead(t('web_nav_home'), esc([household.name, base].filter(Boolean).join(' · ')),
      `<button class="btn btn-primary" data-action="add-tx">${IC.plus}${esc(t('web_tx_add'))}</button>`)}
    <div class="hero-row">
      ${rtaBanner(unallocated, base, true)}
      <div class="card stat-hero">
        <div class="label">${esc(t('web_net_worth'))}</div>
        <div class="value num">${esc(fmt(worth[base] || 0, base))}</div>
        ${worthOthers.length ? `<div class="extra num">${worthOthers.map(([c, v]) => esc(fmt(v, c))).join(' · ')}</div>` : ''}
      </div>
    </div>
    <div class="section-head"><span class="section-title">${esc(t('nav_accounts'))}</span><a class="section-link" href="#/accounts">${esc(t('web_see_all'))}</a></div>
    ${acctHtml}
    <div class="grid-2" style="margin-top:8px">
      <div>
        <div class="section-head"><span class="section-title">${esc(t('web_nav_budget'))}</span><a class="section-link" href="#/envelopes">${esc(t('web_see_all'))}</a></div>
        ${envHtml}
      </div>
      <div>
        <div class="section-head"><span class="section-title">${esc(t('web_recent'))}</span><a class="section-link" href="#/transactions">${esc(t('web_see_all'))}</a></div>
        ${recentHtml}
      </div>
    </div>`);
}

// ── Envelopes ─────────────────────────────────────────────────────────────────

/** What an envelope card shows, in its target currency. */
function envFigures(e) {
  const balances = e.balanceByCurrency || {};
  const cur = e.targetCurrency || Object.keys(balances)[0] || state.baseCurrency;
  const bal = balances[cur] || 0;
  const spent = (e.spentByCurrency || {})[cur] || 0;
  const target = Number(e.targetAmount) || 0;
  const flexible = e.type !== 'spending';
  let pct = null, meta = '', metaEnd = '';
  if (target > 0) {
    if (flexible) {
      pct = Math.max(0, Math.min(100, (bal / target) * 100));
      meta = bal >= target ? t('web_env_reached') : t('web_env_to_go', { amount: fmt(target - bal, cur) });
      metaEnd = t('web_env_of', { amount: fmt(target, cur) });
    } else {
      pct = Math.max(0, Math.min(100, (spent / target) * 100));
      meta = t('web_env_spent', { amount: fmt(spent, cur) });
      metaEnd = t('web_env_of', { amount: fmt(target, cur) });
    }
  } else if (!flexible && spent > 0) {
    meta = t('web_env_spent', { amount: fmt(spent, cur) });
  }
  const others = Object.entries(balances).filter(([c, v]) => c !== cur && Math.abs(v) >= 0.005);
  return { cur, bal, spent, target, pct, meta, metaEnd, others, over: bal < 0, flexible };
}

function envChip(e, cls = '') {
  const color = safeHex(e.colorHex || getComputedStyle(document.documentElement).getPropertyValue('--acc-bright').trim());
  const inner = isEmoji(e.icon) ? esc(e.icon) : `<span style="color:${pastelInk(color)}">${esc((e.name || '?').charAt(0).toUpperCase())}</span>`;
  return `<span class="chip-icon ${cls}" style="background:${pastel(color)}">${inner}</span>`;
}

function barColor(f) {
  if (f.over) return 'var(--expense)';
  if (!f.flexible && f.pct >= 100) return 'var(--expense)';
  if (!f.flexible && f.pct >= 85) return 'var(--caution)';
  return f.flexible ? 'var(--income)' : 'var(--accent)';
}

function envMini(e) {
  const f = envFigures(e);
  return `<a class="env-mini row clickable" href="#/envelopes">
    ${envChip(e, 'sm')}
    <div class="row-main">
      <div class="env-mini-top"><span class="row-title">${esc(e.name)}</span><span class="row-amount ${f.over ? 'expense' : ''}">${esc(fmt(f.bal, f.cur))}</span></div>
      ${f.pct != null ? `<div class="bar thin"><span style="width:${f.pct.toFixed(1)}%;background:${barColor(f)}"></span></div>` : ''}
      ${f.meta ? `<div class="row-sub">${esc(f.meta)}${f.metaEnd ? ` · ${esc(f.metaEnd)}` : ''}</div>` : ''}
    </div>
  </a>`;
}

async function renderBudget(quiet) {
  if (!quiet) setContent(pageHead(t('web_nav_budget'), '') + skeleton(4));
  const d = await api('/api/envelopes');
  if (!d || state.route !== '#/envelopes') return;
  const base = d.baseCurrency || state.baseCurrency;
  state.baseCurrency = base;
  cache.envelopes = d.items || [];
  cache.unallocated = d.unallocated || {};
  const period = d.period ? `${fmtDate(d.period.start)} – ${fmtDate(new Date(new Date(d.period.end) - 1))}` : '';

  const cards = cache.envelopes.map(e => {
    const f = envFigures(e);
    const kind = f.flexible ? t('web_env_flexible') : t('web_env_spending');
    return `<div class="card env-card${f.over ? ' over' : ''}">
      <div class="env-top">
        ${envChip(e)}
        <div class="row-main"><div class="env-name">${esc(e.name)}</div><div class="env-kind">${esc(kind)}</div></div>
      </div>
      <div>
        <div class="env-amount num">${esc(fmt(f.bal, f.cur))}</div>
        <div class="env-kind">${esc(f.over ? t('web_env_overspent') : t('web_env_available'))}</div>
      </div>
      ${f.pct != null ? `<div class="bar"><span style="width:${f.pct.toFixed(1)}%;background:${barColor(f)}"></span></div>` : ''}
      ${f.meta || f.metaEnd ? `<div class="env-meta"><span>${esc(f.meta)}</span><span>${esc(f.metaEnd)}</span></div>` : ''}
      <div class="env-foot">
        <span class="env-cross num">${f.others.map(([c, v]) => esc((v < 0 ? '' : '+ ') + fmt(v, c))).join(' · ')}</span>
        <span class="env-actions">
          <button class="icon-btn" data-action="move" data-id="${esc(e.id)}" title="${esc(t('web_move_title'))}" aria-label="${esc(t('web_move_title'))}">${IC.transfer}</button>
          ${f.over
            ? `<button class="btn btn-sm btn-cover" data-action="cover" data-id="${esc(e.id)}">${esc(t('web_env_cover'))}</button>`
            : `<button class="btn btn-sm btn-tonal" data-action="fund" data-id="${esc(e.id)}">${IC.plus}${esc(t('web_env_fund'))}</button>`}
        </span>
      </div>
    </div>`;
  }).join('');

  setContent(`
    ${pageHead(t('web_nav_budget'), esc(period))}
    ${rtaBanner(d.unallocated, base, false)}
    <div class="section-head"><span class="section-title">${esc(t('nav_envelopes'))}</span></div>
    ${cache.envelopes.length ? `<div class="grid-auto">${cards}</div>` : `<div class="card">${emptyState(IC.envelope, t('web_env_empty_title'), t('web_env_empty_sub'))}</div>`}`);
}

function openFund(id) {
  const e = (cache.envelopes || []).find(x => x.id === id);
  if (!e) return;
  const f = envFigures(e);
  const unalloc = cache.unallocated || {};
  const currencies = [...new Set([f.cur, ...Object.keys(unalloc)])];
  const available = c => unalloc[c] ?? 0;
  const toTarget = f.target > 0 ? Math.max(0, f.target - f.bal) : 0;

  openModal({
    title: t('web_fund_title', { name: e.name }),
    submit: t('web_env_fund'),
    body: `
      <div class="field">
        <label class="label" for="fund-amount">${esc(t('web_form_amount'))}</label>
        <div class="input-cur"><input id="fund-amount" class="input amount num" inputmode="decimal" autocomplete="off" placeholder="0" autofocus><span class="cur" id="fund-cur-badge">${esc(f.cur)}</span></div>
        <div class="chips">
          ${toTarget > 0 ? `<button type="button" class="pill" data-fill="${toTarget}">${esc(t('web_fund_to_target'))}</button>` : ''}
          <button type="button" class="pill" data-fill="all">${esc(t('web_fund_all'))}</button>
        </div>
        <div class="help" id="fund-help"></div>
      </div>
      ${currencies.length > 1 ? `<div class="field"><label class="label" for="fund-cur">${esc(t('web_form_currency'))}</label>
        <select id="fund-cur" class="input">${currencies.map(c => `<option value="${esc(c)}"${c === f.cur ? ' selected' : ''}>${esc(c)}</option>`).join('')}</select></div>` : ''}
      <div class="field"><label class="label" for="fund-note">${esc(t('web_form_note'))}</label><input id="fund-note" class="input" placeholder="${esc(t('web_form_optional'))}" maxlength="500"></div>`,
    onOpen: form => {
      const amount = form.querySelector('#fund-amount');
      const curSel = form.querySelector('#fund-cur');
      const help = form.querySelector('#fund-help');
      const cur = () => curSel?.value || f.cur;
      const update = () => {
        const v = parseAmount(amount.value);
        const left = available(cur()) - (Number.isFinite(v) ? v : 0);
        help.textContent = t('web_fund_available', { amount: fmt(available(cur()), cur()) });
        help.classList.toggle('warn', left < -0.004);
        if (left < -0.004) help.textContent = t('web_fund_over', { amount: fmt(left, cur()) });
        form.querySelector('#fund-cur-badge').textContent = cur();
      };
      form.querySelectorAll('[data-fill]').forEach(b => b.addEventListener('click', () => {
        const v = b.dataset.fill === 'all' ? Math.max(0, available(cur())) : Number(b.dataset.fill);
        amount.value = amountInputValue(v, cur());
        update();
      }));
      amount.addEventListener('input', update);
      curSel?.addEventListener('change', update);
      update();
    },
    onSubmit: async form => {
      const amount = parseAmount(form.querySelector('#fund-amount').value);
      const currency = form.querySelector('#fund-cur')?.value || f.cur;
      if (!(amount > 0)) { toast(t('web_val_valid_amount'), true); return false; }
      // Over-funding: the first submit warns and relabels the button; the
      // second one goes ahead (the app asks the same question).
      if (amount > available(currency) + 0.004 && form.dataset.confirmedFor !== String(amount)) {
        form.dataset.confirmedFor = String(amount);
        form.dataset.okLabel = esc(t('web_fund_anyway'));
        const help = form.querySelector('#fund-help');
        help.textContent = t('web_fund_over_msg');
        help.classList.add('warn');
        return false;
      }
      const r = await api(`/api/envelopes/${encodeURIComponent(id)}/fund`, { method: 'POST', body: { amount, currency, note: form.querySelector('#fund-note').value.trim() } });
      if (!r) return false;
      toast(t('web_toast_env_funded'));
      closeModal();
      refresh(true);
      return true;
    },
  });
}

/**
 * Move money between envelopes / Ready to assign (`''` = Ready to assign).
 * Cover = a move into an overspent envelope, prefilled with the shortfall
 * and taken from Ready to assign (or the envelope with the most money when
 * Ready to assign has none).
 */
function openMove(id, cover = false) {
  const envs = cache.envelopes || [];
  const e = envs.find(x => x.id === id);
  if (!e) return;
  const f = envFigures(e);
  const unalloc = cache.unallocated || {};
  const holding = (key, c) => key ? ((envs.find(x => x.id === key)?.balanceByCurrency || {})[c] || 0) : (unalloc[c] || 0);
  const name = key => key ? (envs.find(x => x.id === key)?.name || '') : t('web_rta');
  const currencies = [...new Set([f.cur, ...Object.keys(unalloc), ...envs.flatMap(x => Object.keys(x.balanceByCurrency || {}))])];
  const shortfall = cover ? Math.max(0, -f.bal) : 0;

  let from = id, to = '';
  if (cover) {
    to = id;
    from = '';
    if (holding('', f.cur) < shortfall - 0.004) {
      const richest = envs.filter(x => x.id !== id).sort((a, b) => holding(b.id, f.cur) - holding(a.id, f.cur))[0];
      if (richest && holding(richest.id, f.cur) > holding('', f.cur)) from = richest.id;
    }
  }
  const options = sel => [`<option value=""${sel === '' ? ' selected' : ''}>${esc(t('web_rta'))}</option>`,
    ...envs.map(x => `<option value="${esc(x.id)}"${x.id === sel ? ' selected' : ''}>${esc(x.name)}</option>`)].join('');

  openModal({
    title: cover ? t('web_cover_title', { name: e.name }) : t('web_move_title'),
    submit: cover ? t('web_env_cover') : t('web_move_submit'),
    body: `
      <div class="field-row">
        <div class="field"><label class="label" for="mv-from">${esc(t('web_move_from'))}</label><select id="mv-from" class="input">${options(from)}</select></div>
        <div class="field"><label class="label" for="mv-to">${esc(t('web_move_to'))}</label><select id="mv-to" class="input">${options(to)}</select></div>
      </div>
      <div class="field">
        <label class="label" for="mv-amount">${esc(t('web_form_amount'))}</label>
        <div class="input-cur"><input id="mv-amount" class="input amount num" inputmode="decimal" autocomplete="off" placeholder="0" autofocus value="${shortfall > 0 ? esc(amountInputValue(shortfall, f.cur)) : ''}"><span class="cur" id="mv-cur-badge">${esc(f.cur)}</span></div>
        <div class="chips">
          ${cover ? `<button type="button" class="pill" data-fill="short">${esc(t('web_move_shortfall'))}</button>` : ''}
          <button type="button" class="pill" data-fill="all">${esc(t('web_move_all'))}</button>
        </div>
        <div class="help" id="mv-help"></div>
      </div>
      ${currencies.length > 1 ? `<div class="field"><label class="label" for="mv-cur">${esc(t('web_form_currency'))}</label>
        <select id="mv-cur" class="input">${currencies.map(c => `<option value="${esc(c)}"${c === f.cur ? ' selected' : ''}>${esc(c)}</option>`).join('')}</select></div>` : ''}`,
    onOpen: form => {
      const amount = form.querySelector('#mv-amount');
      const fromSel = form.querySelector('#mv-from');
      const toSel = form.querySelector('#mv-to');
      const curSel = form.querySelector('#mv-cur');
      const help = form.querySelector('#mv-help');
      const cur = () => curSel?.value || f.cur;
      const update = () => {
        delete form.dataset.confirmedFor;
        delete form.dataset.okLabel;
        const v = parseAmount(amount.value);
        const have = holding(fromSel.value, cur());
        const left = have - (Number.isFinite(v) ? v : 0);
        help.textContent = t('web_move_has', { name: name(fromSel.value), amount: fmt(have, cur()) });
        help.classList.toggle('warn', left < -0.004);
        form.querySelector('#mv-cur-badge').textContent = cur();
      };
      form.querySelectorAll('[data-fill]').forEach(b => b.addEventListener('click', () => {
        const v = b.dataset.fill === 'all' ? holding(fromSel.value, cur()) : -holding(toSel.value, cur());
        amount.value = amountInputValue(Math.max(0, v), cur());
        update();
      }));
      [amount, fromSel, toSel, curSel].forEach(el => el?.addEventListener(el === amount ? 'input' : 'change', update));
      update();
    },
    onSubmit: async form => {
      const fromId = form.querySelector('#mv-from').value;
      const toId = form.querySelector('#mv-to').value;
      const amount = parseAmount(form.querySelector('#mv-amount').value);
      const currency = form.querySelector('#mv-cur')?.value || f.cur;
      if (fromId === toId) { toast(t('web_move_same'), true); return false; }
      if (!(amount > 0)) { toast(t('web_val_valid_amount'), true); return false; }
      const have = holding(fromId, currency);
      if (amount > have + 0.004) {
        // An envelope can't give more than it holds; Ready to assign can go
        // negative after a second click (same rule as funding).
        if (fromId) { toast(t('web_move_not_enough', { name: name(fromId), amount: fmt(have, currency) }), true); return false; }
        if (form.dataset.confirmedFor !== String(amount)) {
          form.dataset.confirmedFor = String(amount);
          form.dataset.okLabel = esc(t('web_fund_anyway'));
          const help = form.querySelector('#mv-help');
          help.textContent = t('web_fund_over_msg');
          help.classList.add('warn');
          return false;
        }
      }
      const r = await api('/api/envelopes/move', { method: 'POST', body: { fromId: fromId || null, toId: toId || null, amount, currency } });
      if (!r) return false;
      toast(cover && toId === id ? t('web_toast_covered') : t('web_toast_moved'));
      closeModal();
      refresh(true);
      return true;
    },
  });
}

// ── Transactions ──────────────────────────────────────────────────────────────

let txView = null;
const PAGE = 40;

function newTxView(accountId = null) {
  const now = new Date();
  return { accountId, type: lsGet('bs_tx_type') || '', search: '', year: now.getFullYear(), month: accountId ? -1 : now.getMonth(), page: 1, items: [], hasMore: false, flash: null };
}

async function renderTransactions(opts = {}) {
  const accountId = opts.accountId || null;
  if (!txView || txView.accountId !== accountId) txView = newTxView(accountId);
  const v = txView;
  const { accounts } = await refs();
  if (txView !== v) return;
  const account = accountId ? accounts.find(a => a.id === accountId) : null;

  const now = new Date();
  const monthPills = [`<button class="pill${v.month < 0 ? ' active' : ''}" data-month="-1">${esc(t('web_whole_year'))}</button>`]
    .concat(Array.from({ length: 12 }, (_, i) => i)
      .filter(i => v.year < now.getFullYear() || i <= now.getMonth())
      .map(i => `<button class="pill${v.month === i ? ' active' : ''}" data-month="${i}">${esc(monthShort(i))}</button>`));

  const head = account
    ? `<a class="back-link" href="#/accounts">${IC.back}${esc(t('nav_accounts'))}</a>
       ${pageHead(account.name, `<span class="num">${esc(fmt(account.balance, account.currency))}</span>`,
         `<button class="btn btn-ghost" data-action="export-tx">${IC.download}${esc(t('web_csv'))}</button>
          <button class="btn btn-primary" data-action="add-tx">${IC.plus}${esc(t('web_tx_add'))}</button>`)}`
    : pageHead(t('nav_transactions'), '',
        `<button class="btn btn-ghost" data-action="export-tx">${IC.download}${esc(t('web_csv'))}</button>
         <a class="btn btn-tonal" href="#/bulk">${IC.grid}${esc(t('web_bulk_add'))}</a>
         <button class="btn btn-primary" data-action="add-tx">${IC.plus}${esc(t('web_tx_add'))}</button>`);

  setContent(`
    ${head}
    <div class="toolbar">
      <label class="search">${IC.search}<span class="sr-only">${esc(t('web_tx_search'))}</span>
        <input id="tx-search" class="input" type="search" placeholder="${esc(t('web_tx_search'))}" value="${esc(v.search)}" autocomplete="off"></label>
      <div class="seg" id="tx-type">
        ${[['', 'type_all'], ['expense', 'type_expense'], ['income', 'type_income'], ['transfer', 'type_transfer']]
          .map(([k, l]) => `<button type="button" data-type="${k}" class="${v.type === k ? 'active' : ''}">${esc(t(l))}</button>`).join('')}
      </div>
    </div>
    ${account ? '' : `<div class="month-bar">
      <button class="icon-btn" data-year="-1" aria-label="${esc(t('web_prev_year'))}"><span class="flip-rtl" style="display:inline-grid">${IC.left}</span></button>
      <span class="year num">${v.year}</span>
      <button class="icon-btn" data-year="1" aria-label="${esc(t('web_next_year'))}" ${v.year >= now.getFullYear() ? 'disabled style="opacity:.3"' : ''}><span class="flip-rtl" style="display:inline-grid">${IC.right}</span></button>
      <div class="months">${monthPills.join('')}</div>
    </div>`}
    <div id="tx-results">${skeleton(7)}</div>`);

  const search = document.getElementById('tx-search');
  let timer;
  search.addEventListener('input', () => {
    clearTimeout(timer);
    timer = setTimeout(() => { v.search = search.value.trim(); loadTx(true); }, 350);
  });
  document.getElementById('tx-type').addEventListener('click', e => {
    const b = e.target.closest('[data-type]'); if (!b) return;
    v.type = b.dataset.type; lsSet('bs_tx_type', v.type);
    document.querySelectorAll('#tx-type button').forEach(x => x.classList.toggle('active', x === b));
    loadTx(true);
  });
  document.querySelector('.month-bar')?.addEventListener('click', e => {
    const m = e.target.closest('[data-month]');
    const y = e.target.closest('[data-year]');
    if (m) { v.month = Number(m.dataset.month); }
    else if (y && !y.disabled) {
      v.year += Number(y.dataset.year);
      if (v.year === now.getFullYear() && v.month > now.getMonth()) v.month = now.getMonth();
    } else return;
    renderTransactions({ accountId });
  });
  if (opts.focusSearch) search.focus();
  loadTx(true);
}

function txQuery(page, limit = PAGE) {
  const v = txView;
  const p = new URLSearchParams({ page, limit });
  if (v.type) p.set('type', v.type);
  if (v.search) p.set('search', v.search);
  if (v.accountId) p.set('accountId', v.accountId);
  if (v.month >= 0) {
    p.set('from', dayKey(new Date(v.year, v.month, 1)));
    p.set('to', dayKey(new Date(v.year, v.month + 1, 1)));
  } else if (!v.accountId) {
    p.set('from', dayKey(new Date(v.year, 0, 1)));
    p.set('to', dayKey(new Date(v.year + 1, 0, 1)));
  }
  return p.toString();
}

async function loadTx(reset) {
  const v = txView;
  if (!v) return;
  if (reset) { v.page = 1; v.items = []; }
  const d = await api(`/api/transactions?${txQuery(v.page)}`);
  if (!d || txView !== v) return;
  state.baseCurrency = d.baseCurrency || state.baseCurrency;
  v.items = reset ? d.items : v.items.concat(d.items);
  v.hasMore = !!d.hasMore;
  drawTx();
}

function drawTx() {
  const v = txView;
  const box = document.getElementById('tx-results');
  if (!box) return;
  const visible = v.items.filter(tx => !pendingDeletes.has(tx.id));
  if (!visible.length) {
    box.innerHTML = `<div class="card">${emptyState(IC.receipt, v.search ? t('web_tx_no_match') : t('web_tx_empty_title'), v.search ? '' : t('web_tx_empty_sub'), v.search ? null : { action: 'add-tx', label: t('web_tx_add') })}</div>`;
    return;
  }
  const groups = [];
  for (const tx of visible) {
    const k = dayKey(tx.date);
    if (!groups.length || groups[groups.length - 1].k !== k) groups.push({ k, date: tx.date, items: [] });
    groups[groups.length - 1].items.push(tx);
  }
  box.innerHTML = `<div class="card card-flush list">
    ${groups.map(g => `<div class="day-head"><span>${esc(fmtDay(g.date))}</span></div>${g.items.map(tx => txRow(tx, state.baseCurrency, { actions: true })).join('')}`).join('')}
    ${v.hasMore ? `<div class="load-more"><button class="btn btn-tonal" data-action="more-tx">${esc(t('web_load_more'))}</button></div>` : ''}
  </div>`;
  if (v.flash) {
    const row = box.querySelector(`[data-id="${CSS.escape(v.flash)}"]`);
    row?.classList.add('flash');
    v.flash = null;
  }
}

// Deleting waits 5 s so Undo can cancel it (like the app's SnackBar).
const pendingDeletes = new Map();

function deleteTx(id) {
  if (pendingDeletes.has(id)) return;
  const timer = setTimeout(() => commitDelete(id), 5200);
  pendingDeletes.set(id, timer);
  if (txView) drawTx();
  else document.querySelectorAll(`[data-action="edit-tx"][data-id="${CSS.escape(id)}"]`).forEach(r => r.classList.add('hidden'));
  toast(t('web_toast_tx_deleted'), false, {
    label: t('web_undo'),
    run: () => {
      clearTimeout(pendingDeletes.get(id));
      pendingDeletes.delete(id);
      if (txView) drawTx(); else refresh(true);
    },
  });
}

async function commitDelete(id, keepalive = false) {
  if (!pendingDeletes.has(id)) return;
  clearTimeout(pendingDeletes.get(id));
  pendingDeletes.delete(id);
  if (keepalive) {
    fetch(`/api/transactions/${encodeURIComponent(id)}`, { method: 'DELETE', keepalive: true, headers: { Authorization: `Bearer ${state.token}` } }).catch(() => {});
    return;
  }
  const r = await api(`/api/transactions/${encodeURIComponent(id)}`, { method: 'DELETE' });
  if (!r) { refresh(true); return; }
  if (txView) txView.items = txView.items.filter(x => x.id !== id);
  delete cache.accounts;
}

window.addEventListener('pagehide', () => { for (const id of [...pendingDeletes.keys()]) commitDelete(id, true); });

async function exportTx() {
  if (!txView) txView = newTxView();
  toast(t('web_csv_preparing'));
  const rows = [];
  for (let page = 1; page <= 25; page++) {
    const d = await api(`/api/transactions?${txQuery(page, 200)}`);
    if (!d) return;
    rows.push(...d.items);
    if (!d.hasMore) break;
  }
  const head = ['date', 'type', 'title', 'category', 'account', 'to_account', 'amount', 'currency', `amount_${state.baseCurrency}`];
  const lines = rows.map(tx => {
    const cur = tx.lineCount > 1 ? tx.currency : (tx.lineCurrency || tx.currency);
    const amt = tx.lineCount > 1 ? tx.amount : (tx.lineAmount ?? tx.amount);
    const rate = tx.type === 'transfer' ? null : (tx.lineExchangeRate ?? tx.exchangeRateToBase);
    const inBase = cur === state.baseCurrency ? amt : rate && Math.abs(rate - 1) > 0.001 ? amt * rate : '';
    const sign = tx.type === 'expense' ? -1 : 1;
    return [dayKey(tx.date), tx.type, tx.note, tx.categoryName, tx.accountName, tx.destinationAccountName,
      (sign * amt).toFixed(decimalsFor(cur)), cur, inBase === '' ? '' : (sign * inBase).toFixed(2)];
  });
  downloadCsv(`budgetseal-transactions-${dayKey()}.csv`, [head, ...lines]);
}

function downloadCsv(name, rows) {
  const csv = rows.map(r => r.map(c => {
    const s = String(c ?? '');
    return /[",\n;]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
  }).join(',')).join('\r\n');
  // BOM so Excel opens UTF-8 (Arabic, €) correctly.
  const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = name;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(a.href), 1000);
  toast(t('web_csv_done', { n: rows.length - 1 }));
}

// ── Transaction form ──────────────────────────────────────────────────────────

function categoryOptions(cats, type, selected) {
  const ofType = cats.filter(c => (type === 'income') === (c.transactionType === 'income'));
  const ids = new Set(ofType.map(c => c.id));
  const roots = ofType.filter(c => !c.parentId || !ids.has(c.parentId));
  const kids = id => ofType.filter(c => c.parentId === id);
  const label = c => `${isEmoji(c.icon) ? c.icon + '  ' : ''}${c.name}`;
  let html = `<option value="">${esc(t('web_form_no_category'))}</option>`;
  for (const r of roots) {
    html += `<option value="${esc(r.id)}"${r.id === selected ? ' selected' : ''}>${esc(label(r))}</option>`;
    for (const k of kids(r.id)) html += `<option value="${esc(k.id)}"${k.id === selected ? ' selected' : ''}>&nbsp;&nbsp;&nbsp;&nbsp;${esc(label(k))}</option>`;
  }
  return html;
}

function accountOptions(accounts, selected, exclude) {
  return accounts.filter(a => a.id !== exclude)
    .map(a => `<option value="${esc(a.id)}"${a.id === selected ? ' selected' : ''}>${esc(a.name)} · ${esc(a.currency)}</option>`).join('');
}

/** Add / edit / duplicate. `pre` is a transaction from GET /api/transactions/:id. */
async function openTxForm(pre = null, mode = 'add') {
  const { accounts, categories } = await refs();
  if (!accounts.length) {
    toast(t('web_need_account'), true);
    return;
  }
  const base = state.baseCurrency;
  const editing = mode === 'edit';
  const split = editing && pre?.lineCount > 1;
  let type = pre?.type || lsGet('bs_last_type') || 'expense';
  if (!['expense', 'income', 'transfer'].includes(type)) type = 'expense';
  const lastAcct = lsGet('bs_last_account');
  const acctId = pre?.accountId || (accounts.some(a => a.id === lastAcct) ? lastAcct : accounts[0].id);
  const destId = pre?.destinationAccountId || accounts.find(a => a.id !== acctId)?.id || '';
  const amount = pre ? (pre.type === 'transfer' || split ? pre.amount : (pre.lineAmount ?? pre.amount)) : '';
  const cur = pre ? (pre.type === 'transfer' ? pre.currency : (pre.lineCurrency || pre.currency)) : null;
  const rate = pre && pre.type !== 'transfer' ? (pre.lineExchangeRate ?? pre.exchangeRateToBase) : null;
  const received = pre?.type === 'transfer' && pre.destinationCurrency && pre.destinationCurrency !== pre.currency ? pre.amount * pre.exchangeRateToBase : '';
  const date = mode === 'dup' || !pre ? dayKey() : dayKey(pre.date);
  const currencies = [...new Set([base, ...accounts.map(a => a.currency)])];

  const linesBox = split ? `<div class="lines-box">${pre.lines.map(l => `
      <div class="row">${catChip(l, 'sm')}<div class="row-main"><div class="row-title">${esc(l.categoryName || t('web_form_no_category'))}</div><div class="row-sub">${esc([l.note, l.accountName].filter(Boolean).join(' · '))}</div></div>
      <div class="row-amount num">${esc(fmt(l.amount, l.currency))}</div></div>`).join('')}</div>
      <p class="help" style="margin:-6px 0 14px">${esc(t('web_tx_split_hint'))}</p>` : '';

  const title = editing ? t(`web_tx_edit_${type}`) : t(`web_tx_new_${type}`);
  const form = openModal({
    title,
    submit: editing ? t('common_save') : t('web_tx_add_short'),
    extra: editing ? { label: t('common_delete'), run: () => { closeModal(); deleteTx(pre.id); } }
      : { label: t('web_save_add_another'), run: f => f.dispatchEvent(new CustomEvent('submit-another', { cancelable: true })) },
    body: `
      <div class="field"><div class="seg full" id="f-type" role="tablist">
        ${['expense', 'income', 'transfer'].map(k => `<button type="button" data-type="${k}" class="${type === k ? 'active' : ''}"${split && k === 'transfer' ? ' disabled' : ''}>${esc(t(`type_${k}`))}</button>`).join('')}
      </div></div>
      ${linesBox}
      <div class="field${split ? ' hidden' : ''}">
        <label class="label" for="f-amount">${esc(t('web_form_amount'))}</label>
        <div class="field-row keep" style="gap:10px">
          <div class="field" style="margin:0;flex:3"><input id="f-amount" class="input amount num" inputmode="decimal" autocomplete="off" placeholder="0" value="${esc(amountInputValue(amount, cur))}" ${split ? 'disabled' : 'autofocus'}></div>
          <div class="field" style="margin:0;flex:1;min-width:96px" id="fg-cur"><select id="f-cur" class="input" aria-label="${esc(t('web_form_currency'))}" ${split ? 'disabled' : ''}>${currencies.map(c => `<option${c === cur ? ' selected' : ''}>${esc(c)}</option>`).join('')}</select></div>
        </div>
        <div class="help" id="f-amount-help"></div>
      </div>
      <div class="field" id="fg-rate">
        <label class="label" for="f-rate" id="f-rate-label"></label>
        <input id="f-rate" class="input num" inputmode="decimal" autocomplete="off" value="${esc(rate && Math.abs(rate - 1) > 0.000001 ? String(rate).replace('.', NUM.decimal) : '')}" placeholder="${esc(t('web_form_rate_auto'))}">
      </div>
      <div class="field-row">
        <div class="field"><label class="label" for="f-account" id="f-account-label"></label><select id="f-account" class="input">${accountOptions(accounts, acctId)}</select></div>
        <div class="field" id="fg-dest"><label class="label" for="f-dest">${esc(t('web_form_to_account'))}</label><select id="f-dest" class="input">${accountOptions(accounts, destId)}</select></div>
        <div class="field" id="fg-cat"><label class="label" for="f-cat">${esc(t('web_form_category'))}</label><select id="f-cat" class="input" ${split ? 'disabled' : ''}></select></div>
      </div>
      <div class="field" id="fg-received">
        <label class="label" for="f-received" id="f-received-label"></label>
        <input id="f-received" class="input num" inputmode="decimal" autocomplete="off" value="${esc(amountInputValue(received, pre?.destinationCurrency))}">
      </div>
      <div class="field-row">
        <div class="field"><label class="label" for="f-date">${esc(t('web_form_date'))}</label><input id="f-date" type="date" class="input" value="${esc(date)}" max="${esc(dayKey(new Date(Date.now() + 366 * 864e5)))}">
          <div class="chips"><button type="button" class="pill" data-day="0">${esc(t('common_today'))}</button><button type="button" class="pill" data-day="1">${esc(t('common_yesterday'))}</button></div></div>
        <div class="field"><label class="label" for="f-note">${esc(t('web_form_title'))}</label><input id="f-note" class="input" maxlength="500" value="${esc(pre?.note || '')}" placeholder="${esc(t('web_form_optional'))}"></div>
      </div>`,
    onOpen: f => wireTxForm(f, { accounts, categories, pre, split, type, cur, mode }),
    onSubmit: f => saveTx(f, { pre, mode, split }),
  });
  form.addEventListener('submit-another', () => saveTx(form, { pre, mode, split, again: true }));
}

function wireTxForm(f, ctx) {
  const $ = s => f.querySelector(s);
  let type = ctx.type;
  let curTouched = !!ctx.cur;
  const acct = () => ctx.accounts.find(a => a.id === $('#f-account').value);
  const dest = () => ctx.accounts.find(a => a.id === $('#f-dest').value);

  function sync() {
    const isT = type === 'transfer';
    f.querySelectorAll('#f-type button').forEach(b => b.classList.toggle('active', b.dataset.type === type));
    $('#modal-title').textContent = t(`web_tx_${ctx.mode === 'edit' ? 'edit' : 'new'}_${type}`);
    $('#fg-dest').classList.toggle('hidden', !isT);
    $('#fg-cat').classList.toggle('hidden', isT || ctx.split);
    $('#fg-cur').classList.toggle('hidden', isT);
    $('#f-account-label').textContent = isT ? t('web_form_from_account') : t('web_form_account');
    if (!isT) {
      const sel = $('#f-cat').value || ctx.pre?.categoryId || '';
      $('#f-cat').innerHTML = categoryOptions(ctx.categories, type, sel);
    }
    const a = acct();
    // The amount is in the account's currency unless the user picked another.
    if (!curTouched && a && !isT) $('#f-cur').value = a.currency;
    const cur = isT ? a?.currency : $('#f-cur').value;
    $('#f-amount-help').textContent = isT && a ? t('web_form_in_currency', { cur: a.currency }) : '';
    const showRate = !isT && cur && cur !== state.baseCurrency;
    $('#fg-rate').classList.toggle('hidden', !showRate);
    if (showRate) $('#f-rate-label').textContent = t('web_form_rate_label', { cur, base: state.baseCurrency });
    const d = dest();
    const showReceived = isT && a && d && a.currency !== d.currency;
    $('#fg-received').classList.toggle('hidden', !showReceived);
    if (showReceived) $('#f-received-label').textContent = t('web_form_received', { cur: d.currency });
  }

  f.querySelector('#f-type').addEventListener('click', e => {
    const b = e.target.closest('[data-type]');
    if (!b || b.disabled) return;
    type = b.dataset.type;
    f.dataset.type = type;
    sync();
  });
  $('#f-cur').addEventListener('change', () => { curTouched = true; sync(); });
  $('#f-account').addEventListener('change', () => {
    if ($('#f-dest').value === $('#f-account').value) {
      const other = ctx.accounts.find(a => a.id !== $('#f-account').value);
      if (other) $('#f-dest').value = other.id;
    }
    curTouched = false;
    sync();
  });
  $('#f-dest').addEventListener('change', sync);
  f.querySelectorAll('[data-day]').forEach(b => b.addEventListener('click', () => {
    const d = new Date(); d.setDate(d.getDate() - Number(b.dataset.day));
    $('#f-date').value = dayKey(d);
  }));
  f.dataset.type = type;
  sync();
}

async function saveTx(f, { pre, mode, split, again = false }) {
  const $ = s => f.querySelector(s);
  const type = f.dataset.type;
  const editing = mode === 'edit';
  const body = { type, accountId: $('#f-account').value, note: $('#f-note').value.trim(), date: $('#f-date').value || dayKey() };
  if (!body.accountId) { toast(t('web_val_select_account'), true); return false; }
  if (!split) {
    const amount = parseAmount($('#f-amount').value);
    if (!(amount > 0)) { toast(t('web_val_valid_amount'), true); $('#f-amount').focus(); return false; }
    body.amount = amount;
  }
  if (type === 'transfer') {
    body.destinationAccountId = $('#f-dest').value;
    if (!body.destinationAccountId) { toast(t('web_val_select_dest'), true); return false; }
    if (body.destinationAccountId === body.accountId) { toast(t('web_val_accounts_differ'), true); return false; }
    if (!$('#fg-received').classList.contains('hidden')) {
      const received = parseAmount($('#f-received').value);
      if (!(received > 0)) { toast(t('web_val_received'), true); $('#f-received').focus(); return false; }
      body.exchangeRateToBase = received / body.amount;
    }
  } else if (!split) {
    body.currency = $('#f-cur').value;
    body.categoryId = $('#f-cat').value || null;
    if (!$('#fg-rate').classList.contains('hidden')) {
      const rate = parseAmount($('#f-rate').value);
      if ($('#f-rate').value.trim() && !(rate > 0)) { toast(t('web_val_rate'), true); return false; }
      if (rate > 0) body.exchangeRateToBase = rate;
    } else {
      body.exchangeRateToBase = 1;
    }
  }
  const r = editing
    ? await api(`/api/transactions/${encodeURIComponent(pre.id)}`, { method: 'PUT', body })
    : await api('/api/transactions', { method: 'POST', body });
  if (!r) return false;
  lsSet('bs_last_account', body.accountId);
  lsSet('bs_last_type', type);
  toast(editing ? t('web_toast_tx_updated') : t('web_toast_tx_added'));
  delete cache.accounts;
  if (txView) { txView.flash = r.id; loadTx(true); }
  else refresh(true);
  if (again) {
    // Keep type, account and date; clear the rest for the next entry.
    $('#f-amount').value = '';
    $('#f-note').value = '';
    $('#f-received').value = '';
    delete f.dataset.dirty;
    $('#f-amount').focus();
    return false;
  }
  return true;
}

async function editTx(id, dup = false) {
  const d = await api(`/api/transactions/${encodeURIComponent(id)}`);
  if (!d) return;
  openTxForm(d, dup ? 'dup' : 'edit');
}

// ── Bulk entry ────────────────────────────────────────────────────────────────
// A grid of expense/income rows saved in one request (all or nothing). Tab
// moves across, Enter goes down (adding a row at the end), Ctrl+Enter saves.
// Pasting spreadsheet rows fills one row per line. The draft survives
// leaving the page (sessionStorage).

const BULK_COLS = ['date', 'type', 'account', 'category', 'note', 'amount'];
let bulk = null;

function bulkLoad() {
  try { const d = JSON.parse(sessionStorage.getItem('bs_bulk') || 'null'); if (Array.isArray(d)) return d; } catch (_) { /* fresh */ }
  return null;
}
function bulkStore() {
  try { sessionStorage.setItem('bs_bulk', JSON.stringify(bulk.rows.filter(r => !bulkBlank(r)).length ? bulk.rows : null)); } catch (_) { /* private mode */ }
}
function bulkBlank(r) { return !String(r.amount || '').trim() && !String(r.note || '').trim(); }

function bulkRow(prev) {
  const lastAcct = lsGet('bs_last_account');
  const accounts = cache.accounts || [];
  return {
    date: prev?.date || dayKey(),
    type: prev?.type || 'expense',
    account: prev?.account || (accounts.some(a => a.id === lastAcct) ? lastAcct : accounts[0]?.id || ''),
    category: '', note: '', amount: '',
  };
}

async function renderBulk() {
  setContent(pageHead(t('web_bulk_title'), '') + skeleton(4));
  const { accounts, categories } = await refs();
  if (state.route !== '#/bulk') return;
  if (!accounts.length) { location.hash = '#/transactions'; toast(t('web_need_account'), true); return; }
  bulk = { accounts, categories, rows: bulkLoad() || [], bad: -1 };
  bulk.rows = bulk.rows.filter(r => accounts.some(a => a.id === r.account));
  if (!bulk.rows.length) bulk.rows.push(bulkRow());
  while (bulk.rows.length < 3) bulk.rows.push(bulkRow(bulk.rows[bulk.rows.length - 1]));

  setContent(`
    <a class="back-link" href="#/transactions">${IC.back}${esc(t('nav_transactions'))}</a>
    ${pageHead(t('web_bulk_title'), esc(t('web_bulk_hint')),
      `<button class="btn btn-ghost" data-action="bulk-clear">${esc(t('web_bulk_clear'))}</button>
       <button class="btn btn-primary" data-action="bulk-save">${IC.check}${esc(t('web_bulk_save'))}</button>`)}
    <div class="card bulk-card">
      <div class="bulk-grid" id="bulk-grid" role="grid">
        <div class="bulk-head" role="row">
          ${[['web_form_date'], ['web_form_type'], ['web_form_account'], ['web_form_category'], ['web_form_title'], ['web_form_amount', 'end']]
            .map(([k, c]) => `<span role="columnheader" class="${c || ''}">${esc(t(k))}</span>`).join('')}<span></span>
        </div>
        <div id="bulk-rows"></div>
      </div>
      <div class="bulk-foot">
        <button class="btn btn-tonal btn-sm" data-action="bulk-add">${IC.plus}${esc(t('web_bulk_add_row'))}</button>
        <span class="bulk-sum" id="bulk-sum"></span>
      </div>
    </div>`);
  drawBulk();
  const grid = document.getElementById('bulk-grid');
  grid.addEventListener('input', bulkInput);
  grid.addEventListener('change', bulkInput);
  grid.addEventListener('keydown', bulkKey);
  grid.addEventListener('paste', bulkPaste);
  grid.querySelector('[data-col="amount"]')?.focus();
}

function bulkCell(r, i, col) {
  const a = `data-row="${i}" data-col="${col}" aria-label="${esc(t({ date: 'web_form_date', type: 'web_form_type', account: 'web_form_account', category: 'web_form_category', note: 'web_form_title', amount: 'web_form_amount' }[col]))}"`;
  switch (col) {
    case 'date': return `<input type="date" class="input" ${a} value="${esc(r.date)}">`;
    case 'type': return `<select class="input" ${a}>${['expense', 'income'].map(k => `<option value="${k}"${r.type === k ? ' selected' : ''}>${esc(t(`type_${k}`))}</option>`).join('')}</select>`;
    case 'account': return `<select class="input" ${a}>${accountOptions(bulk.accounts, r.account)}</select>`;
    case 'category': return `<select class="input" ${a}>${categoryOptions(bulk.categories, r.type, r.category)}</select>`;
    case 'note': return `<input class="input" maxlength="500" ${a} value="${esc(r.note)}" placeholder="${esc(t('web_form_title'))}">`;
    case 'amount': {
      const cur = bulk.accounts.find(x => x.id === r.account)?.currency || '';
      return `<div class="input-cur"><input class="input num" inputmode="decimal" autocomplete="off" placeholder="0" ${a} value="${esc(r.amount)}"><span class="cur">${esc(cur)}</span></div>`;
    }
  }
  return '';
}

function drawBulk(focus) {
  const box = document.getElementById('bulk-rows');
  if (!box) return;
  box.innerHTML = bulk.rows.map((r, i) => `<div class="bulk-row${i === bulk.bad ? ' bad' : ''}" role="row">
    ${BULK_COLS.map(c => `<div class="bulk-cell c-${c}" role="gridcell">${bulkCell(r, i, c)}</div>`).join('')}
    <div class="bulk-cell c-del"><button type="button" class="icon-btn danger" data-action="bulk-del" data-row="${i}" title="${esc(t('web_bulk_remove_row'))}" aria-label="${esc(t('web_bulk_remove_row'))}" tabindex="-1">${IC.trash}</button></div>
  </div>`).join('');
  bulkSummary();
  if (focus) box.querySelector(`[data-row="${focus.row}"][data-col="${focus.col}"]`)?.focus();
}

function bulkSummary() {
  const totals = {};
  let n = 0;
  for (const r of bulk.rows) {
    const v = parseAmount(String(r.amount || ''));
    if (!(v > 0)) continue;
    n++;
    const cur = bulk.accounts.find(x => x.id === r.account)?.currency || state.baseCurrency;
    totals[cur] = (totals[cur] || 0) + (r.type === 'income' ? v : -v);
  }
  const el = document.getElementById('bulk-sum');
  if (el) el.innerHTML = n ? `${esc(t('web_bulk_count', { n }))} · ${Object.entries(totals).map(([c, v]) => `<span class="num ${v < 0 ? 'expense' : 'income'}">${esc(fmt(v, c))}</span>`).join(' · ')}` : '';
}

function bulkInput(e) {
  const el = e.target.closest('[data-col]');
  if (!el) return;
  const i = Number(el.dataset.row), col = el.dataset.col;
  const r = bulk.rows[i];
  if (!r) return;
  r[col] = el.value;
  if (bulk.bad === i) { bulk.bad = -1; el.closest('.bulk-row')?.classList.remove('bad'); }
  if (e.type === 'change' && (col === 'type' || col === 'account')) {
    if (col === 'type') {
      const cat = bulk.categories.find(c => c.id === r.category);
      if (cat && (cat.transactionType === 'income') !== (r.type === 'income')) r.category = '';
    }
    drawBulk({ row: i, col });
  } else bulkSummary();
  bulkStore();
}

function bulkKey(e) {
  const el = e.target.closest('[data-col]');
  if (!el) return;
  if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) { e.preventDefault(); saveBulk(); return; }
  if (e.key !== 'Enter') return;
  e.preventDefault();
  const i = Number(el.dataset.row), col = el.dataset.col;
  if (i === bulk.rows.length - 1) {
    bulk.rows.push(bulkRow(bulk.rows[i]));
    drawBulk({ row: i + 1, col });
  } else {
    document.querySelector(`#bulk-rows [data-row="${i + 1}"][data-col="${col}"]`)?.focus();
  }
}

/** Spreadsheet paste: one row per line; cells are recognised by content. */
function bulkPaste(e) {
  const text = e.clipboardData?.getData('text/plain') || '';
  const lines = text.replace(/\r/g, '').split('\n').filter(l => l.trim());
  if (lines.length < 2 && !text.includes('\t')) return; // a normal single-cell paste
  e.preventDefault();
  const el = e.target.closest('[data-row]');
  let i = el ? Number(el.dataset.row) : bulk.rows.length;
  const norm = s => s.trim().toLowerCase();
  const catByName = new Map(bulk.categories.map(c => [norm(c.name), c]));
  const acctByName = new Map(bulk.accounts.map(a => [norm(a.name), a]));
  let count = 0;
  for (const line of lines) {
    const cells = line.split(line.includes('\t') ? '\t' : /[;,](?=(?:[^"]*"[^"]*")*[^"]*$)/).map(c => c.replace(/^"|"$/g, '').trim());
    const r = bulk.rows[i] && bulkBlank(bulk.rows[i]) ? bulk.rows[i] : null;
    const row = r || bulkRow(bulk.rows[i - 1] || bulk.rows[bulk.rows.length - 1]);
    let amount = null;
    for (const c of cells) {
      if (!c) continue;
      const d = parseLooseDate(c);
      if (d) { row.date = d; continue; }
      const cat = catByName.get(norm(c));
      if (cat) { row.category = cat.id; row.type = cat.transactionType === 'income' ? 'income' : 'expense'; continue; }
      const acct = acctByName.get(norm(c));
      if (acct) { row.account = acct.id; continue; }
      // A number, maybe with a currency symbol/code: "-12.50", "$1,200", "(5) EUR".
      const bare = c.replace(/\p{Sc}|\b[A-Z]{3}\b|\s/gu, '');
      if (amount == null && /^[-+(]?[\d.,]*\d[\d.,]*\)?$/.test(bare)) {
        const v = parseAmount(bare.replace(/[-+()]/g, ''));
        if (v > 0) { amount = v; if (/^[-(]/.test(bare)) row.type = 'expense'; continue; }
      }
      if (!row.note) row.note = c;
    }
    if (amount == null && !row.note) continue;
    if (amount != null) row.amount = amountInputValue(amount, bulk.accounts.find(a => a.id === row.account)?.currency);
    if (!r) bulk.rows.splice(i, 0, row);
    i++;
    count++;
  }
  if (!count) return;
  while (bulk.rows.length > i && bulk.rows.length > 3 && bulkBlank(bulk.rows[bulk.rows.length - 1]) && bulkBlank(bulk.rows[bulk.rows.length - 2])) bulk.rows.pop();
  if (!bulk.rows.length || !bulkBlank(bulk.rows[bulk.rows.length - 1])) bulk.rows.push(bulkRow(bulk.rows[bulk.rows.length - 1]));
  drawBulk({ row: Math.min(i, bulk.rows.length - 1), col: 'amount' });
  bulkStore();
  toast(t('web_bulk_pasted', { n: count }));
}

/** 2026-09-03, 03/09/2026, 3.9.26 → YYYY-MM-DD (day first unless that's impossible or the browser is US). */
function parseLooseDate(s) {
  let m = s.match(/^(\d{4})-(\d{1,2})-(\d{1,2})$/);
  if (m) return dayKey(new Date(+m[1], +m[2] - 1, +m[3]));
  m = s.match(/^(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{2}|\d{4})$/);
  if (!m) return null;
  let a = +m[1], b = +m[2];
  const y = m[3].length === 2 ? 2000 + +m[3] : +m[3];
  const us = (navigator.language || '').toLowerCase() === 'en-us';
  let day = a, mon = b;
  if (b > 12 || (us && a <= 12)) { day = b; mon = a; }
  if (mon < 1 || mon > 12 || day < 1 || day > 31) return null;
  return dayKey(new Date(y, mon - 1, day));
}

async function saveBulk() {
  if (!bulk) return;
  const items = [], index = [];
  for (let i = 0; i < bulk.rows.length; i++) {
    const r = bulk.rows[i];
    if (bulkBlank(r)) continue;
    const amount = parseAmount(String(r.amount || ''));
    if (!(amount > 0) || !r.account) { bulkBad(i); toast(t('web_bulk_row_bad', { n: i + 1 }), true); return; }
    const cur = bulk.accounts.find(a => a.id === r.account)?.currency;
    items.push({ type: r.type, accountId: r.account, amount, currency: cur, categoryId: r.category || null, note: String(r.note || '').trim(), date: r.date || dayKey() });
    index.push(i);
  }
  if (!items.length) { toast(t('web_bulk_empty'), true); return; }
  const btn = document.querySelector('[data-action="bulk-save"]');
  if (btn) btn.disabled = true;
  const res = await fetch('/api/transactions/bulk', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${state.token}` },
    body: JSON.stringify({ items }),
  }).catch(() => null);
  if (btn) btn.disabled = false;
  if (!res) { setConnection(false); toast(t('web_offline_short'), true); return; }
  if (res.status === 401) { sessionExpired(); return; }
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    if (Number.isInteger(data.row)) {
      bulkBad(index[data.row]);
      const msg = /exchange rate/i.test(data.error || '') ? t('web_err_no_rate') : LOCALE === 'en' && data.error ? data.error : '';
      toast(`${t('web_bulk_row_bad', { n: index[data.row] + 1 })}${msg ? ` · ${msg}` : ''}`, true);
    } else toast(res.status === 429 ? t('web_err_too_many') : t('web_err_request'), true);
    return;
  }
  lsSet('bs_last_account', items[items.length - 1].accountId);
  try { sessionStorage.removeItem('bs_bulk'); } catch (_) { /* private mode */ }
  bulk = null;
  invalidate();
  toast(t('web_bulk_saved', { n: data.count || items.length }));
  location.hash = '#/transactions';
}

function bulkBad(i) {
  bulk.bad = i;
  drawBulk({ row: i, col: 'amount' });
}

// ── Accounts ──────────────────────────────────────────────────────────────────

async function renderAccounts(quiet) {
  if (!quiet) setContent(pageHead(t('nav_accounts'), '') + skeleton(5));
  const d = await api('/api/accounts');
  if (!d || state.route !== '#/accounts') return;
  cache.accounts = d.items || [];
  const add = `<button class="btn btn-primary" data-action="add-account">${IC.plus}${esc(t('web_acct_add'))}</button>`;
  if (!cache.accounts.length) {
    setContent(pageHead(t('nav_accounts'), '', add) + `<div class="card">${emptyState(IC.wallet, t('web_acct_empty_title'), t('web_acct_empty_sub'), { action: 'add-account', label: t('web_acct_add') })}</div>`);
    return;
  }
  const worth = {};
  cache.accounts.forEach(a => { worth[a.currency] = (worth[a.currency] || 0) + a.balance; });
  const order = ['bank', 'cash', 'credit', 'wallet'];
  const groups = {};
  cache.accounts.forEach(a => { (groups[order.includes(a.type) ? a.type : 'wallet'] ||= []).push(a); });

  setContent(`
    ${pageHead(t('nav_accounts'), '', add)}
    <div class="stats">${Object.entries(worth).map(([c, v]) => `
      <div class="card stat"><div class="label">${esc(t('web_net_worth_cur', { cur: c }))}</div><div class="value num${v < 0 ? ' expense' : ''}">${esc(fmt(v, c))}</div></div>`).join('')}</div>
    ${order.filter(k => groups[k]).map(k => `
      <div class="section-head"><span class="section-title">${esc(t(`web_acct_group_${k}`))}</span></div>
      <div class="card card-flush list">${groups[k].map(a => `
        <a class="row clickable" href="#/accounts/${esc(a.id)}">
          <span class="type-icon">${a.isTravel ? IC.plane : TYPE_ICON[a.type] || IC.wallet}</span>
          <div class="row-main"><div class="row-title">${esc(a.name)}</div><div class="row-sub">${esc(a.currency)}${a.isTravel ? ` · ${esc(t('web_acct_travel'))}` : ''}</div></div>
          <div class="row-end"><div class="row-amount${a.balance < 0 ? ' expense' : ''}">${esc(fmt(a.balance, a.currency))}</div></div>
          <span class="chev hint" style="display:inline-grid">${IC.right}</span>
        </a>`).join('')}</div>`).join('')}`);
}

function openAddAccount() {
  const currencies = [...new Set([state.baseCurrency, ...(cache.accounts || []).map(a => a.currency)])];
  openModal({
    title: t('web_acct_new'),
    submit: t('web_acct_add'),
    body: `
      <div class="field"><label class="label" for="a-name">${esc(t('web_form_name'))}</label><input id="a-name" class="input" maxlength="100" placeholder="${esc(t('web_acct_name_hint'))}" autofocus></div>
      <div class="field"><label class="label">${esc(t('web_form_type'))}</label><div class="seg full" id="a-type">
        ${['bank', 'cash', 'credit', 'wallet'].map((k, i) => `<button type="button" data-type="${k}" class="${i === 0 ? 'active' : ''}">${esc(t(`web_acct_type_${k}`))}</button>`).join('')}
      </div></div>
      <div class="field-row">
        <div class="field"><label class="label" for="a-cur">${esc(t('web_form_currency'))}</label>
          <input id="a-cur" class="input" maxlength="3" list="a-cur-list" value="${esc(state.baseCurrency)}" style="text-transform:uppercase" autocomplete="off">
          <datalist id="a-cur-list">${currencies.concat(['USD', 'EUR', 'GBP', 'LBP', 'AED', 'SAR', 'EGP', 'TRY', 'CAD', 'AUD', 'JPY', 'CHF', 'INR', 'BRL']).filter((c, i, l) => l.indexOf(c) === i).map(c => `<option value="${esc(c)}">`).join('')}</datalist></div>
        <div class="field"><label class="label" for="a-bal">${esc(t('web_acct_opening'))}</label><input id="a-bal" class="input num" inputmode="decimal" placeholder="0" autocomplete="off">
          <div class="help">${esc(t('web_acct_opening_hint'))}</div></div>
      </div>`,
    onOpen: f => f.querySelector('#a-type').addEventListener('click', e => {
      const b = e.target.closest('[data-type]'); if (!b) return;
      f.querySelectorAll('#a-type button').forEach(x => x.classList.toggle('active', x === b));
    }),
    onSubmit: async f => {
      const name = f.querySelector('#a-name').value.trim();
      const currency = f.querySelector('#a-cur').value.trim().toUpperCase();
      if (!name) { toast(t('web_val_name_required'), true); return false; }
      if (!/^[A-Z]{3}$/.test(currency)) { toast(t('web_val_currency'), true); return false; }
      const raw = f.querySelector('#a-bal').value.trim();
      const initialBalance = raw ? parseAmount(raw) : 0;
      if (!Number.isFinite(initialBalance)) { toast(t('web_val_valid_amount'), true); return false; }
      const type = f.querySelector('#a-type .active').dataset.type;
      const r = await api('/api/accounts', { method: 'POST', body: { name, type, currency, initialBalance } });
      if (!r) return false;
      toast(t('web_toast_acct_added'));
      refresh(true);
      return true;
    },
  });
}

// ── Categories ────────────────────────────────────────────────────────────────

const CAT_COLORS = ['#6366F1', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6', '#06B6D4', '#EC4899', '#F97316', '#14B8A6', '#64748B',
  '#84CC16', '#78716C', '#D946EF', '#0EA5E9', '#E11D48', '#22C55E', '#EAB308', '#3B82F6', '#9333EA', '#90A4AE'];
let catType = 'expense';

async function renderCategories(quiet) {
  if (!quiet) setContent(pageHead(t('nav_categories'), '') + skeleton(6));
  const d = await api('/api/categories');
  if (!d || state.route !== '#/categories') return;
  cache.categories = d.items || [];
  const all = cache.categories;
  const ofType = all.filter(c => (catType === 'income') === (c.transactionType === 'income'));
  const ids = new Set(ofType.map(c => c.id));
  const roots = ofType.filter(c => !c.parentId || !ids.has(c.parentId));
  const kids = id => ofType.filter(c => c.parentId === id);

  const cards = roots.map(r => {
    const children = kids(r.id);
    return `<div class="card cat-card">
      <div class="row clickable" data-action="edit-cat" data-id="${esc(r.id)}" tabindex="0">
        ${catChip(r)}
        <div class="row-main"><div class="row-title">${esc(r.name)}</div>
          <div class="row-sub">${children.length ? esc(t('web_cat_subs', { n: children.length })) : esc(t('web_cat_no_subs'))}</div></div>
        <span class="icon-btn" aria-hidden="true">${IC.edit}</span>
      </div>
      ${children.length ? `<div class="cat-children">${children.map(c => `
        <div class="row clickable" data-action="edit-cat" data-id="${esc(c.id)}" tabindex="0">${catChip(c, 'sm')}<div class="row-main"><div class="row-title" style="font-weight:600">${esc(c.name)}</div></div></div>`).join('')}</div>` : ''}
    </div>`;
  }).join('');

  setContent(`
    ${pageHead(t('nav_categories'), '', `<button class="btn btn-primary" data-action="add-cat">${IC.plus}${esc(t('web_cat_add'))}</button>`)}
    <div class="toolbar"><div class="seg" id="cat-type">
      <button type="button" data-type="expense" class="${catType === 'expense' ? 'active' : ''}">${esc(t('type_expense'))}</button>
      <button type="button" data-type="income" class="${catType === 'income' ? 'active' : ''}">${esc(t('type_income'))}</button>
    </div></div>
    ${roots.length ? `<div class="grid-auto">${cards}</div>` : `<div class="card">${emptyState(IC.tag, t('web_cat_empty_title'), t('web_cat_empty_sub'), { action: 'add-cat', label: t('web_cat_add') })}</div>`}`);
  document.getElementById('cat-type').addEventListener('click', e => {
    const b = e.target.closest('[data-type]'); if (!b) return;
    catType = b.dataset.type;
    renderCategories(true);
  });
}

function openCategoryForm(c = null) {
  const all = cache.categories || [];
  const hasKids = c && all.some(x => x.parentId === c.id);
  let type = c?.transactionType === 'income' ? 'income' : c ? 'expense' : catType;
  let color = c?.colorHex ? safeHex(c.colorHex) : CAT_COLORS[0];
  const parents = tp => all.filter(x => !x.parentId && x.id !== c?.id && (tp === 'income') === (x.transactionType === 'income'));
  const parentOpts = tp => `<option value="">${esc(t('web_cat_top_level'))}</option>` + parents(tp)
    .map(p => `<option value="${esc(p.id)}"${p.id === c?.parentId ? ' selected' : ''}>${esc((isEmoji(p.icon) ? p.icon + '  ' : '') + p.name)}</option>`).join('');

  openModal({
    title: c ? t('web_cat_edit') : t('web_cat_new'),
    submit: c ? t('common_save') : t('web_cat_add'),
    body: `
      <div class="field" style="display:flex;justify-content:center"><span id="c-preview"></span></div>
      <div class="field"><label class="label" for="c-name">${esc(t('web_form_name'))}</label><input id="c-name" class="input" maxlength="100" value="${esc(c?.name || '')}" placeholder="${esc(t('web_cat_name_hint'))}" autofocus></div>
      <div class="field"><div class="seg full" id="c-type">
        <button type="button" data-type="expense" class="${type === 'expense' ? 'active' : ''}">${esc(t('type_expense'))}</button>
        <button type="button" data-type="income" class="${type === 'income' ? 'active' : ''}">${esc(t('type_income'))}</button>
      </div></div>
      <div class="field-row">
        <div class="field"><label class="label" for="c-parent">${esc(t('web_cat_parent'))}</label><select id="c-parent" class="input" ${hasKids ? 'disabled' : ''}>${parentOpts(type)}</select>
          ${hasKids ? `<div class="help">${esc(t('web_cat_parent_locked'))}</div>` : ''}</div>
        <div class="field" style="max-width:130px"><label class="label" for="c-icon">${esc(t('web_cat_icon'))}</label><input id="c-icon" class="input" maxlength="8" value="${esc(isEmoji(c?.icon) ? c.icon : '')}" placeholder="🛒" style="text-align:center;font-size:20px"></div>
      </div>
      <div class="field"><label class="label">${esc(t('web_cat_color'))}</label><div class="swatches" id="c-colors">
        ${CAT_COLORS.map(x => `<button type="button" class="swatch${x.toLowerCase() === color.toLowerCase() ? ' active' : ''}" data-color="${x}" style="background:${x}" aria-label="${x}"></button>`).join('')}
        <label class="swatch swatch-custom" title="${esc(t('web_cat_custom_color'))}"><input type="color" id="c-custom" value="${esc(color)}"></label>
      </div></div>`,
    onOpen: f => {
      const preview = () => {
        const icon = f.querySelector('#c-icon').value.trim();
        // The app's PNG icon stays while the emoji is the one it was saved with.
        const iconFile = c?.iconFile && (icon === (isEmoji(c.icon) ? c.icon : '')) ? c.iconFile : null;
        f.querySelector('#c-preview').innerHTML = catChip({ name: f.querySelector('#c-name').value || '?', icon, colorHex: color, iconFile }, 'lg');
      };
      f.querySelector('#c-type').addEventListener('click', e => {
        const b = e.target.closest('[data-type]'); if (!b) return;
        type = b.dataset.type;
        f.querySelectorAll('#c-type button').forEach(x => x.classList.toggle('active', x === b));
        f.querySelector('#c-parent').innerHTML = parentOpts(type);
      });
      f.querySelector('#c-colors').addEventListener('click', e => {
        const b = e.target.closest('[data-color]'); if (!b) return;
        color = b.dataset.color;
        f.querySelectorAll('.swatch').forEach(x => x.classList.toggle('active', x === b));
        preview();
      });
      f.querySelector('#c-custom').addEventListener('input', e => {
        color = e.target.value;
        f.querySelectorAll('.swatch').forEach(x => x.classList.remove('active'));
        preview();
      });
      f.querySelector('#c-name').addEventListener('input', preview);
      f.querySelector('#c-icon').addEventListener('input', preview);
      preview();
    },
    onSubmit: async f => {
      const name = f.querySelector('#c-name').value.trim();
      if (!name) { toast(t('web_val_name_required'), true); return false; }
      const icon = f.querySelector('#c-icon').value.trim();
      const body = { name, colorHex: color, transactionType: type };
      if (icon) body.icon = icon; else if (!c) body.icon = 'category';
      if (!hasKids) body.parentId = f.querySelector('#c-parent').value || null;
      const r = c
        ? await api(`/api/categories/${encodeURIComponent(c.id)}`, { method: 'PUT', body })
        : await api('/api/categories', { method: 'POST', body });
      if (!r) return false;
      toast(c ? t('web_toast_cat_updated') : t('web_toast_cat_added'));
      catType = type;
      refresh(true);
      return true;
    },
  });
}

// ── Goals & loans ─────────────────────────────────────────────────────────────

/** What a goal/loan card shows: goals count up, loans show what's still owed. */
function goalFigures(o) {
  const cur = o.targetCurrency;
  const paid = Number(o.currentAmount) || 0;
  const target = Number(o.targetAmount) || 0;
  const loan = o.type === 'loan';
  const left = Math.max(0, target - paid);
  const done = target > 0 && paid >= target - 0.004;
  const pct = target > 0 ? Math.max(0, Math.min(100, (paid / target) * 100)) : null;
  return {
    cur, paid, target, loan, left, done, pct,
    big: loan ? left : paid,
    label: loan ? (o.direction === 'borrowed' ? t('web_goal_you_owe') : t('web_goal_owed_to_you')) : t('web_goal_saved'),
    sub: loan ? (o.direction === 'borrowed' ? t('web_goal_borrowed_from', { name: o.contactName || '—' }) : t('web_goal_lent_to', { name: o.contactName || '—' }))
      : o.endDate ? t('web_goal_due', { date: fmtDate(o.endDate, true) }) : t('web_goal_kind_goal'),
    meta: done ? (loan ? t('web_goal_paid_off') : t('web_env_reached'))
      : loan ? t('web_goal_paid_back', { amount: fmt(paid, cur) })
      : target > 0 ? t('web_env_to_go', { amount: fmt(left, cur) }) : '',
    metaEnd: target > 0 ? t('web_env_of', { amount: fmt(target, cur) }) : '',
    payLabel: loan ? (o.direction === 'borrowed' ? t('web_goal_pay_sent') : t('web_goal_pay_received')) : t('web_goal_add_funds'),
  };
}

function goalChip(o, cls = '') {
  const color = safeHex(o.colorHex);
  const inner = isEmoji(o.icon) ? esc(o.icon) : `<span style="color:${pastelInk(color)}">${esc((o.name || '?').charAt(0).toUpperCase())}</span>`;
  return `<span class="chip-icon ${cls}" style="background:${pastel(color)}">${inner}</span>`;
}

async function renderGoals(quiet) {
  const head = actions => pageHead(t('web_nav_goals'), esc(t('web_goals_sub')), actions);
  if (!quiet) setContent(head('') + skeleton(4));
  const d = await api('/api/objectives');
  if (!d || state.route !== '#/goals') return;
  cache.goals = d.items || [];
  const add = `<button class="btn btn-primary" data-action="add-goal">${IC.plus}${esc(t('web_goal_new'))}</button>`;
  if (!cache.goals.length) {
    setContent(head(add) + `<div class="card">${emptyState(IC.target, t('web_goals_empty_title'), t('web_goals_empty_sub'), { action: 'add-goal', label: t('web_goal_new') })}</div>`);
    return;
  }
  const card = o => {
    const f = goalFigures(o);
    return `<div class="card env-card clickable" data-action="open-goal" data-id="${esc(o.id)}" tabindex="0" role="button">
      <div class="env-top">${goalChip(o)}
        <div class="row-main"><div class="env-name">${esc(o.name)}</div><div class="env-kind">${esc(f.sub)}</div></div>
      </div>
      <div><div class="env-amount num">${esc(fmt(f.big, f.cur))}</div><div class="env-kind">${esc(f.label)}</div></div>
      ${f.pct != null ? `<div class="bar"><span style="width:${f.pct.toFixed(1)}%;background:${f.done ? 'var(--income)' : safeHex(o.colorHex)}"></span></div>` : ''}
      ${f.meta || f.metaEnd ? `<div class="env-meta"><span>${esc(f.meta)}</span><span>${esc(f.metaEnd)}</span></div>` : ''}
      <div class="env-foot">
        <span class="env-kind">${o.monthlyPace ? esc(t('web_goal_per_month', { amount: fmt(o.monthlyPace, f.cur) })) : ''}</span>
        ${f.done && f.loan ? '' : `<button class="btn btn-sm btn-tonal" data-action="pay-goal" data-id="${esc(o.id)}">${IC.plus}${esc(f.payLabel)}</button>`}
      </div>
    </div>`;
  };
  const goals = cache.goals.filter(o => o.type !== 'loan');
  const loans = cache.goals.filter(o => o.type === 'loan');
  const section = (title, list) => list.length ? `<div class="section-head"><span class="section-title">${esc(title)}</span></div><div class="grid-auto">${list.map(card).join('')}</div>` : '';
  setContent(head(add) + section(t('web_goals_section'), goals) + section(t('web_loans_section'), loans));
}

async function openGoal(id) {
  const o = await api(`/api/objectives/${encodeURIComponent(id)}`);
  if (!o) return;
  const f = goalFigures(o);
  const stat = (label, value) => value ? `<div class="stat"><div class="stat-label">${esc(label)}</div><div class="stat-value num">${esc(value)}</div></div>` : '';
  openModal({
    title: o.name,
    submit: f.done && f.loan ? null : f.payLabel,
    extra: { label: t('web_goal_edit'), run: () => openGoalForm(o) },
    body: `
      <div class="goal-hero">${goalChip(o, 'lg')}
        <div><div class="env-amount num">${esc(fmt(f.big, f.cur))}</div><div class="env-kind">${esc(f.label)} · ${esc(f.sub)}</div></div>
      </div>
      ${f.pct != null ? `<div class="bar" style="margin:14px 0 6px"><span style="width:${f.pct.toFixed(1)}%;background:${f.done ? 'var(--income)' : safeHex(o.colorHex)}"></span></div>
        <div class="env-meta"><span>${esc(f.meta)}</span><span>${esc(f.metaEnd)}</span></div>` : ''}
      <div class="goal-stats">
        ${stat(f.loan ? t('web_goal_paid_back_label') : t('web_goal_saved'), fmt(f.paid, f.cur))}
        ${f.target > 0 ? stat(t('web_goal_remaining'), fmt(f.left, f.cur)) : ''}
        ${o.monthlyPace ? stat(t('web_goal_per_month_label'), fmt(o.monthlyPace, f.cur)) : ''}
        ${o.endDate ? stat(t('web_goal_deadline'), fmtDate(o.endDate, true)) : ''}
      </div>
      <div class="label" style="margin-top:16px">${esc(t('web_goal_payments'))}</div>
      ${o.payments?.length ? `<div class="lines-box">${o.payments.map(p => `
        <div class="row"><div class="row-main"><div class="row-title">${esc(fmtDate(p.date, true))}</div><div class="row-sub">${esc([p.accountName, p.note].filter(Boolean).join(' · '))}</div></div>
        <div class="row-amount num ${p.type === 'income' ? 'income' : ''}">${esc(fmt(p.amount, f.cur))}</div></div>`).join('')}</div>`
        : `<p class="help">${esc(t('web_goal_no_payments'))}</p>`}`,
    onSubmit: () => { openPayGoal(o); return false; },
  });
}

async function openPayGoal(o) {
  const { accounts, categories } = await refs();
  if (!accounts.length) { toast(t('web_need_account'), true); return; }
  const f = goalFigures(o);
  const txType = f.loan && o.direction !== 'borrowed' ? 'income' : 'expense';
  const lastAcct = lsGet(`bs_goal_acct_${o.id}`) || lsGet('bs_last_account');
  const acctId = (accounts.find(a => a.id === lastAcct && a.currency === o.targetCurrency) || accounts.find(a => a.currency === o.targetCurrency) || accounts.find(a => a.id === lastAcct) || accounts[0]).id;
  const lastCat = lsGet(`bs_goal_cat_${o.id}`) || '';
  openModal({
    title: `${f.payLabel} · ${o.name}`,
    submit: f.payLabel,
    body: `
      <div class="field">
        <label class="label" for="g-amount">${esc(t('web_form_amount'))}</label>
        <div class="input-cur"><input id="g-amount" class="input amount num" inputmode="decimal" autocomplete="off" placeholder="0" autofocus><span class="cur">${esc(f.cur)}</span></div>
        ${f.left > 0 ? `<div class="chips"><button type="button" class="pill" data-fill="${f.left}">${esc(f.loan ? t('web_goal_fill_rest') : t('web_fund_to_target'))}</button></div>` : ''}
      </div>
      <div class="field-row">
        <div class="field"><label class="label" for="g-account">${esc(txType === 'income' ? t('web_goal_into_account') : t('web_goal_from_account'))}</label><select id="g-account" class="input">${accountOptions(accounts, acctId)}</select>
          <div class="help" id="g-conv"></div></div>
        <div class="field"><label class="label" for="g-cat">${esc(t('web_form_category'))}</label><select id="g-cat" class="input">${categoryOptions(categories, txType, lastCat)}</select></div>
      </div>
      <div class="field"><label class="label" for="g-date">${esc(t('web_form_date'))}</label><input id="g-date" type="date" class="input" value="${esc(dayKey())}" max="${esc(dayKey())}"></div>`,
    onOpen: form => {
      const conv = () => {
        const a = accounts.find(x => x.id === form.querySelector('#g-account').value);
        form.querySelector('#g-conv').textContent = a && a.currency !== o.targetCurrency ? t('web_goal_converted', { cur: a.currency }) : '';
      };
      form.querySelector('#g-account').addEventListener('change', conv);
      form.querySelectorAll('[data-fill]').forEach(b => b.addEventListener('click', () => {
        form.querySelector('#g-amount').value = amountInputValue(Number(b.dataset.fill), f.cur);
      }));
      conv();
    },
    onSubmit: async form => {
      const amount = parseAmount(form.querySelector('#g-amount').value);
      if (!(amount > 0)) { toast(t('web_val_valid_amount'), true); return false; }
      const accountId = form.querySelector('#g-account').value;
      const categoryId = form.querySelector('#g-cat').value || null;
      const r = await api(`/api/objectives/${encodeURIComponent(o.id)}/pay`, { method: 'POST', body: { accountId, categoryId, amount, date: form.querySelector('#g-date').value || dayKey() } });
      if (!r) return false;
      lsSet(`bs_goal_acct_${o.id}`, accountId);
      lsSet(`bs_goal_cat_${o.id}`, categoryId || '');
      toast(t('web_toast_goal_paid'));
      invalidate();
      closeModal();
      refresh(true);
      return true;
    },
  });
}

async function openGoalForm(o = null) {
  const { accounts } = await refs();
  let type = o?.type || 'goal';
  let dir = o?.direction || 'lent';
  let color = o?.colorHex ? safeHex(o.colorHex) : CAT_COLORS[0];
  const currencies = [...new Set([o?.targetCurrency, state.baseCurrency, ...accounts.map(a => a.currency)].filter(Boolean))];
  openModal({
    title: o ? t('web_goal_edit') : t('web_goal_new'),
    submit: o ? t('common_save') : t('web_goal_create'),
    extra: o ? { label: t('common_delete'), run: () => deleteGoal(o) } : null,
    body: `
      ${o ? '' : `<div class="field"><div class="seg full" id="g-type">
        <button type="button" data-type="goal" class="${type === 'goal' ? 'active' : ''}">${esc(t('web_goal_kind_goal'))}</button>
        <button type="button" data-type="loan" class="${type === 'loan' ? 'active' : ''}">${esc(t('web_goal_kind_loan'))}</button>
      </div><div class="help" id="g-type-help"></div></div>`}
      <div class="field-row">
        <div class="field"><label class="label" for="g-name">${esc(t('web_form_name'))}</label><input id="g-name" class="input" maxlength="100" value="${esc(o?.name || '')}" autofocus></div>
        <div class="field" style="max-width:110px"><label class="label" for="g-icon">${esc(t('web_cat_icon'))}</label><input id="g-icon" class="input" maxlength="8" value="${esc(isEmoji(o?.icon) ? o.icon : '')}" placeholder="🎯" style="text-align:center;font-size:20px"></div>
      </div>
      <div id="g-loan">
        <div class="field"><div class="seg full" id="g-dir">
          <button type="button" data-dir="lent" class="${dir === 'lent' ? 'active' : ''}">${esc(t('web_goal_lent_choice'))}</button>
          <button type="button" data-dir="borrowed" class="${dir === 'borrowed' ? 'active' : ''}">${esc(t('web_goal_borrowed_choice'))}</button>
        </div><div class="help" id="g-dir-help"></div></div>
        <div class="field"><label class="label" for="g-person">${esc(t('web_goal_person'))}</label><input id="g-person" class="input" maxlength="100" value="${esc(o?.contactName || '')}"></div>
      </div>
      <div class="field-row">
        <div class="field" style="flex:2"><label class="label" for="g-target" id="g-target-label"></label><input id="g-target" class="input num" inputmode="decimal" autocomplete="off" value="${o?.targetAmount ? esc(amountInputValue(o.targetAmount, o.targetCurrency)) : ''}" placeholder="${esc(t('web_form_optional'))}"></div>
        <div class="field"><label class="label" for="g-cur">${esc(t('web_form_currency'))}</label><select id="g-cur" class="input" ${o?.paymentCount ? 'disabled' : ''}>${currencies.map(c => `<option${c === (o?.targetCurrency || state.baseCurrency) ? ' selected' : ''}>${esc(c)}</option>`).join('')}</select></div>
      </div>
      <div class="field"><label class="label" for="g-end" id="g-end-label"></label><input id="g-end" type="date" class="input" value="${o?.endDate ? esc(dayKey(o.endDate)) : ''}"></div>
      <div class="field"><label class="label">${esc(t('web_cat_color'))}</label><div class="swatches" id="g-colors">
        ${CAT_COLORS.map(x => `<button type="button" class="swatch${x.toLowerCase() === color.toLowerCase() ? ' active' : ''}" data-color="${x}" style="background:${x}" aria-label="${x}"></button>`).join('')}
      </div></div>`,
    onOpen: f => {
      const sync = () => {
        const loan = type === 'loan';
        f.querySelector('#g-loan').classList.toggle('hidden', !loan);
        f.querySelector('#g-target-label').textContent = loan ? t('web_goal_loan_amount') : t('web_goal_target');
        f.querySelector('#g-end-label').textContent = loan ? t('web_goal_due_by') : t('web_goal_deadline_opt');
        const th = f.querySelector('#g-type-help');
        if (th) th.textContent = loan ? t('web_goal_what_loan') : t('web_goal_what_goal');
        f.querySelector('#g-dir-help').textContent = dir === 'lent' ? t('web_goal_lent_hint') : t('web_goal_borrowed_hint');
        f.querySelectorAll('#g-type button').forEach(b => b.classList.toggle('active', b.dataset.type === type));
        f.querySelectorAll('#g-dir button').forEach(b => b.classList.toggle('active', b.dataset.dir === dir));
      };
      f.querySelector('#g-type')?.addEventListener('click', e => { const b = e.target.closest('[data-type]'); if (b) { type = b.dataset.type; sync(); } });
      f.querySelector('#g-dir').addEventListener('click', e => { const b = e.target.closest('[data-dir]'); if (b) { dir = b.dataset.dir; sync(); } });
      f.querySelector('#g-colors').addEventListener('click', e => {
        const b = e.target.closest('[data-color]'); if (!b) return;
        color = b.dataset.color;
        f.querySelectorAll('#g-colors .swatch').forEach(x => x.classList.toggle('active', x === b));
      });
      sync();
    },
    onSubmit: async f => {
      const name = f.querySelector('#g-name').value.trim();
      if (!name) { toast(t('web_val_name_required'), true); return false; }
      const rawTarget = f.querySelector('#g-target').value.trim();
      const target = rawTarget ? parseAmount(rawTarget) : 0;
      if (!(target >= 0)) { toast(t('web_val_valid_amount'), true); return false; }
      if (type === 'loan' && !(target > 0)) { toast(t('web_val_valid_amount'), true); f.querySelector('#g-target').focus(); return false; }
      const body = {
        type, name, targetAmount: target, colorHex: color,
        targetCurrency: f.querySelector('#g-cur').value,
        endDate: f.querySelector('#g-end').value || null,
        icon: f.querySelector('#g-icon').value.trim(),
      };
      if (type === 'loan') { body.direction = dir; body.contactName = f.querySelector('#g-person').value.trim(); }
      const r = o
        ? await api(`/api/objectives/${encodeURIComponent(o.id)}`, { method: 'PUT', body })
        : await api('/api/objectives', { method: 'POST', body });
      if (!r) return false;
      toast(o ? t('web_toast_goal_updated') : t('web_toast_goal_added'));
      closeModal();
      refresh(true);
      return true;
    },
  });
}

/** Delete; with payments, choose whether they go too (money returns to the accounts). */
function deleteGoal(o) {
  const del = async payments => {
    const r = await api(`/api/objectives/${encodeURIComponent(o.id)}?payments=${payments}`, { method: 'DELETE' });
    if (!r) return false;
    toast(t('web_toast_goal_deleted'));
    invalidate();
    closeModal();
    refresh(true);
    return true;
  };
  if (!o.paymentCount) {
    confirmDialog(t('web_goal_delete_title', { name: o.name }), t('web_goal_delete_msg')).then(ok => ok && del('keep'));
    return;
  }
  openModal({
    title: t('web_goal_delete_title', { name: o.name }), narrow: true, danger: true,
    submit: t('web_goal_delete_all'),
    extra: { label: t('web_goal_delete_keep'), run: () => del('keep') },
    body: `<p class="modal-text">${esc(t('web_goal_delete_payments', { n: o.paymentCount }))}</p>`,
    onSubmit: () => del('delete'),
  });
}

// ── Recurring & subscriptions ─────────────────────────────────────────────────

async function renderRecurring(subs, quiet) {
  const route = subs ? '#/subscriptions' : '#/recurring';
  const title = subs ? t('nav_subscriptions') : t('nav_recurring');
  if (!quiet) setContent(pageHead(title, '') + skeleton(5));
  const [d] = await Promise.all([api(subs ? '/api/subscriptions' : '/api/recurring'), refs()]);
  if (!d || state.route !== route) return;
  const items = d.items || [];
  cache[subs ? 'subs' : 'recurring'] = items;

  const addAction = subs ? 'add-sub' : 'add-rec';
  const actions = `${items.length ? `<button class="btn btn-ghost" data-action="export-rec" data-subs="${subs ? 1 : 0}">${IC.download}${esc(t('web_csv'))}</button>` : ''}
    <button class="btn btn-primary" data-action="${addAction}">${IC.plus}${esc(subs ? t('web_sub_add') : t('web_rec_add'))}</button>`;

  if (!items.length) {
    setContent(pageHead(title, '', actions) + `<div class="card">${emptyState(subs ? IC.receipt : IC.repeat,
      subs ? t('web_sub_empty') : t('web_rec_empty'), subs ? t('web_sub_empty_sub') : t('web_rec_empty_sub'),
      { action: addAction, label: subs ? t('web_sub_add') : t('web_rec_add') })}</div>`);
    return;
  }

  // Subscriptions: what they cost per month and per year, per currency.
  let summary = '';
  if (subs) {
    const monthly = {};
    items.filter(r => r.enabled).forEach(r => { monthly[r.currency] = (monthly[r.currency] || 0) + perMonth(r); });
    summary = `<div class="stats">${Object.entries(monthly).map(([c, v]) => `
      <div class="card stat"><div class="label">${esc(t('web_sub_monthly'))}</div><div class="value num">${esc(fmt(v, c))}</div><div class="help">${esc(t('web_sub_yearly', { amount: fmt(v * 12, c) }))}</div></div>`).join('')}</div>`;
  }

  const row = r => {
    const isT = r.type === 'transfer';
    const arrow = document.documentElement.dir === 'rtl' ? '←' : '→';
    const sub = [freqLabel(r.frequency, r.interval), t('web_rec_next', { date: fmtDate(r.nextDueDate) }),
      isT ? `${r.accountName || ''} ${arrow} ${r.destinationAccountName || ''}` : r.accountName].filter(Boolean).join(' · ');
    const cls = r.type === 'income' ? 'income' : r.type === 'expense' ? 'expense' : '';
    return `<div class="row clickable${r.enabled ? '' : ' dim'}" data-action="edit-rec" data-id="${esc(r.id)}" data-subs="${subs ? 1 : 0}" tabindex="0">
      ${isT ? transferChip() : catChip(r)}
      <div class="row-main"><div class="row-title">${esc(r.title || r.categoryName || t(`type_${r.type}`))}</div><div class="row-sub">${esc(sub)}</div></div>
      <div class="row-actions"><button class="icon-btn danger" data-action="del-rec" data-id="${esc(r.id)}" data-subs="${subs ? 1 : 0}" aria-label="${esc(t('common_delete'))}" title="${esc(t('common_delete'))}">${IC.trash}</button></div>
      <div class="row-end"><div class="row-amount ${cls}">${esc(fmtSigned(r.amount, r.currency, r.type))}</div></div>
      <label class="toggle" title="${esc(r.enabled ? t('web_rec_on') : t('web_rec_off'))}" data-stop><input type="checkbox" data-action="toggle-rec" data-id="${esc(r.id)}" data-subs="${subs ? 1 : 0}" ${r.enabled ? 'checked' : ''} aria-label="${esc(t('web_rec_on'))}"><span></span></label>
    </div>`;
  };

  const active = items.filter(r => r.enabled), paused = items.filter(r => !r.enabled);
  setContent(`
    ${pageHead(title, '', actions)}
    ${summary}
    ${active.length ? `<div class="card card-flush list">${active.map(row).join('')}</div>` : ''}
    ${paused.length ? `<div class="section-head"><span class="section-title">${esc(t('web_rec_paused'))}</span></div><div class="card card-flush list">${paused.map(row).join('')}</div>` : ''}`);
}

function openRecurringForm(subs, r = null) {
  const { accounts, categories } = { accounts: cache.accounts || [], categories: cache.categories || [] };
  if (!accounts.length) { toast(t('web_need_account'), true); return; }
  let type = subs ? 'expense' : (r?.type || 'expense');
  const acctId = r?.accountId || lsGet('bs_last_account') || accounts[0].id;
  const validAcct = accounts.some(a => a.id === acctId) ? acctId : accounts[0].id;
  const destId = r?.destinationAccountId || accounts.find(a => a.id !== validAcct)?.id || '';
  const title = r ? (subs ? t('web_sub_edit') : t('web_rec_edit')) : (subs ? t('web_sub_new') : t('web_rec_new'));

  openModal({
    title,
    submit: r ? t('common_save') : (subs ? t('web_sub_add') : t('web_rec_add')),
    extra: r ? { label: t('common_delete'), run: () => { closeModal(); deleteRecurring(r.id, subs); } } : null,
    body: `
      ${subs ? '' : `<div class="field"><div class="seg full" id="r-type">
        ${['expense', 'income', 'transfer'].map(k => `<button type="button" data-type="${k}" class="${type === k ? 'active' : ''}"${r ? ' disabled' : ''}>${esc(t(`type_${k}`))}</button>`).join('')}
      </div></div>`}
      <div class="field"><label class="label" for="r-title">${esc(t('web_form_title'))}</label><input id="r-title" class="input" maxlength="100" value="${esc(r?.title || '')}" placeholder="${esc(subs ? t('web_sub_title_hint') : t('web_rec_title_hint'))}" autofocus></div>
      <div class="field"><label class="label" for="r-amount">${esc(t('web_form_amount'))}</label>
        <div class="input-cur"><input id="r-amount" class="input amount num" inputmode="decimal" autocomplete="off" placeholder="0" value="${esc(amountInputValue(r?.amount, r?.currency))}"><span class="cur" id="r-cur"></span></div>
        ${subs && r ? `<div class="help">${esc(t('web_sub_price_hint'))}</div>` : ''}</div>
      <div class="field-row">
        <div class="field"><label class="label" for="r-account" id="r-account-label">${esc(t('web_form_account'))}</label><select id="r-account" class="input">${accountOptions(accounts, validAcct)}</select></div>
        <div class="field" id="rg-dest"><label class="label" for="r-dest">${esc(t('web_form_to_account'))}</label><select id="r-dest" class="input">${accountOptions(accounts, destId)}</select></div>
        <div class="field" id="rg-cat"><label class="label" for="r-cat">${esc(t('web_form_category'))}</label><select id="r-cat" class="input"></select></div>
      </div>
      <div class="field-row">
        <div class="field"><label class="label" for="r-freq">${esc(t('web_form_repeats'))}</label><select id="r-freq" class="input">
          ${['daily', 'weekly', 'monthly', 'yearly'].map(fq => `<option value="${fq}"${(r?.frequency || 'monthly') === fq ? ' selected' : ''}>${esc(t(`freq_${fq}`))}</option>`).join('')}</select></div>
        <div class="field" style="max-width:110px"><label class="label" for="r-interval">${esc(t('web_form_every'))}</label><input id="r-interval" class="input num" type="number" min="1" max="365" value="${esc(r?.interval || 1)}"></div>
        <div class="field"><label class="label" for="r-date">${esc(r ? t('web_form_next_due') : t('web_form_first_date'))}</label><input id="r-date" type="date" class="input" value="${esc(r ? dayKey(r.nextDueDate) : dayKey())}"></div>
      </div>
      <div class="field"><label class="label" for="r-note">${esc(t('web_form_note'))}</label><input id="r-note" class="input" maxlength="500" value="${esc(r?.note || '')}" placeholder="${esc(t('web_form_optional'))}"></div>
      ${!r ? `<p class="help" id="r-past"></p>` : ''}`,
    onOpen: f => {
      const $ = s => f.querySelector(s);
      const sync = () => {
        const isT = type === 'transfer';
        $('#rg-dest').classList.toggle('hidden', !isT);
        $('#rg-cat').classList.toggle('hidden', isT);
        $('#r-account-label').textContent = isT ? t('web_form_from_account') : t('web_form_account');
        if (!isT) $('#r-cat').innerHTML = categoryOptions(categories, type, $('#r-cat').value || r?.categoryId || '');
        const a = accounts.find(x => x.id === $('#r-account').value);
        $('#r-cur').textContent = r?.currency || a?.currency || '';
        const past = $('#r-past');
        if (past) {
          const isPast = $('#r-date').value && $('#r-date').value < dayKey();
          past.textContent = isPast ? t('web_rec_past_hint') : '';
          past.classList.toggle('warn', !!isPast);
        }
      };
      $('#r-type')?.addEventListener('click', e => {
        const b = e.target.closest('[data-type]'); if (!b || b.disabled) return;
        type = b.dataset.type;
        f.querySelectorAll('#r-type button').forEach(x => x.classList.toggle('active', x === b));
        sync();
      });
      $('#r-account').addEventListener('change', sync);
      $('#r-date').addEventListener('change', sync);
      sync();
    },
    onSubmit: async f => {
      const $ = s => f.querySelector(s);
      const amount = parseAmount($('#r-amount').value);
      if (!(amount > 0)) { toast(t('web_val_valid_amount'), true); return false; }
      const date = $('#r-date').value;
      if (!date) { toast(t('web_val_select_start_date'), true); return false; }
      const body = {
        title: $('#r-title').value.trim(), amount, accountId: $('#r-account').value,
        frequency: $('#r-freq').value, interval: Math.max(1, Math.min(365, parseInt($('#r-interval').value, 10) || 1)),
        note: $('#r-note').value.trim(),
      };
      if (type === 'transfer') {
        body.destinationAccountId = $('#r-dest').value;
        if (body.destinationAccountId === body.accountId) { toast(t('web_val_accounts_differ'), true); return false; }
      } else {
        body.categoryId = $('#r-cat').value || null;
      }
      let res;
      const path = subs ? '/api/subscriptions' : '/api/recurring';
      if (r) {
        body.nextDueDate = date;
        res = await api(`${path}/${encodeURIComponent(r.id)}`, { method: 'PUT', body });
      } else {
        const a = accounts.find(x => x.id === body.accountId);
        Object.assign(body, { type, startDate: date, currency: a?.currency });
        res = await api(path, { method: 'POST', body });
      }
      if (!res) return false;
      lsSet('bs_last_account', body.accountId);
      toast(r ? t('web_toast_updated') : (subs ? t('web_toast_sub_added') : t('web_toast_recurring_added')));
      refresh(true);
      return true;
    },
  });
}

async function deleteRecurring(id, subs) {
  const ok = await confirmDialog(subs ? t('web_confirm_delete_sub') : t('web_confirm_delete_recurring'),
    subs ? t('web_confirm_delete_sub_msg') : t('web_confirm_delete_recurring_msg'));
  if (!ok) return;
  const r = await api(`${subs ? '/api/subscriptions' : '/api/recurring'}/${encodeURIComponent(id)}`, { method: 'DELETE' });
  if (r) { toast(t('web_toast_deleted')); refresh(true); }
}

async function toggleRecurring(input) {
  const subs = input.dataset.subs === '1';
  const r = await api(`${subs ? '/api/subscriptions' : '/api/recurring'}/${encodeURIComponent(input.dataset.id)}`,
    { method: 'PUT', body: { enabled: input.checked } });
  if (!r) { input.checked = !input.checked; return; }
  toast(input.checked ? t('web_rec_resumed') : t('web_rec_paused_toast'));
  refresh(true);
}

function exportRecurring(subs) {
  const items = cache[subs ? 'subs' : 'recurring'] || [];
  downloadCsv(`budgetseal-${subs ? 'subscriptions' : 'recurring'}-${dayKey()}.csv`, [
    ['title', 'type', 'amount', 'currency', 'frequency', 'interval', 'next_due', 'account', 'category', 'enabled'],
    ...items.map(r => [r.title, r.type, r.amount, r.currency, r.frequency, r.interval, dayKey(r.nextDueDate), r.accountName, r.categoryName, r.enabled ? 'yes' : 'no']),
  ]);
}

// ── Reports ───────────────────────────────────────────────────────────────────

const rep = { year: new Date().getFullYear(), month: new Date().getMonth() };
let charts = [];

async function renderReports(quiet) {
  const now = new Date();
  const atNow = rep.year === now.getFullYear() && rep.month === now.getMonth();
  const head = pageHead(t('nav_reports'), '', `
    <div class="month-nav">
      <button class="icon-btn" data-action="rep-month" data-step="-1" aria-label="${esc(t('web_prev_month'))}"><span class="flip-rtl" style="display:inline-grid">${IC.left}</span></button>
      <span class="label">${esc(monthLabel(rep.year, rep.month))}</span>
      <button class="icon-btn" data-action="rep-month" data-step="1" aria-label="${esc(t('web_next_month'))}" ${atNow ? 'disabled style="opacity:.3"' : ''}><span class="flip-rtl" style="display:inline-grid">${IC.right}</span></button>
    </div>`);
  if (!quiet) setContent(head + skeleton(4));
  const q = `year=${rep.year}&month=${rep.month + 1}`;
  const [cf, exp, inc] = await Promise.all([
    api(`/api/reports/cashflow?${q}`),
    api(`/api/reports/by-category?${q}`),
    api(`/api/reports/by-category?${q}&type=income`),
  ]);
  if (!cf || state.route !== '#/reports') return;
  charts.forEach(c => c.destroy());
  charts = [];

  const cur = cf.currency || state.baseCurrency;
  const days = cf.daily?.length || 30;
  const elapsed = atNow ? now.getDate() : days;
  const rate = cf.income > 0 ? (cf.net / cf.income) * 100 : null;
  const expItems = exp?.items || [];
  const incItems = inc?.items || [];
  const incTotal = incItems.reduce((s, i) => s + i.total, 0);

  const shareRows = (list, total, cls) => list.map(i => {
    const pct = total > 0 ? (i.total / total) * 100 : 0;
    return `<div class="share-row">${catChip(i, 'sm')}<div class="row-main">
      <div class="share-top"><span class="row-title">${esc(i.name || t('web_form_no_category'))}</span><span class="num ${cls}">${esc(fmt(i.total, cur))}</span></div>
      <div class="bar thin"><span style="width:${pct.toFixed(1)}%;background:${safeHex(i.colorHex)}"></span></div>
      <div class="share-top"><span class="pct">${esc(fmtPlain(pct, 1))}%</span></div>
    </div></div>`;
  }).join('');

  if (!cf.transactionCount) {
    setContent(head + `<div class="card">${emptyState(IC.chart, t('web_rep_empty'), t('web_rep_empty_sub'))}</div>`);
    return;
  }

  setContent(`
    ${head}
    <div class="stats">
      <div class="card stat"><div class="label">${esc(t('web_stat_income'))}</div><div class="value num income">${esc(fmt(cf.income, cur))}</div></div>
      <div class="card stat"><div class="label">${esc(t('web_stat_expenses'))}</div><div class="value num expense">${esc(fmt(cf.expense, cur))}</div></div>
      <div class="card stat"><div class="label">${esc(t('web_stat_net'))}</div><div class="value num ${cf.net >= 0 ? 'income' : 'expense'}">${esc(fmt(cf.net, cur))}</div></div>
      <div class="card stat"><div class="label">${esc(t('web_stat_savings_rate'))}</div><div class="value num">${rate == null ? '—' : esc(fmtPlain(rate, 1)) + '%'}</div></div>
      <div class="card stat"><div class="label">${esc(t('web_stat_avg_daily'))}</div><div class="value num">${esc(fmt(cf.expense / Math.max(1, elapsed), cur))}</div></div>
      <div class="card stat"><div class="label">${esc(t('web_stat_transactions'))}</div><div class="value num">${esc(fmtPlain(cf.transactionCount, 0))}</div></div>
    </div>
    <div class="card card-pad"><div class="section-head"><span class="section-title">${esc(t('web_report_daily_cashflow'))}</span></div>
      <div class="chart-box"><canvas id="ch-daily"></canvas></div></div>
    <div class="grid-2" style="margin-top:16px">
      <div class="card card-pad">
        <div class="section-head"><span class="section-title">${esc(t('web_report_spending_cat'))}</span></div>
        ${expItems.length ? `<div class="donut-box"><canvas id="ch-donut"></canvas><div class="donut-center"><div><div class="value num">${esc(fmt(cf.expense, cur))}</div><div class="label">${esc(t('web_stat_expenses'))}</div></div></div></div>
          <div style="margin:0 -16px">${shareRows(expItems, expItems.reduce((s, i) => s + i.total, 0), '')}</div>`
          : `<p class="muted">${esc(t('web_report_no_expense'))}</p>`}
      </div>
      <div>
        <div class="card card-pad">
          <div class="section-head"><span class="section-title">${esc(t('web_report_income_cat'))}</span></div>
          ${incItems.length ? `<div style="margin:0 -16px">${shareRows(incItems, incTotal, 'income')}</div>` : `<p class="muted">${esc(t('web_report_no_income'))}</p>`}
        </div>
        ${cf.topExpenses?.length ? `<div class="card card-pad" style="margin-top:16px">
          <div class="section-head"><span class="section-title">${esc(t('web_report_top_expenses'))}</span></div>
          <div class="list" style="margin:0 -16px">${cf.topExpenses.map(x => `
            <div class="row clickable" data-action="edit-tx" data-id="${esc(x.id)}" tabindex="0">${catChip(x, 'sm')}
              <div class="row-main"><div class="row-title">${esc(x.note || x.categoryName || t('type_expense'))}</div><div class="row-sub">${esc([fmtDate(x.date), x.accountName].filter(Boolean).join(' · '))}</div></div>
              <div class="row-amount expense">${esc(fmt(-x.amount, cur))}</div></div>`).join('')}</div></div>` : ''}
      </div>
    </div>`);

  drawCharts(cf, expItems, cur);
}

function drawCharts(cf, expItems, cur) {
  if (!window.Chart) return;
  const css = getComputedStyle(document.documentElement);
  const v = n => css.getPropertyValue(n).trim();
  const text = v('--text-2'), grid = v('--line');
  Chart.defaults.font.family = "'Nunito Sans', system-ui, sans-serif";
  Chart.defaults.font.weight = 600;
  Chart.defaults.color = text;
  const rtl = document.documentElement.dir === 'rtl';
  const tooltip = { rtl, backgroundColor: v('--popup'), titleColor: v('--text'), bodyColor: v('--text'), borderColor: grid, borderWidth: 1, padding: 10, cornerRadius: 12, boxPadding: 4 };
  const daily = document.getElementById('ch-daily');
  if (daily) {
    charts.push(new Chart(daily, {
      type: 'bar',
      data: {
        labels: cf.daily.map(d => fmtPlain(d.day, 0)),
        datasets: [
          { label: t('web_chart_income'), data: cf.daily.map(d => d.income), backgroundColor: v('--income'), borderRadius: 6, maxBarThickness: 14 },
          { label: t('web_chart_expense'), data: cf.daily.map(d => d.expense), backgroundColor: v('--expense'), borderRadius: 6, maxBarThickness: 14 },
        ],
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { rtl, labels: { usePointStyle: true, pointStyle: 'circle', boxWidth: 8 } }, tooltip: { ...tooltip, callbacks: { label: c => ` ${c.dataset.label}: ${fmt(c.parsed.y, cur)}` } } },
        scales: {
          x: { reverse: rtl, grid: { display: false }, ticks: { maxRotation: 0, autoSkipPadding: 8 } },
          y: { position: rtl ? 'right' : 'left', beginAtZero: true, grid: { color: grid }, border: { display: false }, ticks: { callback: x => fmt(x, cur), maxTicksLimit: 5 } },
        },
      },
    }));
  }
  const donut = document.getElementById('ch-donut');
  if (donut) {
    charts.push(new Chart(donut, {
      type: 'doughnut',
      data: { labels: expItems.map(i => i.name), datasets: [{ data: expItems.map(i => i.total), backgroundColor: expItems.map(i => safeHex(i.colorHex)), borderWidth: 3, borderColor: v('--card'), hoverOffset: 6 }] },
      options: { responsive: true, maintainAspectRatio: false, cutout: '72%', plugins: { legend: { display: false }, tooltip: { ...tooltip, callbacks: { label: c => ` ${c.label}: ${fmt(c.parsed, cur)}` } } } },
    }));
  }
}

// ── Theme ─────────────────────────────────────────────────────────────────────

function applyTheme(th) {
  state.theme = th;
  lsSet('bs_theme', th);
  if (th === 'system') delete document.documentElement.dataset.theme;
  else document.documentElement.dataset.theme = th;
  const el = document.getElementById('theme-label');
  if (el) el.textContent = { system: t('theme_auto'), dark: t('theme_dark'), light: t('theme_light') }[th];
}
function cycleTheme() {
  const order = ['system', 'light', 'dark'];
  applyTheme(order[(order.indexOf(state.theme) + 1) % 3]);
  navigate(state.route, true); // pastel fills and charts depend on the mode
}
matchMedia('(prefers-color-scheme: dark)').addEventListener?.('change', () => {
  if (state.theme === 'system' && state.token) navigate(state.route, true);
});

// ── Connection status ─────────────────────────────────────────────────────────

let connTimer = null;
let online = true;

function setConnection(ok) {
  online = ok;
  const dot = document.getElementById('conn-dot');
  if (dot) dot.className = `conn-dot ${ok ? 'ok' : 'err'}`;
  const label = document.getElementById('conn-label');
  if (label) label.textContent = ok ? t('web_conn_ok') : t('web_conn_lost');
  document.getElementById('offline-banner')?.classList.toggle('hidden', ok);
}

async function checkConnection() {
  try {
    const r = await fetch('/auth/status', { headers: state.token ? { Authorization: `Bearer ${state.token}` } : {} });
    const d = await r.json().catch(() => ({}));
    const wasOffline = !online;
    setConnection(r.ok);
    if (r.ok && !d.authenticated) { sessionExpired(); return; }
    if (wasOffline && r.ok) refresh(true);
  } catch (_) {
    setConnection(false);
  }
}
function startConnectionCheck() { stopConnectionCheck(); checkConnection(); connTimer = setInterval(checkConnection, 15000); }
function stopConnectionCheck() { clearInterval(connTimer); connTimer = null; }

// Coming back to the tab: show what changed on the phone meanwhile.
document.addEventListener('visibilitychange', () => {
  if (document.visibilityState !== 'visible' || !state.token) return;
  checkConnection();
  if (Date.now() - state.lastRender > 30000 && !document.getElementById('modal-overlay')) refresh(true);
});

// ── Sidebar (narrow screens) ──────────────────────────────────────────────────

function toggleSidebar(open) {
  const sb = document.getElementById('sidebar');
  const isOpen = open ?? !sb.classList.contains('open');
  sb.classList.toggle('open', isOpen);
  document.getElementById('scrim').classList.toggle('open', isOpen);
}

// ── Actions (event delegation) ────────────────────────────────────────────────

const actions = {
  'menu': () => toggleSidebar(),
  'menu-close': () => toggleSidebar(false),
  'theme': cycleTheme,
  'shortcuts': showShortcuts,
  'retry-conn': () => checkConnection(),
  'sign-out': signOut,
  'add-tx': () => openTxForm(null, 'add').then(() => {
    // From an account page, default the form to that account.
    if (txView?.accountId) { const s = document.getElementById('f-account'); if (s) { s.value = txView.accountId; s.dispatchEvent(new Event('change')); } }
  }),
  'edit-tx': el => editTx(el.dataset.id),
  'dup-tx': el => editTx(el.dataset.id, true),
  'del-tx': el => deleteTx(el.dataset.id),
  'more-tx': el => { el.disabled = true; txView.page++; loadTx(false); },
  'export-tx': exportTx,
  'fund': el => openFund(el.dataset.id),
  'add-goal': () => openGoalForm(),
  'open-goal': el => openGoal(el.dataset.id),
  'pay-goal': el => { const o = (cache.goals || []).find(x => x.id === el.dataset.id); if (o) openPayGoal(o); },
  'bulk-save': () => saveBulk(),
  'bulk-add': () => { bulk.rows.push(bulkRow(bulk.rows[bulk.rows.length - 1])); drawBulk({ row: bulk.rows.length - 1, col: 'amount' }); },
  'bulk-del': el => { bulk.rows.splice(Number(el.dataset.row), 1); if (!bulk.rows.length) bulk.rows.push(bulkRow()); bulk.bad = -1; drawBulk(); bulkStore(); },
  'bulk-clear': () => { bulk.rows = [bulkRow()]; while (bulk.rows.length < 3) bulk.rows.push(bulkRow(bulk.rows[0])); bulk.bad = -1; drawBulk({ row: 0, col: 'amount' }); bulkStore(); },
  'move': el => openMove(el.dataset.id),
  'cover': el => openMove(el.dataset.id, true),
  'add-account': openAddAccount,
  'add-cat': () => refs().then(() => openCategoryForm()),
  'edit-cat': el => openCategoryForm((cache.categories || []).find(c => c.id === el.dataset.id)),
  'add-rec': () => refs().then(() => openRecurringForm(false)),
  'add-sub': () => refs().then(() => openRecurringForm(true)),
  'edit-rec': el => {
    const subs = el.dataset.subs === '1';
    const r = (cache[subs ? 'subs' : 'recurring'] || []).find(x => x.id === el.dataset.id);
    if (r) openRecurringForm(subs, r);
  },
  'del-rec': el => deleteRecurring(el.dataset.id, el.dataset.subs === '1'),
  'export-rec': el => exportRecurring(el.dataset.subs === '1'),
  'rep-month': el => {
    const step = Number(el.dataset.step);
    const d = new Date(rep.year, rep.month + step, 1);
    if (d > new Date()) return;
    rep.year = d.getFullYear(); rep.month = d.getMonth();
    renderReports(true);
  },
};

document.addEventListener('click', e => {
  if (e.target.closest('[data-stop]') && !e.target.matches('input')) return;
  const toggle = e.target.closest('input[data-action="toggle-rec"]');
  if (toggle) return; // handled on change
  const el = e.target.closest('[data-action]');
  if (!el || el.disabled) return;
  const fn = actions[el.dataset.action];
  if (!fn) return;
  e.preventDefault();
  e.stopPropagation();
  fn(el);
});
document.addEventListener('change', e => {
  if (e.target.matches('input[data-action="toggle-rec"]')) toggleRecurring(e.target);
});
document.addEventListener('keydown', e => {
  // Rows are focusable: Enter opens them like a click.
  if (e.key === 'Enter' && e.target.matches('.row[data-action], .card[data-action]')) { e.preventDefault(); e.target.click(); }
});

// ── Keyboard shortcuts ────────────────────────────────────────────────────────

function initShortcuts() {
  document.addEventListener('keydown', e => {
    if (!state.token || !document.getElementById('auth-screen').classList.contains('hidden')) return;
    if (e.ctrlKey || e.metaKey || e.altKey) return;
    const tag = document.activeElement?.tagName;
    if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') {
      if (e.key === 'Escape' && !document.getElementById('modal-overlay')) document.activeElement.blur();
      return;
    }
    if (e.key === 'Escape') { closeModal(); toggleSidebar(false); return; }
    if (document.getElementById('modal-overlay')) return;
    const k = e.key.toLowerCase();
    if (k === 'n') { e.preventDefault(); openTxForm(null, 'add'); }
    else if (k === 'r') { e.preventDefault(); refresh(); }
    else if (e.key === '/') {
      e.preventDefault();
      if (state.route === '#/transactions') document.getElementById('tx-search')?.focus();
      else { location.hash = '#/transactions'; setTimeout(() => document.getElementById('tx-search')?.focus(), 150); }
    }
    else if (e.key === '?') showShortcuts();
    else if (/^[1-9]$/.test(e.key)) {
      const links = [...document.querySelectorAll('.nav-link')];
      links[Number(e.key) - 1]?.click();
    }
  });
}

function showShortcuts() {
  const rows = [['N', 'web_shortcut_new_tx'], ['/', 'web_shortcut_search'], ['R', 'web_shortcut_refresh'], ['1–9', 'web_shortcut_pages'], ['Esc', 'web_shortcut_close'], ['?', 'web_shortcut_help']];
  openModal({
    title: t('web_shortcuts_title'), narrow: true,
    body: `<div class="kbd-grid">${rows.map(([k, l]) => `<kbd>${esc(k)}</kbd><span>${esc(t(l))}</span>`).join('')}</div>`,
  });
}

// ── Sign out ──────────────────────────────────────────────────────────────────

function signOut() {
  for (const id of [...pendingDeletes.keys()]) commitDelete(id, true);
  fetch('/auth/logout', { method: 'POST', headers: { Authorization: `Bearer ${state.token}` } }).catch(() => {});
  state.token = null;
  sessionStorage.removeItem('bs_token');
  invalidate();
  txView = null;
  showAuth('');
}

// ── Start ─────────────────────────────────────────────────────────────────────

(async () => {
  applyTheme(state.theme);
  initAuth();
  initShortcuts();
  await loadConfig();
  applyTheme(state.theme);
  if (state.token) {
    const d = await fetch('/auth/status', { headers: { Authorization: `Bearer ${state.token}` } }).then(r => r.json()).catch(() => null);
    if (d?.authenticated) { enterApp(); return; }
    state.token = null;
    sessionStorage.removeItem('bs_token');
  }
  showAuth('');
})();

})();
