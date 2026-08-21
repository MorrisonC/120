const http = require('http');
const fs = require('fs');
const path = require('path');
const mime = require('mime');

const port = parseInt(process.argv[2] || '8070', 10);
const dir = path.resolve(process.argv[3] || 'build/web');

const server = http.createServer((req, res) => {
    res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
    res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');

    let filePath = path.join(dir, req.url === '/' ? 'index.html' : req.url.split('?')[0]);

    fs.readFile(filePath, (err, data) => {
        if (err) {
            res.writeHead(404);
            res.end('404 Not Found');
            return;
        }

        const ext = path.extname(filePath);
        let contentType = mime.getType(ext) || 'application/octet-stream';
        if (ext === '.wasm') contentType = 'application/wasm';

        res.setHeader('Content-Type', contentType);
        res.writeHead(200);
        res.end(data);
    });
});

server.listen(port, () => {
    console.log(`Serving ${dir} on http://localhost:${port} with COOP/COEP headers`);
});
