// Walks a seeded run using REAL simulated keyboard input against the
// web-exported canvas -- this replaces the earlier version of this
// script, which only took time-spaced screenshots and never sent a
// single keypress. That gap is the root cause of the "movement isn't
// being tested" bug: nothing was ever driving the player character.
//
// Two modes:
//
//   --mode sanity   Zero map knowledge required. Presses each of
//                    up/down/left/right (both arrow-key and WASD
//                    variants, since the actual InputMap isn't visible
//                    from here -- see TASK_QUEUE additions to confirm
//                    and trim to the real bindings) for a short hold,
//                    screenshots before/after each, and hashes the
//                    frames to confirm the canvas actually changed.
//                    This is the direct, always-runnable fix for "is
//                    keyboard input reaching the game at all."
//
//   --mode script    Replays a JSON sequence of moves from
//                    --walk-script (see resources/walk-script-format.md).
//                    Screenshots after every step and hash-diffs
//                    against the previous frame, so a human or another
//                    agent turn can look at the resulting manifest +
//                    screenshots and author the NEXT script to push
//                    further into the map. This is intentionally NOT
//                    automatic pathfinding -- see
//                    TEST_HARNESS_ARCHITECTURE.md for why that's a
//                    separate, harder problem (best solved via the
//                    Godot MCP editor-runtime tier reading real player
//                    position, not by guessing from pixels here).
//
// Usage:
//   node playwright_walk_run.js --url <url> --out <dir> --mode sanity
//   node playwright_walk_run.js --url <url> --out <dir> --mode script --walk-script <path>
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

function parseArgs() {
  const args = process.argv.slice(2);
  const out = {};
  for (let i = 0; i < args.length; i += 2) {
    out[args[i].replace(/^--/, '')] = args[i + 1];
  }
  return out;
}

function hashFile(filePath) {
  return crypto.createHash('sha256').update(fs.readFileSync(filePath)).digest('hex');
}

async function focusCanvas(page) {
  // Godot's web export needs the canvas itself focused to receive
  // keyboard events -- a page-level goto() does NOT give it focus.
  // This was the second thing the old script never did.
  const canvas = page.locator('canvas').first();
  await canvas.click({ position: { x: 5, y: 5 } }).catch(async () => {
    // Some export templates size the canvas to fill the viewport with
    // no visible click target at (5,5) -- fall back to a center click.
    await canvas.click();
  });
}

async function pressAndCapture(page, outDir, label, key, holdMs) {
  const beforePath = path.join(outDir, `${label}_before.png`);
  const afterPath = path.join(outDir, `${label}_after.png`);
  await page.screenshot({ path: beforePath });

  await page.keyboard.down(key);
  await page.waitForTimeout(holdMs);
  await page.keyboard.up(key);
  await page.waitForTimeout(200); // let the frame settle before capture

  await page.screenshot({ path: afterPath });

  const changed = hashFile(beforePath) !== hashFile(afterPath);
  return { label, key, holdMs, changed, before: beforePath, after: afterPath };
}

async function runSanityCheck(page, outDir) {
  // Both schemes, since the real InputMap isn't visible from here.
  // A key that does nothing is a no-op keypress, not an error -- the
  // manifest below is what tells you which scheme (if either) is wired.
  const directions = [
    { name: 'up', keys: ['ArrowUp', 'KeyW'] },
    { name: 'down', keys: ['ArrowDown', 'KeyS'] },
    { name: 'left', keys: ['ArrowLeft', 'KeyA'] },
    { name: 'right', keys: ['ArrowRight', 'KeyD'] },
  ];

  const results = [];
  for (const dir of directions) {
    for (const key of dir.keys) {
      const result = await pressAndCapture(page, outDir, `sanity_${dir.name}_${key}`, key, 600);
      results.push(result);
      console.log(`[sanity] ${dir.name} (${key}): ${result.changed ? 'FRAME CHANGED' : 'no visible change'}`);
    }
  }
  return results;
}

async function runWalkScript(page, outDir, scriptPath) {
  const script = JSON.parse(fs.readFileSync(scriptPath, 'utf8'));
  const results = [];
  for (let i = 0; i < script.moves.length; i++) {
    const move = script.moves[i];
    const label = `step_${String(i).padStart(3, '0')}_${move.key}`;
    const result = await pressAndCapture(page, outDir, label, move.key, move.hold_ms || 500);
    result.step_label = move.label || '';
    results.push(result);
    console.log(`[script] step ${i} (${move.key}, "${move.label || ''}"): ${result.changed ? 'FRAME CHANGED' : 'no visible change'}`);
  }
  return results;
}

(async () => {
  const { url, out, mode, 'walk-script': walkScriptPath } = parseArgs();
  if (!url || !out || !mode) {
    console.error('Usage: node playwright_walk_run.js --url <url> --out <dir> --mode sanity|script [--walk-script <path>]');
    process.exit(1);
  }
  if (mode === 'script' && !walkScriptPath) {
    console.error('--mode script requires --walk-script <path>');
    process.exit(1);
  }
  fs.mkdirSync(out, { recursive: true });

  const consoleErrors = [];
  const browser = await chromium.launch({
    headless: true,
    args: ['--use-gl=angle', '--enable-webgl', '--disable-gpu-sandbox', '--no-sandbox']
  });
  const context = await browser.newContext();
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

  page.on('console', (msg) => {
    if (msg.type() === 'error') consoleErrors.push(msg.text());
  });

  console.log(`[playwright_walk_run] Loading ${url}`);
  await page.goto(url, { waitUntil: 'networkidle' });
  await page.waitForTimeout(4000); // let the Godot web export boot

  console.log('[playwright_walk_run] Focusing canvas for keyboard input...');
  await focusCanvas(page);
  await page.screenshot({ path: path.join(out, 'checkpoint_00_start.png') });

  let results;
  if (mode === 'sanity') {
    results = await runSanityCheck(page, out);
  } else {
    results = await runWalkScript(page, out, walkScriptPath);
  }

  const anyMovement = results.some((r) => r.changed);
  const manifest = {
    mode,
    timestamp: new Date().toISOString(),
    any_frame_changed: anyMovement,
    steps: results,
  };
  fs.writeFileSync(path.join(out, 'manifest.json'), JSON.stringify(manifest, null, 2));

  fs.writeFileSync(
    path.join(out, 'console_errors.log'),
    consoleErrors.length ? consoleErrors.join('\n') : 'No console errors captured.\n'
  );

  await browser.close();

  if (!anyMovement) {
    console.error('[playwright_walk_run] WARNING: no keypress produced a visible frame change.');
    console.error('[playwright_walk_run] Either the canvas did not have focus, or neither the');
    console.error('[playwright_walk_run] arrow-key nor WASD scheme matches the real InputMap.');
    console.error("[playwright_walk_run] Check project.godot's [input] section against the");
    console.error('[playwright_walk_run] keys tried in manifest.json.');
  }
  console.log(`[playwright_walk_run] Done. ${results.length} steps, movement detected: ${anyMovement}. ${consoleErrors.length} console errors.`);
})().catch((err) => {
  console.error('[playwright_walk_run] FAILED:', err);
  process.exit(1);
});
