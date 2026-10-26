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
        fs.writeFileSync(filename, Buffer.from(dataUrl.split(',')[1], 'base64'));
    } else {
        await page.screenshot({ path: filename });
    }
    console.log(`Saved screenshot: ${filename}`);
}

async function runEndgamePlaytest() {
    server.listen(PORT, () => console.log(`Playtest server listening on port ${PORT}`));

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
            console.error(`[Console Error]: ${msg.text()}`);
        } else {
            console.log(`[Console]: ${msg.text()}`);
        }
    });

    console.log("Navigating to WebGL game...");
    await page.goto(`http://localhost:${PORT}`);
    await page.waitForSelector('#canvas', { timeout: 30000 });
    await page.waitForTimeout(4000);

    // Shot 1: Start / Spawn
    await captureCanvas(page, 'shot_1_start.png');

    // Shot 2: Moving around Hearth Village & Notice Board / Quests
    console.log("Moving around village and interacting with quests...");
    for (let i = 0; i < 6; i++) {
        await page.keyboard.press('KeyD');
        await page.waitForTimeout(150);
        await page.keyboard.press('KeyS');
        await page.waitForTimeout(150);
    }
    await page.keyboard.press('KeyE'); // Interact
    await page.waitForTimeout(300);
    await captureCanvas(page, 'shot_2_village_quests.png');

    // Shot 3: Combat / Swing sword / Movement into zone 1
    console.log("Performing combat actions and moving to zone 1...");
    for (let i = 0; i < 8; i++) {
        await page.keyboard.press('KeyD');
        await page.waitForTimeout(150);
        await page.keyboard.press('KeyW');
        await page.waitForTimeout(150);
        if (i % 2 === 0) {
            await page.keyboard.press('Space'); // Attack
            await page.waitForTimeout(150);
        }
    }
    await captureCanvas(page, 'shot_3_combat_zone1.png');

    // Shot 4: Map view / Overlay
    console.log("Opening map overlay...");
    await page.keyboard.press('KeyM');
    await page.waitForTimeout(300);
    await captureCanvas(page, 'shot_4_map_overlay.png');
    await page.keyboard.press('KeyM'); // Close map
    await page.waitForTimeout(200);

    // Shot 5: Progressing through further zones towards endgame
    console.log("Progressing through zones towards endgame...");
    for (let i = 0; i < 12; i++) {
        await page.keyboard.press('KeyD');
        await page.waitForTimeout(150);
        await page.keyboard.press('KeyS');
        await page.waitForTimeout(150);
        await page.keyboard.press('Space');
        await page.waitForTimeout(100);
    }
    await captureCanvas(page, 'shot_5_endgame_progress.png');

    await browser.close();
    server.close();
    console.log("Endgame playtest complete!");
}

runEndgamePlaytest().catch(err => {
    console.error("Error in endgame playtest:", err);
    server.close();
    process.exit(1);
});
