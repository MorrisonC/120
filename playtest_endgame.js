const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');
const mime = require('mime');
const zlib = require('zlib');

const PORT = 8083;
const BUILD_DIR = fs.existsSync(path.join(__dirname, 'web_build')) ? path.join(__dirname, 'web_build') : path.join(__dirname, 'game', 'build', 'web');

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
        console.log(`Saved screenshot to ${filename}`);
    } else {
        await page.screenshot({ path: filename });
        console.log(`Saved page screenshot fallback to ${filename}`);
    }
}

async function runEndgamePlaytest() {
    return new Promise((resolve, reject) => {
        server.listen(PORT, async () => {
            console.log(`Endgame playtest server running on http://localhost:${PORT}`);
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

                page.on('console', msg => console.log('BROWSER LOG:', msg.text()));
                page.on('pageerror', err => console.error('BROWSER ERROR:', err.message));

                console.log("Navigating to WebGL canvas...");
                await page.goto(`http://localhost:${PORT}`);
                await page.waitForSelector('#canvas', { timeout: 30000 });
                await page.waitForTimeout(4000);

                // Shot 1: Spawn / Hearth Village
                console.log("Capturing Shot 1: Spawn / Hearth Village");
                await captureCanvas(page, 'shot_1_spawn.png');

                // Movement 1: Move right & down, interact
                console.log("Moving character towards Bridge...");
                for (let i = 0; i < 15; i++) {
                    await page.keyboard.press('KeyD');
                    await page.waitForTimeout(100);
                }
                for (let i = 0; i < 10; i++) {
                    await page.keyboard.press('KeyS');
                    await page.waitForTimeout(100);
                }
                await page.keyboard.press('KeyE');
                await page.waitForTimeout(500);

                // Shot 2: Bridge / Waterwheel
                console.log("Capturing Shot 2: Bridge");
                await captureCanvas(page, 'shot_2_bridge.png');

                // Movement 2: Advance towards Brambles / Forest
                console.log("Moving character towards Brambles / Forest...");
                for (let i = 0; i < 20; i++) {
                    await page.keyboard.press('KeyD');
                    await page.waitForTimeout(100);
                }
                for (let i = 0; i < 10; i++) {
                    await page.keyboard.press('KeyW');
                    await page.waitForTimeout(100);
                }
                await page.keyboard.press('Space'); // attack / action
                await page.waitForTimeout(500);

                // Shot 3: Brambles / Forest
                console.log("Capturing Shot 3: Brambles");
                await captureCanvas(page, 'shot_3_brambles.png');

                // Movement 3: Advance towards Shrine / Cave
                console.log("Moving character towards Shrine / Cave...");
                for (let i = 0; i < 25; i++) {
                    await page.keyboard.press('KeyW');
                    await page.waitForTimeout(100);
                }
                for (let i = 0; i < 10; i++) {
                    await page.keyboard.press('KeyA');
                    await page.waitForTimeout(100);
                }
                await page.keyboard.press('KeyE');
                await page.waitForTimeout(500);

                // Shot 4: Shrine / Cave
                console.log("Capturing Shot 4: Shrine");
                await captureCanvas(page, 'shot_4_shrine.png');

                // Movement 4: Advance towards Spire
                console.log("Moving character towards Clockwork Spire...");
                for (let i = 0; i < 30; i++) {
                    await page.keyboard.press('KeyD');
                    await page.waitForTimeout(100);
                }
                for (let i = 0; i < 15; i++) {
                    await page.keyboard.press('KeyW');
                    await page.waitForTimeout(100);
                }
                await page.keyboard.press('Space');
                await page.waitForTimeout(500);

                // Shot 5: Clockwork Spire
                console.log("Capturing Shot 5: Spire");
                await captureCanvas(page, 'shot_5_spire.png');

                await browser.close();
                server.close();
                console.log("Endgame playtest finished successfully.");
                resolve();
            } catch (err) {
                console.error("Endgame playtest error:", err);
                server.close();
                reject(err);
            }
        });
    });
}

if (require.main === module) {
    runEndgamePlaytest().then(() => process.exit(0)).catch(() => process.exit(1));
}
