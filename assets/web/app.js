'use strict';

// ── i18n ──────────────────────────────────────────────────────────────────────
let _strings = {};
let _locale = localStorage.getItem('pp_locale') || 'en';

/** Lookup a translated string. Supports {param} substitution.
 *  t('web_tx_page_n', { page: 3 }) → "Page 3"
 */
function t(key, params) {
  let s = _strings[key] || key;
  if (params) {
    for (const [k, v] of Object.entries(params)) {
      s = s.replace(new RegExp(`\\{${k}\\}`, 'g'), v);
    }
  }
  return s;
}

async function loadLocale(lang) {
  try {
    const res = await fetch(`/assets/locale_${lang}.json`);
    if (res.ok) {
      _strings = await res.json();
      _locale = lang;
      localStorage.setItem('pp_locale', lang);
    }
  } catch (_) {
    // fallback: keep current strings
  }
}

// ── State ─────────────────────────────────────────────────────────────────────
const state = {
  token: sessionStorage.getItem('pp_token') || null,
  currentRoute: location.hash || '#/',
  theme: localStorage.getItem('pp_theme') || 'system',
};
const cache = {};
let _txPage = 1;
let _txFilter = '';
let _txSearch = '';
let _txYear = new Date().getFullYear();
let _txMonth = new Date().getMonth(); // 0-indexed; -1 = all
let _reportChart = null;
let _reportCatChart = null;
let _connInterval = null;

// ── API ───────────────────────────────────────────────────────────────────────
async function api(path, opts = {}) {
  const hasBody = opts.body != null;
  const headers = {
    ...(hasBody ? { 'Content-Type': 'application/json' } : {}),
    ...(state.token ? { Authorization: `Bearer ${state.token}` } : {}),
    ...(opts.headers || {}),
  };

  let res;
  try {
    res = await fetch(path, { ...opts, headers });
  } catch (_) {
    toast(t('web_server_unreachable'), true);
    return null;
  }

  if (res.status === 401) {
    state.token = null;
    sessionStorage.removeItem('pp_token');
    showAuthScreen();
    return null;
  }
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    // Show user-friendly message; log technical details to console only
    const msg = err.error || '';
    if (res.status >= 500) {
      toast(t('common_something_went_wrong'), true);
    } else if (res.status === 429) {
      toast('Too many requests. Please wait a moment.', true);
    } else if (res.status === 413) {
      toast('Request too large. Try reducing the data.', true);
    } else {
      toast(msg || 'Request failed', true);
    }
    return null;
  }

  try {
    return await res.json();
  } catch (_) {
    toast(t('web_unexpected_response'), true);
    return null;
  }
}

// ── Formatters ────────────────────────────────────────────────────────────────
function fmt(amount, currency) {
  try {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: currency || 'USD',
      maximumFractionDigits: 2,
    }).format(amount);
  } catch {
    return `${currency || ''} ${Number(amount).toFixed(2)}`;
  }
}

function fmtDate(iso) {
  if (!iso) return '';
  return new Date(iso).toLocaleDateString(_locale || 'en', { month: 'short', day: 'numeric', year: 'numeric' });
}

function todayISO() { return new Date().toISOString().slice(0, 10); }

function fmtFreq(f, interval) {
  const map = { daily: t('freq_daily'), weekly: t('freq_weekly'), monthly: t('freq_monthly'), yearly: t('freq_yearly') };
  if (!interval || interval === 1) return map[f] || f;
  const pluralKeys = { daily: 'freq_every_n_days', weekly: 'freq_every_n_weeks', monthly: 'freq_every_n_months', yearly: 'freq_every_n_years' };
  return pluralKeys[f] ? t(pluralKeys[f], { n: interval }) : `${interval} ${f}`;
}

function _monthNames() { return [t('month_jan'),t('month_feb'),t('month_mar'),t('month_apr'),t('month_may'),t('month_jun'),t('month_jul'),t('month_aug'),t('month_sep'),t('month_oct'),t('month_nov'),t('month_dec')]; }

// ── Escape / helpers ──────────────────────────────────────────────────────────
function esc(s) {
  return String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}
function safeHex(v) {
  return /^#[0-9A-Fa-f]{3,8}$/.test(v) ? v : '#607D8B';
}
// Safe array accessor — prevents crash if API response is missing 'items'
function items(d) { return d?.items ?? []; }

function setContent(html) { document.getElementById('content').innerHTML = html; }

function skeleton(rows = 5) {
  const lines = Array.from({ length: rows }, () =>
    `<div class="skel-row"><div class="skel-cell" style="width:${60 + Math.random() * 30}%"></div><div class="skel-cell" style="width:${15 + Math.random() * 15}%"></div></div>`
  ).join('');
  return `<div class="skeleton-wrap">${lines}</div>`;
}

function loading() {
  return `<div class="loading"><div class="spinner"></div>${esc(t('common_loading'))}</div>`;
}

function empty(title, sub) {
  return `<div class="empty-state">
    <div class="empty-state-icon"><svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 7V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v2"/><line x1="12" x2="12" y1="12" y2="16"/><line x1="10" x2="14" y1="14" y2="14"/></svg></div>
    <div class="empty-state-title">${esc(title)}</div>
    ${sub ? `<p class="text-secondary text-sm">${esc(sub)}</p>` : ''}
  </div>`;
}

function typeBadge(type) {
  return ({
    income: `<span class="badge badge-income">${esc(t('type_income'))}</span>`,
    expense: `<span class="badge badge-expense">${esc(t('type_expense'))}</span>`,
    transfer: `<span class="badge badge-transfer">${esc(t('type_transfer'))}</span>`,
  })[type] || `<span class="badge">${esc(type)}</span>`;
}

function amtEl(amount, currency, type) {
  const cls = type === 'income' ? 'amount-income' : type === 'expense' ? 'amount-expense' : 'amount-neutral';
  const sign = type === 'income' ? '+' : type === 'expense' ? '−' : '';
  return `<span class="${cls}">${sign}${fmt(amount, currency)}</span>`;
}

function invalidate(...keys) { keys.forEach(k => delete cache[k]); }
function invalidateAll() { Object.keys(cache).forEach(k => delete cache[k]); }

// ── Toast ─────────────────────────────────────────────────────────────────────
function toast(msg, isErr = false, undoFn = null) {
  document.querySelectorAll('.toast').forEach(t => t.remove());
  const el = document.createElement('div');
  el.className = `toast${isErr ? ' toast-error' : ''}`;
  if (undoFn) {
    el.innerHTML = `<span>${esc(msg)}</span><button class="toast-undo">${esc(t('web_undo'))}</button>`;
    el.querySelector('.toast-undo').onclick = () => { undoFn(); el.remove(); };
  } else {
    el.textContent = msg;
  }
  document.body.appendChild(el);
  requestAnimationFrame(() => el.classList.add('toast-show'));
  const dur = undoFn ? 5000 : 2400;
  setTimeout(() => { el.classList.remove('toast-show'); setTimeout(() => el.remove(), 300); }, dur);
}

// ── Modal ─────────────────────────────────────────────────────────────────────
function openModal(title, bodyHtml, onConfirm, confirmLabel) {
  if (!confirmLabel) confirmLabel = t('common_save');
  closeModal();
  const o = document.createElement('div');
  o.className = 'modal-overlay';
  o.id = 'modal-overlay';
  o.innerHTML = `
    <div class="modal" role="dialog" aria-modal="true">
      <h2 class="modal-title">${esc(title)}</h2>
      ${bodyHtml}
      <div class="hp-field" aria-hidden="true"><label>Website<input type="text" id="hp-website" name="website" autocomplete="off" tabindex="-1"></label></div>
      <div class="modal-actions">
        <button class="btn btn-outline" id="modal-cancel">${esc(t('common_cancel'))}</button>
        <button class="btn btn-primary" id="modal-confirm">${esc(confirmLabel)}</button>
      </div>
    </div>`;
  document.body.appendChild(o);
  o.querySelector('#modal-cancel').onclick = closeModal;
  const btn = o.querySelector('#modal-confirm');
  btn.onclick = async () => {
    btn.disabled = true; btn.innerHTML = '<span class="spinner" style="width:14px;height:14px;border-width:2px;display:inline-block;vertical-align:middle;margin-right:6px"></span>' + esc(t('web_saving'));
    try { await onConfirm(); } catch (err) { toast(t('web_unexpected_error'), true); }
    finally { if (btn.isConnected) { btn.disabled = false; btn.textContent = confirmLabel; } }
  };
  // Focus trap: Tab cycles within modal
  const modal = o.querySelector('.modal');
  modal.addEventListener('keydown', e => {
    if (e.key !== 'Tab') return;
    const focusable = modal.querySelectorAll('input:not([tabindex="-1"]),select,textarea,button:not([disabled])');
    if (!focusable.length) return;
    const first = focusable[0], last = focusable[focusable.length - 1];
    if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
    else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
  });
  // Auto-focus first input
  setTimeout(() => { const fi = modal.querySelector('input:not([type=hidden]):not([tabindex="-1"]),select'); if (fi) fi.focus(); }, 50);
}

function closeModal() { document.getElementById('modal-overlay')?.remove(); }

function confirmDialog(title, msg, confirmLabel, isDanger = true) {
  if (!confirmLabel) confirmLabel = t('common_delete');
  return new Promise(resolve => {
    closeModal();
    const o = document.createElement('div');
    o.className = 'modal-overlay';
    o.id = 'modal-overlay';
    o.innerHTML = `
      <div class="modal" role="dialog" aria-modal="true" style="max-width:400px">
        <h2 class="modal-title">${esc(title)}</h2>
        <p style="color:var(--text-secondary);font-size:14px;line-height:1.6;margin-bottom:4px">${esc(msg)}</p>
        <div class="modal-actions">
          <button class="btn btn-outline" id="modal-cancel">${esc(t('common_cancel'))}</button>
          <button class="btn ${isDanger ? 'btn-danger' : 'btn-primary'}" id="modal-confirm">${esc(confirmLabel)}</button>
        </div>
      </div>`;
    document.body.appendChild(o);
    o.querySelector('#modal-cancel').onclick = () => { closeModal(); resolve(false); };
    o.querySelector('#modal-confirm').onclick = () => { closeModal(); resolve(true); };
    // Don't close on overlay click — require explicit Cancel/Confirm
  });
}

// ── Data loaders (cached) ─────────────────────────────────────────────────────
async function getAccounts() {
  if (!('accounts' in cache)) {
    const d = await api('/api/accounts');
    if (d) cache.accounts = d.items ?? [];
  }
  return cache.accounts ?? [];
}
async function getCategories() {
  if (!('categories' in cache)) {
    const d = await api('/api/categories');
    if (d) cache.categories = d.items ?? [];
  }
  return cache.categories ?? [];
}

// ── Auth ──────────────────────────────────────────────────────────────────────
let _pin = '';

