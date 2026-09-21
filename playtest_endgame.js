const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');
const mime = require('mime');
const zlib = require('zlib');

const PORT = 8083;
const BUILD_DIR = path.join(__dirname, 'web_build');

const server = http.createServer((req, res) => {
    res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
    res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');

    let filePath = path.join(BUILD_DIR, req.url === '/' ? 'index.html' : req.url).split('?')[0];

    fs.readFile(filePath, (err, data) => {
        if (err) {
            res.writeHead(404);
            res.end("Not Found");
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
}

async function focusCanvas(page) {
    try {
        const canvas = page.locator('canvas').first();
        if (await canvas.count() > 0) {
            await canvas.click({ position: { x: 10, y: 10 }, timeout: 5000 }).catch(() => {});
        } else {
            await page.mouse.click(100, 100);
        }
    } catch (e) {
        await page.mouse.click(100, 100).catch(() => {});
    }
}

async function runEndgamePlaytest() {
    return new Promise((resolve, reject) => {
        server.listen(PORT, async () => {
            console.log(`Endgame Playtest Server running on http://localhost:${PORT}`);
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
                    console.log(`[Browser Console ${msg.type()}]:`, msg.text());
                });

                page.on('pageerror', err => {
                    console.error(`[Browser PageError]:`, err.message);
                });

                console.log("Navigating to WebGL export...");
                await page.goto(`http://localhost:${PORT}`);
                await page.waitForSelector('#canvas', { timeout: 30000 });
                await page.waitForTimeout(5000); // Godot boot time
                await focusCanvas(page);

                // 1. Spawn Screenshot
                console.log("Capturing 1: Spawn...");
                await captureCanvas(page, 'shot_1_spawn.png');

                // Simulate movement & combat in starting area
                console.log("Moving character around starting village...");
                const moves1 = ['KeyD', 'KeyD', 'KeyW', 'KeyS', 'KeyA', 'Space', 'KeyD'];
                for (const key of moves1) {
                    await page.keyboard.down(key);
                    await page.waitForTimeout(300);
                    await page.keyboard.up(key);
                    await page.waitForTimeout(100);
                }

                // 2. Waterwheel / Bridge quest milestone
                console.log("Capturing 2: Waterwheel...");
                await captureCanvas(page, 'shot_2_waterwheel.png');

                // Continue movement across zones
                console.log("Moving character towards Whispering Woods & Brambles...");
                const moves2 = ['KeyD', 'KeyD', 'KeyD', 'KeyW', 'Space', 'KeyD'];
                for (const key of moves2) {
                    await page.keyboard.down(key);
                    await page.waitForTimeout(400);
                    await page.keyboard.up(key);
                    await page.waitForTimeout(100);
                }

                // 3. Brambles / Machete quest milestone
                console.log("Capturing 3: Brambles...");
                await captureCanvas(page, 'shot_3_brambles.png');

                // Continue movement towards Sunken Marsh & Shrine
                console.log("Moving character towards Sunken Marsh & Shrine...");
                const moves3 = ['KeyS', 'KeyD', 'KeyD', 'KeyW', 'Space', 'KeyS'];
                for (const key of moves3) {
                    await page.keyboard.down(key);
                    await page.waitForTimeout(400);
                    await page.keyboard.up(key);
                    await page.waitForTimeout(100);
                }

                // 4. Shrine milestone
                console.log("Capturing 4: Shrine...");
                await captureCanvas(page, 'shot_4_shrine.png');

                // Move character towards Spire Gate
                console.log("Moving character towards Spire Gate...");
                const moves4 = ['KeyW', 'KeyW', 'KeyD', 'KeyD', 'Space'];
                for (const key of moves4) {
                    await page.keyboard.down(key);
                    await page.waitForTimeout(400);
                    await page.keyboard.up(key);
                    await page.waitForTimeout(100);
                }

                // 5. Spire Gate milestone
                console.log("Capturing 5: Spire Gate...");
                await captureCanvas(page, 'shot_5_spire_gate.png');

                // Move character into Endgame / Clockwork Spire
                console.log("Moving character into Clockwork Spire...");
                const moves5 = ['KeyW', 'KeyW', 'KeyW', 'Space', 'KeyD'];
                for (const key of moves5) {
                    await page.keyboard.down(key);
                    await page.waitForTimeout(400);
                    await page.keyboard.up(key);
                    await page.waitForTimeout(100);
                }

                // 6. Endgame milestone
                console.log("Capturing 6: Endgame...");
                await captureCanvas(page, 'shot_6_endgame.png');

                console.log("All 6 screenshots captured successfully.");
                await browser.close();
                server.close();
                resolve();
            } catch (err) {
                console.error("Error during playtest execution:", err);
                server.close();
                reject(err);
            }
        });
    });
}

if (require.main === module) {
    runEndgamePlaytest().then(() => process.exit(0)).catch((err) => {
        console.error(err);
        process.exit(1);
    });
}
