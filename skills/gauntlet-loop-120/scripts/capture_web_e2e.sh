#!/usr/bin/env bash
# Usage: capture_web_e2e.sh <target_id> [mode] [walk_script_path]
#   mode: "sanity" (default, zero map knowledge, confirms keyboard input
#         actually reaches the game) or "script" (replays a JSON move
#         sequence -- requires walk_script_path)
#
# Exports the web build, serves it, and drives it with REAL simulated
# keyboard input via playwright_walk_run.js. Previous versions of this
# script only took time-spaced screenshots with no input -- see
# TEST_HARNESS_ARCHITECTURE.md for why that was the root cause of the
# "movement isn't tested" bug and how this fixes it.
set -euo pipefail

TARGET="${1:?Usage: capture_web_e2e.sh <target_id> [sanity|script] [walk_script_path]}"
MODE="${2:-sanity}"
WALK_SCRIPT="${3:-}"

if [[ "$MODE" == "script" && -z "$WALK_SCRIPT" ]]; then
  echo "[capture_web_e2e] mode=script requires a walk_script_path argument." >&2
  echo "[capture_web_e2e] See resources/walk-script-format.md." >&2
  exit 1
fi

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${SKILL_ROOT}/assets/config.yaml"
get_cfg () { yq -r ".$1" "$CONFIG"; }

GODOT_BIN="$(get_cfg godot_binary)"
PROJECT_PATH="$(get_cfg project_path)"
EXPORT_PRESET="$(get_cfg web_export_preset)"
WEB_BUILD_DIR="$(get_cfg web_build_dir)"
SERVE_PORT="$(get_cfg serve_port)"
CAPTURE_DIR="$(get_cfg capture_dir)/${TARGET}"
mkdir -p "$CAPTURE_DIR"
mkdir -p "$WEB_BUILD_DIR"

echo "[capture_web_e2e] Exporting web build..."
if command -v "$GODOT_BIN" >/dev/null 2>&1; then
  "$GODOT_BIN" --path "$PROJECT_PATH" --headless --export-release "$EXPORT_PRESET" "../${WEB_BUILD_DIR}/index.html"
else
  echo "[capture_web_e2e] $GODOT_BIN not found in path, checking if build exists..."
fi

echo "[capture_web_e2e] Serving on port ${SERVE_PORT}..."
( cd "$WEB_BUILD_DIR" && python3 -m http.server "$SERVE_PORT" >/tmp/120_serve.log 2>&1 & echo $! > /tmp/120_serve.pid )
sleep 2
trap 'kill "$(cat /tmp/120_serve.pid)" 2>/dev/null || true' EXIT

echo "[capture_web_e2e] Driving with mode=${MODE} for target ${TARGET}..."
echo "target: ${TARGET}" > "${CAPTURE_DIR}/run_metadata.yaml"
echo "mode: ${MODE}" >> "${CAPTURE_DIR}/run_metadata.yaml"
echo "timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "${CAPTURE_DIR}/run_metadata.yaml"

if [[ "$MODE" == "sanity" ]]; then
  node "${SKILL_ROOT}/scripts/playwright_walk_run.js" \
    --url "http://localhost:${SERVE_PORT}/index.html" \
    --out "$CAPTURE_DIR" \
    --mode sanity
else
  node "${SKILL_ROOT}/scripts/playwright_walk_run.js" \
    --url "http://localhost:${SERVE_PORT}/index.html" \
    --out "$CAPTURE_DIR" \
    --mode script \
    --walk-script "$WALK_SCRIPT"
fi

echo "[capture_web_e2e] Done. Artifacts + manifest.json in ${CAPTURE_DIR}"
cat "${CAPTURE_DIR}/manifest.json" | python3 -c "
import json, sys
m = json.load(sys.stdin)
print(f\"black_screen_detected: {m.get('black_screen_detected', False)}\")
print(f\"any_frame_changed: {m['any_frame_changed']}\")
for s in m['steps']:
    print(f\"  {s['label']:<30} key={s['key']:<12} changed={s['changed']}\")
if m.get('black_screen_detected', False):
    print('[capture_web_e2e] ERROR: Black/unrendered screen detected in capture!')
    sys.exit(1)
"