function initAuth() {
  function dots() { return document.querySelectorAll('.pin-dot'); }
  function errEl() { return document.getElementById('auth-error'); }

  function updateDots() {
    dots().forEach((d, i) => { d.classList.toggle('filled', i < _pin.length); d.classList.remove('error'); });
    if (_pin.length === 4) submitPin();
  }

  document.querySelectorAll('.num-btn[data-num]').forEach(btn =>
    btn.addEventListener('click', () => { if (_pin.length < 4) { _pin += btn.dataset.num; updateDots(); } })
  );
  document.getElementById('del-btn').addEventListener('click', () => { _pin = _pin.slice(0, -1); updateDots(); });

  document.addEventListener('keydown', e => {
    if (document.getElementById('auth-screen').classList.contains('hidden')) return;
    if (e.key >= '0' && e.key <= '9' && _pin.length < 4) { _pin += e.key; updateDots(); }
    else if (e.key === 'Backspace') { _pin = _pin.slice(0, -1); updateDots(); }
  });

  async function submitPin() {
    const pin = _pin; _pin = ''; updateDots();
    const data = await fetch('/auth/pin', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ pin }),
    }).then(r => r.json()).catch(() => null);

    if (!data?.token) {
      const msg = data?.isLockout
        ? (data.error || t('web_auth_lockout'))
        : (data?.error || t('web_auth_incorrect'));
      dots().forEach(d => d.classList.add('error'));
      const el = errEl(); if (el) { el.textContent = msg; el.classList.remove('hidden'); }
      setTimeout(() => { dots().forEach(d => d.classList.remove('error', 'filled')); errEl()?.classList.add('hidden'); }, 2000);
      return;
    }
    state.token = data.token;
    sessionStorage.setItem('pp_token', data.token);
    showMainLayout();
    navigate(state.currentRoute);
    getCategories();
    getAccounts();
    startConnectionCheck();
  }
}

// ── Navigation ────────────────────────────────────────────────────────────────
const routes = {
  '#/': renderDashboard,
  '#/transactions': () => renderTransactions(),
  '#/categories': renderCategories,
  '#/accounts': renderAccounts,
  '#/envelopes': renderEnvelopes,
  '#/recurring': renderRecurring,
  '#/subscriptions': renderSubscriptions,
  '#/reports': renderReports,
};

function navigate(hash) {
  const route = hash || '#/';
  state.currentRoute = route;
  if (route !== '#/transactions') { _txPage = 1; _txFilter = ''; _txSearch = ''; _txMonth = new Date().getMonth(); _txYear = new Date().getFullYear(); }
  document.querySelectorAll('.nav-link').forEach(a => a.classList.toggle('active', a.dataset.route === route));
  (routes[route] || renderDashboard)();
}
function refreshPage() { invalidateAll(); navigate(state.currentRoute); }

window.addEventListener('hashchange', () => navigate(location.hash));

function showAuthScreen() {
  document.getElementById('auth-screen').classList.remove('hidden');
  document.getElementById('main-layout').classList.add('hidden');
  stopConnectionCheck();
}
function showMainLayout() {
  document.getElementById('auth-screen').classList.add('hidden');
  document.getElementById('main-layout').classList.remove('hidden');
}

// ── Dashboard ─────────────────────────────────────────────────────────────────
async function renderDashboard() {
  setContent(skeleton(6));
  const data = await api('/api/dashboard');
  if (!data) return;
  const { household = {}, accounts = [], envelopes = [], unallocated = {}, recentTransactions = [] } = data;
  if (!cache.accounts) cache.accounts = accounts;
  if (household.baseCurrency) cache.baseCurrency = household.baseCurrency;

  // ── Accounts: horizontal scroll cards ──
  const acctHtml = accounts.length
    ? `<div class="acct-scroll">${accounts.map(a => `
        <div class="acct-card">
          <div class="acct-name">${esc(a.name)}</div>
          <div class="acct-balance${a.balance < 0 ? ' negative' : ''}">${fmt(a.balance, a.currency)}</div>
          <span class="acct-type">${esc(a.type)}</span>
        </div>`).join('')}</div>`
    : `<p class="text-secondary text-sm" style="margin-bottom:16px">${esc(t('web_dash_no_accounts'))}</p>`;

  // ── Unallocated: compact banner ──
  const unallocEntries = Object.entries(unallocated);
  const unallocPills = unallocEntries.length
    ? unallocEntries.map(([cur, amt]) =>
        `<span class="unalloc-pill ${amt < 0 ? 'unalloc-pill-warn' : ''}">${fmt(amt, cur)}</span>`).join('')
    : '<span class="text-secondary text-sm">—</span>';

  const unallocHtml = `<div class="unalloc-banner">
    <span class="unalloc-label">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12V7H5a2 2 0 0 1 0-4h14v4"/><path d="M3 5v14a2 2 0 0 0 2 2h16v-5"/><path d="M18 12a2 2 0 0 0 0 4h4v-4Z"/></svg>
      ${esc(t('web_dash_unallocated'))}
    </span>
    <span class="unalloc-amounts">${unallocPills}</span>
  </div>`;

  // ── Envelopes: rich cards with target + color-coded progress ──
  const envsHtml = envelopes.slice(0, 6).length
    ? envelopes.slice(0, 6).map(e => {
        const tCur = e.targetCurrency || Object.keys(e.balanceByCurrency || {})[0] || 'USD';
        const bal = (e.balanceByCurrency || {})[tCur] || 0;
        const target = e.targetAmount || 0;
        const pct = target > 0 ? Math.min(100, Math.max(0, (bal / target) * 100)) : null;
        const isOver = bal < 0;

        // Color: green > 50%, amber 20-50%, red < 20% or negative
        let barColor = 'accent';
        if (target > 0) {
          const ratio = bal / target;
          if (isOver) barColor = 'red';
          else if (ratio >= 0.5) barColor = 'green';
          else if (ratio >= 0.2) barColor = 'amber';
          else barColor = 'red';
        }
        if (isOver) barColor = 'red';

        // Amount color class
        const amtClass = isOver ? 'amount-expense' : bal > 0 ? 'amount-income' : '';

        // Meta line: "X / Y" or periodicity
        const metaText = target > 0
          ? t('web_env_balance_of_target', { balance: fmt(bal, tCur), target: fmt(target, tCur) })
          : e.periodicity ? e.periodicity.charAt(0).toUpperCase() + e.periodicity.slice(1) : '';

        return `<div class="dash-env-item">
          <div class="dash-env-row">
            <div class="dash-env-icon">${esc(e.icon || '📁')}</div>
            <div class="dash-env-info">
              <div class="dash-env-name">${esc(e.name)}</div>
              ${metaText ? `<div class="dash-env-meta">${esc(metaText)}</div>` : ''}
            </div>
            <div class="dash-env-amount ${amtClass}">${fmt(bal, tCur)}</div>
          </div>
          ${pct !== null ? `<div class="dash-env-progress"><div class="dash-env-progress-fill ${barColor}" style="width:${pct.toFixed(1)}%"></div></div>` : ''}
        </div>`;
      }).join('')
    : `<p class="text-secondary text-sm" style="padding:8px 0">${esc(t('web_dash_no_envelopes'))}</p>`;

  // ── Recent transactions: compact list ──
  const recHtml = recentTransactions.length
    ? recentTransactions.map(tx => {
        const icon = _isEmoji(tx.categoryIcon) ? tx.categoryIcon + ' ' : '';
        const title = tx.note
          ? esc(tx.note)
          : tx.categoryName
            ? `${esc(icon)}${esc(tx.categoryName)}`
            : esc(t('web_dash_fallback_tx'));
        const sub = [fmtDate(tx.date), tx.accountName].filter(Boolean).map(esc).join(' · ');
        // Show the transaction's native currency/amount, not the base header
        // amount (tx.amount/currency is always base currency).
        const lineCur = tx.lineCurrency || tx.currency;
        const lineAmt = tx.lineAmount ?? tx.amount;
        return `<div class="dash-tx-item">
          <div class="dash-tx-dot ${esc(tx.type)}"></div>
          <div class="dash-tx-info">
            <div class="dash-tx-title">${title}</div>
            <div class="dash-tx-sub">${sub}</div>
          </div>
          <div class="dash-tx-amount ${tx.type === 'income' ? 'amount-income' : tx.type === 'expense' ? 'amount-expense' : ''}">${amtEl(lineAmt, lineCur, tx.type)}</div>
        </div>`;
      }).join('')
    : empty(t('web_dash_no_tx_title'), t('web_dash_no_tx_sub'));

  setContent(`
    <div class="page-header">
      <h1 class="page-title">${esc(t('nav_dashboard'))}</h1>
      <span class="text-secondary text-sm">${esc(household.name || '')}${household.baseCurrency ? ` · ${esc(household.baseCurrency)}` : ''}</span>
    </div>
    <div class="section-title">${esc(t('nav_accounts'))}</div>
    ${acctHtml}
    ${unallocHtml}
    <div class="card">
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:4px">
        <span class="card-title" style="margin-bottom:0">${esc(t('nav_envelopes'))}</span>
        <a href="#/envelopes" class="btn btn-sm btn-outline">${esc(t('web_dash_see_all'))}</a>
      </div>
      ${envsHtml}
    </div>
    <div class="card">
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:4px">
        <span class="card-title" style="margin-bottom:0">${esc(t('web_dash_recent'))}</span>
        <a href="#/transactions" class="btn btn-sm btn-outline">${esc(t('web_dash_view_all'))}</a>
      </div>
      ${recHtml}
    </div>
  `);
}

