const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');
const mime = require('mime');

const PORT = 8083;
const BUILD_DIR = path.join(__dirname, 'web_build');

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
        console.log(`Saved screenshot: ${filename} (${buf.length} bytes)`);
    } else {
        await page.screenshot({ path: filename });
        console.log(`Saved page screenshot: ${filename}`);
    }
}

async function runEndgamePlaytest() {
    return new Promise((resolve, reject) => {
        server.listen(PORT, async () => {
            console.log(`Playtest server running on http://localhost:${PORT}`);
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
                    if (msg.type() === 'error') {
                        console.error('Browser console error:', msg.text());
                    }
                });

                console.log("Navigating to test harness...");
                await page.goto(`http://localhost:${PORT}`);
                await page.waitForSelector('#canvas', { timeout: 30000 });
                await page.waitForTimeout(5000); // Wait for WebGL & scene load

                // Shot 1: Initial Spawn (Hearth Village / Zone 0)
                console.log("Capturing Shot 1: Start (Hearth Village)...");
                await captureCanvas(page, 'shot_1_start.png');

                // Step 1: Move around Hearth Village and attempt bridge / interact
                console.log("Moving around Hearth Village & interacting...");
                for (let i = 0; i < 8; i++) {
                    await page.keyboard.press('KeyD');
                    await page.waitForTimeout(100);
                    await page.keyboard.press('KeyE'); // Interact
                    await page.waitForTimeout(100);
                }
                await page.keyboard.press('Space'); // Attack/Action
                await page.waitForTimeout(300);

                // Shot 2: Zone 1 / Bridge area
                console.log("Capturing Shot 2: Zone 1 / Bridge Area...");
                await captureCanvas(page, 'shot_2_zone1.png');

                // Step 2: Move North / East towards Zone 2
                console.log("Moving towards Zone 2...");
                for (let i = 0; i < 12; i++) {
                    await page.keyboard.press('KeyW');
                    await page.waitForTimeout(150);
                    await page.keyboard.press('KeyD');
                    await page.waitForTimeout(150);
                    await page.keyboard.press('KeyE');
                }

                // Shot 3: Zone 2
                console.log("Capturing Shot 3: Zone 2...");
                await captureCanvas(page, 'shot_3_zone2.png');

                // Step 3: Move towards Zone 3
                console.log("Moving towards Zone 3...");
                for (let i = 0; i < 12; i++) {
                    await page.keyboard.press('KeyW');
                    await page.waitForTimeout(150);
                    await page.keyboard.press('KeyA');
                    await page.waitForTimeout(150);
                    await page.keyboard.press('Space');
                }

                // Shot 4: Zone 3
                console.log("Capturing Shot 4: Zone 3...");
                await captureCanvas(page, 'shot_4_zone3.png');

                // Step 4: Move towards Zone 4 (Clockwork Spire)
                console.log("Moving towards Zone 4 (Spire)...");
                for (let i = 0; i < 15; i++) {
                    await page.keyboard.press('KeyW');
                    await page.waitForTimeout(150);
                    await page.keyboard.press('KeyE');
                    await page.waitForTimeout(150);
                }

                // Shot 5: Zone 4 (Spire Gate)
                console.log("Capturing Shot 5: Spire Gate...");
                await captureCanvas(page, 'shot_5_spire.png');

                // Step 5: Engage Boss / Spire area interactions
                console.log("Engaging Endgame / Spire interactions...");
                for (let i = 0; i < 10; i++) {
                    await page.keyboard.press('Space');
                    await page.waitForTimeout(100);
                    await page.keyboard.press('KeyF'); // Dash
                    await page.waitForTimeout(100);
                }

                // Shot 6: Endgame State
                console.log("Capturing Shot 6: Endgame State...");
                await captureCanvas(page, 'shot_6_endgame.png');

                console.log("All 6 screenshots captured successfully.");
                await browser.close();
                server.close();
                resolve();
            } catch (err) {
                console.error("Playtest execution failed:", err);
                server.close();
                reject(err);
            }
        });
    });
}

runEndgamePlaytest().then(() => process.exit(0)).catch(() => process.exit(1));
