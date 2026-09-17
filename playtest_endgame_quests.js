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

async function runEndgameWalkthrough() {
    return new Promise((resolve, reject) => {
        server.listen(PORT, async () => {
            console.log(`Endgame quest playtest server running on http://localhost:${PORT}`);
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
                    if (msg.type() === 'error' && !msg.text().includes('favicon.ico')) {
                        consoleErrors.push(msg.text());
                    }
                });

                page.on('pageerror', err => {
                    consoleErrors.push(err.message);
                });

                console.log("Navigating to web export canvas...");
                await page.goto(`http://localhost:${PORT}`);
                await page.waitForSelector('#canvas', { timeout: 30000 });
                await page.waitForTimeout(3000);

                // Shot 1: Initial Spawn
                console.log("Capturing Shot 1: Start/Spawn...");
                await captureCanvas(page, 'shot_1_start.png');

                // Movement 1: Talk to Elder Thomas / Quest 1
                console.log("Navigating towards Quest 1 target...");
                for (let i = 0; i < 10; i++) {
                    await page.keyboard.press('KeyW');
                    await page.waitForTimeout(40);
                }
                await page.keyboard.press('Space'); // Interact / Attack
                await page.waitForTimeout(400);

                // Shot 2: Quest 1
                console.log("Capturing Shot 2: Quest 1...");
                await captureCanvas(page, 'shot_2_quest1.png');

                // Movement 2: Advance towards Zone 1 / Combat
                console.log("Navigating towards Zone 1...");
                for (let i = 0; i < 12; i++) {
                    await page.keyboard.press('KeyD');
                    await page.waitForTimeout(40);
                }
                for (let i = 0; i < 10; i++) {
                    await page.keyboard.press('KeyW');
                    await page.waitForTimeout(40);
                }
                await page.keyboard.press('Space');
                await page.waitForTimeout(400);

                // Shot 3: Zone 1
                console.log("Capturing Shot 3: Zone 1...");
                await captureCanvas(page, 'shot_3_zone1.png');

                // Touch interaction & movement for Zone 2
                console.log("Simulating touch actions and moving towards Zone 2...");
                await page.touchscreen.tap(1126, 547); // SWORD / Action
                await page.waitForTimeout(100);
                await page.touchscreen.tap(972, 604);  // DASH
                await page.waitForTimeout(100);
                for (let i = 0; i < 10; i++) {
                    await page.keyboard.press('KeyA');
                    await page.waitForTimeout(40);
                }

                // Shot 4: Zone 2
                console.log("Capturing Shot 4: Zone 2...");
                await captureCanvas(page, 'shot_4_zone2.png');

                // Movement 3: Advance to Zone 3
                console.log("Moving towards Zone 3...");
                for (let i = 0; i < 15; i++) {
                    await page.keyboard.press('KeyS');
                    await page.waitForTimeout(40);
                }
                await page.keyboard.press('Space');
                await page.waitForTimeout(400);

                // Shot 5: Zone 3
                console.log("Capturing Shot 5: Zone 3...");
                await captureCanvas(page, 'shot_5_zone3.png');

                // Movement 4: Endgame Clockwork Spire transition
                console.log("Navigating towards Zone 4 Clockwork Spire...");
                for (let i = 0; i < 15; i++) {
                    await page.keyboard.press('KeyD');
                    await page.waitForTimeout(40);
                }
                for (let i = 0; i < 12; i++) {
                    await page.keyboard.press('KeyW');
                    await page.waitForTimeout(40);
                }
                await page.keyboard.press('Space');
                await page.waitForTimeout(500);

                // Shot 6: Endgame
                console.log("Capturing Shot 6: Endgame...");
                await captureCanvas(page, 'shot_6_endgame.png');

                console.log("Walkthrough completed with console errors count:", consoleErrors.length);
                await browser.close();
                server.close();
                resolve();
            } catch (err) {
                console.error("Endgame playtest harness exception:", err);
                server.close();
                reject(err);
            }
        });
    });
}

if (require.main === module) {
    runEndgameWalkthrough().then(() => process.exit(0)).catch((err) => {
        console.error(err);
        process.exit(1);
    });
}
