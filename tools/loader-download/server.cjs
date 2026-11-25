'use strict';
const http = require('node:http');
const path = require('node:path');
const fs = require('node:fs');
const { randomBytes } = require('node:crypto');
const { pipeline } = require('node:stream/promises');

const SESSION_URL = 'https://proudlyauthentication.com/api/portal/v1/pk_gri2butNfQ28AWQqNTD5xLtQKwer2MNv/auth/session';
const DEFAULT_ORIGINS = ['https://scoobymenu.cc', 'https://www.scoobymenu.cc'];

function createHandler({
    filePath = process.env.SCOOBY_LOADER_PATH || path.join(__dirname, 'private', 'ScoobyLoader.exe'),
    sessionUrl = SESSION_URL,
    allowedOrigins = DEFAULT_ORIGINS,
    sessionTimeoutMs = 10000,
    downloadPath = '/loader',
} = {}) {
    const origins = new Set(allowedOrigins);
    return async (req, res) => {
        res.setHeader('Cache-Control', 'private, no-store');
        res.setHeader('X-Content-Type-Options', 'nosniff');
        res.setHeader('Vary', 'Origin');
        const fail = (status, message) => {
            res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
            res.end(JSON.stringify({ message }));
        };
        const origin = req.headers.origin;
        if (origin && !origins.has(origin)) return fail(403, 'Origin not allowed.');
        if (origin) {
            res.setHeader('Access-Control-Allow-Origin', origin);
            res.setHeader('Access-Control-Expose-Headers', 'Content-Disposition');
        }
        // Never serve arbitrary paths or expose the private file directory.
        if (req.url !== downloadPath) return fail(404, 'Not found.');
        if (req.method === 'OPTIONS') {
            res.writeHead(204, {
                'Access-Control-Allow-Methods': 'GET, OPTIONS',
                'Access-Control-Allow-Headers': 'Authorization',
            });
            return res.end();
        }
        if (req.method !== 'GET') {
            res.setHeader('Allow', 'GET, OPTIONS');
            return fail(405, 'Method not allowed.');
        }
        const authorization = req.headers.authorization || '';
        if (authorization.length > 8192 || !/^Bearer \S+$/i.test(authorization)) {
            return fail(401, 'Sign in to download the loader.');
        }
        // Validate every request with the same portal that issued the token.
        // Never accept an auth URL, token, or file path from a query string.
        let session;
        try {
            const response = await fetch(sessionUrl, {
                headers: { Authorization: authorization, Accept: 'application/json' },
                cache: 'no-store',
                redirect: 'error',
                signal: AbortSignal.timeout(sessionTimeoutMs),
            });
            if (response.status === 401 || response.status === 403) {
                await response.body?.cancel();
                return fail(401, 'Your session has expired. Please sign in again.');
            }
            if (!response.ok) {
                await response.body?.cancel();
                return fail(503, 'Could not check your session. Please try again.');
            }
            session = await response.json();
        } catch (_) {
            return fail(503, 'Could not check your session. Please try again.');
        }
        if (session?.valid !== true || !session.customer || typeof session.customer !== 'object' || Array.isArray(session.customer) || !session.customer.id) {
            return fail(401, 'Your session has expired. Please sign in again.');
        }
        let file;
        try {
            file = await fs.promises.open(filePath, 'r');
            const stat = await file.stat();
            if (!stat.isFile() || stat.size === 0) throw new Error('Loader unavailable');
            res.writeHead(200, {
                'Content-Type': 'application/octet-stream',
                'Content-Length': stat.size,
                'Content-Disposition': `attachment; filename="${randomBytes(16).toString('hex')}.exe"`,
            });
            await pipeline(file.createReadStream(), res);
        } catch (_) {
            if (!res.headersSent) fail(503, 'The loader is temporarily unavailable.');
            else res.destroy();
        } finally {
            await file?.close().catch(() => {});
        }
    };
}

function createServer(options) { return http.createServer(createHandler(options)); }

if (require.main === module) {
    const allowedOrigins = process.env.SCOOBY_ALLOWED_ORIGINS?.split(',').map(value => value.trim()).filter(Boolean) || DEFAULT_ORIGINS;
    const server = createServer({ allowedOrigins });
    const host = process.env.HOST || '127.0.0.1';
    const port = Number(process.env.PORT || 8787);
    server.on('error', error => { console.error(error.message); process.exitCode = 1; });
    server.listen(port, host, () => console.log(`Loader service listening on http://${host}:${port}/loader`));
}
module.exports = { createServer, createHandler, SESSION_URL };
