const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');
const mime = require('mime');

const PORT = 8085;
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
    } else {
        await page.screenshot({ path: filename });
    }
    console.log(`Saved screenshot: ${filename}`);
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
                    if (msg.type() === 'error') {
                        console.error('Browser Console Error:', msg.text());
                    }
                });

                console.log("Navigating to web export...");
                await page.goto(`http://localhost:${PORT}`);
                await page.waitForSelector('#canvas', { timeout: 30000 });
                await page.waitForTimeout(4000);

                // Shot 1: Beginning Spawn (Hearth Village / Start)
                console.log("Capturing Shot 1: Spawn / Beginning");
                await captureCanvas(page, 'shot_1_start.png');

                // Simulate movement & Quest 1 progression (Bridge / Waterwheel)
                console.log("Moving character & pressing action keys...");
                for (let i = 0; i < 15; i++) {
                    await page.keyboard.press('KeyD');
                    await page.waitForTimeout(100);
                    await page.keyboard.press('KeyW');
                    await page.waitForTimeout(100);
                }
                await page.keyboard.press('Space'); // Attack/Interact
                await page.waitForTimeout(500);

                // Shot 2: Quest 1 / Bridge area
                console.log("Capturing Shot 2: Quest 1 / Bridge");
                await captureCanvas(page, 'shot_2_bridge.png');

                // Move further towards Whispering Woods / Machete / Brambles
                for (let i = 0; i < 15; i++) {
                    await page.keyboard.press('KeyW');
                    await page.waitForTimeout(100);
                    await page.keyboard.press('KeyA');
                    await page.waitForTimeout(100);
                }
                await page.keyboard.press('KeyE'); // Interact
                await page.waitForTimeout(500);

                // Shot 3: Quest 2 / Machete & Brambles
                console.log("Capturing Shot 3: Quest 2 / Machete");
                await captureCanvas(page, 'shot_3_machete.png');

                // Move towards Waypoint Shrine / Sunken Marsh / Quarry
                for (let i = 0; i < 15; i++) {
                    await page.keyboard.press('KeyS');
                    await page.waitForTimeout(100);
                    await page.keyboard.press('KeyD');
                    await page.waitForTimeout(100);
                }
                await page.keyboard.press('Space');
                await page.waitForTimeout(500);

                // Shot 4: Waypoint Shrine / Shrine Alpha
                console.log("Capturing Shot 4: Waypoint Shrine");
                await captureCanvas(page, 'shot_4_shrine.png');

                // Move towards Boss / Ashen Ruins / Clockwork Spire
                for (let i = 0; i < 20; i++) {
                    await page.keyboard.press('KeyW');
                    await page.waitForTimeout(100);
                }
                await page.keyboard.press('Space');
                await page.waitForTimeout(500);

                // Shot 5: Boss Encounter / Ashen Ruins
                console.log("Capturing Shot 5: Boss Encounter");
                await captureCanvas(page, 'shot_5_boss.png');

                // Touch input test & Endgame Spire completion
                await page.touchscreen.tap(1126, 547); // SWORD button
                await page.waitForTimeout(200);
                await page.touchscreen.tap(972, 604); // DASH button
                await page.waitForTimeout(500);

                // Shot 6: Endgame State
                console.log("Capturing Shot 6: Endgame State");
                await captureCanvas(page, 'shot_6_endgame.png');

                await browser.close();
                server.close();
                console.log("Playtest complete. All 6 endgame screenshots captured.");
                resolve();
            } catch (err) {
                console.error("Playtest failed:", err);
                server.close();
                reject(err);
            }
        });
    });
}

runEndgamePlaytest().then(() => process.exit(0)).catch(() => process.exit(1));
