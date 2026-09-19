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
        console.log(`Saved canvas screenshot to ${filename}`);
    } else {
        await page.screenshot({ path: filename });
        console.log(`Saved page screenshot to ${filename}`);
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

                console.log("Navigating to game canvas...");
                await page.goto(`http://localhost:${PORT}`);
                await page.waitForSelector('#canvas', { timeout: 30000 });
                await page.waitForTimeout(4000);

                // Focus canvas for input
                const canvas = page.locator('#canvas');
                await canvas.click({ position: { x: 100, y: 100 } }).catch(() => {});

                // Shot 1: Beginning / Start
                console.log("Capturing Shot 1: Beginning Spawn...");
                await captureCanvas(page, 'shot_1_start.png');

                // Move character & attempt initial quest interactions
                console.log("Moving character & attempting initial quests...");
                const movesPhase1 = ['KeyD', 'KeyD', 'KeyW', 'KeyW', 'KeyE', 'Space', 'KeyD'];
                for (const key of movesPhase1) {
                    await page.keyboard.down(key);
                    await page.waitForTimeout(400);
                    await page.keyboard.up(key);
                    await page.waitForTimeout(100);
                }

                // Shot 2: Quest movement and interaction
                console.log("Capturing Shot 2: Quest Movement...");
                await captureCanvas(page, 'shot_2_quest_movement.png');

                // Perform combat and further navigation towards endgame zones
                console.log("Navigating further across zones towards endgame...");
                const movesPhase2 = ['KeyD', 'KeyD', 'KeyS', 'Space', 'ShiftLeft', 'KeyD', 'KeyD', 'KeyW', 'KeyE'];
                for (const key of movesPhase2) {
                    await page.keyboard.down(key);
                    await page.waitForTimeout(500);
                    await page.keyboard.up(key);
                    await page.waitForTimeout(100);
                }

                // Shot 3: Combat and quest progress
                console.log("Capturing Shot 3: Combat Quest...");
                await captureCanvas(page, 'shot_3_combat_quest.png');

                // Push forward into endgame zones/actions
                console.log("Attempting endgame zone push...");
                for (let i = 0; i < 8; i++) {
                    await page.keyboard.down('KeyD');
                    await page.waitForTimeout(300);
                    await page.keyboard.up('KeyD');
                    await page.keyboard.press('Space');
                    await page.waitForTimeout(150);
                }

                // Shot 4: Endgame Attempt
                console.log("Capturing Shot 4: Endgame Attempt...");
                await captureCanvas(page, 'shot_4_endgame_attempt.png');

                await browser.close();
                server.close();
                resolve();
            } catch (err) {
                console.error("Playtest error:", err);
                server.close();
                reject(err);
            }
        });
    });
}

runEndgamePlaytest().then(() => process.exit(0)).catch(() => process.exit(1));
