// Runs against a relay: `npx wrangler dev` then `npm test`, or
// RELAY=https://… npm test for a deployed one (uses a throwaway household).
import assert from 'node:assert/strict';
import { randomBytes } from 'node:crypto';

const base = process.env.RELAY ?? 'http://127.0.0.1:8787';
const hid = randomBytes(16).toString('hex');
const auth = randomBytes(32).toString('base64url');
const other = randomBytes(32).toString('base64url');

const call = (method, path, { key = auth, body } = {}) =>
  fetch(`${base}/v1/h/${hid}${path}`, {
    method,
    headers: { authorization: `Bearer ${key}` },
    body,
  });

let passed = 0;
async function test(name, body) {
  await body();
  passed++;
  console.log(`ok - ${name}`);
}

await test('health', async () => {
  assert.equal((await fetch(`${base}/health`)).status, 200);
});
await test('unknown household', async () => {
  assert.equal((await call('GET', '/files')).status, 404);
});
await test('create, again with the same key, then another key', async () => {
  assert.equal((await call('PUT', '')).status, 201);
  assert.equal((await call('PUT', '')).status, 200);
  assert.equal((await call('PUT', '', { key: other })).status, 409);
});
await test('wrong key is refused', async () => {
  assert.equal((await call('GET', '/files', { key: other })).status, 401);
  assert.equal((await call('PUT', '/files/x.json', { key: other, body: 'x' })).status, 401);
});
await test('missing key is refused', async () => {
  const r = await fetch(`${base}/v1/h/${hid}/files`);
  assert.equal(r.status, 401);
});
await test('empty list', async () => {
  assert.deepEqual(await (await call('GET', '/files')).json(), { files: [] });
});
await test('write and read back', async () => {
  const r = await call('PUT', '/files/log-dev1-00001.json', { body: 'hello' });
  assert.equal(r.status, 200);
  assert.equal((await r.json()).version, 1);
  const g = await call('GET', '/files/log-dev1-00001.json');
  assert.equal(await g.text(), 'hello');
});
await test('a 3 MB file spans chunks and comes back intact', async () => {
  const big = randomBytes(3 * 1024 * 1024 + 123);
  assert.equal((await call('PUT', '/files/log-snapshot-dev1.json', { body: big })).status, 200);
  const back = Buffer.from(await (await call('GET', '/files/log-snapshot-dev1.json')).arrayBuffer());
  assert.ok(back.equals(big));
});
await test('replacing bumps the version and shrinks cleanly', async () => {
  await call('PUT', '/files/log-snapshot-dev1.json', { body: 'small' });
  const list = (await (await call('GET', '/files')).json()).files;
  const snap = list.find((f) => f.name === 'log-snapshot-dev1.json');
  assert.equal(snap.version, 2);
  assert.equal(snap.size, 5);
  assert.equal(await (await call('GET', '/files/log-snapshot-dev1.json')).text(), 'small');
});
await test('unknown file is 404', async () => {
  assert.equal((await call('GET', '/files/nope.json')).status, 404);
});
await test('bad names are refused', async () => {
  assert.equal((await call('PUT', '/files/..%2Fx', { body: 'x' })).status, 400);
  assert.equal((await call('PUT', '/files/a%20b', { body: 'x' })).status, 400);
});
await test('a file over 20 MB is refused', async () => {
  const r = await call('PUT', '/files/huge.json', { body: randomBytes(20 * 1024 * 1024 + 1) });
  assert.equal(r.status, 413);
});
await test('delete removes the household', async () => {
  assert.equal((await call('DELETE', '')).status, 200);
  assert.equal((await call('GET', '/files')).status, 404);
});

console.log(`\n${passed} passed`);
