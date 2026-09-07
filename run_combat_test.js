const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');
const mime = require('mime');

const PORT = 8082;
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
    console.log(`Saved screenshot to ${filename}`);
}

async function runCombatTest() {
    server.listen(PORT, () => console.log(`Test server running on port ${PORT}`));

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

    await page.goto(`http://localhost:${PORT}`);
    await page.waitForSelector('#canvas', { timeout: 30000 });
    await page.waitForTimeout(4000);

    // 1. Initial Spawn Screenshot
    await captureCanvas(page, 'shot_1_spawn.png');

    // 2. Move Forward/Right towards enemy areas
    console.log("Moving character right and forward...");
    for (let i = 0; i < 8; i++) {
        await page.keyboard.press('KeyD');
        await page.waitForTimeout(200);
        await page.keyboard.press('KeyW');
        await page.waitForTimeout(200);
    }
    await captureCanvas(page, 'shot_2_moved.png');

    // 3. Attack (Sword Swing / Charge)
    console.log("Executing sword attack...");
    await page.keyboard.press('Space');
    await page.waitForTimeout(150);
    await captureCanvas(page, 'shot_3_attack.png');

    // 4. Move down/left into combat area and engage
    console.log("Moving towards enemy patrol zone...");
    for (let i = 0; i < 12; i++) {
        await page.keyboard.press('KeyS');
        await page.waitForTimeout(200);
        await page.keyboard.press('KeyD');
        await page.waitForTimeout(200);
    }
    await page.keyboard.press('Space');
    await page.waitForTimeout(200);
    await captureCanvas(page, 'shot_4_combat_zone.png');

    // 5. Touch Controls Test (Joystick, SWORD, DASH, INTERACT)
    console.log("Testing touch controls...");
    // Touch Joystick (center ~ x: 192, y: 561) drag right/up
    await page.touchscreen.tap(192, 561);
    await page.waitForTimeout(200);

    // Touch SWORD button (~ x: 1126, y: 547)
    console.log("Tapping Touch SWORD button...");
    await page.touchscreen.tap(1126, 547);
    await page.waitForTimeout(200);

    // Touch DASH button (~ x: 972, y: 604)
    console.log("Tapping Touch DASH button...");
    await page.touchscreen.tap(972, 604);
    await page.waitForTimeout(200);

    // Touch INTERACT button (~ x: 1126, y: 417)
    console.log("Tapping Touch INTERACT button...");
    await page.touchscreen.tap(1126, 417);
    await page.waitForTimeout(200);

    await captureCanvas(page, 'shot_5_touch_test.png');

    await browser.close();
    server.close();
    console.log("Combat and Touch Controls test complete.");
}

runCombatTest();
