const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');
const mime = require('mime');

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
        console.log(`Fallback screenshot saved to ${filename}`);
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

                page.on('console', msg => {
                    if (msg.type() === 'error') {
                        console.error('PAGE ERROR:', msg.text());
                    }
                });

                console.log("Navigating to test harness...");
                await page.goto(`http://localhost:${PORT}`);
                await page.waitForSelector('#canvas', { timeout: 30000 });
                await page.waitForTimeout(3000);

                // Shot 1: Start
                console.log("Capturing Shot 1: Start...");
                await captureCanvas(page, 'shot_1_start.png');

                // Move character around Hearth Village
                console.log("Moving around Hearth Village...");
                await page.keyboard.down('KeyD');
                await page.waitForTimeout(1000);
                await page.keyboard.up('KeyD');
                await page.keyboard.down('KeyW');
                await page.waitForTimeout(1000);
                await page.keyboard.up('KeyW');

                // Shot 2: Hearth Village
                console.log("Capturing Shot 2: Hearth Village...");
                await captureCanvas(page, 'shot_2_hearth_village.png');

                // Quest interactions
                console.log("Executing quest interactions...");
                await page.keyboard.press('Space');
                await page.waitForTimeout(200);
                await page.keyboard.press('KeyE');
                await page.waitForTimeout(200);

                // Shot 3: Quest Triggers
                console.log("Capturing Shot 3: Quest Triggers...");
                await captureCanvas(page, 'shot_3_quest_triggers.png');

                // Move towards overworld zone transitions
                console.log("Moving towards overworld zone transitions...");
                await page.keyboard.down('KeyS');
                await page.waitForTimeout(1500);
                await page.keyboard.up('KeyS');
                await page.keyboard.down('KeyD');
                await page.waitForTimeout(1500);
                await page.keyboard.up('KeyD');

                // Shot 4: Overworld Zones
                console.log("Capturing Shot 4: Overworld Zones...");
                await captureCanvas(page, 'shot_4_overworld_zones.png');

                // Navigate towards endgame area
                console.log("Navigating towards endgame Clockwork Spire...");
                await page.keyboard.down('KeyW');
                await page.waitForTimeout(2000);
                await page.keyboard.up('KeyW');
                await page.keyboard.press('Space');

                // Shot 5: Clockwork Spire
                console.log("Capturing Shot 5: Clockwork Spire...");
                await captureCanvas(page, 'shot_5_clockwork_spire.png');

                // Final endgame state checks
                await page.waitForTimeout(1000);

                // Shot 6: Endgame
                console.log("Capturing Shot 6: Endgame...");
                await captureCanvas(page, 'shot_6_endgame.png');

                await browser.close();
                server.close();
                resolve();
            } catch (err) {
                console.error("Endgame playtest error:", err);
                server.close();
                reject(err);
            }
        });
    });
}

runEndgamePlaytest().then(() => process.exit(0)).catch(() => process.exit(1));
