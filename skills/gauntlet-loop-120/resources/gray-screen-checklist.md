# Gray/Black/White Screen Checklist — Godot 4 Web Export

Grounded in Godot 4's actual web export architecture, not generic
guesswork. Check in this order — the first cause is by far the most
common for Godot 4 specifically.

## 1. Missing COOP/COEP headers (most common cause)

Godot 4's **threaded** web export uses `SharedArrayBuffer` for
multi-threaded WebAssembly. Browsers only expose `SharedArrayBuffer` when
the page is served "cross-origin isolated," which requires the server to
send BOTH response headers on the HTML page:
```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```
Godot does not set these — whatever serves the files must. Symptoms:
white or gray screen, console error mentioning `SharedArrayBuffer is not
defined` or `crossOriginIsolated` is false.

**Check:** `curl -I` the served `index.html` and look for both headers.
`scripts/diagnose_gray_screen.sh` does this automatically.

**Two fixes, pick one** (this is exactly `TASK_QUEUE.md`'s `GRAY-2`
decision point):
- **(a) Add the headers** to whatever serves the build (check
  `serve_and_test.js` at the repo root first — it may need only a small
  addition, not new infrastructure). Required if you want multi-threaded
  performance.
- **(b) Disable Thread Support** in the Web export preset. Produces a
  single-threaded build with no `SharedArrayBuffer` requirement — simpler,
  but loses multi-threaded performance. Reasonable fallback for a project
  this size, especially if hosting (e.g. itch.io) already handles headers
  for you and only your CI/local testing setup doesn't.

Opening `index.html` directly from disk (`file://`) will **never** work
either way — there's no server to send headers, and some browser APIs
the export needs are unavailable over `file://` regardless.

## 2. Main Scene not set / stale path

Project Settings → Application → Run → Main Scene must point at a real,
current scene. A stale path from an earlier milestone (e.g. pointing at
a since-renamed/moved test scene) produces a blank/gray screen with no
obvious console error. Check `project.godot`'s `run/main_scene` value
directly — `TASK_QUEUE.md`'s `GRAY-5`.

## 3. 404 / CORS on `.pck`, `.wasm`, or `.js`

Open the browser console (F12) and check the Network tab for failed
requests. A missing or wrongly-pathed `.pck` file (the packed game data)
is a common cause of a black screen specifically (vs. white for the
threading issue) — the engine loads and starts but has nothing to render.
Also check that all four exported files (`index.html`, `.wasm`, `.pck`,
`.js`) were actually uploaded/served together, not just the HTML.

## 4. Files inside `addons/` don't get exported

Godot's export process excludes certain paths by convention/config —
double-check nothing your **actual game** (not test-only tooling like
GUT) depends on lives somewhere that gets excluded from the export
filter in `export_presets.cfg`.

## 5. Browser/engine version mismatch (less likely on 4.3 stable)

Older Godot 4 betas had web-export-specific gray-screen bugs later fixed
in subsequent releases — much less likely to be the cause on 4.3 stable
(per `Progress.md` Milestone 1), but if the above four checks all come
back clean, confirm the export templates installed match the exact
editor version building the project.

## Diagnostic order for this project specifically
Given `Progress.md` confirms Godot 4.3 stable (past the beta-era bugs)
and Web export was configured fresh in Milestone 5, cause #1 (headers)
or #2 (main scene / stale config from milestone-to-milestone changes) are
the most likely candidates. Run `scripts/diagnose_gray_screen.sh` — it
checks both first, then falls through to #3 and #4.
