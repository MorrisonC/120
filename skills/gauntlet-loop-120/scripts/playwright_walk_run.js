// Walks a deterministic seeded run and captures a screenshot at each
// biome/checkpoint transition. The generic scaffolding (page load,
// screenshot, console/error capture) is filled in; the actual
// "set the RNG seed" and "detect a checkpoint transition" hooks are
// marked TODO because they depend on this project's real
// test_harness.js API, which this skill doesn't have visibility into
// -- wire these to whatever hooks that harness already exposes (it
// was built in Milestone 5's CI setup) rather than guessing at a new
// interface.
//
// Usage: node playwright_walk_run.js --url <url> --seed <seed> --out <dir>
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

function parseArgs() {
  const args = process.argv.slice(2);
  const out = {};
  for (let i = 0; i < args.length; i += 2) {
    out[args[i].replace(/^--/, '')] = args[i + 1];
  }
  return out;
}

(async () => {
  const { url, seed, out } = parseArgs();
  if (!url || !seed || !out) {
    console.error('Usage: node playwright_walk_run.js --url <url> --seed <seed> --out <dir>');
    process.exit(1);
  }
  fs.mkdirSync(out, { recursive: true });

  const consoleErrors = [];
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });

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

  page.on('console', (msg) => {
    if (msg.type() === 'error') consoleErrors.push(msg.text());
  });

  console.log(`[playwright_walk_run] Loading ${url}`);
  await page.goto(url, { waitUntil: 'networkidle' });
  await page.waitForTimeout(4000); // let the Godot web export boot

  // TODO (project-specific): set the procedural generator's seed before
  // the run starts. If test_harness.js already exposes a URL param or a
  // window-level hook for this (check its existing implementation
  // first), call it here instead of this placeholder. Example shape,
  // adjust to the real API:
  //   await page.evaluate((s) => { window.setRunSeed?.(s); }, seed);
  console.log(`[playwright_walk_run] TODO: wire actual seed-setting hook for seed=${seed}`);

  await page.screenshot({ path: path.join(out, 'checkpoint_00_start.png') });

  // TODO (project-specific): detect checkpoint transitions to capture
  // each biome as the run progresses, rather than just one start-of-run
  // frame. If GameState.gd (Milestone 2) emits a signal on checkpoint
  // change, the cleanest approach is exposing that signal to JS (e.g.
  // via a window-level callback set up in an autoload) and awaiting it
  // here in a loop. Placeholder below just takes a few time-spaced
  // frames so the script produces SOMETHING useful before that wiring
  // exists.
  for (let i = 1; i <= 3; i++) {
    await page.waitForTimeout(15000);
    await page.screenshot({ path: path.join(out, `checkpoint_${String(i).padStart(2, '0')}_timed.png`) });
  }

  fs.writeFileSync(
    path.join(out, 'console_errors.log'),
    consoleErrors.length ? consoleErrors.join('\n') : 'No console errors captured.\n'
  );

  await browser.close();
  console.log(`[playwright_walk_run] Done. ${consoleErrors.length} console errors captured.`);
})().catch((err) => {
  console.error('[playwright_walk_run] FAILED:', err);
  process.exit(1);
});
