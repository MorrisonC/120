const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');
const mime = require('mime');

const PORT = 8085;
const BUILD_DIR = path.join(__dirname, 'web_build');

const server = http.createServer((req, res) => {
    res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
    res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');

    let filePath = path.join(BUILD_DIR, req.url === '/' ? 'index.html' : req.url.split('?')[0]);

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

async function focusCanvas(page) {
    try {
        const canvas = page.locator('#canvas').first();
        if (await canvas.count() > 0) {
            await canvas.click({ timeout: 5000 }).catch(async () => {
                await canvas.click({ position: { x: 10, y: 10 }, timeout: 5000 }).catch(() => {});
            });
        } else {
            await page.mouse.click(200, 200);
        }
    } catch (e) {
        await page.mouse.click(200, 200).catch(() => {});
    }
}

async function captureShot(page, filename) {
    await page.waitForTimeout(300);
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

    if (dataUrl && dataUrl.startsWith('data:image/png;base64,')) {
        const buf = Buffer.from(dataUrl.split(',')[1], 'base64');
        fs.writeFileSync(filename, buf);
        console.log(`Saved screenshot via canvas.toDataURL: ${filename}`);
    } else {
        await page.screenshot({ path: filename });
        console.log(`Saved screenshot via page.screenshot: ${filename}`);
    }
}

async function runEndgamePlaytest() {
    return new Promise((resolve, reject) => {
        server.listen(PORT, async () => {
            console.log(`Endgame playtest server listening on http://localhost:${PORT}`);
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
                        console.error('[Browser Error]', msg.text());
                    }
                });

                console.log("Navigating to game URL...");
                await page.goto(`http://localhost:${PORT}`);
                await page.waitForSelector('#canvas', { timeout: 30000 });
                console.log("Waiting for game engine initialization...");
                await page.waitForTimeout(5000);

                await focusCanvas(page);

                // Shot 1: Initial Start / Spawn
                console.log("Capturing Shot 1: Start / Spawn...");
                await captureShot(page, 'shot_1_start.png');

                // Step 1: Move around Hearth Village
                console.log("Moving player in Hearth Village (WASD)...");
                for (let i = 0; i < 5; i++) {
                    await page.keyboard.down('KeyD');
                    await page.waitForTimeout(300);
                    await page.keyboard.up('KeyD');
                    await page.keyboard.down('KeyS');
                    await page.waitForTimeout(300);
                    await page.keyboard.up('KeyS');
                }

                console.log("Capturing Shot 2: Hearth Village movement...");
                await captureShot(page, 'shot_2_hearth_village.png');

                // Step 2: Attempt Quest interactions & Notice board / MAP UI
                console.log("Interacting with quest / Notice Board / MAP button...");
                await page.keyboard.press('KeyM'); // Toggle Map overlay
                await page.waitForTimeout(500);

                // Touch/click MAP button or Notice Board UI if available
                await page.mouse.click(1100, 50); // upper right area / MAP button
                await page.waitForTimeout(500);

                // Sword attack / interact action
                await page.keyboard.press('Space');
                await page.waitForTimeout(300);
                await page.keyboard.press('KeyE');
                await page.waitForTimeout(300);

                console.log("Capturing Shot 3: Quest Notice / UI interaction...");
                await captureShot(page, 'shot_3_quest_notice.png');

                // Step 3: Move towards gate / obstacle
                console.log("Navigating player towards gate roadblocks...");
                for (let i = 0; i < 8; i++) {
                    await page.keyboard.down('KeyW');
                    await page.waitForTimeout(300);
                    await page.keyboard.up('KeyW');
                    await page.keyboard.down('KeyD');
                    await page.waitForTimeout(300);
                    await page.keyboard.up('KeyD');
                }

                console.log("Capturing Shot 4: Gate / Obstacle progression...");
                await captureShot(page, 'shot_4_gate_obstacle.png');

                // Step 4: Advance further towards clockwork spire / endgame zone
                console.log("Navigating player towards endgame zone...");
                for (let i = 0; i < 10; i++) {
                    await page.keyboard.down('KeyD');
                    await page.waitForTimeout(200);
                    await page.keyboard.up('KeyD');
                    await page.keyboard.press('Space'); // Attack/action
                    await page.waitForTimeout(200);
                }

                console.log("Capturing Shot 5: Endgame Spire progression...");
                await captureShot(page, 'shot_5_endgame_spire.png');

                console.log("Endgame playtest completed successfully.");
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
    runEndgamePlaytest().then(() => process.exit(0)).catch(() => process.exit(1));
}