// ── Transactions ──────────────────────────────────────────────────────────────
async function renderTransactions(page, typeFilter, search) {
  page = page ?? _txPage; typeFilter = typeFilter ?? _txFilter; search = search ?? _txSearch;
  _txPage = page; _txFilter = typeFilter; _txSearch = search;
  setContent(skeleton(8));

  let dateParams = '';
  if (_txMonth >= 0) {
    const from = `${_txYear}-${String(_txMonth + 1).padStart(2, '0')}-01`;
    const toM = _txMonth === 11 ? 0 : _txMonth + 1;
    const toY = _txMonth === 11 ? _txYear + 1 : _txYear;
    const to = `${toY}-${String(toM + 1).padStart(2, '0')}-01`;
    dateParams = `&from=${from}&to=${to}`;
  }

  const searchParam = search ? `&search=${encodeURIComponent(search)}` : '';

  const [txData, accounts, cats] = await Promise.all([
    api(`/api/transactions?page=${page}&limit=25${typeFilter ? '&type=' + typeFilter : ''}${dateParams}${searchParam}`),
    getAccounts(),
    getCategories(),
  ]);
  if (!txData) return;

  // Type filter — segmented control style
  const filterBtns = [['', t('type_all')], ['income', t('type_income')], ['expense', t('type_expense')], ['transfer', t('type_transfer')]]
    .map(([f, l]) => `<button class="type-tab${f === typeFilter ? ' active' : ''}" onclick="renderTransactions(1,'${f}')">${l}</button>`)
    .join('');

  // Month tabs — inline with year nav
  const now = new Date();
  const monthTabs = [
    `<button class="month-tab${_txMonth < 0 ? ' active' : ''}" onclick="_txMonth=-1;renderTransactions(1)">${esc(t('type_all'))}</button>`,
    ..._monthNames().map((m, i) => {
      if (_txYear === now.getFullYear() && i > now.getMonth()) return '';
      return `<button class="month-tab${_txMonth === i ? ' active' : ''}" onclick="_txMonth=${i};renderTransactions(1)">${m}</button>`;
    }).filter(Boolean),
  ].join('');

  const baseCur = txData.baseCurrency || cache.baseCurrency || 'USD';

  const rows = items(txData).length
    ? items(txData).map(tx => {
        const lineCur = tx.lineCurrency || tx.currency;
        const lineAmt = tx.lineAmount ?? tx.amount;
        const isForeign = lineCur !== baseCur;
        const hasRealRate = isForeign && tx.lineExchangeRate && Math.abs(tx.lineExchangeRate - 1) > 0.001;
        const missingRate = isForeign && !hasRealRate;

        let amountHtml;
        if (isForeign) {
          amountHtml = `${amtEl(lineAmt, lineCur, tx.type)}`;
          if (hasRealRate) {
            amountHtml += `<div class="text-secondary" style="font-size:11px">${fmt(lineAmt * tx.lineExchangeRate, baseCur)}</div>`;
          } else {
            amountHtml += `<div style="font-size:11px;color:var(--caution)">⚠ ${esc(t('web_tx_no_rate'))}</div>`;
          }
        } else {
          amountHtml = amtEl(tx.amount, tx.currency, tx.type);
        }

        return `
        <tr class="tx-row${missingRate ? ' tx-warn' : ''}" onclick="toggleTxDetail('${esc(tx.id)}', this)">
          <td class="text-secondary text-sm" style="white-space:nowrap">${fmtDate(tx.date)}</td>
          <td>${typeBadge(tx.type)}</td>
          <td class="text-sm" style="max-width:180px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${esc(tx.note || '—')}</td>
          <td class="text-sm">${esc(tx.accountName || '')}${tx.destinationAccountName ? `<span class="text-secondary"> → ${esc(tx.destinationAccountName)}</span>` : ''}</td>
          <td class="text-sm">
            ${tx.categoryName
              ? `<div style="display:flex;align-items:center;gap:6px"><span style="width:8px;height:8px;border-radius:50%;background:${safeHex(tx.categoryColor || '#607D8B')};flex-shrink:0"></span>${_isEmoji(tx.categoryIcon) ? esc(tx.categoryIcon) + ' ' : ''}${esc(tx.categoryName)}</div>`
              : '<span class="text-secondary">—</span>'}
          </td>
          <td style="text-align:right;white-space:nowrap">${amountHtml}</td>
          <td style="white-space:nowrap" onclick="event.stopPropagation()">
            <button class="btn btn-sm btn-outline" onclick="editTransaction('${esc(tx.id)}')">${esc(t('web_tx_edit'))}</button>
            <button class="btn btn-sm btn-danger" style="margin-left:4px" onclick="deleteTransaction('${esc(tx.id)}')">${esc(t('web_tx_del'))}</button>
          </td>
        </tr>`;
      }).join('')
    : `<tr><td colspan="7" style="padding:32px;text-align:center;color:var(--text-secondary)">${esc(t('web_tx_no_found'))}</td></tr>`;

  setContent(`
    <div class="page-header">
      <h1 class="page-title">${esc(t('nav_transactions'))}</h1>
      <div style="display:flex;gap:8px;align-items:center">
        <button class="btn btn-outline btn-sm" onclick="exportCSV()" title="${esc(t('web_tx_csv_tooltip'))}">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" x2="12" y1="15" y2="3"/></svg>
          ${esc(t('web_tx_csv'))}
        </button>
        <button class="btn btn-primary" onclick="addTransaction()">${esc(t('web_tx_add'))}</button>
      </div>
    </div>
    <div style="position:relative;margin-bottom:14px">
      <svg style="position:absolute;left:10px;top:50%;transform:translateY(-50%);color:var(--text-hint)" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" x2="16.65" y1="21" y2="16.65"/></svg>
      <input type="text" id="tx-search" class="form-control" style="padding-left:32px;font-size:13px" placeholder="${esc(t('web_tx_search'))}" value="${esc(search)}" oninput="clearTimeout(window._searchTimer);window._searchTimer=setTimeout(()=>{_txSearch=this.value;renderTransactions(1)},400)">
    </div>
    <div class="date-bar">
      <div class="date-bar-year">
        <button class="year-arrow" onclick="_txYear--;renderTransactions(1)">‹</button>
        <span class="year-label">${_txYear}</span>
        <button class="year-arrow" onclick="_txYear++;renderTransactions(1)" ${_txYear >= now.getFullYear() ? 'disabled' : ''}>›</button>
      </div>
      <div class="month-tabs-scroll">${monthTabs}</div>
    </div>
    <div style="margin-bottom:16px">
      <div class="type-tabs" style="max-width:360px">${filterBtns}</div>
    </div>
    <div class="card" style="padding:0;overflow:auto">
      <table class="data-table">
        <thead><tr><th>${esc(t('web_tx_th_date'))}</th><th>${esc(t('web_tx_th_type'))}</th><th>${esc(t('web_tx_th_title'))}</th><th>${esc(t('web_tx_th_account'))}</th><th>${esc(t('web_tx_th_category'))}</th><th style="text-align:right">${esc(t('web_tx_th_amount'))}</th><th></th></tr></thead>
        <tbody>${rows}</tbody>
      </table>
    </div>
    <div class="pagination">
      <button class="btn btn-outline btn-sm" ${page <= 1 ? 'disabled' : ''} onclick="renderTransactions(${page - 1})">${esc(t('web_tx_prev'))}</button>
      <span class="text-secondary text-sm">${esc(t('web_tx_page_n', { page }))}</span>
      <button class="btn btn-outline btn-sm" ${items(txData).length < 25 ? 'disabled' : ''} onclick="renderTransactions(${page + 1})">${esc(t('web_tx_next'))}</button>
    </div>
  `);

  // Focus search if user was searching
  if (search) { const el = document.getElementById('tx-search'); if (el) { el.focus(); el.setSelectionRange(el.value.length, el.value.length); } }
}

