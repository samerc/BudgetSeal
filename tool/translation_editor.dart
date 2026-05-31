// ignore_for_file: avoid_print
/// Local translation editor for docs/i18n_strings.csv.
///
/// Usage:  dart run tool/translation_editor.dart
/// Then open http://localhost:4488 in your browser.
library;

import 'dart:convert';
import 'dart:io';

const _csvPath = 'docs/i18n_strings.csv';
const _port = 4488;

void main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port);
  print('Translation editor running at http://localhost:$_port');
  print('Editing: $_csvPath');
  print('Press Ctrl+C to stop.\n');

  await for (final req in server) {
    try {
      if (req.uri.path == '/' && req.method == 'GET') {
        _serveHtml(req);
      } else if (req.uri.path == '/api/strings' && req.method == 'GET') {
        _serveStrings(req);
      } else if (req.uri.path == '/api/save' && req.method == 'POST') {
        await _saveStrings(req);
      } else {
        req.response
          ..statusCode = 404
          ..write('Not found')
          ..close();
      }
    } catch (e) {
      print('Error: $e');
      req.response
        ..statusCode = 500
        ..write('Internal error')
        ..close();
    }
  }
}

/// Parse CSV into structured data.
List<Map<String, String>> _readCsv() {
  final file = File(_csvPath);
  final lines = file.readAsLinesSync();
  final rows = <Map<String, String>>[];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    rows.add({'_raw': line, '_line': '$i'});

    if (i == 0 || line.trim().isEmpty || line.startsWith('#')) continue;

    final fields = _parseCsvLine(line);
    if (fields.length >= 5) {
      rows.last['key'] = fields[0].trim();
      rows.last['context'] = fields[1].trim();
      rows.last['english'] = fields[2].trim();
      rows.last['arabic'] = fields[3].trim();
      rows.last['french'] = fields[4].trim();
    }
  }
  return rows;
}

/// Serve the string data as JSON.
void _serveStrings(HttpRequest req) {
  final rows = _readCsv();
  final strings = <Map<String, String>>[];
  String currentSection = '';

  for (final row in rows) {
    if (row['_raw']!.startsWith('# ') && !row['_raw']!.startsWith('# ──')) {
      currentSection = row['_raw']!.substring(2).trim().replaceAll(RegExp(r'[,\s]+$'), '');
      continue;
    }
    if (row.containsKey('key') && row['key']!.isNotEmpty) {
      row['section'] = currentSection;
      strings.add(row);
    }
  }

  req.response
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(strings))
    ..close();
}

/// Save updated translations back to CSV.
Future<void> _saveStrings(HttpRequest req) async {
  final body = await utf8.decoder.bind(req).join();
  final updates = (jsonDecode(body) as List)
      .cast<Map<String, dynamic>>();

  // Build a map of key -> {arabic, french, english}
  final updateMap = <String, Map<String, String>>{};
  for (final u in updates) {
    updateMap[u['key'] as String] = {
      'english': u['english'] as String? ?? '',
      'arabic': u['arabic'] as String? ?? '',
      'french': u['french'] as String? ?? '',
    };
  }

  // Re-read and patch the CSV
  final file = File(_csvPath);
  final lines = file.readAsLinesSync();
  final output = <String>[];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (i == 0 || line.trim().isEmpty || line.startsWith('#')) {
      output.add(line);
      continue;
    }

    final fields = _parseCsvLine(line);
    if (fields.length >= 5) {
      final key = fields[0].trim();
      if (updateMap.containsKey(key)) {
        final u = updateMap[key]!;
        fields[2] = u['english'] ?? fields[2];
        fields[3] = u['arabic'] ?? fields[3];
        fields[4] = u['french'] ?? fields[4];
        output.add(_toCsvLine(fields));
        continue;
      }
    }
    output.add(line);
  }

  file.writeAsStringSync('${output.join('\n')}\n');
  print('Saved ${updateMap.length} update(s) to $_csvPath');

  req.response
    ..headers.contentType = ContentType.json
    ..write(jsonEncode({'ok': true, 'count': updateMap.length}))
    ..close();
}

/// Rebuild a CSV line, quoting fields that contain commas or quotes.
String _toCsvLine(List<String> fields) {
  return fields.map((f) {
    if (f.contains(',') || f.contains('"') || f.contains('\n')) {
      return '"${f.replaceAll('"', '""')}"';
    }
    return f;
  }).join(',');
}

