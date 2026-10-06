const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');
const { siteRoot, isPublic } = require('./site-layout.cjs');
const mime = { '.html':'text/html; charset=utf-8', '.css':'text/css', '.js':'text/javascript', '.mjs':'text/javascript', '.json':'application/json', '.png':'image/png', '.jpg':'image/jpeg', '.jpeg':'image/jpeg', '.webp':'image/webp', '.svg':'image/svg+xml', '.woff2':'font/woff2', '.xml':'application/xml', '.txt':'text/plain', '.md':'text/plain', '.pdf':'application/pdf', '.zip':'application/zip' };
function createServer(root = siteRoot) {
  return http.createServer((req, res) => {
    const error = code => {
      const body = code === 404 ? fs.readFileSync(path.join(root, '404.html')) : Buffer.from('Bad request');
      res.writeHead(code, { 'Content-Type':'text/html; charset=utf-8', 'Content-Length':body.length });
      res.end(req.method === 'HEAD' ? undefined : body);
    };
    if (!['GET', 'HEAD'].includes(req.method)) { res.writeHead(405, { Allow:'GET, HEAD' }); res.end(); return; }
    let url, pathname;
    try { url = new URL(req.url, 'http://localhost'); pathname = decodeURIComponent(url.pathname); }
    catch { error(400); return; }
    if (pathname.includes('\0') || pathname.includes('\\')) { error(400); return; }
    const relative = pathname.replace(/^\/+/, '') || 'index.html';
    if (!isPublic(relative)) { error(404); return; }
    let file = path.resolve(root, relative);
    if (!file.startsWith(path.resolve(root) + path.sep)) { error(404); return; }
    try {
      if (fs.statSync(file).isDirectory()) {
        if (!pathname.endsWith('/')) { res.writeHead(301, { Location:url.pathname + '/' + url.search }); res.end(); return; }
        file = path.join(file, 'index.html');
      }
      const stat = fs.statSync(file);
      if (!stat.isFile()) { error(404); return; }
      res.writeHead(200, { 'Content-Type':mime[path.extname(file)] || 'application/octet-stream', 'Content-Length':stat.size });
      if (req.method === 'HEAD') res.end(); else fs.createReadStream(file).pipe(res);
    } catch { error(404); }
  });
}
if (require.main === module) {
  const port = Number(process.argv[2] || 8080);
  const server = createServer();
  server.on('error', error => { console.error(error.code === 'EADDRINUSE' ? `Port ${port} is in use. Try npm start -- ${port + 1}` : error.message); process.exitCode = 1; });
  server.listen(port, '127.0.0.1', () => console.log(`Serving ${siteRoot}\nhttp://127.0.0.1:${port}/`));
}
module.exports = { createServer };