// CSV export
function exportCSV() {
  const table = document.querySelector('.data-table');
  if (!table) return;
  // Skip expanded detail rows (tx-lines-*) which have different column structure
  const rows = [...table.querySelectorAll('tr')].filter(r => !r.id?.startsWith('tx-lines-'));
  const csv = rows.map(r => {
    const cells = [...r.querySelectorAll(':scope > th, :scope > td')];
    return cells.slice(0, -1).map(c => `"${c.textContent.trim().replace(/"/g, '""')}"`).join(',');
  }).join('\n');

  const blob = new Blob([csv], { type: 'text/csv' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = `budgetseal-transactions-${todayISO()}.csv`;
  a.click();
  URL.revokeObjectURL(a.href);
  toast(t('web_tx_csv_exported'));
}

function _txFormHtml(accounts, cats, pre = null) {
  const type = pre?.type || 'expense';
  const acctOpts = accounts.map(a =>
    `<option value="${a.id}" data-currency="${esc(a.currency)}" ${pre?.accountId === a.id ? 'selected' : ''}>${esc(a.name)} (${esc(a.currency)})</option>`).join('');
  const destOpts = accounts.map(a =>
    `<option value="${a.id}" ${pre?.destinationAccountId === a.id ? 'selected' : ''}>${esc(a.name)} (${esc(a.currency)})</option>`).join('');
  const catOpts = `<option value="">${esc(t('web_form_none'))}</option>` + cats.map(c =>
    `<option value="${c.id}" data-txtype="${esc(c.transactionType)}" ${pre?.categoryId === c.id ? 'selected' : ''}>${_isEmoji(c.icon) ? esc(c.icon) + ' ' : ''}${esc(c.name)}</option>`).join('');

  return `
    <div class="form-group">
      <label class="form-label">${esc(t('web_form_type'))}</label>
      <div class="type-tabs">
        <button type="button" class="type-tab${type === 'expense' ? ' active' : ''}" data-type="expense">${esc(t('type_expense'))}</button>
        <button type="button" class="type-tab${type === 'income' ? ' active' : ''}" data-type="income">${esc(t('type_income'))}</button>
        <button type="button" class="type-tab${type === 'transfer' ? ' active' : ''}" data-type="transfer">${esc(t('type_transfer'))}</button>
      </div>
    </div>
    <div class="form-group">
      <label class="form-label" id="lbl-account">${type === 'transfer' ? esc(t('web_form_from_account')) : esc(t('web_form_account'))}</label>
      <select id="tx-account" class="form-control"><option value="">${esc(t('web_form_select_account'))}</option>${acctOpts}</select>
    </div>
    <div class="form-group" id="fg-dest" style="${type !== 'transfer' ? 'display:none' : ''}">
      <label class="form-label">${esc(t('web_form_to_account'))}</label>
      <select id="tx-dest" class="form-control">${destOpts}</select>
    </div>
    <div class="form-group" id="fg-cat" style="${type === 'transfer' ? 'display:none' : ''}">
      <label class="form-label">${esc(t('web_form_category'))}</label>
      <select id="tx-cat" class="form-control">${catOpts}</select>
    </div>
    <div style="display:flex;gap:12px">
      <div class="form-group" style="flex:1">
        <label class="form-label">${esc(t('web_form_amount'))}</label>
        <input type="number" id="tx-amount" class="form-control" min="0.01" step="0.01" value="${esc(pre?.amount || '')}" placeholder="${esc(t('web_form_amount_placeholder'))}">
      </div>
      <div class="form-group" style="width:80px">
        <label class="form-label">${esc(t('web_form_currency'))}</label>
        <input type="text" id="tx-currency" class="form-control" maxlength="3" placeholder="${esc(t('web_form_currency_placeholder'))}" value="${esc(pre?.currency || '')}">
      </div>
    </div>
    <div class="form-group" id="fg-rate" style="display:none">
      <label class="form-label">${esc(t('web_form_exchange_rate'))}</label>
      <input type="number" id="tx-rate" class="form-control" min="0.000001" step="any" value="${esc(pre?.exchangeRateToBase && pre.exchangeRateToBase !== 1 ? pre.exchangeRateToBase : '')}" placeholder="${esc(t('web_form_rate_placeholder'))}">
      <div class="text-secondary text-sm" id="rate-hint" style="margin-top:4px"></div>
    </div>
    <div class="form-group">
      <label class="form-label">${esc(t('web_form_date'))}</label>
      <input type="date" id="tx-date" class="form-control" value="${pre?.date ? pre.date.slice(0, 10) : todayISO()}">
    </div>
    <div class="form-group">
      <label class="form-label">${esc(t('web_form_title_note'))}</label>
      <input type="text" id="tx-note" class="form-control" placeholder="${esc(t('web_form_optional'))}" value="${esc(pre?.note || '')}">
    </div>`;
}

function _setupTxForm() {
  const tabs = document.querySelectorAll('.type-tab');
  const fgDest = document.getElementById('fg-dest');
  const fgCat = document.getElementById('fg-cat');
  const lblAcct = document.getElementById('lbl-account');
  const acctSel = document.getElementById('tx-account');
  const curInput = document.getElementById('tx-currency');

  function applyType(tp) {
    tabs.forEach(tab => tab.classList.toggle('active', tab.dataset.type === tp));
    fgDest.style.display = tp === 'transfer' ? '' : 'none';
    fgCat.style.display = tp === 'transfer' ? 'none' : '';
    lblAcct.textContent = tp === 'transfer' ? t('web_form_from_account') : t('web_form_account');
  }

  tabs.forEach(tab => tab.addEventListener('click', () => applyType(tab.dataset.type)));

  const rateGroup = document.getElementById('fg-rate');
  const rateHint = document.getElementById('rate-hint');

  function updateRateVisibility() {
    const baseCur = cache.baseCurrency || 'USD';
    const txCur = curInput.value.trim().toUpperCase();
    if (txCur && txCur !== baseCur) {
      rateGroup.style.display = '';
      rateHint.textContent = t('web_form_rate_hint', { txCur, baseCur });
    } else {
      rateGroup.style.display = 'none';
    }
  }

  curInput.addEventListener('input', updateRateVisibility);

  acctSel.addEventListener('change', () => {
    const opt = acctSel.selectedOptions[0];
    if (opt?.dataset.currency && !curInput.value) curInput.value = opt.dataset.currency;
    updateRateVisibility();
  });
  if (acctSel.value && !curInput.value) {
    const opt = acctSel.selectedOptions[0];
    if (opt?.dataset.currency) curInput.value = opt.dataset.currency;
  }
  updateRateVisibility();
}

function _readTxForm() {
  const type = document.querySelector('.type-tab.active')?.dataset.type || 'expense';
  const accountId = document.getElementById('tx-account').value;
  const amount = parseFloat(document.getElementById('tx-amount').value);
  const currency = (document.getElementById('tx-currency').value.trim() || 'USD').toUpperCase();
  const date = document.getElementById('tx-date').value;
  const note = document.getElementById('tx-note').value.trim();

  if (!accountId) { toast(t('web_val_select_account'), true); return null; }
  if (!amount || amount <= 0) { toast(t('web_val_valid_amount'), true); return null; }

  const body = { type, accountId, amount, currency, note };
  const rateVal = parseFloat(document.getElementById('tx-rate')?.value);
  const baseCur = cache.baseCurrency || 'USD';
  if (currency !== baseCur && rateVal && rateVal > 0) {
    body.exchangeRateToBase = rateVal;
  }
  if (date) body.date = date + 'T12:00:00.000Z';

  if (type === 'transfer') {
    const destId = document.getElementById('tx-dest').value;
    if (!destId) { toast(t('web_val_select_dest'), true); return null; }
    if (destId === accountId) { toast(t('web_val_accounts_differ'), true); return null; }
    body.destinationAccountId = destId;
  } else {
    const catId = document.getElementById('tx-cat').value;
    if (catId) body.categoryId = catId;
  }
  return body;
}

async function addTransaction() {
  const [accounts, cats] = await Promise.all([getAccounts(), getCategories()]);
  openModal(t('web_modal_add_tx'), _txFormHtml(accounts, cats), async () => {
    const body = _readTxForm();
    if (!body) return;
    const res = await api('/api/transactions', { method: 'POST', body: JSON.stringify(body) });
    if (res) { toast(t('web_toast_tx_added')); invalidateAll(); closeModal(); renderTransactions(_txPage, _txFilter, _txSearch); }
  });
  _setupTxForm();
}

async function editTransaction(id) {
  const [detail, accounts, cats] = await Promise.all([
    api(`/api/transactions/${id}`),
    getAccounts(),
    getCategories(),
  ]);
  if (!detail) return;
  openModal(t('web_modal_edit_tx'), _txFormHtml(accounts, cats, detail), async () => {
    const body = _readTxForm();
    if (!body) return;
    const res = await api(`/api/transactions/${id}`, { method: 'PUT', body: JSON.stringify(body) });
    if (res) { toast(t('web_toast_tx_updated')); invalidateAll(); closeModal(); renderTransactions(_txPage, _txFilter, _txSearch); }
  });
  _setupTxForm();
}

async function deleteTransaction(id) {
  // Delete immediately, offer undo via toast
  const res = await api(`/api/transactions/${id}`, { method: 'DELETE' });
  if (res) {
    invalidateAll();
    renderTransactions(_txPage, _txFilter, _txSearch);
    toast(t('web_toast_tx_deleted'), false);
  }
}

async function toggleTxDetail(id, rowEl) {
  const existing = document.getElementById(`tx-lines-${id}`);
  if (existing) { existing.remove(); return; }

  const detail = await api(`/api/transactions/${id}`);
  if (!detail?.lines?.length) { toast(t('web_toast_no_lines')); return; }

  const linesHtml = detail.lines.map(l => {
    const hasRate = l.exchangeRateToBase && Math.abs(l.exchangeRateToBase - 1) > 0.001;
    return `<tr>
      <td>${fmt(l.amount, l.currency)}</td>
      <td>${esc(l.currency)}</td>
      <td>${l.categoryName ? `${_isEmoji(l.categoryIcon) ? esc(l.categoryIcon) + ' ' : ''}${esc(l.categoryName)}` : '<span class="text-secondary">—</span>'}</td>
      <td>${esc(l.accountName || '—')}</td>
      <td class="text-secondary">${esc(l.note || '')}</td>
      <td class="text-secondary">${hasRate ? l.exchangeRateToBase.toFixed(4) : ''}</td>
    </tr>`;
  }).join('');

  const detailRow = document.createElement('tr');
  detailRow.id = `tx-lines-${id}`;
  detailRow.innerHTML = `<td colspan="7" class="tx-detail-cell">
    <div class="tx-detail-inner">
      <div style="font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:var(--text-secondary);margin-bottom:8px">${esc(t('web_tx_lines_header', { count: detail.lines.length }))}</div>
      <table class="data-table">
        <thead><tr><th>${esc(t('web_th_line_amount'))}</th><th>${esc(t('web_th_line_currency'))}</th><th>${esc(t('web_th_line_category'))}</th><th>${esc(t('web_th_line_account'))}</th><th>${esc(t('web_th_line_note'))}</th><th>${esc(t('web_th_line_rate'))}</th></tr></thead>
        <tbody>${linesHtml}</tbody>
      </table>
    </div>
  </td>`;
  rowEl.after(detailRow);
}

// Returns true if str starts with a non-ASCII codepoint (i.e. is an emoji, not a keyword like "category")
function _isEmoji(str) {
  return !!str && str.codePointAt(0) > 255;
}

// ── Categories ────────────────────────────────────────────────────────────────
async function renderCategories() {
  setContent(skeleton(6));
  const d = await api('/api/categories');
  if (!d) return;
  cache.categories = d.items || [];

  const expense = d.items.filter(c => c.transactionType !== 'income');
  const income  = d.items.filter(c => c.transactionType === 'income');

  function buildGroups(items) {
    const idSet = new Set(items.map(c => c.id));
    const roots = items.filter(c => !c.parentId || !idSet.has(c.parentId));
    const childrenOf = {};
    items.filter(c => c.parentId && idSet.has(c.parentId)).forEach(c => {
      if (!childrenOf[c.parentId]) childrenOf[c.parentId] = [];
      childrenOf[c.parentId].push(c);
    });
    return roots.map(r => ({ parent: r, children: childrenOf[r.id] || [] }));
  }

  function catIcon(icon, name) {
    // Show emoji icon if present, otherwise first letter of name
    if (_isEmoji(icon)) return icon;
    return name ? name.charAt(0).toUpperCase() : '?';
  }

  function catCard(group) {
    const p = group.parent;
    const childCount = group.children.length;
    const childHtml = group.children.map(ch => {
      return `<div class="cat-child">
        <span class="cat-child-icon" style="background:${safeHex(ch.colorHex)}">${esc(catIcon(ch.icon, ch.name))}</span>
        <span class="cat-child-name">${esc(ch.name)}</span>
        <button class="cat-edit-btn" onclick="event.stopPropagation();openEditCategory('${esc(ch.id)}')">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/></svg>
        </button>
      </div>`;
    }).join('');

    return `<div class="cat-card">
      <div class="cat-card-header">
        <span class="cat-card-icon" style="background:${safeHex(p.colorHex)}">${esc(catIcon(p.icon, p.name))}</span>
        <div class="cat-card-info">
          <div class="cat-card-name">${esc(p.name)}</div>
          ${childCount > 0 ? `<div class="cat-card-count">${childCount === 1 ? esc(t('web_cat_sub_singular')) : esc(t('web_cat_sub_plural', { count: childCount }))}</div>` : ''}
        </div>
        <button class="cat-edit-btn" onclick="openEditCategory('${esc(p.id)}')">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/></svg>
        </button>
      </div>
      ${childCount > 0 ? `<div class="cat-children">${childHtml}</div>` : ''}
    </div>`;
  }

  function section(label, badgeCls, items) {
    if (!items.length) return '';
    const groups = buildGroups(items);
    return `
      <div style="margin-bottom:24px">
        <div style="display:flex;align-items:center;gap:8px;margin-bottom:12px">
          <span class="section-title" style="margin-bottom:0">${label}</span>
          <span class="badge ${badgeCls}" style="font-size:10px">${items.length}</span>
        </div>
        <div class="cat-grid">${groups.map(catCard).join('')}</div>
      </div>`;
  }

  const content = items(d).length
    ? section(t('web_cat_section_expense'), 'badge-expense', expense) + section(t('web_cat_section_income'), 'badge-income', income)
    : empty(t('web_cat_empty_title'), t('web_cat_empty_sub'));

  setContent(`
    <div class="page-header">
      <h1 class="page-title">${esc(t('nav_categories'))}</h1>
      <button class="btn btn-primary" onclick="openAddCategory()">${esc(t('web_tx_add'))}</button>
    </div>
    ${content}`);
}

function _catFormHtml(pre = null) {
  const cats = cache.categories || [];
  const parentOpts = cats.filter(c => !c.parentId).map(c =>
    `<option value="${c.id}" ${pre?.parentId === c.id ? 'selected' : ''}>${_isEmoji(c.icon) ? c.icon + ' ' : ''}${esc(c.name)}</option>`).join('');
  return `
    <div class="form-group">
      <label class="form-label">${esc(t('web_cat_form_name'))}</label>
      <input type="text" id="cat-name" class="form-control" value="${esc(pre?.name || '')}" placeholder="${esc(t('web_cat_form_name_hint'))}">
    </div>
    <div class="form-group">
      <label class="form-label">${esc(t('web_cat_form_parent'))}</label>
      <select id="cat-parent" class="form-control">
        <option value="">${esc(t('web_cat_form_none'))}</option>
        ${parentOpts}
      </select>
    </div>
    <div style="display:flex;gap:12px">
      <div class="form-group" style="flex:1">
        <label class="form-label">${esc(t('web_cat_form_icon'))}</label>
        <input type="text" id="cat-icon" class="form-control" value="${esc(pre?.icon || '')}" placeholder="🛒">
      </div>
      <div class="form-group" style="flex:1">
        <label class="form-label">${esc(t('web_cat_form_color'))}</label>
        <input type="color" id="cat-color" class="form-control" value="${esc(pre?.colorHex || '#607D8B')}" style="height:42px;padding:4px;cursor:pointer">
      </div>
    </div>
    <div class="form-group">
      <label class="form-label">${esc(t('web_cat_form_type'))}</label>
      <select id="cat-type" class="form-control">
        <option value="expense" ${pre?.transactionType !== 'income' ? 'selected' : ''}>${esc(t('type_expense'))}</option>
        <option value="income" ${pre?.transactionType === 'income' ? 'selected' : ''}>${esc(t('type_income'))}</option>
      </select>
    </div>`;
}

async function openAddCategory() {
  if (!cache.categories) await getCategories();
  openModal(t('web_modal_add_cat'), _catFormHtml(), async () => {
    const name = document.getElementById('cat-name').value.trim();
    if (!name) { toast(t('web_val_name_required'), true); return; }
    const parentId = document.getElementById('cat-parent').value || undefined;
    const body = {
      name,
      icon: document.getElementById('cat-icon').value.trim() || 'category',
      colorHex: document.getElementById('cat-color').value,
      transactionType: document.getElementById('cat-type').value,
      parentId,
    };
    const res = await api('/api/categories', { method: 'POST', body: JSON.stringify(body) });
    if (res) { toast(t('web_toast_cat_added')); invalidate('categories'); closeModal(); renderCategories(); }
  });
}

function openEditCategory(id) {
  const c = (cache.categories || []).find(x => x.id === id);
  if (!c) { toast(t('web_toast_cat_not_found'), true); return; }
  openModal(t('web_modal_edit_cat'), _catFormHtml(c), async () => {
    const name = document.getElementById('cat-name').value.trim();
    if (!name) { toast(t('web_val_name_required'), true); return; }
    const body = {
      name,
      icon: document.getElementById('cat-icon').value.trim() || c.icon,
      colorHex: document.getElementById('cat-color').value,
      transactionType: document.getElementById('cat-type').value,
    };
    const res = await api(`/api/categories/${id}`, { method: 'PUT', body: JSON.stringify(body) });
    if (res) { toast(t('web_toast_cat_updated')); invalidate('categories'); closeModal(); renderCategories(); }
  });
}

// ── Accounts ──────────────────────────────────────────────────────────────────
async function renderAccounts() {
  setContent(skeleton(5));
  const d = await api('/api/accounts');
  if (!d) return;
  cache.accounts = d.items || [];

  if (!items(d).length) {
    setContent(`
      <div class="page-header">
        <h1 class="page-title">${esc(t('nav_accounts'))}</h1>
        <button class="btn btn-primary" onclick="openAddAccount()">${esc(t('web_tx_add'))}</button>
      </div>
      ${empty(t('web_acct_empty_title'), t('web_acct_empty_sub'))}`);
    return;
  }

  const typeOrder = ['bank', 'cash', 'credit', 'wallet'];
  const typeLabels = { bank: t('web_acct_type_bank'), cash: t('web_acct_type_cash'), credit: t('web_acct_type_credit'), wallet: t('web_acct_type_wallet') };
  const typeIcons = {
    bank: '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 21h18M3 10h18M5 6l7-3 7 3M4 10v11M20 10v11M8 14v3M12 14v3M16 14v3"/></svg>',
    cash: '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="2"/><path d="M6 12h.01M18 12h.01"/></svg>',
    credit: '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="5" width="20" height="14" rx="2"/><line x1="2" x2="22" y1="10" y2="10"/></svg>',
    wallet: '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12V7H5a2 2 0 0 1 0-4h14v4"/><path d="M3 5v14a2 2 0 0 0 2 2h16v-5"/><path d="M18 12a2 2 0 0 0 0 4h4v-4Z"/></svg>',
  };
  const grouped = {};
  d.items.forEach(a => { const tp = a.type || 'bank'; if (!grouped[tp]) grouped[tp] = []; grouped[tp].push(a); });

  // Net worth — horizontal scroll cards (same as dashboard)
  const byCurrency = {};
  d.items.forEach(a => { byCurrency[a.currency] = (byCurrency[a.currency] || 0) + a.balance; });
  const netWorthHtml = `<div class="acct-scroll" style="margin-bottom:20px">${Object.entries(byCurrency).map(([cur, total]) => {
    const count = d.items.filter(a => a.currency === cur).length;
    return `<div class="acct-card">
      <div class="acct-name">${esc(t('web_acct_net_worth', { cur }))}</div>
      <div class="acct-balance${total < 0 ? ' negative' : ''}">${fmt(total, cur)}</div>
      <span class="acct-type">${count === 1 ? esc(t('web_acct_count_singular')) : esc(t('web_acct_count_plural', { count }))}</span>
    </div>`;
  }).join('')}</div>`;

  // Account groups — card rows, clickable
  let sectionsHtml = '';
  typeOrder.forEach(type => {
    const accts = grouped[type]; if (!accts?.length) return;
    const groupTotal = {}; accts.forEach(a => { groupTotal[a.currency] = (groupTotal[a.currency] || 0) + a.balance; });
    const totalStr = Object.entries(groupTotal).map(([c, amt]) => fmt(amt, c)).join(' + ');

    const rows = accts.map(a => `
      <div class="acct-row" onclick="viewAccountTransactions('${esc(a.id)}','${esc(a.name)}')">
        <div class="acct-row-left">
          <div class="acct-row-name">${esc(a.name)}</div>
          <span class="acct-row-cur">${esc(a.currency)}</span>
        </div>
        <div class="acct-row-bal${a.balance < 0 ? ' negative' : ''}">${fmt(a.balance, a.currency)}</div>
        <svg class="acct-row-arrow" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 18 15 12 9 6"/></svg>
      </div>`).join('');

    sectionsHtml += `
      <div class="card" style="padding:0;margin-bottom:12px;overflow:hidden">
        <div class="acct-group-header">
          <div style="display:flex;align-items:center;gap:8px">
            <span style="color:var(--text-secondary)">${typeIcons[type] || ''}</span>
            <span class="acct-group-label">${typeLabels[type] || type}</span>
          </div>
          <span class="acct-group-total">${totalStr}</span>
        </div>
        ${rows}
      </div>`;
  });

  setContent(`
    <div class="page-header"><h1 class="page-title">${esc(t('nav_accounts'))}</h1><button class="btn btn-primary" onclick="openAddAccount()">${esc(t('web_tx_add'))}</button></div>
    ${netWorthHtml}
    ${sectionsHtml}`);
}

let _acctTxPage = 1;
async function viewAccountTransactions(accountId, accountName, page) {
  page = page || 1; _acctTxPage = page;
  setContent(skeleton(6));
  const txData = await api(`/api/transactions?page=${page}&limit=25&accountId=${accountId}`);
  if (!txData) return;
  const baseCur = txData.baseCurrency || cache.baseCurrency || 'USD';
  const rows = items(txData).length
    ? items(txData).map(tx => {
        const lineCur = tx.lineCurrency || tx.currency;
        const lineAmt = tx.lineAmount ?? tx.amount;
        const isForeign = lineCur !== baseCur;
        const hasRealRate = isForeign && tx.lineExchangeRate && Math.abs(tx.lineExchangeRate - 1) > 0.001;
        let amountHtml = isForeign
          ? `${amtEl(lineAmt, lineCur, tx.type)}${hasRealRate ? `<div class="text-secondary" style="font-size:11px">${fmt(lineAmt * tx.lineExchangeRate, baseCur)}</div>` : `<div style="font-size:11px;color:var(--caution)">⚠ ${esc(t('web_tx_no_rate'))}</div>`}`
          : amtEl(tx.amount, tx.currency, tx.type);
        return `<tr>
          <td class="text-secondary text-sm" style="white-space:nowrap">${fmtDate(tx.date)}</td>
          <td>${typeBadge(tx.type)}</td>
          <td class="text-sm" style="max-width:180px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${esc(tx.note || '—')}</td>
          <td class="text-sm">${tx.categoryName ? `<div style="display:flex;align-items:center;gap:6px"><span style="width:8px;height:8px;border-radius:50%;background:${safeHex(tx.categoryColor || '#607D8B')};flex-shrink:0"></span>${_isEmoji(tx.categoryIcon) ? esc(tx.categoryIcon) + ' ' : ''}${esc(tx.categoryName)}</div>` : '<span class="text-secondary">—</span>'}</td>
          <td class="text-sm">${tx.type === 'transfer' ? `${esc(tx.accountName || '')} <span class="text-secondary">→</span> ${esc(tx.destinationAccountName || '')}` : esc(tx.accountName || '')}</td>
          <td style="text-align:right;white-space:nowrap">${amountHtml}</td>
        </tr>`;
      }).join('')
    : `<tr><td colspan="6" style="padding:32px;text-align:center;color:var(--text-secondary)">${esc(t('web_acct_tx_empty'))}</td></tr>`;
  setContent(`
    <div class="page-header"><div style="display:flex;align-items:center;gap:12px"><button class="btn btn-outline btn-sm" onclick="renderAccounts()">${esc(t('web_acct_back'))}</button><h1 class="page-title">${esc(accountName)}</h1></div></div>
    <div class="card" style="padding:0;overflow:auto"><table class="data-table">
      <thead><tr><th>${esc(t('web_tx_th_date'))}</th><th>${esc(t('web_tx_th_type'))}</th><th>${esc(t('web_tx_th_title'))}</th><th>${esc(t('web_tx_th_category'))}</th><th>${esc(t('web_tx_th_account'))}</th><th style="text-align:right">${esc(t('web_tx_th_amount'))}</th></tr></thead>
      <tbody>${rows}</tbody></table></div>
    <div class="pagination">
      <button class="btn btn-outline btn-sm" ${page <= 1 ? 'disabled' : ''} onclick="viewAccountTransactions('${esc(accountId)}','${esc(accountName)}',${page - 1})">${esc(t('web_tx_prev'))}</button>
      <span class="text-secondary text-sm">${esc(t('web_tx_page_n', { page }))}</span>
      <button class="btn btn-outline btn-sm" ${items(txData).length < 25 ? 'disabled' : ''} onclick="viewAccountTransactions('${esc(accountId)}','${esc(accountName)}',${page + 1})">${esc(t('web_tx_next'))}</button>
    </div>`);
}

function openAddAccount() {
  const html = `
    <div class="form-group"><label class="form-label">${esc(t('web_cat_form_name'))}</label><input type="text" id="acct-name" class="form-control" placeholder="${esc(t('web_acct_form_name_hint'))}"></div>
    <div style="display:flex;gap:12px">
      <div class="form-group" style="flex:1"><label class="form-label">${esc(t('web_acct_form_type'))}</label><select id="acct-type" class="form-control"><option value="bank">${esc(t('web_acct_form_type_bank'))}</option><option value="cash">${esc(t('web_acct_form_type_cash'))}</option><option value="credit">${esc(t('web_acct_form_type_credit'))}</option><option value="wallet">${esc(t('web_acct_form_type_wallet'))}</option></select></div>
      <div class="form-group" style="flex:1"><label class="form-label">${esc(t('web_form_currency'))}</label><input type="text" id="acct-currency" class="form-control" maxlength="3" placeholder="${esc(t('web_form_currency_placeholder'))}" value="USD"></div>
    </div>
    <div class="form-group"><label class="form-label">${esc(t('web_acct_form_opening'))}</label><input type="number" id="acct-balance" class="form-control" value="0" min="0" step="0.01"></div>`;
  openModal(t('web_modal_add_acct'), html, async () => {
    const name = document.getElementById('acct-name').value.trim();
    if (!name) { toast(t('web_val_name_required'), true); return; }
    const body = { name, type: document.getElementById('acct-type').value, currency: (document.getElementById('acct-currency').value.trim() || 'USD').toUpperCase(), initialBalance: parseFloat(document.getElementById('acct-balance').value) || 0 };
    const res = await api('/api/accounts', { method: 'POST', body: JSON.stringify(body) });
    if (res) { toast(t('web_toast_acct_added')); invalidateAll(); closeModal(); renderAccounts(); }
  });
}

// ── Envelopes ─────────────────────────────────────────────────────────────────
async function renderEnvelopes() {
  setContent(skeleton(4));
  const d = await api('/api/envelopes');
  if (!d) return;
  cache.envelopes = d.items || [];
  const unallocEntries = Object.entries(d.unallocated || {});
  const unallocHtml = unallocEntries.length
    ? unallocEntries.map(([cur, amt]) => `<span class="unalloc-pill ${amt < 0 ? 'unalloc-pill-warn' : ''}">${fmt(amt, cur)}</span>`).join(' ')
    : '<span class="text-secondary">—</span>';
  const envsHtml = items(d).length
    ? `<div class="env-grid">${items(d).map(e => {
        const entries = Object.entries(e.balanceByCurrency || {});
        const [cur, bal] = entries[0] ?? ['USD', 0];
        const pct = e.targetAmount ? Math.min(100, Math.max(0, (bal / e.targetAmount) * 100)) : null;
        const isOver = bal < 0;
        return `<div class="envelope-card"><div class="envelope-header"><div><div class="envelope-name">${esc(e.icon || '📁')} ${esc(e.name)}</div><div class="text-secondary text-sm" style="margin-top:2px">${esc(e.type)} · ${esc(e.periodicity)}</div></div><div style="text-align:right;flex-shrink:0"><div class="${bal < 0 ? 'amount-expense' : bal > 0 ? 'amount-income' : ''}" style="font-weight:700;font-size:15px">${fmt(bal, cur)}</div>${e.targetAmount ? `<div class="text-secondary text-sm">${esc(t('web_env_balance_of_target', { balance: fmt(bal, cur), target: fmt(e.targetAmount, e.targetCurrency || cur) }))}</div>` : ''}</div></div>${pct !== null ? `<div class="progress-bar" style="margin-bottom:12px"><div class="progress-fill ${isOver ? 'over' : ''}" style="width:${pct.toFixed(1)}%"></div></div>` : '<div style="margin-bottom:12px"></div>'}<button class="btn btn-sm btn-outline" onclick="openFundEnvelope('${esc(e.id)}','${esc(cur)}')">${esc(t('web_env_fund'))}</button></div>`;
      }).join('')}</div>`
    : empty(t('web_env_empty_title'), t('web_env_empty_sub'));
  setContent(`<div class="page-header"><h1 class="page-title">${esc(t('nav_envelopes'))}</h1><div style="display:flex;align-items:center;gap:12px"><span class="text-secondary text-sm">${esc(t('web_env_unallocated'))} ${unallocHtml}</span></div></div>${envsHtml}`);
}

function openFundEnvelope(id, defaultCurrency) {
  openModal(t('web_modal_fund'), `
    <div class="form-group"><label class="form-label">${esc(t('web_form_amount_to_fund'))}</label><input type="number" id="fund-amount" class="form-control" min="0.01" step="0.01" placeholder="${esc(t('web_form_amount_placeholder'))}"></div>
    <div class="form-group"><label class="form-label">${esc(t('web_form_currency'))}</label><input type="text" id="fund-currency" class="form-control" maxlength="3" value="${esc(defaultCurrency)}"></div>
    <div class="form-group"><label class="form-label">${esc(t('web_form_note'))}</label><input type="text" id="fund-note" class="form-control" placeholder="${esc(t('web_form_optional'))}"></div>`, async () => {
    const amount = parseFloat(document.getElementById('fund-amount').value);
    const currency = (document.getElementById('fund-currency').value.trim() || 'USD').toUpperCase();
    const note = document.getElementById('fund-note').value.trim();
    if (!amount || amount <= 0) { toast(t('web_val_valid_amount'), true); return; }
    const res = await api(`/api/envelopes/${id}/fund`, { method: 'POST', body: JSON.stringify({ amount, currency, note }) });
    if (res) { toast(t('web_toast_env_funded')); invalidateAll(); closeModal(); renderEnvelopes(); }
  }, t('web_btn_fund_confirm'));
}

// ── Recurring ─────────────────────────────────────────────────────────────────
async function renderRecurring() {
  setContent(skeleton(5));
  const [d, accounts, cats] = await Promise.all([api('/api/recurring'), getAccounts(), getCategories()]);
  if (!d) return;
  cache._recurringItems = d.items;
  const rows = items(d).length
    ? items(d).map(r => { const acct = accounts.find(a => a.id === r.accountId); const cat = cats.find(c => c.id === r.categoryId); return `<tr><td>${esc(r.title || '—')}</td><td>${typeBadge(r.type)}</td><td>${esc(acct?.name || r.accountId)}</td><td>${cat ? `${esc(cat.icon)} ${esc(cat.name)}` : '<span class="text-secondary">—</span>'}</td><td class="text-sm">${fmtFreq(r.frequency, r.interval)}</td><td style="white-space:nowrap">${fmt(r.amount, r.currency)}</td><td class="text-secondary text-sm">${fmtDate(r.nextDueDate)}</td><td><label class="toggle-wrap" title="${r.enabled ? t('web_toggle_enabled') : t('web_toggle_disabled')}"><input type="checkbox" ${r.enabled ? 'checked' : ''} onchange="toggleRecurring('${esc(r.id)}', this.checked)"><span class="toggle-slider"></span></label></td><td style="white-space:nowrap"><button class="btn btn-sm btn-outline" onclick="openEditRecurring('${esc(r.id)}')">${esc(t('common_edit'))}</button> <button class="btn btn-sm btn-danger" style="margin-left:4px" onclick="deleteRecurring('${esc(r.id)}')">${esc(t('web_tx_del'))}</button></td></tr>`; }).join('')
    : `<tr><td colspan="9" style="padding:32px;text-align:center;color:var(--text-secondary)">${esc(t('web_recurring_empty'))}<br><button class="btn btn-primary btn-sm" style="margin-top:12px" onclick="openAddRecurring()">${esc(t('web_tx_add'))}</button></td></tr>`;
  setContent(`<div class="page-header"><h1 class="page-title">${esc(t('nav_recurring'))}</h1><div style="display:flex;gap:8px"><button class="btn btn-outline btn-sm" onclick="exportCSV()" title="${esc(t('web_tx_csv_tooltip'))}">${esc(t('web_tx_csv'))}</button><button class="btn btn-primary" onclick="openAddRecurring()">${esc(t('web_tx_add'))}</button></div></div><div class="card" style="padding:0;overflow:auto"><table class="data-table"><thead><tr><th>${esc(t('web_tx_th_title'))}</th><th>${esc(t('web_tx_th_type'))}</th><th>${esc(t('web_tx_th_account'))}</th><th>${esc(t('web_tx_th_category'))}</th><th>${esc(t('web_th_frequency'))}</th><th>${esc(t('web_tx_th_amount'))}</th><th>${esc(t('web_th_next_due'))}</th><th>${esc(t('web_th_on'))}</th><th></th></tr></thead><tbody>${rows}</tbody></table></div>`);
}

function _recurFormHtml(pre = null, isSub = false) {
  const accounts = cache.accounts || []; const cats = cache.categories || []; const type = pre?.type || 'expense';
  const acctOpts = accounts.map(a => `<option value="${a.id}" ${pre?.accountId === a.id ? 'selected' : ''}>${esc(a.name)} (${esc(a.currency)})</option>`).join('');
  const catOpts = `<option value="">${esc(t('web_form_none'))}</option>` + cats.map(c => `<option value="${c.id}" ${pre?.categoryId === c.id ? 'selected' : ''}>${_isEmoji(c.icon) ? esc(c.icon) + ' ' : ''}${esc(c.name)}</option>`).join('');
  return `${!isSub ? `<div class="form-group"><label class="form-label">${esc(t('web_form_type'))}</label><div class="type-tabs"><button type="button" class="type-tab${type === 'expense' ? ' active' : ''}" data-type="expense">${esc(t('type_expense'))}</button><button type="button" class="type-tab${type === 'income' ? ' active' : ''}" data-type="income">${esc(t('type_income'))}</button><button type="button" class="type-tab${type === 'transfer' ? ' active' : ''}" data-type="transfer">${esc(t('type_transfer'))}</button></div></div>` : ''}
    <div class="form-group"><label class="form-label">${esc(t('web_form_title_label'))}</label><input type="text" id="rec-title" class="form-control" value="${esc(pre?.title || '')}" placeholder="${esc(t('web_form_title_hint'))}"></div>
    <div class="form-group"><label class="form-label">${esc(t('web_form_account'))}</label><select id="rec-account" class="form-control">${acctOpts}</select></div>
    <div class="form-group"><label class="form-label">${esc(t('web_form_category'))}</label><select id="rec-cat" class="form-control">${catOpts}</select></div>
    <div style="display:flex;gap:12px"><div class="form-group" style="flex:1"><label class="form-label">${esc(t('web_form_amount'))}</label><input type="number" id="rec-amount" class="form-control" min="0.01" step="0.01" value="${esc(pre?.amount || '')}" placeholder="${esc(t('web_form_amount_placeholder'))}"></div><div class="form-group" style="width:80px"><label class="form-label">${esc(t('web_form_currency'))}</label><input type="text" id="rec-currency" class="form-control" maxlength="3" value="${esc(pre?.currency || 'USD')}"></div></div>
    <div style="display:flex;gap:12px"><div class="form-group" style="flex:1"><label class="form-label">${esc(t('web_form_frequency'))}</label><select id="rec-freq" class="form-control">${['daily','weekly','monthly','yearly'].map(f => `<option value="${f}" ${pre?.frequency === f ? 'selected' : ''}>${{daily:t('freq_daily'),weekly:t('freq_weekly'),monthly:t('freq_monthly'),yearly:t('freq_yearly')}[f]}</option>`).join('')}</select></div><div class="form-group" style="width:70px"><label class="form-label">${esc(t('web_form_every'))}</label><input type="number" id="rec-interval" class="form-control" value="${esc(pre?.interval || '1')}" min="1" max="99"></div></div>
    <div class="form-group"><label class="form-label">${esc(t('web_form_start_date'))}</label><input type="date" id="rec-start" class="form-control" value="${pre?.nextDueDate ? pre.nextDueDate.slice(0,10) : todayISO()}"></div>
    <div class="form-group"><label class="form-label">${esc(t('web_form_note'))}</label><input type="text" id="rec-note" class="form-control" value="${esc(pre?.note || '')}" placeholder="${esc(t('web_form_optional'))}"></div>`;
}

async function openAddRecurring() {
  await Promise.all([getAccounts(), getCategories()]);
  openModal(t('web_modal_add_recurring'), _recurFormHtml(), async () => {
    const type = document.querySelector('.type-tab.active')?.dataset.type || 'expense';
    const body = _readRecurForm(type, false); if (!body) return;
    const res = await api('/api/recurring', { method: 'POST', body: JSON.stringify(body) });
    if (res) { toast(t('web_toast_recurring_added')); closeModal(); renderRecurring(); }
  });
  document.querySelectorAll('.type-tab').forEach(tab => tab.addEventListener('click', () => document.querySelectorAll('.type-tab').forEach(tt => tt.classList.toggle('active', tt === tab))));
}

function openEditRecurring(id) {
  const r = (cache._recurringItems || []).find(x => x.id === id); if (!r) { toast(t('web_toast_not_found'), true); return; }
  openModal(t('web_modal_edit_recurring'), `<div class="form-group"><label class="form-label">${esc(t('web_form_title_label'))}</label><input type="text" id="rec-title" class="form-control" value="${esc(r.title || '')}"></div><div class="form-group"><label class="form-label">${esc(t('web_form_amount'))}</label><input type="number" id="rec-amount" class="form-control" value="${esc(r.amount)}" min="0.01" step="0.01"></div><div class="form-group"><label class="form-label">${esc(t('web_form_note'))}</label><input type="text" id="rec-note" class="form-control" value="${esc(r.note || '')}"></div>`, async () => {
    const body = { title: document.getElementById('rec-title').value.trim(), amount: parseFloat(document.getElementById('rec-amount').value), note: document.getElementById('rec-note').value.trim() };
    const res = await api(`/api/recurring/${id}`, { method: 'PUT', body: JSON.stringify(body) });
    if (res) { toast(t('web_toast_updated')); closeModal(); renderRecurring(); }
  });
}

function _readRecurForm(type, isSub) {
  const accountId = document.getElementById('rec-account')?.value;
  const amount = parseFloat(document.getElementById('rec-amount').value);
  const currency = (document.getElementById('rec-currency').value.trim() || 'USD').toUpperCase();
  const startDate = document.getElementById('rec-start').value;
  if (!accountId) { toast(t('web_val_select_account'), true); return null; }
  if (!amount || amount <= 0) { toast(t('web_val_valid_amount'), true); return null; }
  if (!startDate) { toast(t('web_val_select_start_date'), true); return null; }
  return { type: isSub ? 'expense' : type, title: document.getElementById('rec-title').value.trim(), accountId, categoryId: document.getElementById('rec-cat')?.value || undefined, amount, currency, frequency: document.getElementById('rec-freq').value, interval: parseInt(document.getElementById('rec-interval').value) || 1, startDate, note: document.getElementById('rec-note').value.trim(), isSubscription: isSub };
}

async function toggleRecurring(id, enabled) {
  const res = await api(`/api/recurring/${id}`, { method: 'PUT', body: JSON.stringify({ enabled }) });
  if (res) { toast(t('web_toast_updated')); invalidate('_recurringItems'); }
  else renderRecurring();
}

async function deleteRecurring(id) {
  const ok = await confirmDialog(t('web_confirm_delete_recurring'), t('web_confirm_delete_recurring_msg'));
  if (!ok) return;
  const res = await api(`/api/recurring/${id}`, { method: 'DELETE' });
  if (res) { toast(t('web_toast_deleted')); renderRecurring(); }
}

// ── Subscriptions ─────────────────────────────────────────────────────────────
async function renderSubscriptions() {
  setContent(skeleton(5));
  const [d, accounts, cats] = await Promise.all([api('/api/subscriptions'), getAccounts(), getCategories()]);
  if (!d) return;
  cache._subItems = d.items;
  const rows = items(d).length
    ? items(d).map(r => { const acct = accounts.find(a => a.id === r.accountId); const cat = cats.find(c => c.id === r.categoryId); return `<tr><td style="font-weight:600">${esc(r.title || '—')}</td><td>${esc(acct?.name || r.accountId)}</td><td>${cat ? `${esc(cat.icon)} ${esc(cat.name)}` : '<span class="text-secondary">—</span>'}</td><td class="text-sm">${fmtFreq(r.frequency, r.interval)}</td><td style="white-space:nowrap;font-weight:600">${fmt(r.amount, r.currency)}</td><td class="text-secondary text-sm">${fmtDate(r.nextDueDate)}</td><td><label class="toggle-wrap"><input type="checkbox" ${r.enabled ? 'checked' : ''} onchange="toggleSubscription('${esc(r.id)}', this.checked)"><span class="toggle-slider"></span></label></td><td style="white-space:nowrap"><button class="btn btn-sm btn-outline" onclick="openEditSubscription('${esc(r.id)}')">${esc(t('common_edit'))}</button> <button class="btn btn-sm btn-danger" style="margin-left:4px" onclick="deleteSubscription('${esc(r.id)}')">${esc(t('web_tx_del'))}</button></td></tr>`; }).join('')
    : `<tr><td colspan="8" style="padding:32px;text-align:center;color:var(--text-secondary)">${esc(t('web_sub_empty'))}<br><button class="btn btn-primary btn-sm" style="margin-top:12px" onclick="openAddSubscription()">${esc(t('web_tx_add'))}</button></td></tr>`;
  setContent(`<div class="page-header"><h1 class="page-title">${esc(t('nav_subscriptions'))}</h1><div style="display:flex;gap:8px"><button class="btn btn-outline btn-sm" onclick="exportCSV()" title="${esc(t('web_tx_csv_tooltip'))}">${esc(t('web_tx_csv'))}</button><button class="btn btn-primary" onclick="openAddSubscription()">${esc(t('web_tx_add'))}</button></div></div><div class="card" style="padding:0;overflow:auto"><table class="data-table"><thead><tr><th>${esc(t('web_th_service'))}</th><th>${esc(t('web_tx_th_account'))}</th><th>${esc(t('web_tx_th_category'))}</th><th>${esc(t('web_th_frequency'))}</th><th>${esc(t('web_tx_th_amount'))}</th><th>${esc(t('web_th_next_due'))}</th><th>${esc(t('web_th_on'))}</th><th></th></tr></thead><tbody>${rows}</tbody></table></div>`);
}

async function openAddSubscription() {
  await Promise.all([getAccounts(), getCategories()]);
  openModal(t('web_modal_add_sub'), _recurFormHtml(null, true), async () => {
    const body = _readRecurForm('expense', true); if (!body) return;
    const res = await api('/api/subscriptions', { method: 'POST', body: JSON.stringify(body) });
    if (res) { toast(t('web_toast_sub_added')); closeModal(); renderSubscriptions(); }
  });
}

function openEditSubscription(id) {
  const r = (cache._subItems || []).find(x => x.id === id); if (!r) { toast(t('web_toast_not_found'), true); return; }
  openModal(t('web_modal_edit_sub'), `<div class="form-group"><label class="form-label">${esc(t('web_form_title_label'))}</label><input type="text" id="sub-title" class="form-control" value="${esc(r.title || '')}"></div><div style="display:flex;gap:12px"><div class="form-group" style="flex:1"><label class="form-label">${esc(t('web_form_new_amount'))}</label><input type="number" id="sub-amount" class="form-control" value="${esc(r.amount)}" min="0.01" step="0.01"></div><div class="form-group" style="width:80px"><label class="form-label">${esc(t('web_form_currency'))}</label><input type="text" class="form-control" value="${esc(r.currency)}" disabled></div></div><p class="text-secondary text-sm" style="margin-top:-8px">${esc(t('web_sub_price_hint'))}</p>`, async () => {
    const body = { title: document.getElementById('sub-title').value.trim(), amount: parseFloat(document.getElementById('sub-amount').value) };
    const res = await api(`/api/subscriptions/${id}`, { method: 'PUT', body: JSON.stringify(body) });
    if (res) { toast(t('web_toast_updated')); closeModal(); renderSubscriptions(); }
  });
}

async function toggleSubscription(id, enabled) {
  const res = await api(`/api/subscriptions/${id}`, { method: 'PUT', body: JSON.stringify({ enabled }) });
  if (res) { toast(t('web_toast_updated')); invalidate('_subItems'); }
  else renderSubscriptions();
}

async function deleteSubscription(id) {
  const ok = await confirmDialog(t('web_confirm_delete_sub'), t('web_confirm_delete_sub_msg'));
  if (!ok) return;
  const res = await api(`/api/subscriptions/${id}`, { method: 'DELETE' });
  if (res) { toast(t('web_toast_deleted')); renderSubscriptions(); }
}

// ── Reports ───────────────────────────────────────────────────────────────────
function renderReports() {
  const now = new Date();
  const mNames = _monthNames();
  const monthOpts = Array.from({ length: 12 }, (_, i) =>
    `<option value="${i + 1}" ${i + 1 === now.getMonth() + 1 ? 'selected' : ''}>${esc(mNames[i])}</option>`
  ).join('');
  setContent(`
    <div class="page-header"><h1 class="page-title">${esc(t('nav_reports'))}</h1></div>
    <div style="display:flex;gap:12px;align-items:flex-end;flex-wrap:wrap;margin-bottom:20px">
      <div><label class="form-label">${esc(t('web_reports_year'))}</label><input type="number" id="rep-year" class="form-control" style="width:90px" value="${now.getFullYear()}" min="2020" max="2040"></div>
      <div><label class="form-label">${esc(t('web_reports_month'))}</label><select id="rep-month" class="form-control" style="width:130px">${monthOpts}</select></div>
      <button class="btn btn-primary" onclick="loadReports()">${esc(t('web_reports_load'))}</button>
    </div>
    <div id="reports-content"><p class="text-secondary">${esc(t('web_reports_select_prompt'))}</p></div>`);
}

async function loadReports() {
  const year = document.getElementById('rep-year').value;
  const month = document.getElementById('rep-month').value;
  const content = document.getElementById('reports-content');
  if (!content) return;
  content.innerHTML = skeleton(4);
  if (_reportChart) { _reportChart.destroy(); _reportChart = null; }
  if (_reportCatChart) { _reportCatChart.destroy(); _reportCatChart = null; }

  const [cashflow, byCategory, byIncome] = await Promise.all([
    api(`/api/reports/cashflow?year=${year}&month=${month}`),
    api(`/api/reports/by-category?year=${year}&month=${month}`),
    api(`/api/reports/by-category?year=${year}&month=${month}&type=income`),
  ]);
  if (!cashflow) return;

  const cur = cashflow.currency || 'USD';
  const daysInMonth = cashflow.daily?.length || 30;
  const savingsRate = cashflow.income > 0 ? ((cashflow.net / cashflow.income) * 100).toFixed(1) : '0.0';
  const avgDaily = cashflow.expense > 0 ? (cashflow.expense / daysInMonth) : 0;
  const txCount = cashflow.transactionCount || 0;
  const expenseCatItems = byCategory?.items || [];
  const incomeCatItems = byIncome?.items || [];
  const incomeTotal = incomeCatItems.reduce((s, i) => s + i.total, 0);
  const topExpenses = cashflow.topExpenses || [];

  const catRows = expenseCatItems.map(item => { const pct = cashflow.expense > 0 ? Math.min(100, (item.total / cashflow.expense) * 100).toFixed(1) : 0; return `<tr><td><div style="display:flex;align-items:center;gap:8px"><span style="width:10px;height:10px;border-radius:50%;background:${safeHex(item.colorHex || '#607D8B')};flex-shrink:0"></span>${esc(item.icon)} ${esc(item.name)}</div></td><td style="text-align:right;white-space:nowrap" class="amount-expense">${fmt(item.total, cur)}</td><td class="text-secondary text-sm" style="text-align:right">${pct}%</td><td style="width:120px"><div class="progress-bar"><div class="progress-fill" style="width:${pct}%;background:${safeHex(item.colorHex || '#607D8B')}"></div></div></td></tr>`; }).join('');
  const incomeCatRows = incomeCatItems.map(item => { const pct = incomeTotal > 0 ? Math.min(100, (item.total / incomeTotal) * 100).toFixed(1) : 0; return `<tr><td><div style="display:flex;align-items:center;gap:8px"><span style="width:10px;height:10px;border-radius:50%;background:${safeHex(item.colorHex || '#059669')};flex-shrink:0"></span>${esc(item.icon)} ${esc(item.name)}</div></td><td style="text-align:right;white-space:nowrap" class="amount-income">${fmt(item.total, cur)}</td><td class="text-secondary text-sm" style="text-align:right">${pct}%</td></tr>`; }).join('');
  const topExpHtml = topExpenses.length ? topExpenses.map(tx => `<tr><td class="text-secondary text-sm" style="white-space:nowrap">${fmtDate(tx.date)}</td><td class="text-sm">${tx.categoryIcon ? esc(tx.categoryIcon) + ' ' : ''}${esc(tx.categoryName || '—')}</td><td class="text-sm">${esc(tx.accountName || '')}</td><td class="text-sm text-secondary" style="max-width:160px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${esc(tx.note || '')}</td><td style="text-align:right;white-space:nowrap" class="amount-expense">${fmt(tx.amount, cur)}</td></tr>`).join('') : '';

  content.innerHTML = `
    <div class="stat-grid" style="margin-bottom:16px">
      <div class="stat-card"><div class="stat-label">${esc(t('web_stat_income'))}</div><div class="stat-value amount-income">${fmt(cashflow.income, cur)}</div></div>
      <div class="stat-card"><div class="stat-label">${esc(t('web_stat_expenses'))}</div><div class="stat-value amount-expense">${fmt(cashflow.expense, cur)}</div></div>
      <div class="stat-card"><div class="stat-label">${esc(t('web_stat_net'))}</div><div class="stat-value ${cashflow.net >= 0 ? 'amount-income' : 'amount-expense'}">${fmt(cashflow.net, cur)}</div></div>
      <div class="stat-card"><div class="stat-label">${esc(t('web_stat_savings_rate'))}</div><div class="stat-value ${Number(savingsRate) >= 0 ? 'amount-income' : 'amount-expense'}">${savingsRate}%</div></div>
      <div class="stat-card"><div class="stat-label">${esc(t('web_stat_avg_daily'))}</div><div class="stat-value">${fmt(avgDaily, cur)}</div></div>
      <div class="stat-card"><div class="stat-label">${esc(t('web_stat_transactions'))}</div><div class="stat-value">${txCount}</div></div>
    </div>
    <div class="card" style="margin-bottom:16px"><div class="report-section-title">${esc(t('web_report_daily_cashflow'))}</div><div style="max-height:280px"><canvas id="cashflow-chart"></canvas></div></div>
    <div class="report-two-col">
      <div class="card" style="margin-bottom:0"><div class="report-section-title">${esc(t('web_report_spending_cat'))}</div>${expenseCatItems.length > 1 ? '<div style="max-height:220px;margin-bottom:16px"><canvas id="cat-doughnut"></canvas></div>' : ''}${expenseCatItems.length ? `<table class="data-table"><tbody>${catRows}</tbody></table>` : `<p class="text-secondary text-sm">${esc(t('web_report_no_expense'))}</p>`}</div>
      <div class="card" style="margin-bottom:0"><div class="report-section-title">${esc(t('web_report_income_cat'))}</div>${incomeCatItems.length ? `<table class="data-table"><tbody>${incomeCatRows}</tbody></table>` : `<p class="text-secondary text-sm">${esc(t('web_report_no_income'))}</p>`}</div>
    </div>
    ${topExpHtml ? `<div class="card" style="padding:0;margin-top:16px"><div style="padding:16px 20px 0"><div class="report-section-title">${esc(t('web_report_top_expenses'))}</div></div><table class="data-table"><thead><tr><th>${esc(t('web_tx_th_date'))}</th><th>${esc(t('web_tx_th_category'))}</th><th>${esc(t('web_tx_th_account'))}</th><th>${esc(t('web_form_note'))}</th><th style="text-align:right">${esc(t('web_tx_th_amount'))}</th></tr></thead><tbody>${topExpHtml}</tbody></table></div>` : ''}`;

  const hasDark = document.documentElement.dataset.theme === 'dark' || (document.documentElement.dataset.theme !== 'light' && window.matchMedia?.('(prefers-color-scheme: dark)').matches);
  const gridColor = hasDark ? 'rgba(255,255,255,.08)' : 'rgba(0,0,0,.07)';
  const textColor = hasDark ? '#94A3B8' : '#64748B';

  const barCtx = document.getElementById('cashflow-chart');
  if (barCtx && window.Chart && cashflow.daily?.length) {
    _reportChart = new Chart(barCtx, { type: 'bar', data: { labels: cashflow.daily.map(d => d.day), datasets: [{ label: t('web_chart_income'), data: cashflow.daily.map(d => d.income), backgroundColor: 'rgba(5,150,105,.75)', borderRadius: 4 }, { label: t('web_chart_expense'), data: cashflow.daily.map(d => d.expense), backgroundColor: 'rgba(220,38,38,.75)', borderRadius: 4 }] }, options: { responsive: true, maintainAspectRatio: true, plugins: { legend: { labels: { color: textColor, font: { family: "'Plus Jakarta Sans', sans-serif", size: 12 } } }, tooltip: { callbacks: { label: c => ` ${c.dataset.label}: ${fmt(c.parsed.y, cur)}` } } }, scales: { x: { grid: { color: gridColor }, ticks: { color: textColor } }, y: { beginAtZero: true, grid: { color: gridColor }, ticks: { color: textColor, callback: v => fmt(v, cur) } } } } });
  }
  const doughCtx = document.getElementById('cat-doughnut');
  if (doughCtx && window.Chart && expenseCatItems.length > 1) {
    _reportCatChart = new Chart(doughCtx, { type: 'doughnut', data: { labels: expenseCatItems.map(i => i.name), datasets: [{ data: expenseCatItems.map(i => i.total), backgroundColor: expenseCatItems.map(i => i.colorHex || '#607D8B'), borderWidth: 0 }] }, options: { responsive: true, maintainAspectRatio: true, cutout: '60%', plugins: { legend: { position: 'right', labels: { color: textColor, font: { family: "'Plus Jakarta Sans', sans-serif", size: 11 }, boxWidth: 10, padding: 8 } }, tooltip: { callbacks: { label: c => ` ${c.label}: ${fmt(c.parsed, cur)}` } } } } });
  }
}

// ── Theme ─────────────────────────────────────────────────────────────────────
function applyTheme(th) {
  state.theme = th;
  localStorage.setItem('pp_theme', th);
  if (th === 'system') { document.documentElement.removeAttribute('data-theme'); }
  else { document.documentElement.dataset.theme = th; }
  const el = document.getElementById('theme-label');
  if (el) el.textContent = { system: t('theme_auto'), dark: t('theme_dark'), light: t('theme_light') }[th] || th;
}

function cycleTheme() {
  const order = ['system', 'light', 'dark'];
  applyTheme(order[(order.indexOf(state.theme) + 1) % 3]);
}

// ── Connection Status ─────────────────────────────────────────────────────────
function startConnectionCheck() {
  stopConnectionCheck();
  checkConnection();
  _connInterval = setInterval(checkConnection, 15000);
}
function stopConnectionCheck() { clearInterval(_connInterval); _connInterval = null; }

async function checkConnection() {
  const dot = document.getElementById('conn-dot');
  if (!dot) return;
  try {
    const r = await fetch('/auth/status', { headers: state.token ? { Authorization: `Bearer ${state.token}` } : {} });
    dot.className = r.ok ? 'conn-dot conn-ok' : 'conn-dot conn-err';
  } catch {
    dot.className = 'conn-dot conn-err';
  }
}

// ── Keyboard Shortcuts ────────────────────────────────────────────────────────
function initKeyboardShortcuts() {
  document.addEventListener('keydown', e => {
    // Don't trigger when typing in inputs
    const tag = document.activeElement?.tagName;
    if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') {
      if (e.key === 'Escape') document.activeElement.blur();
      return;
    }
    // Don't trigger on auth screen
    if (!document.getElementById('auth-screen').classList.contains('hidden')) return;

    const modalOpen = !!document.getElementById('modal-overlay');
    if (e.key === 'Escape') { closeModal(); return; }
    if (modalOpen) return; // Don't fire action shortcuts while a modal is open
    if (e.key === 'n' || e.key === 'N') { e.preventDefault(); addTransaction(); return; }
    if (e.key === 'r' || e.key === 'R') { e.preventDefault(); refreshPage(); return; }
    if (e.key === '/') { e.preventDefault(); location.hash = '#/transactions'; setTimeout(() => { const el = document.getElementById('tx-search'); if (el) el.focus(); }, 100); return; }
    if (e.key === '?') { showShortcutsHelp(); return; }
  });
}

function showShortcutsHelp() {
  openModal(t('web_shortcuts_title'), `
    <div style="display:grid;grid-template-columns:auto 1fr;gap:8px 16px;font-size:13.5px">
      <kbd class="kbd">N</kbd><span>${esc(t('web_shortcut_new_tx'))}</span>
      <kbd class="kbd">R</kbd><span>${esc(t('web_shortcut_refresh'))}</span>
      <kbd class="kbd">/</kbd><span>${esc(t('web_shortcut_search'))}</span>
      <kbd class="kbd">Esc</kbd><span>${esc(t('web_shortcut_close'))}</span>
      <kbd class="kbd">?</kbd><span>${esc(t('web_shortcut_help'))}</span>
    </div>`, () => closeModal(), t('common_close'));
}

// ── Sign out ──────────────────────────────────────────────────────────────────
document.getElementById('sign-out-btn').addEventListener('click', () => {
  fetch('/auth/logout', { method: 'POST', headers: { Authorization: 'Bearer ' + state.token } }).catch(() => {});
  state.token = null;
  sessionStorage.removeItem('pp_token');
  Object.keys(cache).forEach(k => delete cache[k]);
  showAuthScreen();
});

// ── Mobile sidebar toggle ────────────────────────────────────────────────────
const _hamburger = document.getElementById('hamburger-btn');
const _sidebarOverlay = document.getElementById('sidebar-overlay');
const _sidebar = document.getElementById('sidebar');
function toggleSidebar(open) {
  const isOpen = open ?? !_sidebar.classList.contains('open');
  _sidebar.classList.toggle('open', isOpen);
  _sidebarOverlay.classList.toggle('open', isOpen);
}
_hamburger?.addEventListener('click', () => toggleSidebar());
_sidebarOverlay?.addEventListener('click', () => toggleSidebar(false));
// Close sidebar when a nav link is clicked (mobile)
document.querySelectorAll('.nav-link').forEach(link => {
  link.addEventListener('click', () => { if (window.innerWidth <= 768) toggleSidebar(false); });
});

// ── Init ──────────────────────────────────────────────────────────────────────
applyTheme(state.theme);
initAuth();
initKeyboardShortcuts();

(async () => {
  await loadLocale(_locale);
  // Re-apply theme to update label with translated text
  applyTheme(state.theme);

  if (state.token) {
    const data = await fetch('/auth/status', {
      headers: { Authorization: `Bearer ${state.token}` },
    }).then(r => r.json()).catch(() => null);

    if (data?.authenticated) {
      showMainLayout();
      navigate(state.currentRoute);
      getCategories();
      getAccounts();
      startConnectionCheck();
      return;
    }
    state.token = null;
    sessionStorage.removeItem('pp_token');
  }
  showAuthScreen();
})();
