'use strict';

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
  } catch (e) {
    console.error('[api] fetch failed:', path, e);
    toast('Server unreachable', true);
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
    toast(err.error || `Error ${res.status}`, true);
    return null;
  }

  try {
    return await res.json();
  } catch (e) {
    console.error('[api] JSON parse failed:', path, res.status, e);
    toast('Unexpected server response', true);
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
  return new Date(iso).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

function todayISO() { return new Date().toISOString().slice(0, 10); }

function fmtFreq(f, interval) {
  const map = { daily: 'Daily', weekly: 'Weekly', monthly: 'Monthly', yearly: 'Yearly' };
  if (!interval || interval === 1) return map[f] || f;
  return `Every ${interval} ${f.replace('ly', 's')}`;
}

const _monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

// ── Escape / helpers ──────────────────────────────────────────────────────────
function esc(s) {
  return String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

function setContent(html) { document.getElementById('content').innerHTML = html; }

function skeleton(rows = 5) {
  const lines = Array.from({ length: rows }, () =>
    `<div class="skel-row"><div class="skel-cell" style="width:${60 + Math.random() * 30}%"></div><div class="skel-cell" style="width:${15 + Math.random() * 15}%"></div></div>`
  ).join('');
  return `<div class="skeleton-wrap">${lines}</div>`;
}

function loading() {
  return `<div class="loading"><div class="spinner"></div>Loading…</div>`;
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
    income: '<span class="badge badge-income">Income</span>',
    expense: '<span class="badge badge-expense">Expense</span>',
    transfer: '<span class="badge badge-transfer">Transfer</span>',
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
  const t = document.createElement('div');
  t.className = `toast${isErr ? ' toast-error' : ''}`;
  if (undoFn) {
    t.innerHTML = `<span>${esc(msg)}</span><button class="toast-undo">Undo</button>`;
    t.querySelector('.toast-undo').onclick = () => { undoFn(); t.remove(); };
  } else {
    t.textContent = msg;
  }
  document.body.appendChild(t);
  requestAnimationFrame(() => t.classList.add('toast-show'));
  const dur = undoFn ? 5000 : 2400;
  setTimeout(() => { t.classList.remove('toast-show'); setTimeout(() => t.remove(), 300); }, dur);
}

// ── Modal ─────────────────────────────────────────────────────────────────────
function openModal(title, bodyHtml, onConfirm, confirmLabel = 'Save') {
  closeModal();
  const o = document.createElement('div');
  o.className = 'modal-overlay';
  o.id = 'modal-overlay';
  o.innerHTML = `
    <div class="modal" role="dialog" aria-modal="true">
      <h2 class="modal-title">${esc(title)}</h2>
      ${bodyHtml}
      <div class="modal-actions">
        <button class="btn btn-outline" id="modal-cancel">Cancel</button>
        <button class="btn btn-primary" id="modal-confirm">${esc(confirmLabel)}</button>
      </div>
    </div>`;
  document.body.appendChild(o);
  o.querySelector('#modal-cancel').onclick = closeModal;
  const btn = o.querySelector('#modal-confirm');
  btn.onclick = async () => {
    btn.disabled = true; btn.textContent = 'Saving…';
    try { await onConfirm(); } catch { toast('Unexpected error', true); }
    finally { if (btn.isConnected) { btn.disabled = false; btn.textContent = confirmLabel; } }
  };
  o.addEventListener('click', e => { if (e.target === o) closeModal(); });
}

function closeModal() { document.getElementById('modal-overlay')?.remove(); }

function confirmDialog(title, msg, confirmLabel = 'Delete', isDanger = true) {
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
          <button class="btn btn-outline" id="modal-cancel">Cancel</button>
          <button class="btn ${isDanger ? 'btn-danger' : 'btn-primary'}" id="modal-confirm">${esc(confirmLabel)}</button>
        </div>
      </div>`;
    document.body.appendChild(o);
    o.querySelector('#modal-cancel').onclick = () => { closeModal(); resolve(false); };
    o.querySelector('#modal-confirm').onclick = () => { closeModal(); resolve(true); };
    o.addEventListener('click', e => { if (e.target === o) { closeModal(); resolve(false); } });
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
        ? (data.error || 'Too many attempts. Try again later.')
        : (data?.error || 'Incorrect PIN');
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
  if (route !== '#/transactions') { _txPage = 1; _txFilter = ''; _txSearch = ''; }
  document.querySelectorAll('.nav-link').forEach(a => a.classList.toggle('active', a.dataset.route === route));
  (routes[route] || renderDashboard)();
}

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
  cache.accounts = accounts;
  if (household.baseCurrency) cache.baseCurrency = household.baseCurrency;

  const acctHtml = accounts.length
    ? `<div class="stat-grid">${accounts.map(a => `
        <div class="stat-card">
          <div class="stat-label">${esc(a.name)}</div>
          <div class="stat-value ${a.balance < 0 ? 'amount-expense' : ''}">${fmt(a.balance, a.currency)}</div>
          <div class="stat-sub">${esc(a.type)}</div>
        </div>`).join('')}</div>`
    : `<p class="text-secondary text-sm" style="margin-bottom:16px">No accounts yet.</p>`;

  const unallocEntries = Object.entries(unallocated);
  const unallocHtml = unallocEntries.length
    ? unallocEntries.map(([cur, amt]) =>
        `<span class="unalloc-pill ${amt < 0 ? 'unalloc-pill-warn' : ''}">${fmt(amt, cur)}</span>`).join(' ')
    : '<span class="text-secondary text-sm">—</span>';

  const envsHtml = envelopes.slice(0, 6).length
    ? envelopes.slice(0, 6).map(e => {
        const entries = Object.entries(e.balanceByCurrency || {});
        const [cur, bal] = entries[0] ?? ['USD', 0];
        const pct = e.targetAmount ? Math.min(100, Math.max(0, (bal / e.targetAmount) * 100)) : null;
        const isOver = pct !== null && pct >= 100;
        return `<div style="margin-bottom:12px">
          <div style="display:flex;justify-content:space-between;align-items:baseline;margin-bottom:5px">
            <span class="text-sm" style="font-weight:500">${esc(e.icon || '📁')} ${esc(e.name)}</span>
            <span class="text-sm ${bal < 0 ? 'amount-expense' : bal > 0 ? 'amount-income' : ''}" style="font-weight:600">${fmt(bal, cur)}</span>
          </div>
          ${pct !== null ? `<div class="progress-bar"><div class="progress-fill ${isOver ? 'over' : ''}" style="width:${pct.toFixed(1)}%"></div></div>` : ''}
        </div>`;
      }).join('')
    : '<p class="text-secondary text-sm">No envelopes yet.</p>';

  const recHtml = recentTransactions.length
    ? `<div style="overflow:auto"><table class="data-table">
        <thead><tr><th>Date</th><th>Type</th><th>Account</th><th>Category / Note</th><th style="text-align:right">Amount</th></tr></thead>
        <tbody>${recentTransactions.map(t => `
          <tr>
            <td class="text-secondary text-sm" style="white-space:nowrap">${fmtDate(t.date)}</td>
            <td>${typeBadge(t.type)}</td>
            <td class="text-sm">${esc(t.accountName || '')}</td>
            <td class="text-sm">
              ${t.categoryName
                ? `<div style="display:flex;align-items:center;gap:6px"><span style="width:7px;height:7px;border-radius:50%;background:${esc(t.categoryColor || '#607D8B')};flex-shrink:0"></span>${esc(t.categoryIcon || '')} ${esc(t.categoryName)}</div>`
                : `<span class="text-secondary">${esc(t.note || '—')}</span>`}
            </td>
            <td style="text-align:right;white-space:nowrap">${amtEl(t.amount, t.currency, t.type)}</td>
          </tr>`).join('')}
        </tbody></table></div>`
    : empty('No transactions yet', 'Add your first transaction to get started');

  setContent(`
    <div class="page-header">
      <h1 class="page-title">Dashboard</h1>
      <span class="text-secondary text-sm">${esc(household.name || '')}${household.baseCurrency ? ` · ${esc(household.baseCurrency)}` : ''}</span>
    </div>
    <div class="section-title">Accounts</div>
    ${acctHtml}
    <div style="display:flex;gap:16px;flex-wrap:wrap;margin-bottom:16px">
      <div class="card" style="flex:1;min-width:200px;margin-bottom:0">
        <div style="display:flex;align-items:center;justify-content:space-between">
          <span class="card-title" style="margin-bottom:0">Unallocated</span>
          <span style="display:flex;gap:6px;flex-wrap:wrap;justify-content:flex-end">${unallocHtml}</span>
        </div>
      </div>
    </div>
    <div class="card">
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:16px">
        <span class="card-title" style="margin-bottom:0">Envelopes</span>
        <a href="#/envelopes" class="btn btn-sm btn-outline">See all</a>
      </div>
      ${envsHtml}
    </div>
    <div class="card" style="padding:0">
      <div style="display:flex;align-items:center;justify-content:space-between;padding:16px 20px 0">
        <span class="card-title" style="margin-bottom:0">Recent Transactions</span>
        <a href="#/transactions" class="btn btn-sm btn-outline">See all</a>
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

  const filterBtns = [['', 'All'], ['income', 'Income'], ['expense', 'Expense'], ['transfer', 'Transfer']]
    .map(([f, l]) => `<button class="filter-btn${f === typeFilter ? ' active' : ''}" onclick="renderTransactions(1,'${f}')">${l}</button>`)
    .join('');

  // Month tabs
  const now = new Date();
  const monthTabs = [
    `<button class="filter-btn${_txMonth < 0 ? ' active' : ''}" onclick="_txMonth=-1;renderTransactions(1)">All</button>`,
    ..._monthNames.map((m, i) => {
      if (_txYear === now.getFullYear() && i > now.getMonth()) return '';
      return `<button class="filter-btn${_txMonth === i ? ' active' : ''}" onclick="_txMonth=${i};renderTransactions(1)">${m}</button>`;
    }).filter(Boolean),
  ].join('');

  const baseCur = txData.baseCurrency || cache.baseCurrency || 'USD';

  const rows = txData.items.length
    ? txData.items.map(t => {
        const lineCur = t.lineCurrency || t.currency;
        const lineAmt = t.lineAmount ?? t.amount;
        const isForeign = lineCur !== baseCur;
        const hasRealRate = isForeign && t.lineExchangeRate && Math.abs(t.lineExchangeRate - 1) > 0.001;
        const missingRate = isForeign && !hasRealRate;

        let amountHtml;
        if (isForeign) {
          amountHtml = `${amtEl(lineAmt, lineCur, t.type)}`;
          if (hasRealRate) {
            amountHtml += `<div class="text-secondary" style="font-size:11px">${fmt(lineAmt * t.lineExchangeRate, baseCur)}</div>`;
          } else {
            amountHtml += `<div style="font-size:11px;color:var(--caution)">⚠ No rate</div>`;
          }
        } else {
          amountHtml = amtEl(t.amount, t.currency, t.type);
        }

        return `
        <tr class="tx-row${missingRate ? ' tx-warn' : ''}" onclick="toggleTxDetail('${t.id}', this)">
          <td class="text-secondary text-sm" style="white-space:nowrap">${fmtDate(t.date)}</td>
          <td>${typeBadge(t.type)}</td>
          <td class="text-sm" style="max-width:180px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${esc(t.note || '—')}</td>
          <td class="text-sm">${esc(t.accountName || '')}${t.destinationAccountName ? `<span class="text-secondary"> → ${esc(t.destinationAccountName)}</span>` : ''}</td>
          <td class="text-sm">
            ${t.categoryName
              ? `<div style="display:flex;align-items:center;gap:6px"><span style="width:8px;height:8px;border-radius:50%;background:${esc(t.categoryColor || '#607D8B')};flex-shrink:0"></span>${esc(t.categoryIcon || '')} ${esc(t.categoryName)}</div>`
              : '<span class="text-secondary">—</span>'}
          </td>
          <td style="text-align:right;white-space:nowrap">${amountHtml}</td>
          <td style="white-space:nowrap" onclick="event.stopPropagation()">
            <button class="btn btn-sm btn-outline" onclick="editTransaction('${t.id}')">Edit</button>
            <button class="btn btn-sm btn-danger" style="margin-left:4px" onclick="deleteTransaction('${t.id}')">Del</button>
          </td>
        </tr>`;
      }).join('')
    : `<tr><td colspan="7" style="padding:32px;text-align:center;color:var(--text-secondary)">No transactions found</td></tr>`;

  setContent(`
    <div class="page-header">
      <h1 class="page-title">Transactions</h1>
      <div style="display:flex;gap:8px;align-items:center">
        <button class="btn btn-outline btn-sm" onclick="exportCSV()" title="Export CSV">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" x2="12" y1="15" y2="3"/></svg>
          CSV
        </button>
        <button class="btn btn-primary" onclick="addTransaction()">+ Add</button>
      </div>
    </div>
    <div style="display:flex;gap:12px;align-items:center;margin-bottom:14px;flex-wrap:wrap">
      <div style="flex:1;min-width:200px;position:relative">
        <svg style="position:absolute;left:10px;top:50%;transform:translateY(-50%);color:var(--text-hint)" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" x2="16.65" y1="21" y2="16.65"/></svg>
        <input type="text" id="tx-search" class="form-control" style="padding-left:32px;font-size:13px" placeholder="Search by title…" value="${esc(search)}" onkeydown="if(event.key==='Enter'){_txSearch=this.value;renderTransactions(1)}">
      </div>
      <div style="display:flex;gap:6px;align-items:center">
        <button class="btn btn-outline btn-sm" onclick="_txYear--;renderTransactions(1)">←</button>
        <span class="text-sm" style="font-weight:600;min-width:40px;text-align:center">${_txYear}</span>
        <button class="btn btn-outline btn-sm" onclick="_txYear++;renderTransactions(1)" ${_txYear >= now.getFullYear() ? 'disabled' : ''}>→</button>
      </div>
    </div>
    <div class="filter-row" style="margin-bottom:8px">${monthTabs}</div>
    <div class="filter-row">${filterBtns}</div>
    <div class="card" style="padding:0;overflow:auto">
      <table class="data-table">
        <thead><tr><th>Date</th><th>Type</th><th>Title</th><th>Account</th><th>Category</th><th style="text-align:right">Amount</th><th></th></tr></thead>
        <tbody>${rows}</tbody>
      </table>
    </div>
    <div class="pagination">
      <button class="btn btn-outline btn-sm" ${page <= 1 ? 'disabled' : ''} onclick="renderTransactions(${page - 1},'${typeFilter}','${esc(search)}')">← Prev</button>
      <span class="text-secondary text-sm">Page ${page}</span>
      <button class="btn btn-outline btn-sm" ${txData.items.length < 25 ? 'disabled' : ''} onclick="renderTransactions(${page + 1},'${typeFilter}','${esc(search)}')">Next →</button>
    </div>
  `);

  // Focus search if user was searching
  if (search) { const el = document.getElementById('tx-search'); if (el) { el.focus(); el.setSelectionRange(el.value.length, el.value.length); } }
}

// CSV export
function exportCSV() {
  const table = document.querySelector('.data-table');
  if (!table) return;
  const rows = [...table.querySelectorAll('tr')];
  const csv = rows.map(r => {
    const cells = [...r.querySelectorAll('th, td')];
    return cells.slice(0, -1).map(c => `"${c.textContent.trim().replace(/"/g, '""')}"`).join(',');
  }).join('\n');

  const blob = new Blob([csv], { type: 'text/csv' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = `pocketplan-transactions-${todayISO()}.csv`;
  a.click();
  URL.revokeObjectURL(a.href);
  toast('CSV exported');
}

function _txFormHtml(accounts, cats, pre = null) {
  const type = pre?.type || 'expense';
  const acctOpts = accounts.map(a =>
    `<option value="${a.id}" data-currency="${esc(a.currency)}" ${pre?.accountId === a.id ? 'selected' : ''}>${esc(a.name)} (${esc(a.currency)})</option>`).join('');
  const destOpts = accounts.map(a =>
    `<option value="${a.id}" ${pre?.destinationAccountId === a.id ? 'selected' : ''}>${esc(a.name)} (${esc(a.currency)})</option>`).join('');
  const catOpts = '<option value="">— None —</option>' + cats.map(c =>
    `<option value="${c.id}" data-txtype="${esc(c.transactionType)}" ${pre?.categoryId === c.id ? 'selected' : ''}>${esc(c.icon)} ${esc(c.name)}</option>`).join('');

  return `
    <div class="form-group">
      <label class="form-label">Type</label>
      <div class="type-tabs">
        <button type="button" class="type-tab${type === 'expense' ? ' active' : ''}" data-type="expense">Expense</button>
        <button type="button" class="type-tab${type === 'income' ? ' active' : ''}" data-type="income">Income</button>
        <button type="button" class="type-tab${type === 'transfer' ? ' active' : ''}" data-type="transfer">Transfer</button>
      </div>
    </div>
    <div class="form-group">
      <label class="form-label" id="lbl-account">${type === 'transfer' ? 'From Account' : 'Account'}</label>
      <select id="tx-account" class="form-control"><option value="">Select account</option>${acctOpts}</select>
    </div>
    <div class="form-group" id="fg-dest" style="${type !== 'transfer' ? 'display:none' : ''}">
      <label class="form-label">To Account</label>
      <select id="tx-dest" class="form-control">${destOpts}</select>
    </div>
    <div class="form-group" id="fg-cat" style="${type === 'transfer' ? 'display:none' : ''}">
      <label class="form-label">Category</label>
      <select id="tx-cat" class="form-control">${catOpts}</select>
    </div>
    <div style="display:flex;gap:12px">
      <div class="form-group" style="flex:1">
        <label class="form-label">Amount</label>
        <input type="number" id="tx-amount" class="form-control" min="0.01" step="0.01" value="${esc(pre?.amount || '')}" placeholder="0.00">
      </div>
      <div class="form-group" style="width:80px">
        <label class="form-label">Currency</label>
        <input type="text" id="tx-currency" class="form-control" maxlength="3" placeholder="USD" value="${esc(pre?.currency || '')}">
      </div>
    </div>
    <div class="form-group" id="fg-rate" style="display:none">
      <label class="form-label">Exchange Rate</label>
      <input type="number" id="tx-rate" class="form-control" min="0.000001" step="any" value="${esc(pre?.exchangeRateToBase && pre.exchangeRateToBase !== 1 ? pre.exchangeRateToBase : '')}" placeholder="Rate to base currency">
      <div class="text-secondary text-sm" id="rate-hint" style="margin-top:4px"></div>
    </div>
    <div class="form-group">
      <label class="form-label">Date</label>
      <input type="date" id="tx-date" class="form-control" value="${pre?.date ? pre.date.slice(0, 10) : todayISO()}">
    </div>
    <div class="form-group">
      <label class="form-label">Title / Note</label>
      <input type="text" id="tx-note" class="form-control" placeholder="Optional" value="${esc(pre?.note || '')}">
    </div>`;
}

function _setupTxForm() {
  const tabs = document.querySelectorAll('.type-tab');
  const fgDest = document.getElementById('fg-dest');
  const fgCat = document.getElementById('fg-cat');
  const lblAcct = document.getElementById('lbl-account');
  const acctSel = document.getElementById('tx-account');
  const curInput = document.getElementById('tx-currency');

  function applyType(t) {
    tabs.forEach(tab => tab.classList.toggle('active', tab.dataset.type === t));
    fgDest.style.display = t === 'transfer' ? '' : 'none';
    fgCat.style.display = t === 'transfer' ? 'none' : '';
    lblAcct.textContent = t === 'transfer' ? 'From Account' : 'Account';
  }

  tabs.forEach(tab => tab.addEventListener('click', () => applyType(tab.dataset.type)));

  const rateGroup = document.getElementById('fg-rate');
  const rateHint = document.getElementById('rate-hint');

  function updateRateVisibility() {
    const baseCur = cache.baseCurrency || 'USD';
    const txCur = curInput.value.trim().toUpperCase();
    if (txCur && txCur !== baseCur) {
      rateGroup.style.display = '';
      rateHint.textContent = `1 ${txCur} = ? ${baseCur}`;
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

  if (!accountId) { toast('Select an account', true); return null; }
  if (!amount || amount <= 0) { toast('Enter a valid amount', true); return null; }

  const body = { type, accountId, amount, currency, note };
  const rateVal = parseFloat(document.getElementById('tx-rate')?.value);
  const baseCur = cache.baseCurrency || 'USD';
  if (currency !== baseCur && rateVal && rateVal > 0) {
    body.exchangeRateToBase = rateVal;
  }
  if (date) body.date = date + 'T12:00:00.000Z';

  if (type === 'transfer') {
    const destId = document.getElementById('tx-dest').value;
    if (!destId) { toast('Select destination account', true); return null; }
    if (destId === accountId) { toast('From and To accounts must differ', true); return null; }
    body.destinationAccountId = destId;
  } else {
    const catId = document.getElementById('tx-cat').value;
    if (catId) body.categoryId = catId;
  }
  return body;
}

async function addTransaction() {
  const [accounts, cats] = await Promise.all([getAccounts(), getCategories()]);
  openModal('Add Transaction', _txFormHtml(accounts, cats), async () => {
    const body = _readTxForm();
    if (!body) return;
    const res = await api('/api/transactions', { method: 'POST', body: JSON.stringify(body) });
    if (res) { toast('Transaction added'); invalidateAll(); closeModal(); renderTransactions(_txPage, _txFilter, _txSearch); }
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
  openModal('Edit Transaction', _txFormHtml(accounts, cats, detail), async () => {
    const body = _readTxForm();
    if (!body) return;
    const res = await api(`/api/transactions/${id}`, { method: 'PUT', body: JSON.stringify(body) });
    if (res) { toast('Transaction updated'); invalidateAll(); closeModal(); renderTransactions(_txPage, _txFilter, _txSearch); }
  });
  _setupTxForm();
}

async function deleteTransaction(id) {
  // Delete immediately, offer undo via toast
  const res = await api(`/api/transactions/${id}`, { method: 'DELETE' });
  if (res) {
    invalidateAll();
    renderTransactions(_txPage, _txFilter, _txSearch);
    toast('Transaction deleted', false);
  }
}

async function toggleTxDetail(id, rowEl) {
  const existing = document.getElementById(`tx-lines-${id}`);
  if (existing) { existing.remove(); return; }

  const detail = await api(`/api/transactions/${id}`);
  if (!detail?.lines?.length) { toast('No line details available'); return; }

  const linesHtml = detail.lines.map(l => {
    const hasRate = l.exchangeRateToBase && Math.abs(l.exchangeRateToBase - 1) > 0.001;
    return `<tr>
      <td>${fmt(l.amount, l.currency)}</td>
      <td>${esc(l.currency)}</td>
      <td>${l.categoryName ? `${esc(l.categoryIcon || '')} ${esc(l.categoryName)}` : '<span class="text-secondary">—</span>'}</td>
      <td>${esc(l.accountName || '—')}</td>
      <td class="text-secondary">${esc(l.note || '')}</td>
      <td class="text-secondary">${hasRate ? l.exchangeRateToBase.toFixed(4) : ''}</td>
    </tr>`;
  }).join('');

  const detailRow = document.createElement('tr');
  detailRow.id = `tx-lines-${id}`;
  detailRow.innerHTML = `<td colspan="7" class="tx-detail-cell">
    <div class="tx-detail-inner">
      <div style="font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:var(--text-secondary);margin-bottom:8px">Transaction Lines (${detail.lines.length})</div>
      <table class="data-table">
        <thead><tr><th>Amount</th><th>Currency</th><th>Category</th><th>Account</th><th>Note</th><th>Rate</th></tr></thead>
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
  cache.categories = d.items;

  const expense = d.items.filter(c => c.transactionType !== 'income');
  const income  = d.items.filter(c => c.transactionType === 'income');

  function buildHierarchy(items) {
    const idSet = new Set(items.map(c => c.id));
    const roots = items.filter(c => !c.parentId || !idSet.has(c.parentId));
    const childrenOf = {};
    items.filter(c => c.parentId && idSet.has(c.parentId)).forEach(c => {
      if (!childrenOf[c.parentId]) childrenOf[c.parentId] = [];
      childrenOf[c.parentId].push(c);
    });
    const result = [];
    roots.forEach(r => {
      result.push({ ...r, _isChild: false });
      (childrenOf[r.id] || []).forEach(ch => result.push({ ...ch, _isChild: true }));
    });
    return result;
  }

  function catRow(c) {
    const emoji = _isEmoji(c.icon) ? c.icon : '';
    return `
      <tr>
        <td>
          <div style="display:flex;align-items:center;gap:10px;${c._isChild ? 'padding-left:28px' : ''}">
            <span style="width:30px;height:30px;border-radius:7px;background:${esc(c.colorHex)};display:inline-flex;align-items:center;justify-content:center;flex-shrink:0;font-size:15px">${esc(emoji)}</span>
            <div>
              <div style="font-weight:${c._isChild ? '400' : '600'}">${esc(c.name)}</div>
              ${c._isChild ? '<div class="text-secondary" style="font-size:11px">Sub-category</div>' : ''}
            </div>
          </div>
        </td>
        <td><span class="badge ${c.transactionType === 'income' ? 'badge-income' : 'badge-expense'}">${esc(c.transactionType)}</span></td>
        <td><button class="btn btn-sm btn-outline" onclick="openEditCategory('${c.id}')">Edit</button></td>
      </tr>`;
  }

  function section(label, items) {
    if (!items.length) return '';
    const ordered = buildHierarchy(items);
    return `
      <tr><td colspan="3" style="padding:16px 12px 6px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.6px;color:var(--text-secondary);border-bottom:none">${label}</td></tr>
      ${ordered.map(catRow).join('')}`;
  }

  const rows = d.items.length
    ? section('Expense', expense) + section('Income', income)
    : `<tr><td colspan="3" style="padding:32px;text-align:center;color:var(--text-secondary)">No categories yet</td></tr>`;

  setContent(`
    <div class="page-header">
      <h1 class="page-title">Categories</h1>
      <button class="btn btn-primary" onclick="openAddCategory()">+ Add</button>
    </div>
    <div class="card" style="padding:0">
      <table class="data-table">
        <thead><tr><th>Category</th><th>Type</th><th></th></tr></thead>
        <tbody>${rows}</tbody>
      </table>
    </div>`);
}

function _catFormHtml(pre = null) {
  const cats = cache.categories || [];
  const parentOpts = cats.filter(c => !c.parentId).map(c =>
    `<option value="${c.id}" ${pre?.parentId === c.id ? 'selected' : ''}>${_isEmoji(c.icon) ? c.icon + ' ' : ''}${esc(c.name)}</option>`).join('');
  return `
    <div class="form-group">
      <label class="form-label">Name</label>
      <input type="text" id="cat-name" class="form-control" value="${esc(pre?.name || '')}" placeholder="e.g. Groceries">
    </div>
    <div class="form-group">
      <label class="form-label">Parent Category</label>
      <select id="cat-parent" class="form-control">
        <option value="">— None (top-level) —</option>
        ${parentOpts}
      </select>
    </div>
    <div style="display:flex;gap:12px">
      <div class="form-group" style="flex:1">
        <label class="form-label">Icon (emoji)</label>
        <input type="text" id="cat-icon" class="form-control" value="${esc(pre?.icon || '')}" placeholder="🛒">
      </div>
      <div class="form-group" style="flex:1">
        <label class="form-label">Color</label>
        <input type="color" id="cat-color" class="form-control" value="${esc(pre?.colorHex || '#607D8B')}" style="height:42px;padding:4px;cursor:pointer">
      </div>
    </div>
    <div class="form-group">
      <label class="form-label">Transaction Type</label>
      <select id="cat-type" class="form-control">
        <option value="expense" ${pre?.transactionType !== 'income' ? 'selected' : ''}>Expense</option>
        <option value="income" ${pre?.transactionType === 'income' ? 'selected' : ''}>Income</option>
      </select>
    </div>`;
}

function openAddCategory() {
  openModal('Add Category', _catFormHtml(), async () => {
    const name = document.getElementById('cat-name').value.trim();
    if (!name) { toast('Name is required', true); return; }
    const parentId = document.getElementById('cat-parent').value || undefined;
    const body = {
      name,
      icon: document.getElementById('cat-icon').value.trim() || 'category',
      colorHex: document.getElementById('cat-color').value,
      transactionType: document.getElementById('cat-type').value,
      parentId,
    };
    const res = await api('/api/categories', { method: 'POST', body: JSON.stringify(body) });
    if (res) { toast('Category added'); invalidate('categories'); closeModal(); renderCategories(); }
  });
}

function openEditCategory(id) {
  const c = (cache.categories || []).find(x => x.id === id);
  if (!c) { toast('Category not found', true); return; }
  openModal('Edit Category', _catFormHtml(c), async () => {
    const name = document.getElementById('cat-name').value.trim();
    if (!name) { toast('Name is required', true); return; }
    const body = {
      name,
      icon: document.getElementById('cat-icon').value.trim() || c.icon,
      colorHex: document.getElementById('cat-color').value,
      transactionType: document.getElementById('cat-type').value,
    };
    const res = await api(`/api/categories/${id}`, { method: 'PUT', body: JSON.stringify(body) });
    if (res) { toast('Category updated'); invalidate('categories'); closeModal(); renderCategories(); }
  });
}

// ── Accounts ──────────────────────────────────────────────────────────────────
async function renderAccounts() {
  setContent(skeleton(5));
  const d = await api('/api/accounts');
  if (!d) return;
  cache.accounts = d.items;

  if (!d.items.length) {
    setContent(`
      <div class="page-header">
        <h1 class="page-title">Accounts</h1>
        <button class="btn btn-primary" onclick="openAddAccount()">+ Add</button>
      </div>
      ${empty('No accounts yet', 'Add your first account to get started')}`);
    return;
  }

  const typeOrder = ['bank', 'cash', 'credit', 'wallet'];
  const typeLabels = { bank: 'Bank Accounts', cash: 'Cash', credit: 'Credit Cards', wallet: 'Wallets' };
  const typeIcons = {
    bank: '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 21h18M3 10h18M5 6l7-3 7 3M4 10v11M20 10v11M8 14v3M12 14v3M16 14v3"/></svg>',
    cash: '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="2"/><path d="M6 12h.01M18 12h.01"/></svg>',
    credit: '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="5" width="20" height="14" rx="2"/><line x1="2" x2="22" y1="10" y2="10"/></svg>',
    wallet: '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12V7H5a2 2 0 0 1 0-4h14v4"/><path d="M3 5v14a2 2 0 0 0 2 2h16v-5"/><path d="M18 12a2 2 0 0 0 0 4h4v-4Z"/></svg>',
  };
  const grouped = {};
  d.items.forEach(a => { const t = a.type || 'bank'; if (!grouped[t]) grouped[t] = []; grouped[t].push(a); });

  const byCurrency = {};
  d.items.forEach(a => { byCurrency[a.currency] = (byCurrency[a.currency] || 0) + a.balance; });
  const netWorthHtml = Object.entries(byCurrency).map(([cur, total]) =>
    `<div class="stat-card">
      <div class="stat-label">Net Worth · ${esc(cur)}</div>
      <div class="stat-value ${total < 0 ? 'amount-expense' : ''}">${fmt(total, cur)}</div>
      <div class="stat-sub">${d.items.filter(a => a.currency === cur).length} account${d.items.filter(a => a.currency === cur).length > 1 ? 's' : ''}</div>
    </div>`).join('');

  let sectionsHtml = '';
  typeOrder.forEach(type => {
    const accts = grouped[type]; if (!accts?.length) return;
    const groupTotal = {}; accts.forEach(a => { groupTotal[a.currency] = (groupTotal[a.currency] || 0) + a.balance; });
    const totalStr = Object.entries(groupTotal).map(([c, t]) => fmt(t, c)).join(' + ');
    sectionsHtml += `
      <div class="card" style="padding:0;margin-bottom:12px">
        <div style="display:flex;align-items:center;justify-content:space-between;padding:14px 16px 0">
          <div style="display:flex;align-items:center;gap:8px">
            <span style="color:var(--text-secondary)">${typeIcons[type] || ''}</span>
            <span style="font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.6px;color:var(--text-secondary)">${typeLabels[type] || type}</span>
          </div>
          <span class="text-secondary text-sm" style="font-weight:600">${totalStr}</span>
        </div>
        <table class="data-table">
          <thead><tr><th>Account</th><th>Currency</th><th style="text-align:right">Balance</th><th></th></tr></thead>
          <tbody>${accts.map(a => `<tr>
              <td style="font-weight:600">${esc(a.name)}</td>
              <td><span class="badge badge-transfer">${esc(a.currency)}</span></td>
              <td style="text-align:right;white-space:nowrap"><span class="${a.balance < 0 ? 'amount-expense' : ''}" style="font-weight:700;font-size:15px">${fmt(a.balance, a.currency)}</span></td>
              <td style="white-space:nowrap"><button class="btn btn-sm btn-outline" onclick="viewAccountTransactions('${a.id}','${esc(a.name)}')">Transactions</button></td>
            </tr>`).join('')}</tbody>
        </table>
      </div>`;
  });

  setContent(`
    <div class="page-header"><h1 class="page-title">Accounts</h1><button class="btn btn-primary" onclick="openAddAccount()">+ Add</button></div>
    <div class="stat-grid" style="margin-bottom:16px">${netWorthHtml}</div>
    ${sectionsHtml}`);
}

let _acctTxPage = 1;
async function viewAccountTransactions(accountId, accountName, page) {
  page = page || 1; _acctTxPage = page;
  setContent(skeleton(6));
  const txData = await api(`/api/transactions?page=${page}&limit=25&accountId=${accountId}`);
  if (!txData) return;
  const baseCur = txData.baseCurrency || cache.baseCurrency || 'USD';
  const rows = txData.items.length
    ? txData.items.map(t => {
        const lineCur = t.lineCurrency || t.currency;
        const lineAmt = t.lineAmount ?? t.amount;
        const isForeign = lineCur !== baseCur;
        const hasRealRate = isForeign && t.lineExchangeRate && Math.abs(t.lineExchangeRate - 1) > 0.001;
        let amountHtml = isForeign
          ? `${amtEl(lineAmt, lineCur, t.type)}${hasRealRate ? `<div class="text-secondary" style="font-size:11px">${fmt(lineAmt * t.lineExchangeRate, baseCur)}</div>` : '<div style="font-size:11px;color:var(--caution)">⚠ No rate</div>'}`
          : amtEl(t.amount, t.currency, t.type);
        return `<tr>
          <td class="text-secondary text-sm" style="white-space:nowrap">${fmtDate(t.date)}</td>
          <td>${typeBadge(t.type)}</td>
          <td class="text-sm" style="max-width:180px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${esc(t.note || '—')}</td>
          <td class="text-sm">${t.categoryName ? `<div style="display:flex;align-items:center;gap:6px"><span style="width:8px;height:8px;border-radius:50%;background:${esc(t.categoryColor || '#607D8B')};flex-shrink:0"></span>${esc(t.categoryIcon || '')} ${esc(t.categoryName)}</div>` : '<span class="text-secondary">—</span>'}</td>
          <td class="text-sm">${t.type === 'transfer' ? `${esc(t.accountName || '')} <span class="text-secondary">→</span> ${esc(t.destinationAccountName || '')}` : esc(t.accountName || '')}</td>
          <td style="text-align:right;white-space:nowrap">${amountHtml}</td>
        </tr>`;
      }).join('')
    : `<tr><td colspan="6" style="padding:32px;text-align:center;color:var(--text-secondary)">No transactions for this account</td></tr>`;
  setContent(`
    <div class="page-header"><div style="display:flex;align-items:center;gap:12px"><button class="btn btn-outline btn-sm" onclick="renderAccounts()">← Back</button><h1 class="page-title">${esc(accountName)}</h1></div></div>
    <div class="card" style="padding:0;overflow:auto"><table class="data-table">
      <thead><tr><th>Date</th><th>Type</th><th>Title</th><th>Category</th><th>Account</th><th style="text-align:right">Amount</th></tr></thead>
      <tbody>${rows}</tbody></table></div>
    <div class="pagination">
      <button class="btn btn-outline btn-sm" ${page <= 1 ? 'disabled' : ''} onclick="viewAccountTransactions('${accountId}','${esc(accountName)}',${page - 1})">← Prev</button>
      <span class="text-secondary text-sm">Page ${page}</span>
      <button class="btn btn-outline btn-sm" ${txData.items.length < 25 ? 'disabled' : ''} onclick="viewAccountTransactions('${accountId}','${esc(accountName)}',${page + 1})">Next →</button>
    </div>`);
}

function openAddAccount() {
  const html = `
    <div class="form-group"><label class="form-label">Name</label><input type="text" id="acct-name" class="form-control" placeholder="e.g. Checking"></div>
    <div style="display:flex;gap:12px">
      <div class="form-group" style="flex:1"><label class="form-label">Type</label><select id="acct-type" class="form-control"><option value="bank">Bank</option><option value="cash">Cash</option><option value="credit">Credit</option><option value="wallet">Wallet</option></select></div>
      <div class="form-group" style="flex:1"><label class="form-label">Currency</label><input type="text" id="acct-currency" class="form-control" maxlength="3" placeholder="USD" value="USD"></div>
    </div>
    <div class="form-group"><label class="form-label">Opening Balance</label><input type="number" id="acct-balance" class="form-control" value="0" min="0" step="0.01"></div>`;
  openModal('Add Account', html, async () => {
    const name = document.getElementById('acct-name').value.trim();
    if (!name) { toast('Name is required', true); return; }
    const body = { name, type: document.getElementById('acct-type').value, currency: (document.getElementById('acct-currency').value.trim() || 'USD').toUpperCase(), initialBalance: parseFloat(document.getElementById('acct-balance').value) || 0 };
    const res = await api('/api/accounts', { method: 'POST', body: JSON.stringify(body) });
    if (res) { toast('Account added'); invalidateAll(); closeModal(); renderAccounts(); }
  });
}

// ── Envelopes ─────────────────────────────────────────────────────────────────
async function renderEnvelopes() {
  setContent(skeleton(4));
  const d = await api('/api/envelopes');
  if (!d) return;
  cache.envelopes = d.items;
  const unallocEntries = Object.entries(d.unallocated || {});
  const unallocHtml = unallocEntries.length
    ? unallocEntries.map(([cur, amt]) => `<span class="unalloc-pill ${amt < 0 ? 'unalloc-pill-warn' : ''}">${fmt(amt, cur)}</span>`).join(' ')
    : '<span class="text-secondary">—</span>';
  const envsHtml = d.items.length
    ? `<div class="env-grid">${d.items.map(e => {
        const entries = Object.entries(e.balanceByCurrency || {});
        const [cur, bal] = entries[0] ?? ['USD', 0];
        const pct = e.targetAmount ? Math.min(100, Math.max(0, (bal / e.targetAmount) * 100)) : null;
        const isOver = pct !== null && pct >= 100;
        return `<div class="envelope-card"><div class="envelope-header"><div><div class="envelope-name">${esc(e.icon || '📁')} ${esc(e.name)}</div><div class="text-secondary text-sm" style="margin-top:2px">${esc(e.type)} · ${esc(e.periodicity)}</div></div><div style="text-align:right;flex-shrink:0"><div class="${bal < 0 ? 'amount-expense' : bal > 0 ? 'amount-income' : ''}" style="font-weight:700;font-size:15px">${fmt(bal, cur)}</div>${e.targetAmount ? `<div class="text-secondary text-sm">of ${fmt(e.targetAmount, e.targetCurrency || cur)}</div>` : ''}</div></div>${pct !== null ? `<div class="progress-bar" style="margin-bottom:12px"><div class="progress-fill ${isOver ? 'over' : ''}" style="width:${pct.toFixed(1)}%"></div></div>` : '<div style="margin-bottom:12px"></div>'}<button class="btn btn-sm btn-outline" onclick="openFundEnvelope('${e.id}','${esc(cur)}')">+ Fund</button></div>`;
      }).join('')}</div>`
    : empty('No envelopes', 'Envelopes are managed in the PocketPlan app.');
  setContent(`<div class="page-header"><h1 class="page-title">Envelopes</h1><div style="display:flex;align-items:center;gap:12px"><span class="text-secondary text-sm">Unallocated: ${unallocHtml}</span></div></div>${envsHtml}`);
}

function openFundEnvelope(id, defaultCurrency) {
  openModal('Fund Envelope', `
    <div class="form-group"><label class="form-label">Amount to Fund</label><input type="number" id="fund-amount" class="form-control" min="0.01" step="0.01" placeholder="0.00"></div>
    <div class="form-group"><label class="form-label">Currency</label><input type="text" id="fund-currency" class="form-control" maxlength="3" value="${esc(defaultCurrency)}"></div>
    <div class="form-group"><label class="form-label">Note</label><input type="text" id="fund-note" class="form-control" placeholder="Optional"></div>`, async () => {
    const amount = parseFloat(document.getElementById('fund-amount').value);
    const currency = (document.getElementById('fund-currency').value.trim() || 'USD').toUpperCase();
    const note = document.getElementById('fund-note').value.trim();
    if (!amount || amount <= 0) { toast('Enter a valid amount', true); return; }
    const res = await api(`/api/envelopes/${id}/fund`, { method: 'POST', body: JSON.stringify({ amount, currency, note }) });
    if (res) { toast('Envelope funded'); invalidateAll(); closeModal(); renderEnvelopes(); }
  }, 'Fund');
}

// ── Recurring ─────────────────────────────────────────────────────────────────
async function renderRecurring() {
  setContent(skeleton(5));
  const [d, accounts, cats] = await Promise.all([api('/api/recurring'), getAccounts(), getCategories()]);
  if (!d) return;
  cache._recurringItems = d.items;
  const rows = d.items.length
    ? d.items.map(r => { const acct = accounts.find(a => a.id === r.accountId); const cat = cats.find(c => c.id === r.categoryId); return `<tr><td>${esc(r.title || '—')}</td><td>${typeBadge(r.type)}</td><td>${esc(acct?.name || r.accountId)}</td><td>${cat ? `${esc(cat.icon)} ${esc(cat.name)}` : '<span class="text-secondary">—</span>'}</td><td class="text-sm">${fmtFreq(r.frequency, r.interval)}</td><td style="white-space:nowrap">${fmt(r.amount, r.currency)}</td><td class="text-secondary text-sm">${fmtDate(r.nextDueDate)}</td><td><label class="toggle-wrap" title="${r.enabled ? 'Enabled' : 'Disabled'}"><input type="checkbox" ${r.enabled ? 'checked' : ''} onchange="toggleRecurring('${r.id}', this.checked)"><span class="toggle-slider"></span></label></td><td style="white-space:nowrap"><button class="btn btn-sm btn-outline" onclick="openEditRecurring('${r.id}')">Edit</button> <button class="btn btn-sm btn-danger" style="margin-left:4px" onclick="deleteRecurring('${r.id}')">Del</button></td></tr>`; }).join('')
    : `<tr><td colspan="9" style="padding:32px;text-align:center;color:var(--text-secondary)">No recurring transactions</td></tr>`;
  setContent(`<div class="page-header"><h1 class="page-title">Recurring</h1><button class="btn btn-primary" onclick="openAddRecurring()">+ Add</button></div><div class="card" style="padding:0;overflow:auto"><table class="data-table"><thead><tr><th>Title</th><th>Type</th><th>Account</th><th>Category</th><th>Frequency</th><th>Amount</th><th>Next Due</th><th>On</th><th></th></tr></thead><tbody>${rows}</tbody></table></div>`);
}

function _recurFormHtml(pre = null, isSub = false) {
  const accounts = cache.accounts || []; const cats = cache.categories || []; const type = pre?.type || 'expense';
  const acctOpts = accounts.map(a => `<option value="${a.id}" ${pre?.accountId === a.id ? 'selected' : ''}>${esc(a.name)} (${esc(a.currency)})</option>`).join('');
  const catOpts = '<option value="">— None —</option>' + cats.map(c => `<option value="${c.id}" ${pre?.categoryId === c.id ? 'selected' : ''}>${esc(c.icon)} ${esc(c.name)}</option>`).join('');
  return `${!isSub ? `<div class="form-group"><label class="form-label">Type</label><div class="type-tabs"><button type="button" class="type-tab${type === 'expense' ? ' active' : ''}" data-type="expense">Expense</button><button type="button" class="type-tab${type === 'income' ? ' active' : ''}" data-type="income">Income</button><button type="button" class="type-tab${type === 'transfer' ? ' active' : ''}" data-type="transfer">Transfer</button></div></div>` : ''}
    <div class="form-group"><label class="form-label">Title</label><input type="text" id="rec-title" class="form-control" value="${esc(pre?.title || '')}" placeholder="e.g. Netflix"></div>
    <div class="form-group"><label class="form-label">Account</label><select id="rec-account" class="form-control">${acctOpts}</select></div>
    <div class="form-group"><label class="form-label">Category</label><select id="rec-cat" class="form-control">${catOpts}</select></div>
    <div style="display:flex;gap:12px"><div class="form-group" style="flex:1"><label class="form-label">Amount</label><input type="number" id="rec-amount" class="form-control" min="0.01" step="0.01" value="${esc(pre?.amount || '')}" placeholder="0.00"></div><div class="form-group" style="width:80px"><label class="form-label">Currency</label><input type="text" id="rec-currency" class="form-control" maxlength="3" value="${esc(pre?.currency || 'USD')}"></div></div>
    <div style="display:flex;gap:12px"><div class="form-group" style="flex:1"><label class="form-label">Frequency</label><select id="rec-freq" class="form-control">${['daily','weekly','monthly','yearly'].map(f => `<option value="${f}" ${pre?.frequency === f ? 'selected' : ''}>${f.charAt(0).toUpperCase()+f.slice(1)}</option>`).join('')}</select></div><div class="form-group" style="width:70px"><label class="form-label">Every</label><input type="number" id="rec-interval" class="form-control" value="${esc(pre?.interval || '1')}" min="1" max="99"></div></div>
    <div class="form-group"><label class="form-label">Start Date</label><input type="date" id="rec-start" class="form-control" value="${pre?.nextDueDate ? pre.nextDueDate.slice(0,10) : todayISO()}"></div>
    <div class="form-group"><label class="form-label">Note</label><input type="text" id="rec-note" class="form-control" value="${esc(pre?.note || '')}" placeholder="Optional"></div>`;
}

async function openAddRecurring() {
  await Promise.all([getAccounts(), getCategories()]);
  openModal('Add Recurring', _recurFormHtml(), async () => {
    const type = document.querySelector('.type-tab.active')?.dataset.type || 'expense';
    const body = _readRecurForm(type, false); if (!body) return;
    const res = await api('/api/recurring', { method: 'POST', body: JSON.stringify(body) });
    if (res) { toast('Recurring added'); closeModal(); renderRecurring(); }
  });
  document.querySelectorAll('.type-tab').forEach(tab => tab.addEventListener('click', () => document.querySelectorAll('.type-tab').forEach(t => t.classList.toggle('active', t === tab))));
}

function openEditRecurring(id) {
  const r = (cache._recurringItems || []).find(x => x.id === id); if (!r) { toast('Not found', true); return; }
  openModal('Edit Recurring', `<div class="form-group"><label class="form-label">Title</label><input type="text" id="rec-title" class="form-control" value="${esc(r.title || '')}"></div><div class="form-group"><label class="form-label">Amount</label><input type="number" id="rec-amount" class="form-control" value="${esc(r.amount)}" min="0.01" step="0.01"></div><div class="form-group"><label class="form-label">Note</label><input type="text" id="rec-note" class="form-control" value="${esc(r.note || '')}"></div>`, async () => {
    const body = { title: document.getElementById('rec-title').value.trim(), amount: parseFloat(document.getElementById('rec-amount').value), note: document.getElementById('rec-note').value.trim() };
    const res = await api(`/api/recurring/${id}`, { method: 'PUT', body: JSON.stringify(body) });
    if (res) { toast('Updated'); closeModal(); renderRecurring(); }
  });
}

function _readRecurForm(type, isSub) {
  const accountId = document.getElementById('rec-account')?.value;
  const amount = parseFloat(document.getElementById('rec-amount').value);
  const currency = (document.getElementById('rec-currency').value.trim() || 'USD').toUpperCase();
  const startDate = document.getElementById('rec-start').value;
  if (!accountId) { toast('Select an account', true); return null; }
  if (!amount || amount <= 0) { toast('Enter a valid amount', true); return null; }
  if (!startDate) { toast('Select a start date', true); return null; }
  return { type: isSub ? 'expense' : type, title: document.getElementById('rec-title').value.trim(), accountId, categoryId: document.getElementById('rec-cat')?.value || undefined, amount, currency, frequency: document.getElementById('rec-freq').value, interval: parseInt(document.getElementById('rec-interval').value) || 1, startDate, note: document.getElementById('rec-note').value.trim(), isSubscription: isSub };
}

async function toggleRecurring(id, enabled) {
  const res = await api(`/api/recurring/${id}`, { method: 'PUT', body: JSON.stringify({ enabled }) });
  if (!res) renderRecurring();
}

async function deleteRecurring(id) {
  const ok = await confirmDialog('Delete Recurring', 'This recurring transaction will be permanently deleted.');
  if (!ok) return;
  const res = await api(`/api/recurring/${id}`, { method: 'DELETE' });
  if (res) { toast('Deleted'); renderRecurring(); }
}

// ── Subscriptions ─────────────────────────────────────────────────────────────
async function renderSubscriptions() {
  setContent(skeleton(5));
  const [d, accounts, cats] = await Promise.all([api('/api/subscriptions'), getAccounts(), getCategories()]);
  if (!d) return;
  cache._subItems = d.items;
  const rows = d.items.length
    ? d.items.map(r => { const acct = accounts.find(a => a.id === r.accountId); const cat = cats.find(c => c.id === r.categoryId); return `<tr><td style="font-weight:600">${esc(r.title || '—')}</td><td>${esc(acct?.name || r.accountId)}</td><td>${cat ? `${esc(cat.icon)} ${esc(cat.name)}` : '<span class="text-secondary">—</span>'}</td><td class="text-sm">${fmtFreq(r.frequency, r.interval)}</td><td style="white-space:nowrap;font-weight:600">${fmt(r.amount, r.currency)}</td><td class="text-secondary text-sm">${fmtDate(r.nextDueDate)}</td><td><label class="toggle-wrap"><input type="checkbox" ${r.enabled ? 'checked' : ''} onchange="toggleSubscription('${r.id}', this.checked)"><span class="toggle-slider"></span></label></td><td style="white-space:nowrap"><button class="btn btn-sm btn-outline" onclick="openEditSubscription('${r.id}')">Edit</button> <button class="btn btn-sm btn-danger" style="margin-left:4px" onclick="deleteSubscription('${r.id}')">Del</button></td></tr>`; }).join('')
    : `<tr><td colspan="8" style="padding:32px;text-align:center;color:var(--text-secondary)">No subscriptions yet</td></tr>`;
  setContent(`<div class="page-header"><h1 class="page-title">Subscriptions</h1><button class="btn btn-primary" onclick="openAddSubscription()">+ Add</button></div><div class="card" style="padding:0;overflow:auto"><table class="data-table"><thead><tr><th>Service</th><th>Account</th><th>Category</th><th>Frequency</th><th>Amount</th><th>Next Due</th><th>On</th><th></th></tr></thead><tbody>${rows}</tbody></table></div>`);
}

async function openAddSubscription() {
  await Promise.all([getAccounts(), getCategories()]);
  openModal('Add Subscription', _recurFormHtml(null, true), async () => {
    const body = _readRecurForm('expense', true); if (!body) return;
    const res = await api('/api/subscriptions', { method: 'POST', body: JSON.stringify(body) });
    if (res) { toast('Subscription added'); closeModal(); renderSubscriptions(); }
  });
}

function openEditSubscription(id) {
  const r = (cache._subItems || []).find(x => x.id === id); if (!r) { toast('Not found', true); return; }
  openModal('Edit Subscription', `<div class="form-group"><label class="form-label">Title</label><input type="text" id="sub-title" class="form-control" value="${esc(r.title || '')}"></div><div style="display:flex;gap:12px"><div class="form-group" style="flex:1"><label class="form-label">New Amount</label><input type="number" id="sub-amount" class="form-control" value="${esc(r.amount)}" min="0.01" step="0.01"></div><div class="form-group" style="width:80px"><label class="form-label">Currency</label><input type="text" class="form-control" value="${esc(r.currency)}" disabled></div></div><p class="text-secondary text-sm" style="margin-top:-8px">Changing the amount will add a price history entry.</p>`, async () => {
    const body = { title: document.getElementById('sub-title').value.trim(), amount: parseFloat(document.getElementById('sub-amount').value) };
    const res = await api(`/api/subscriptions/${id}`, { method: 'PUT', body: JSON.stringify(body) });
    if (res) { toast('Updated'); closeModal(); renderSubscriptions(); }
  });
}

async function toggleSubscription(id, enabled) {
  const res = await api(`/api/subscriptions/${id}`, { method: 'PUT', body: JSON.stringify({ enabled }) });
  if (!res) renderSubscriptions();
}

async function deleteSubscription(id) {
  const ok = await confirmDialog('Delete Subscription', 'This subscription will be permanently deleted.');
  if (!ok) return;
  const res = await api(`/api/recurring/${id}`, { method: 'DELETE' });
  if (res) { toast('Deleted'); renderSubscriptions(); }
}

// ── Reports ───────────────────────────────────────────────────────────────────
function renderReports() {
  const now = new Date();
  const monthOpts = Array.from({ length: 12 }, (_, i) =>
    `<option value="${i + 1}" ${i + 1 === now.getMonth() + 1 ? 'selected' : ''}>${new Date(2000, i, 1).toLocaleString('en-US', { month: 'long' })}</option>`
  ).join('');
  setContent(`
    <div class="page-header"><h1 class="page-title">Reports</h1></div>
    <div style="display:flex;gap:12px;align-items:flex-end;flex-wrap:wrap;margin-bottom:20px">
      <div><label class="form-label">Year</label><input type="number" id="rep-year" class="form-control" style="width:90px" value="${now.getFullYear()}" min="2020" max="2040"></div>
      <div><label class="form-label">Month</label><select id="rep-month" class="form-control" style="width:130px">${monthOpts}</select></div>
      <button class="btn btn-primary" onclick="loadReports()">Load</button>
    </div>
    <div id="reports-content"><p class="text-secondary">Select a period and click Load.</p></div>`);
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

  const catRows = expenseCatItems.map(item => { const pct = cashflow.expense > 0 ? Math.min(100, (item.total / cashflow.expense) * 100).toFixed(1) : 0; return `<tr><td><div style="display:flex;align-items:center;gap:8px"><span style="width:10px;height:10px;border-radius:50%;background:${esc(item.colorHex || '#607D8B')};flex-shrink:0"></span>${esc(item.icon)} ${esc(item.name)}</div></td><td style="text-align:right;white-space:nowrap" class="amount-expense">${fmt(item.total, cur)}</td><td class="text-secondary text-sm" style="text-align:right">${pct}%</td><td style="width:120px"><div class="progress-bar"><div class="progress-fill" style="width:${pct}%;background:${esc(item.colorHex || '#607D8B')}"></div></div></td></tr>`; }).join('');
  const incomeCatRows = incomeCatItems.map(item => { const pct = incomeTotal > 0 ? Math.min(100, (item.total / incomeTotal) * 100).toFixed(1) : 0; return `<tr><td><div style="display:flex;align-items:center;gap:8px"><span style="width:10px;height:10px;border-radius:50%;background:${esc(item.colorHex || '#059669')};flex-shrink:0"></span>${esc(item.icon)} ${esc(item.name)}</div></td><td style="text-align:right;white-space:nowrap" class="amount-income">${fmt(item.total, cur)}</td><td class="text-secondary text-sm" style="text-align:right">${pct}%</td></tr>`; }).join('');
  const topExpHtml = topExpenses.length ? topExpenses.map(t => `<tr><td class="text-secondary text-sm" style="white-space:nowrap">${fmtDate(t.date)}</td><td class="text-sm">${t.categoryIcon ? esc(t.categoryIcon) + ' ' : ''}${esc(t.categoryName || '—')}</td><td class="text-sm">${esc(t.accountName || '')}</td><td class="text-sm text-secondary" style="max-width:160px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${esc(t.note || '')}</td><td style="text-align:right;white-space:nowrap" class="amount-expense">${fmt(t.amount, cur)}</td></tr>`).join('') : '';

  content.innerHTML = `
    <div class="stat-grid" style="margin-bottom:16px">
      <div class="stat-card"><div class="stat-label">Income</div><div class="stat-value amount-income">${fmt(cashflow.income, cur)}</div></div>
      <div class="stat-card"><div class="stat-label">Expenses</div><div class="stat-value amount-expense">${fmt(cashflow.expense, cur)}</div></div>
      <div class="stat-card"><div class="stat-label">Net</div><div class="stat-value ${cashflow.net >= 0 ? 'amount-income' : 'amount-expense'}">${fmt(cashflow.net, cur)}</div></div>
      <div class="stat-card"><div class="stat-label">Savings Rate</div><div class="stat-value ${Number(savingsRate) >= 0 ? 'amount-income' : 'amount-expense'}">${savingsRate}%</div></div>
      <div class="stat-card"><div class="stat-label">Avg. Daily Spend</div><div class="stat-value">${fmt(avgDaily, cur)}</div></div>
      <div class="stat-card"><div class="stat-label">Transactions</div><div class="stat-value">${txCount}</div></div>
    </div>
    <div class="card" style="margin-bottom:16px"><div class="report-section-title">Daily Cashflow</div><div style="max-height:280px"><canvas id="cashflow-chart"></canvas></div></div>
    <div class="report-two-col">
      <div class="card" style="margin-bottom:0"><div class="report-section-title">Spending by Category</div>${expenseCatItems.length > 1 ? '<div style="max-height:220px;margin-bottom:16px"><canvas id="cat-doughnut"></canvas></div>' : ''}${expenseCatItems.length ? `<table class="data-table"><tbody>${catRows}</tbody></table>` : '<p class="text-secondary text-sm">No expense data</p>'}</div>
      <div class="card" style="margin-bottom:0"><div class="report-section-title">Income by Category</div>${incomeCatItems.length ? `<table class="data-table"><tbody>${incomeCatRows}</tbody></table>` : '<p class="text-secondary text-sm">No income data</p>'}</div>
    </div>
    ${topExpHtml ? `<div class="card" style="padding:0;margin-top:16px"><div style="padding:16px 20px 0"><div class="report-section-title">Top Expenses</div></div><table class="data-table"><thead><tr><th>Date</th><th>Category</th><th>Account</th><th>Note</th><th style="text-align:right">Amount</th></tr></thead><tbody>${topExpHtml}</tbody></table></div>` : ''}`;

  const hasDark = document.documentElement.dataset.theme === 'dark' || (document.documentElement.dataset.theme !== 'light' && window.matchMedia?.('(prefers-color-scheme: dark)').matches);
  const gridColor = hasDark ? 'rgba(255,255,255,.08)' : 'rgba(0,0,0,.07)';
  const textColor = hasDark ? '#94A3B8' : '#64748B';

  const barCtx = document.getElementById('cashflow-chart');
  if (barCtx && window.Chart && cashflow.daily?.length) {
    _reportChart = new Chart(barCtx, { type: 'bar', data: { labels: cashflow.daily.map(d => d.day), datasets: [{ label: 'Income', data: cashflow.daily.map(d => d.income), backgroundColor: 'rgba(5,150,105,.75)', borderRadius: 4 }, { label: 'Expense', data: cashflow.daily.map(d => d.expense), backgroundColor: 'rgba(220,38,38,.75)', borderRadius: 4 }] }, options: { responsive: true, maintainAspectRatio: true, plugins: { legend: { labels: { color: textColor, font: { family: "'Plus Jakarta Sans', sans-serif", size: 12 } } }, tooltip: { callbacks: { label: c => ` ${c.dataset.label}: ${fmt(c.parsed.y, cur)}` } } }, scales: { x: { grid: { color: gridColor }, ticks: { color: textColor } }, y: { beginAtZero: true, grid: { color: gridColor }, ticks: { color: textColor, callback: v => fmt(v, cur) } } } } });
  }
  const doughCtx = document.getElementById('cat-doughnut');
  if (doughCtx && window.Chart && expenseCatItems.length > 1) {
    _reportCatChart = new Chart(doughCtx, { type: 'doughnut', data: { labels: expenseCatItems.map(i => i.name), datasets: [{ data: expenseCatItems.map(i => i.total), backgroundColor: expenseCatItems.map(i => i.colorHex || '#607D8B'), borderWidth: 0 }] }, options: { responsive: true, maintainAspectRatio: true, cutout: '60%', plugins: { legend: { position: 'right', labels: { color: textColor, font: { family: "'Plus Jakarta Sans', sans-serif", size: 11 }, boxWidth: 10, padding: 8 } }, tooltip: { callbacks: { label: c => ` ${c.label}: ${fmt(c.parsed, cur)}` } } } } });
  }
}

// ── Theme ─────────────────────────────────────────────────────────────────────
function applyTheme(t) {
  state.theme = t;
  localStorage.setItem('pp_theme', t);
  if (t === 'system') { document.documentElement.removeAttribute('data-theme'); }
  else { document.documentElement.dataset.theme = t; }
  const el = document.getElementById('theme-label');
  if (el) el.textContent = t === 'system' ? 'Auto' : t === 'dark' ? 'Dark' : 'Light';
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
    if (e.key === '/') { e.preventDefault(); location.hash = '#/transactions'; setTimeout(() => { const el = document.getElementById('tx-search'); if (el) el.focus(); }, 100); return; }
    if (e.key === '?') { showShortcutsHelp(); return; }
  });
}

function showShortcutsHelp() {
  openModal('Keyboard Shortcuts', `
    <div style="display:grid;grid-template-columns:auto 1fr;gap:8px 16px;font-size:13.5px">
      <kbd class="kbd">N</kbd><span>New transaction</span>
      <kbd class="kbd">/</kbd><span>Search transactions</span>
      <kbd class="kbd">Esc</kbd><span>Close modal / unfocus</span>
      <kbd class="kbd">?</kbd><span>Show this help</span>
    </div>`, () => closeModal(), 'Close');
}

// ── Sign out ──────────────────────────────────────────────────────────────────
document.getElementById('sign-out-btn').addEventListener('click', () => {
  state.token = null;
  sessionStorage.removeItem('pp_token');
  Object.keys(cache).forEach(k => delete cache[k]);
  showAuthScreen();
});

// ── Init ──────────────────────────────────────────────────────────────────────
applyTheme(state.theme);
initAuth();
initKeyboardShortcuts();

(async () => {
  if (state.token) {
    const data = await fetch('/auth/status', {
      headers: { Authorization: `Bearer ${state.token}` },
    }).then(r => r.json()).catch(() => null);

    if (data?.authenticated) {
      showMainLayout();
      navigate(state.currentRoute);
      getCategories();
      startConnectionCheck();
      return;
    }
    state.token = null;
    sessionStorage.removeItem('pp_token');
  }
  showAuthScreen();
})();
