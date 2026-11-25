const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const { createServer } = require('./server.cjs');

test('private loader: real session checks, fresh filenames, CORS, and failure handling', async () => {
    const folder = await fs.mkdtemp(path.join(os.tmpdir(), 'scooby-loader-test-'));
    const filePath = path.join(folder, 'ScoobyLoader.exe');
    const bytes = Buffer.from('MZ\0private test payload');
    await fs.writeFile(filePath, bytes);
    let authMode = 'valid';
    const checkedTokens = [];
    const auth = http.createServer((req, res) => {
        checkedTokens.push(req.headers.authorization);
        if (authMode === 'offline') { res.writeHead(503).end(); return; }
        if (authMode === 'redirect') { res.writeHead(302, { Location: '/elsewhere' }).end(); return; }
        if (authMode === 'malformed') { res.end('invalid JSON'); return; }
        if (authMode === 'unauthorized') { res.writeHead(401).end('{}'); return; }
        if (authMode === 'empty-customer') { res.end(JSON.stringify({ valid: true, customer: {} })); return; }
        const valid = authMode === 'valid' && req.headers.authorization === 'Bearer valid-session';
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify({ valid, customer: valid ? { id: 42 } : null }));
    });
    await new Promise(resolve => auth.listen(0, '127.0.0.1', resolve));
    const service = createServer({ filePath, sessionUrl: `http://127.0.0.1:${auth.address().port}/session`, allowedOrigins: ['https://scoobymenu.cc'] });
    await new Promise(resolve => service.listen(0, '127.0.0.1', resolve));
    const url = `http://127.0.0.1:${service.address().port}/loader`;
    const headers = { Authorization: 'Bearer valid-session', Origin: 'https://scoobymenu.cc' };
    const status = async (target, options) => { const response = await fetch(target, options); await response.arrayBuffer(); return response.status; };
    try {
        assert.equal(await status(url), 401);
        assert.equal(checkedTokens.length, 0);
        assert.equal(await status(url + '?token=valid-session'), 404);
        assert.equal(await status(url.replace('/loader', '/private/ScoobyLoader.exe'), { headers }), 404);
        assert.equal(await status(url, { method: 'POST', headers }), 405);
        assert.equal(await status(url, { headers: { ...headers, Origin: 'https://untrusted.example' } }), 403);
        assert.equal(checkedTokens.length, 0);
        const preflight = await fetch(url, { method: 'OPTIONS', headers: { Origin: headers.Origin, 'Access-Control-Request-Headers': 'authorization' } });
        assert.equal(preflight.status, 204);
        assert.equal(preflight.headers.get('Access-Control-Allow-Origin'), headers.Origin);
        assert.equal(preflight.headers.get('Access-Control-Allow-Headers'), 'Authorization');
        const filenames = new Set();
        for (let i = 0; i < 8; i++) {
            const response = await fetch(url, { headers });
            assert.equal(response.status, 200);
            const disposition = response.headers.get('Content-Disposition');
            assert.match(disposition, /^attachment; filename="[a-f0-9]{32}\.exe"$/);
            filenames.add(disposition);
            assert.equal(response.headers.get('Cache-Control'), 'private, no-store');
            assert.equal(response.headers.get('Access-Control-Expose-Headers'), 'Content-Disposition');
            assert.deepEqual(Buffer.from(await response.arrayBuffer()), bytes);
        }
        assert.equal(filenames.size, 8);
        assert.equal(checkedTokens.length, 8);
        assert.equal(await status(url, { headers: { Authorization: 'Bearer invalid-session' } }), 401);
        for (const mode of ['expired', 'unauthorized', 'empty-customer', 'offline', 'redirect', 'malformed']) {
            authMode = mode;
            assert.equal(await status(url, { headers }), ['expired', 'unauthorized', 'empty-customer'].includes(mode) ? 401 : 503, mode);
        }
        // An outage cannot fall back to an earlier successful session.
        authMode = 'valid';
        await fs.unlink(filePath);
        assert.equal(await status(url, { headers }), 503);
    } finally {
        service.closeAllConnections(); auth.closeAllConnections();
        await Promise.all([new Promise(resolve => service.close(resolve)), new Promise(resolve => auth.close(resolve))]);
        assert.equal(path.dirname(path.resolve(folder)), path.resolve(os.tmpdir()));
        assert.ok(path.basename(folder).startsWith('scooby-loader-test-'));
        await fs.rm(folder, { recursive: true, force: true });
    }
});
