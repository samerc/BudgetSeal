// BudgetSeal household relay — a Cloudflare Worker + one Durable Object per
// household. It stores files it cannot read: the phones encrypt everything
// with a key that only exists on the phones and in the household's QR code.
//
// Protocol (all requests: `Authorization: Bearer <auth>`, where auth and the
// household id are both derived on the phone from the household secret):
//   PUT    /v1/h/:hid               create the household (idempotent)
//   DELETE /v1/h/:hid               delete the household and every file
//   GET    /v1/h/:hid/files         {files: [{name, version, size}]}
//   GET    /v1/h/:hid/files/:name   the file's bytes
//   PUT    /v1/h/:hid/files/:name   create or replace a file
//
// The relay knows: a random household id, file names (random device ids and
// counters), sizes and times. Never the budget.

import { DurableObject } from 'cloudflare:workers';

const MAX_FILE = 20 * 1024 * 1024; // one file (a big budget's snapshot ~16 MB)
const MAX_HOUSEHOLD = 200 * 1024 * 1024; // all files of one household
const CHUNK = 1024 * 1024; // SQLite values are capped at 2 MB
const RATE_PER_MINUTE = 240; // requests per household

const HID = /^[0-9a-f]{32}$/;
const NAME = /^[A-Za-z0-9._-]{1,120}$/;

const json = (status, body) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const parts = url.pathname.split('/').filter(Boolean);
    if (parts.length === 1 && parts[0] === 'health') return json(200, { ok: true });
    if (parts[0] !== 'v1' || parts[1] !== 'h' || !HID.test(parts[2] ?? '')) {
      return json(404, { error: 'not_found' });
    }
    if (parts.length > 3 && (parts[3] !== 'files' || parts.length > 5)) {
      return json(404, { error: 'not_found' });
    }
    if (parts.length === 5 && !NAME.test(parts[4])) {
      return json(400, { error: 'bad_name' });
    }
    const auth = (request.headers.get('authorization') ?? '').replace(/^Bearer /, '');
    if (auth.length < 32 || auth.length > 128) return json(401, { error: 'unauthorized' });
    if (Number(request.headers.get('content-length') ?? '0') > MAX_FILE) {
      return json(413, { error: 'file_too_large' });
    }
    const stub = env.HOUSEHOLD.get(env.HOUSEHOLD.idFromName(parts[2]));
    return stub.fetch(request);
  },
};

async function sha256(text) {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

function sameText(a, b) {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

export class Household extends DurableObject {
  constructor(ctx, env) {
    super(ctx, env);
    this.sql = ctx.storage.sql;
    this.window = { start: 0, count: 0 };
    this.tables();
  }

  // Again after a delete: deleteAll() drops the tables too.
  tables() {
    this.sql.exec(`CREATE TABLE IF NOT EXISTS meta (k TEXT PRIMARY KEY, v TEXT NOT NULL)`);
    this.sql.exec(`CREATE TABLE IF NOT EXISTS files (
      name TEXT PRIMARY KEY, version INTEGER NOT NULL, size INTEGER NOT NULL,
      chunks INTEGER NOT NULL, updated INTEGER NOT NULL)`);
    this.sql.exec(`CREATE TABLE IF NOT EXISTS chunks (
      name TEXT NOT NULL, idx INTEGER NOT NULL, data BLOB NOT NULL,
      PRIMARY KEY (name, idx))`);
  }

  meta(k) {
    const row = this.sql.exec('SELECT v FROM meta WHERE k = ?', k).toArray()[0];
    return row ? row.v : null;
  }

  limited() {
    const now = Date.now();
    if (now - this.window.start > 60_000) this.window = { start: now, count: 0 };
    return ++this.window.count > RATE_PER_MINUTE;
  }

  async fetch(request) {
    const response = await this.handle(request);
    // An upload refused before its body was read: read it anyway, or the
    // Worker forwarding it fails ("can't read from request stream").
    if (request.body && !request.bodyUsed) await request.arrayBuffer().catch(() => {});
    return response;
  }

  async handle(request) {
    if (this.limited()) return json(429, { error: 'too_many_requests' });
    const parts = new URL(request.url).pathname.split('/').filter(Boolean);
    const auth = (request.headers.get('authorization') ?? '').replace(/^Bearer /, '');
    const hash = await sha256(auth);
    const stored = this.meta('auth');

    // Create: the first phone sets the key hash; the same key again is fine.
    if (parts.length === 3 && request.method === 'PUT') {
      if (stored === null) {
        this.sql.exec(`INSERT INTO meta (k, v) VALUES ('auth', ?), ('created', ?)`,
          hash, String(Date.now()));
        return json(201, { created: true });
      }
      return sameText(stored, hash) ? json(200, { created: false }) : json(409, { error: 'exists' });
    }
    if (stored === null) return json(404, { error: 'no_household' });
    if (!sameText(stored, hash)) return json(401, { error: 'unauthorized' });

    if (parts.length === 3 && request.method === 'DELETE') {
      await this.ctx.storage.deleteAll();
      this.tables();
      return json(200, { deleted: true });
    }
    if (parts.length === 4 && request.method === 'GET') {
      const files = this.sql
        .exec('SELECT name, version, size FROM files ORDER BY name')
        .toArray();
      return json(200, { files });
    }
    if (parts.length === 5) {
      const name = parts[4];
      if (request.method === 'GET') return this.read(name);
      if (request.method === 'PUT') return this.write(name, request);
    }
    return json(405, { error: 'method_not_allowed' });
  }

  read(name) {
    const file = this.sql.exec('SELECT size, chunks FROM files WHERE name = ?', name).toArray()[0];
    if (!file) return json(404, { error: 'no_file' });
    const out = new Uint8Array(file.size);
    let at = 0;
    for (const row of this.sql.exec('SELECT data FROM chunks WHERE name = ? ORDER BY idx', name)) {
      const part = new Uint8Array(row.data);
      out.set(part, at);
      at += part.length;
    }
    return new Response(out, { headers: { 'content-type': 'application/octet-stream' } });
  }

  async write(name, request) {
    const declared = Number(request.headers.get('content-length') ?? '0');
    if (declared > MAX_FILE) return json(413, { error: 'file_too_large' });
    const body = new Uint8Array(await request.arrayBuffer());
    if (body.length > MAX_FILE) return json(413, { error: 'file_too_large' });

    const old = this.sql.exec('SELECT size, version FROM files WHERE name = ?', name).toArray()[0];
    const used = this.sql.exec('SELECT COALESCE(SUM(size), 0) AS total FROM files').one().total;
    if (used - (old?.size ?? 0) + body.length > MAX_HOUSEHOLD) {
      return json(413, { error: 'household_full' });
    }
    const version = (old?.version ?? 0) + 1;
    const chunks = Math.max(1, Math.ceil(body.length / CHUNK));
    this.ctx.storage.transactionSync(() => {
      this.sql.exec('DELETE FROM chunks WHERE name = ?', name);
      for (let i = 0; i < chunks; i++) {
        this.sql.exec('INSERT INTO chunks (name, idx, data) VALUES (?, ?, ?)',
          name, i, body.subarray(i * CHUNK, (i + 1) * CHUNK));
      }
      this.sql.exec(`INSERT INTO files (name, version, size, chunks, updated)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(name) DO UPDATE SET version = excluded.version,
          size = excluded.size, chunks = excluded.chunks, updated = excluded.updated`,
        name, version, body.length, chunks, Date.now());
    });
    return json(200, { version, size: body.length });
  }
}
