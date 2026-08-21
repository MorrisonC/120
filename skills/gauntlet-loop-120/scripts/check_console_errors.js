// Loads the served web build, captures console errors and failed
// network requests (the two signals that distinguish gray-screen
// cause #1 (threading) from #3 (404/CORS)), and optionally screenshots
// for visual confirmation.
//
// Usage: node check_console_errors.js --url <url> --out <log path> [--screenshot <png path>]
const { chromium } = require('playwright');
const fs = require('fs');

function parseArgs() {
  const args = process.argv.slice(2);
  const out = {};
  for (let i = 0; i < args.length; i += 2) {
    out[args[i].replace(/^--/, '')] = args[i + 1];
  }
  return out;
}

(async () => {
  const { url, out, screenshot } = parseArgs();
  if (!url || !out) {
    console.error('Usage: node check_console_errors.js --url <url> --out <log>');
    process.exit(1);
  }

  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });

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

  const lines = [];
  page.on('console', (msg) => {
    if (msg.type() === 'error' || msg.type() === 'warning') {
      lines.push(`[console.${msg.type()}] ${msg.text()}`);
    }
  });
  page.on('requestfailed', (req) => {
    lines.push(`[requestfailed] ${req.url()} — ${req.failure()?.errorText}`);
  });
  page.on('response', (res) => {
    if (res.status() >= 400) {
      lines.push(`[http ${res.status()}] ${res.url()}`);
    }
  });

  await page.goto(url, { waitUntil: 'networkidle', timeout: 30000 }).catch((e) => {
    lines.push(`[navigation error] ${e.message}`);
  });

  // Give the Godot web export a beat to either boot or fail.
  await page.waitForTimeout(5000);

  const crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated).catch(() => 'unknown');
  lines.push(`[page context] window.crossOriginIsolated = ${crossOriginIsolated}`);

  if (out !== '/dev/null') {
    fs.writeFileSync(out, lines.length ? lines.join('\n') : 'No console errors or failed requests captured.\n');
  } else {
    console.log(lines.join('\n'));
  }

  if (screenshot) {
    await page.screenshot({ path: screenshot });
    console.log(`Screenshot written to ${screenshot}`);
  }

  await browser.close();
})().catch((err) => {
  console.error('[check_console_errors] FAILED:', err);
  process.exit(1);
});
