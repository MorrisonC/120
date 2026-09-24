const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');
const mime = require('mime');
const zlib = require('zlib');

const PORT = 8083;
const BUILD_DIR = fs.existsSync(path.join(__dirname, 'web_build')) ? path.join(__dirname, 'web_build') : path.join(__dirname, 'build', 'web');

const server = http.createServer((req, res) => {
    res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
    res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');

    let filePath = path.join(BUILD_DIR, req.url === '/' ? 'index.html' : req.url).split('?')[0];

    fs.readFile(filePath, (err, data) => {
        if (err) {
            res.writeHead(404);
            res.end();
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

function evaluateCanvas(buf) {
    let idx = 8, width = 0, height = 0, colorType = 0;
    const chunks = [];
    while (idx < buf.length) {
        const len = buf.readUInt32BE(idx);
        const type = buf.toString('ascii', idx + 4, idx + 8);
        if (type === 'IHDR') {
            width = buf.readUInt32BE(idx + 8);
            height = buf.readUInt32BE(idx + 12);
            colorType = buf.readUInt8(idx + 17);
        } else if (type === 'IDAT') chunks.push(buf.subarray(idx + 8, idx + 8 + len));
        idx += 12 + len;
    }
    const decomp = zlib.inflateSync(Buffer.concat(chunks));
    const bpp = colorType === 2 ? 3 : 4;
    const stride = width * bpp + 1;
    let sum = 0, nonZero = 0;
    const total = width * height;
    for (let y = 0; y < height; y++) {
        const row = y * stride + 1;
        for (let x = 0; x < width; x++) {
            const off = row + x * bpp;
            const val = decomp[off] + decomp[off + 1] + decomp[off + 2];
            sum += val;
            if (val > 10) nonZero++;
        }
    }
    const avg = sum / (total * 3);
    const ratio = nonZero / total;
    return { avg, ratio, nonZero, isBlack: nonZero < 500 || avg < 0.1 };
}

async function captureCanvas(page, filename) {
    const dataUrl = await page.evaluate(() => {
        return new Promise((resolve) => {
            requestAnimationFrame(() => {
                requestAnimationFrame(() => {
                    const canvas = document.getElementById('canvas');
                    if (canvas && typeof canvas.toDataURL === 'function') {
                        resolve(canvas.toDataURL('image/png'));
                    } else {
                        resolve(null);
                    }
                });
            });
        });
    });

    if (dataUrl) {
        const buf = Buffer.from(dataUrl.split(',')[1], 'base64');
        fs.writeFileSync(filename, buf);
        return evaluateCanvas(buf);
    } else {
        await page.screenshot({ path: filename });
        const buf = fs.readFileSync(filename);
        return evaluateCanvas(buf);
    }
}

async function runQuestPlaytest() {
    return new Promise((resolve, reject) => {
        server.listen(PORT, async () => {
            console.log(`Playtest server running on http://localhost:${PORT}`);
            const logs = [];
            const consoleErrors = [];

            try {
                const browser = await chromium.launch({
                    headless: true,
                    args: [
                        '--use-gl=angle',
                        '--enable-webgl',
                        '--disable-gpu-sandbox',
                        '--no-sandbox'
                    ]
                });

                const context = await browser.newContext({
                    hasTouch: true,
                    viewport: { width: 1280, height: 720 }
                });
                const page = await context.newPage();

                await page.addInitScript(() => {
                    const origGetContext = HTMLCanvasElement.prototype.getContext;
                    HTMLCanvasElement.prototype.getContext = function (type, attributes) {
                        if (type === 'webgl' || type === 'webgl2' || type === 'experimental-webgl') {
                            attributes = attributes || {};
                            attributes.preserveDrawingBuffer = true;
                        }
                        return origGetContext.call(this, type, attributes);
                    };
                });

                page.on('console', msg => {
                    logs.push(`[${msg.type()}] ${msg.text()}`);
                    if (msg.type() === 'error' && !msg.text().includes('favicon.ico')) {
                        consoleErrors.push(msg.text());
                    }
                });

                page.on('pageerror', err => {
                    consoleErrors.push(err.message);
                });

                console.log("Navigating to WebGL canvas...");
                await page.goto(`http://localhost:${PORT}`);
                await page.waitForSelector('#canvas', { timeout: 30000 });
                await page.waitForTimeout(4000);

                // Stage 1: Spawn / Beginning
                console.log("1. Capturing Shot 1: Beginning Spawn...");
                const shot1 = await captureCanvas(page, 'shot_1_start.png');

                // Simulate movement & unit spawn / interactions
                console.log("2. Moving character and spawning units...");
                const movementKeys = ['KeyD', 'KeyD', 'KeyW', 'KeyS', 'Space', 'ShiftLeft'];
                for (const key of movementKeys) {
                    await page.keyboard.press(key);
                    await page.waitForTimeout(150);
                }

                // Stage 2: Quest / Unit battle progression
                console.log("3. Capturing Shot 2: Quest Progression...");
                const shot2 = await captureCanvas(page, 'shot_2_quest.png');

                // Interact with UI / simulate progression
                await page.waitForTimeout(3000);

                // Stage 3: Midgame Progression
                console.log("4. Capturing Shot 3: Midgame Progression...");
                const shot3 = await captureCanvas(page, 'shot_3_midgame.png');

                // Stage 4: Endgame State
                await page.waitForTimeout(3000);
                console.log("5. Capturing Shot 4: Endgame State...");
                const shot4 = await captureCanvas(page, 'shot_4_endgame.png');

                fs.writeFileSync('playtest_quest_log.txt', logs.join('\n'));
                console.log("Playtest completed. Console errors:", consoleErrors.length);

                await browser.close();
                server.close();
                resolve({ shot1, shot2, shot3, shot4, consoleErrors });
            } catch (err) {
                console.error("Playtest execution failed:", err);
                server.close();
                reject(err);
            }
        });
    });
}

if (require.main === module) {
    runQuestPlaytest().then(() => process.exit(0)).catch(() => process.exit(1));
}

module.exports = { runQuestPlaytest };
