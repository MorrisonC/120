const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');
const mime = require('mime');

const PORT = 8081;
const BUILD_DIR = path.join(__dirname, 'build', 'web');

const server = http.createServer((req, res) => {
    // Set mandatory headers for Godot Web Exports
    res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
    res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');

    let filePath = path.join(BUILD_DIR, req.url === '/' ? 'index.html' : req.url);

    // Strip query strings
    filePath = filePath.split('?')[0];

    fs.readFile(filePath, (err, data) => {
        if (err) {
            console.error(`404 Not Found: ${req.url}`);
            res.writeHead(404);
            res.end();
            return;
        }

        const ext = path.extname(filePath);
        let contentType = mime.getType(ext) || 'application/octet-stream';

        // Godot WebAssembly needs application/wasm
        if (ext === '.wasm') contentType = 'application/wasm';

        res.setHeader('Content-Type', contentType);
        res.writeHead(200);
        res.end(data);
    });
});

async function runTest() {
    server.listen(PORT, () => {
        console.log(`Server listening on http://localhost:${PORT}`);
    });

    console.log("Launching headless Chromium...");
    const browser = await chromium.launch({
        headless: true,
        args: [
            '--use-gl=angle', // Force Angle for WebGL support in headless
            '--enable-webgl',
            '--disable-gpu-sandbox',
            '--no-sandbox'
        ]
    });

    const context = await browser.newContext();
    const page = await context.newPage();

    // Patch WebGL context creation to preserve drawing buffer for screenshots
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

    let hasErrors = false;

    page.on('pageerror', error => {
        console.error(`[Page Error]: ${error.message}`);
        hasErrors = true;
    });

    page.on('console', msg => {
        if (msg.type() === 'error') {
            const text = msg.text();
            // Ignore some known minor errors or favicon 404s
            if (!text.includes('favicon.ico')) {
                console.error(`[Console Error]: ${text}`);
                hasErrors = true;
            }
        } else {
            console.log(`[Console]: ${msg.text()}`);
        }
    });

    page.on('requestfailed', request => {
        console.error(`[Request Failed]: ${request.url()} - ${request.failure()?.errorText}`);
        hasErrors = true;
    });

    console.log(`Navigating to http://localhost:${PORT}...`);
    await page.goto(`http://localhost:${PORT}`);

    console.log("Waiting for Godot canvas to load...");
    try {
        await page.waitForSelector('#canvas', { timeout: 30000 });
        console.log("Canvas found. Waiting 5 seconds to let the main scene render...");
        await page.waitForTimeout(5000);

        // Emulate the gauntlet interaction loop
        console.log("Running automated gauntlet interaction loop...");
        for (let i = 0; i < 5; i++) {
            await page.keyboard.press('ArrowRight');
            await page.waitForTimeout(500);
            await page.keyboard.press('ArrowUp');
            await page.waitForTimeout(500);
        }

        console.log("Taking screenshot...");
        await page.screenshot({ path: 'web_screenshot.png' });
        console.log("Screenshot saved to web_screenshot.png");
    } catch (e) {
        console.error("Timeout waiting for canvas or rendering.", e);
        hasErrors = true;
    }

    await browser.close();
    server.close();

    if (hasErrors) {
        console.error("Test failed due to browser console/network errors.");
        process.exit(1);
    } else {
        console.log("SUCCESS: Automated Web E2E Test passed without errors.");
        process.exit(0);
    }
}

runTest();
