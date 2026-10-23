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
        console.log(`Saved canvas snapshot to ${filename}`);
        return evaluateCanvas(buf);
    } else {
        await page.screenshot({ path: filename });
        const buf = fs.readFileSync(filename);
        console.log(`Saved screenshot fallback to ${filename}`);
        return evaluateCanvas(buf);
    }
}

async function runEndgamePlaytest() {
    return new Promise((resolve, reject) => {
        server.listen(PORT, async () => {
            console.log(`Endgame Playtest Server running on http://localhost:${PORT}`);
            const metrics = {
                timestamp: new Date().toISOString(),
                console_errors: [],
                screenshots: [],
                overall_status: "PASSED"
            };

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
                        metrics.console_errors.push(msg.text());
                    }
                });

                page.on('pageerror', err => {
                    metrics.console_errors.push(err.message);
                });

                console.log("Navigating to web build...");
                await page.goto(`http://localhost:${PORT}`);
                await page.waitForSelector('#canvas', { timeout: 30000 });
                await page.waitForTimeout(4000);

                // Shot 1: Start / Village
                console.log("Capturing Shot 1: Start / Hearth Village...");
                const shot1 = await captureCanvas(page, 'shot_1_start.png');
                metrics.screenshots.push({ name: 'shot_1_start.png', ...shot1 });

                // Step 1: Move around Village & perform attack / interaction
                for (let i = 0; i < 5; i++) {
                    await page.keyboard.press('KeyD');
                    await page.waitForTimeout(150);
                    await page.keyboard.press('KeyW');
                    await page.waitForTimeout(150);
                }
                await page.keyboard.press('Space'); // Attack
                await page.waitForTimeout(200);

                // Shot 2: Whispering Woods transition
                console.log("Navigating to Whispering Woods & Capturing Shot 2...");
                for (let i = 0; i < 8; i++) {
                    await page.keyboard.press('KeyD');
                    await page.waitForTimeout(150);
                }
                await page.keyboard.press('KeyE'); // Interact/Quest trigger
                await page.waitForTimeout(300);
                const shot2 = await captureCanvas(page, 'shot_2_woods.png');
                metrics.screenshots.push({ name: 'shot_2_woods.png', ...shot2 });

                // Shot 3: Old Quarry / Sunken Marsh
                console.log("Navigating to Quarry / Marsh & Capturing Shot 3...");
                for (let i = 0; i < 10; i++) {
                    await page.keyboard.press('KeyS');
                    await page.waitForTimeout(150);
                    await page.keyboard.press('KeyD');
                    await page.waitForTimeout(150);
                }
                await page.keyboard.press('Space');
                await page.waitForTimeout(200);
                const shot3 = await captureCanvas(page, 'shot_3_quarry_marsh.png');
                metrics.screenshots.push({ name: 'shot_3_quarry_marsh.png', ...shot3 });

                // Shot 4: Frostpeak
                console.log("Navigating to Frostpeak & Capturing Shot 4...");
                for (let i = 0; i < 8; i++) {
                    await page.keyboard.press('KeyW');
                    await page.waitForTimeout(150);
                    await page.keyboard.press('KeyA');
                    await page.waitForTimeout(150);
                }
                const shot4 = await captureCanvas(page, 'shot_4_frostpeak.png');
                metrics.screenshots.push({ name: 'shot_4_frostpeak.png', ...shot4 });

                // Shot 5: Ashen Ruins
                console.log("Navigating to Ashen Ruins & Capturing Shot 5...");
                for (let i = 0; i < 10; i++) {
                    await page.keyboard.press('KeyW');
                    await page.waitForTimeout(150);
                    await page.keyboard.press('KeyD');
                    await page.waitForTimeout(150);
                }
                const shot5 = await captureCanvas(page, 'shot_5_ashen_ruins.png');
                metrics.screenshots.push({ name: 'shot_5_ashen_ruins.png', ...shot5 });

                // Shot 6: Clockwork Spire / Endgame Area
                console.log("Navigating to Clockwork Spire / Endgame & Capturing Shot 6...");
                for (let i = 0; i < 8; i++) {
                    await page.keyboard.press('KeyD');
                    await page.waitForTimeout(150);
                    await page.keyboard.press('Space');
                    await page.waitForTimeout(150);
                }
                const shot6 = await captureCanvas(page, 'shot_6_endgame.png');
                metrics.screenshots.push({ name: 'shot_6_endgame.png', ...shot6 });

                if (metrics.console_errors.length > 0) {
                    metrics.overall_status = "FAILED";
                }

                fs.writeFileSync('playtest_endgame_metrics.json', JSON.stringify(metrics, null, 2));
                console.log("Playtest complete. Closing browser and server.");

                await browser.close();
                server.close();
                resolve(metrics);
            } catch (err) {
                console.error("Playtest exception:", err);
                server.close();
                reject(err);
            }
        });
    });
}

if (require.main === module) {
    runEndgamePlaytest().then(() => process.exit(0)).catch(() => process.exit(1));
}