/// Parse a CSV line respecting quoted fields.
List<String> _parseCsvLine(String line) {
  final fields = <String>[];
  var current = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (c == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        current.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (c == ',' && !inQuotes) {
      fields.add(current.toString());
      current = StringBuffer();
    } else {
      current.write(c);
    }
  }
  fields.add(current.toString());
  return fields;
}

/// Serve the HTML editor page.
void _serveHtml(HttpRequest req) {
  req.response
    ..headers.contentType = ContentType.html
    ..write(_html)
    ..close();
}

const _html = r'''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>PocketPlan Translation Editor</title>
<style>
  :root {
    --bg: #F8FAFC; --surface: #FFFFFF; --border: #E2E8F0;
    --text: #1E293B; --text2: #64748B; --accent: #2563EB;
    --green: #059669; --red: #DC2626; --amber: #D97706;
    --radius: 10px; --font: 'Segoe UI', system-ui, sans-serif;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: var(--font); background: var(--bg); color: var(--text);
    line-height: 1.5;
  }

  /* ── Header ── */
  .header {
    background: var(--surface); border-bottom: 1px solid var(--border);
    padding: 16px 24px; position: sticky; top: 0; z-index: 100;
  }
  .header-top { display: flex; align-items: center; gap: 16px; flex-wrap: wrap; }
  .header h1 { font-size: 20px; font-weight: 700; }
  .header .stats { font-size: 13px; color: var(--text2); }
  .header .stats .missing { color: var(--red); font-weight: 600; }
  .header .stats .complete { color: var(--green); font-weight: 600; }

  /* ── Controls ── */
  .controls {
    display: flex; gap: 10px; margin-top: 12px; flex-wrap: wrap; align-items: center;
  }
  .search-box {
    flex: 1; min-width: 200px; padding: 8px 12px; border: 1px solid var(--border);
    border-radius: var(--radius); font-size: 14px; outline: none;
  }
  .search-box:focus { border-color: var(--accent); box-shadow: 0 0 0 2px rgba(37,99,235,0.15); }
  select, .btn {
    padding: 8px 14px; border: 1px solid var(--border); border-radius: var(--radius);
    font-size: 13px; background: var(--surface); cursor: pointer;
  }
  .btn { font-weight: 600; }
  .btn-primary { background: var(--accent); color: white; border-color: var(--accent); }
  .btn-primary:hover { background: #1D4ED8; }
  .btn-primary:disabled { opacity: 0.5; cursor: default; }
  .btn-outline:hover { background: #F1F5F9; }
  .chip {
    display: inline-flex; align-items: center; gap: 4px; padding: 4px 10px;
    border-radius: 20px; font-size: 12px; font-weight: 600; cursor: pointer;
    border: 1px solid var(--border); background: var(--surface);
    transition: all 0.15s;
  }
  .chip.active { background: var(--accent); color: white; border-color: var(--accent); }
  .chip .dot { width: 8px; height: 8px; border-radius: 50%; }
  .chip .dot.red { background: var(--red); }
  .chip .dot.amber { background: var(--amber); }
  .chip .dot.green { background: var(--green); }

  /* ── Section headers ── */
  .section-header {
    padding: 12px 24px; background: #EEF2FF; font-size: 12px; font-weight: 700;
    color: var(--accent); letter-spacing: 0.5px; text-transform: uppercase;
    border-bottom: 1px solid var(--border); position: sticky; top: 105px; z-index: 50;
  }

  /* ── String rows ── */
  .string-row {
    display: grid; grid-template-columns: 220px 1fr 1fr 1fr;
    gap: 12px; padding: 14px 24px; border-bottom: 1px solid var(--border);
    background: var(--surface); transition: background 0.15s;
  }
  .string-row:hover { background: #FAFBFF; }
  .string-row.modified { background: #FFFBEB; }
  .string-row.missing-ar .field-ar,
  .string-row.missing-fr .field-fr { background: #FEF2F2; }

  .key-col { overflow: hidden; }
  .key-name {
    font-family: 'Consolas', 'SF Mono', monospace; font-size: 12px;
    font-weight: 600; color: var(--accent); word-break: break-all;
  }
  .key-context { font-size: 11px; color: var(--text2); margin-top: 2px; }

  .field-col { display: flex; flex-direction: column; gap: 2px; }
  .field-label { font-size: 10px; font-weight: 700; color: var(--text2); text-transform: uppercase; letter-spacing: 0.5px; }
  .field-col textarea {
    width: 100%; min-height: 40px; padding: 6px 8px; border: 1px solid var(--border);
    border-radius: 6px; font-size: 13px; font-family: var(--font);
    resize: vertical; outline: none; line-height: 1.4;
  }
  .field-col textarea:focus { border-color: var(--accent); box-shadow: 0 0 0 2px rgba(37,99,235,0.1); }
  .field-ar textarea { direction: rtl; font-family: 'Segoe UI', 'Tahoma', sans-serif; }

  /* ── Save bar ── */
  .save-bar {
    position: fixed; bottom: 0; left: 0; right: 0; background: var(--surface);
    border-top: 2px solid var(--accent); padding: 12px 24px;
    display: none; align-items: center; justify-content: space-between;
    z-index: 200; box-shadow: 0 -4px 12px rgba(0,0,0,0.08);
  }
  .save-bar.visible { display: flex; }
  .save-bar .change-count { font-size: 14px; font-weight: 600; }

  /* ── Column header ── */
  .col-header {
    display: grid; grid-template-columns: 220px 1fr 1fr 1fr;
    gap: 12px; padding: 8px 24px; background: #F1F5F9;
    font-size: 11px; font-weight: 700; color: var(--text2);
    text-transform: uppercase; letter-spacing: 0.5px;
    border-bottom: 1px solid var(--border);
    position: sticky; top: 105px; z-index: 60;
  }

  /* ── Toast ── */
  .toast {
    position: fixed; top: 20px; right: 20px; padding: 12px 20px;
    background: var(--green); color: white; border-radius: var(--radius);
    font-weight: 600; font-size: 14px; z-index: 999;
    transform: translateY(-100px); opacity: 0; transition: all 0.3s;
  }
  .toast.show { transform: translateY(0); opacity: 1; }

  /* ── Empty state ── */
  .empty-state {
    text-align: center; padding: 60px 24px; color: var(--text2);
  }
  .empty-state h2 { font-size: 18px; margin-bottom: 8px; color: var(--text); }

  /* ── Responsive ── */
  @media (max-width: 900px) {
    .string-row, .col-header { grid-template-columns: 1fr; }
    .key-col { padding-bottom: 4px; border-bottom: 1px dashed var(--border); }
  }

  /* ── Progress bar ── */
  .progress-wrap { display: flex; gap: 12px; align-items: center; margin-top: 8px; }
  .progress-bar { flex: 1; height: 6px; background: var(--border); border-radius: 3px; overflow: hidden; }
  .progress-fill { height: 100%; background: var(--green); border-radius: 3px; transition: width 0.3s; }
  .progress-label { font-size: 12px; color: var(--text2); white-space: nowrap; }
</style>
</head>
<body>

<div class="header">
  <div class="header-top">
    <h1>PocketPlan Translation Editor</h1>
    <span class="stats" id="stats"></span>
  </div>
  <div class="progress-wrap">
    <div class="progress-bar"><div class="progress-fill" id="progress-fill"></div></div>
    <span class="progress-label" id="progress-label"></span>
  </div>
  <div class="controls">
    <input class="search-box" id="search" type="text" placeholder="Search keys, text, or translations...">
    <select id="section-filter"><option value="">All sections</option></select>
    <select id="lang-filter">
      <option value="">All languages</option>
      <option value="ar">Arabic only</option>
      <option value="fr">French only</option>
    </select>
    <div style="display:flex;gap:6px;">
      <span class="chip active" data-filter="all">All</span>
      <span class="chip" data-filter="missing"><span class="dot red"></span> Missing</span>
      <span class="chip" data-filter="modified"><span class="dot amber"></span> Modified</span>
      <span class="chip" data-filter="complete"><span class="dot green"></span> Complete</span>
    </div>
  </div>
</div>

<div class="col-header" id="col-header">
  <div>Key / Context</div>
  <div>English</div>
  <div>Arabic (AR)</div>
  <div>French (FR)</div>
</div>

<div id="content"></div>

<div class="save-bar" id="save-bar">
  <span class="change-count" id="change-count"></span>
  <div style="display:flex;gap:8px;">
    <button class="btn btn-outline" onclick="discardChanges()">Discard</button>
    <button class="btn btn-primary" id="save-btn" onclick="saveChanges()">Save to CSV</button>
  </div>
</div>

<div class="toast" id="toast"></div>

<script>
let allStrings = [];
let modified = {};  // key -> {english, arabic, french}
let currentFilter = 'all';
let searchTerm = '';
let sectionFilter = '';
let langFilter = '';

async function loadStrings() {
  const res = await fetch('/api/strings');
  allStrings = await res.json();
  populateSections();
  render();
}

function populateSections() {
  const sections = [...new Set(allStrings.map(s => s.section).filter(Boolean))];
  const sel = document.getElementById('section-filter');
  for (const s of sections) {
    const opt = document.createElement('option');
    opt.value = s;
    opt.textContent = s;
    sel.appendChild(opt);
  }
}

function updateStats() {
  const total = allStrings.length;
  const missingAr = allStrings.filter(s => !getVal(s, 'arabic')).length;
  const missingFr = allStrings.filter(s => !getVal(s, 'french')).length;
  const totalMissing = missingAr + missingFr;
  const pct = total > 0 ? Math.round(((total * 2 - totalMissing) / (total * 2)) * 100) : 100;

  document.getElementById('stats').innerHTML =
    `<span>${total} strings</span> &middot; ` +
    (missingAr > 0 ? `<span class="missing">${missingAr} AR missing</span> &middot; ` : '<span class="complete">AR complete</span> &middot; ') +
    (missingFr > 0 ? `<span class="missing">${missingFr} FR missing</span>` : '<span class="complete">FR complete</span>');

  document.getElementById('progress-fill').style.width = pct + '%';
  document.getElementById('progress-label').textContent = pct + '% translated';
}

function getVal(s, lang) {
  if (modified[s.key] && modified[s.key][lang] !== undefined) return modified[s.key][lang];
  return s[lang] || '';
}

function render() {
  updateStats();
  const content = document.getElementById('content');
  const filtered = allStrings.filter(s => {
    // Status filter
    const arVal = getVal(s, 'arabic');
    const frVal = getVal(s, 'french');
    const isMissing = !arVal || !frVal;
    const isModified = !!modified[s.key];
    const isComplete = arVal && frVal;

    if (currentFilter === 'missing' && !isMissing) return false;
    if (currentFilter === 'modified' && !isModified) return false;
    if (currentFilter === 'complete' && !isComplete) return false;

    // Section filter
    if (sectionFilter && s.section !== sectionFilter) return false;

    // Language filter
    if (langFilter === 'ar' && arVal) return false;
    if (langFilter === 'fr' && frVal) return false;

    // Search
    if (searchTerm) {
      const q = searchTerm.toLowerCase();
      return (s.key || '').toLowerCase().includes(q) ||
             (s.context || '').toLowerCase().includes(q) ||
             (s.english || '').toLowerCase().includes(q) ||
             (s.arabic || '').toLowerCase().includes(q) ||
             (s.french || '').toLowerCase().includes(q);
    }
    return true;
  });

  if (filtered.length === 0) {
    content.innerHTML = '<div class="empty-state"><h2>No strings match</h2><p>Try adjusting your filters or search term.</p></div>';
    return;
  }

  let html = '';
  let lastSection = '';

  for (const s of filtered) {
    if (s.section && s.section !== lastSection) {
      lastSection = s.section;
      html += `<div class="section-header">${esc(s.section)}</div>`;
    }

    const arVal = getVal(s, 'arabic');
    const frVal = getVal(s, 'french');
    const enVal = getVal(s, 'english');
    const isModified = !!modified[s.key];
    const classes = [
      'string-row',
      isModified ? 'modified' : '',
      !arVal ? 'missing-ar' : '',
      !frVal ? 'missing-fr' : '',
    ].filter(Boolean).join(' ');

    html += `<div class="${classes}" id="row-${esc(s.key)}">
      <div class="key-col">
        <div class="key-name">${esc(s.key)}</div>
        <div class="key-context">${esc(s.context || '')}</div>
      </div>
      <div class="field-col field-en">
        <span class="field-label">English</span>
        <textarea data-key="${esc(s.key)}" data-lang="english" onfocus="autoGrow(this)" oninput="onEdit(this); autoGrow(this)">${esc(enVal)}</textarea>
      </div>
      <div class="field-col field-ar">
        <span class="field-label">Arabic</span>
        <textarea data-key="${esc(s.key)}" data-lang="arabic" dir="rtl" placeholder="${!arVal ? 'Missing translation...' : ''}" onfocus="autoGrow(this)" oninput="onEdit(this); autoGrow(this)">${esc(arVal)}</textarea>
      </div>
      <div class="field-col field-fr">
        <span class="field-label">French</span>
        <textarea data-key="${esc(s.key)}" data-lang="french" placeholder="${!frVal ? 'Missing translation...' : ''}" onfocus="autoGrow(this)" oninput="onEdit(this); autoGrow(this)">${esc(frVal)}</textarea>
      </div>
    </div>`;
  }

  content.innerHTML = html;
  // Auto-grow all textareas
  content.querySelectorAll('textarea').forEach(autoGrow);
}

function autoGrow(el) {
  el.style.height = 'auto';
  el.style.height = Math.max(40, el.scrollHeight) + 'px';
}

function onEdit(el) {
  const key = el.dataset.key;
  const lang = el.dataset.lang;
  const original = allStrings.find(s => s.key === key);
  if (!modified[key]) modified[key] = {};
  modified[key][lang] = el.value;

  // Check if all values match original — if so, remove from modified
  const m = modified[key];
  const enSame = (m.english ?? original.english) === original.english;
  const arSame = (m.arabic ?? original.arabic) === original.arabic;
  const frSame = (m.french ?? original.french) === original.french;
  if (enSame && arSame && frSame) {
    delete modified[key];
    el.closest('.string-row')?.classList.remove('modified');
  } else {
    el.closest('.string-row')?.classList.add('modified');
  }

  updateSaveBar();
  updateStats();
}

function updateSaveBar() {
  const count = Object.keys(modified).length;
  const bar = document.getElementById('save-bar');
  bar.classList.toggle('visible', count > 0);
  document.getElementById('change-count').textContent = `${count} unsaved change${count !== 1 ? 's' : ''}`;
}

async function saveChanges() {
  const btn = document.getElementById('save-btn');
  btn.disabled = true;
  btn.textContent = 'Saving...';

  const updates = Object.entries(modified).map(([key, vals]) => {
    const original = allStrings.find(s => s.key === key);
    return {
      key,
      english: vals.english ?? original.english,
      arabic: vals.arabic ?? original.arabic,
      french: vals.french ?? original.french,
    };
  });

  try {
    const res = await fetch('/api/save', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updates),
    });
    const data = await res.json();
    if (data.ok) {
      // Apply changes to allStrings
      for (const u of updates) {
        const s = allStrings.find(x => x.key === u.key);
        if (s) {
          s.english = u.english;
          s.arabic = u.arabic;
          s.french = u.french;
        }
      }
      modified = {};
      updateSaveBar();
      render();
      showToast(`Saved ${data.count} string(s) to CSV`);
    }
  } catch (e) {
    showToast('Save failed: ' + e.message);
  }

  btn.disabled = false;
  btn.textContent = 'Save to CSV';
}

function discardChanges() {
  modified = {};
  updateSaveBar();
  render();
}

function showToast(msg) {
  const el = document.getElementById('toast');
  el.textContent = msg;
  el.classList.add('show');
  setTimeout(() => el.classList.remove('show'), 3000);
}

function esc(s) {
  if (!s) return '';
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
          .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

// ── Event listeners ──
document.getElementById('search').addEventListener('input', (e) => {
  searchTerm = e.target.value;
  render();
});

document.getElementById('section-filter').addEventListener('change', (e) => {
  sectionFilter = e.target.value;
  render();
});

document.getElementById('lang-filter').addEventListener('change', (e) => {
  langFilter = e.target.value;
  render();
});

document.querySelectorAll('.chip').forEach(chip => {
  chip.addEventListener('click', () => {
    document.querySelectorAll('.chip').forEach(c => c.classList.remove('active'));
    chip.classList.add('active');
    currentFilter = chip.dataset.filter;
    render();
  });
});

// Warn before leaving with unsaved changes
window.addEventListener('beforeunload', (e) => {
  if (Object.keys(modified).length > 0) {
    e.preventDefault();
    e.returnValue = '';
  }
});

// Ctrl+S to save
document.addEventListener('keydown', (e) => {
  if ((e.ctrlKey || e.metaKey) && e.key === 's') {
    e.preventDefault();
    if (Object.keys(modified).length > 0) saveChanges();
  }
});

// ── Init ──
loadStrings();
</script>
</body>
</html>
''';
