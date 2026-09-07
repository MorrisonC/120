const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');
const mime = require('mime');
const zlib = require('zlib');

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

function evaluateCanvas(buf) {
    let idx = 8, width = 0, height = 0, colorType = 0;
    const chunks = [];
    while (idx < buf.length) {
        const len = buf.readUInt32BE(idx);
        const type = buf.toString('ascii', idx + 4, idx + 8);
        if (type === 'IHDR') {
            width = buf.readUInt32BE(idx + 8);
            height = buf.readUInt32BE(idx + 12);
            colorType = buf.readUInt8(idx + 17);
        } else if (type === 'IDAT') chunks.push(buf.subarray(idx + 8, idx + 8 + len));
        idx += 12 + len;
    }
    const decomp = zlib.inflateSync(Buffer.concat(chunks));
    const bpp = colorType === 2 ? 3 : 4;
    const stride = width * bpp + 1;
    let sum = 0, nonZero = 0;
    const total = width * height;
    for (let y = 0; y < height; y++) {
        const row = y * stride + 1;
        for (let x = 0; x < width; x++) {
            const off = row + x * bpp;
            const val = decomp[off] + decomp[off + 1] + decomp[off + 2];
            sum += val;
            if (val > 10) nonZero++;
        }
    }
    const avg = sum / (total * 3);
    const ratio = nonZero / total;
    return { avg, ratio, nonZero, isBlack: nonZero < 500 || avg < 0.1 };
}

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
        return evaluateCanvas(buf);
    } else {
        await page.screenshot({ path: filename });
        const buf = fs.readFileSync(filename);
        return evaluateCanvas(buf);
    }
}

async function runPlaytestGauntlet() {
    return new Promise((resolve, reject) => {
        server.listen(PORT, async () => {
            console.log(`Playtest server running on http://localhost:${PORT}`);
            const metrics = {
                timestamp: new Date().toISOString(),
                console_errors: [],
                keyboard_inputs_sent: 0,
                touch_inputs_sent: 0,
                touch_taps_attempted: 0,
                frame_evaluations: [],
                session_duration_ms: 0,
                overall_status: "PASSED"
            };

            const startTime = Date.now();

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
                        const txt = msg.text();
                        if (!txt.includes('favicon.ico')) {
                            metrics.console_errors.push(txt);
                        }
                    }
                });

                page.on('pageerror', err => {
                    metrics.console_errors.push(err.message);
                });

                console.log("Navigating to test harness...");
                await page.goto(`http://localhost:${PORT}`);
                await page.waitForSelector('#canvas', { timeout: 30000 });
                await page.waitForTimeout(4000);

                // Frame 1: Initial Render
                const frame1 = await captureCanvas(page, 'shot_playtest_frame1.png');
                metrics.frame_evaluations.push({ frame: 'initial_spawn', ...frame1 });

                // 1. Keyboard Navigation & Movement Loop
                console.log("Simulating player keyboard navigation & combat...");
                const keys = ['KeyD', 'KeyW', 'KeyS', 'KeyA', 'Space', 'ShiftLeft'];
                for (let i = 0; i < 10; i++) {
                    const key = keys[i % keys.length];
                    await page.keyboard.press(key);
                    metrics.keyboard_inputs_sent++;
                    await page.waitForTimeout(150);
                }

                const frame2 = await captureCanvas(page, 'shot_playtest_frame2.png');
                metrics.frame_evaluations.push({ frame: 'after_keyboard_nav', ...frame2 });

                // 2. Touch Controls Simulation
                console.log("Simulating player touch controls...");
                // Touch Joystick drag
                await page.touchscreen.tap(192, 561);
                metrics.touch_inputs_sent++;
                await page.waitForTimeout(100);

                // Touch Action Buttons (SWORD, DASH, INTERACT)
                const touchTargets = [
                    { name: 'SWORD', x: 1126, y: 547 },
                    { name: 'DASH', x: 972, y: 604 },
                    { name: 'INTERACT', x: 1126, y: 417 }
                ];

                for (const target of touchTargets) {
                    metrics.touch_taps_attempted++;
                    await page.touchscreen.tap(target.x, target.y);
                    metrics.touch_inputs_sent++;
                    await page.waitForTimeout(150);
                }

                const frame3 = await captureCanvas(page, 'shot_playtest_frame3.png');
                metrics.frame_evaluations.push({ frame: 'after_touch_inputs', ...frame3 });

                metrics.session_duration_ms = Date.now() - startTime;
                if (metrics.console_errors.length > 0 || frame3.isBlack) {
                    metrics.overall_status = "FAILED";
                }

                fs.writeFileSync('playtest_metrics.json', JSON.stringify(metrics, null, 2));

                const reportContent = `
## Gauntlet Automated Playtest Run (${metrics.timestamp})

- **Session Duration:** ${metrics.session_duration_ms} ms
- **Overall Status:** ${metrics.overall_status}
- **Console Errors:** ${metrics.console_errors.length}
- **Keyboard Inputs Sent:** ${metrics.keyboard_inputs_sent}
- **Touch Inputs Sent:** ${metrics.touch_inputs_sent}
- **Touch Taps Attempted:** ${metrics.touch_taps_attempted}
- **Frame Render Non-Zero Pixel Ratios:**
  - Initial Spawn: ${(frame1.ratio * 100).toFixed(2)}%
  - After Keyboard Nav: ${(frame2.ratio * 100).toFixed(2)}%
  - After Touch Inputs: ${(frame3.ratio * 100).toFixed(2)}%

### Diagnostics & Findings:
${metrics.console_errors.length === 0 ? '- [x] Zero console errors during play session' : `- [ ] Console errors detected: ${metrics.console_errors.join(', ')}`}
${!frame3.isBlack ? '- [x] Canvas rendered non-black WebGL scene cleanly' : '- [ ] WebGL canvas rendered black frame'}
`;
                fs.writeFileSync('GAUNTLET_REPORT.md', reportContent);
                console.log("Playtest metrics and GAUNTLET_REPORT.md saved.");

                await browser.close();
                server.close();
                resolve(metrics);
            } catch (err) {
                console.error("Playtest harness exception:", err);
                server.close();
                reject(err);
            }
        });
    });
}

if (require.main === module) {
    runPlaytestGauntlet().then(() => process.exit(0)).catch(() => process.exit(1));
}

module.exports = { runPlaytestGauntlet };
