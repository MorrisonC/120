#!/usr/bin/env bash
# Runs the checks from resources/gray-screen-checklist.md, in order,
# against the currently-served web build. Exports fresh first.
set -euo pipefail

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${SKILL_ROOT}/assets/config.yaml"
get_cfg () { yq -r ".$1" "$CONFIG"; }

GODOT_BIN="$(get_cfg godot_binary)"
PROJECT_PATH="$(get_cfg project_path)"
EXPORT_PRESET="$(get_cfg web_export_preset)"
WEB_BUILD_DIR_REL="$(get_cfg web_build_dir)"
WEB_BUILD_DIR="$(pwd)/${WEB_BUILD_DIR_REL}"
SERVE_PORT="$(get_cfg serve_port)"
mkdir -p ./logs
mkdir -p "$WEB_BUILD_DIR"

echo "=== Check 0: Main Scene setting (cause #2) ==="
GODOT_PROJ="${PROJECT_PATH}/project.godot"
if [[ -f "$GODOT_PROJ" ]]; then
  MAIN_SCENE="$(grep -E '^run/main_scene' "$GODOT_PROJ" || echo 'NOT SET')"
  echo "run/main_scene = $MAIN_SCENE"
  if [[ "$MAIN_SCENE" == "NOT SET" ]]; then
    echo "FAIL: no main scene set. See gray-screen-checklist.md #2."
  fi
else
  echo "WARNING: $GODOT_PROJ not found."
fi

echo ""
echo "=== Exporting web build ==="
"$GODOT_BIN" --path "$PROJECT_PATH" --headless --export-release "$EXPORT_PRESET" "${WEB_BUILD_DIR}/index.html" \
  2>&1 | tee ./logs/gray_screen_export.log

echo ""
echo "=== Serving on port ${SERVE_PORT} ==="
( node "${SKILL_ROOT}/scripts/serve_with_headers.js" "$SERVE_PORT" "$WEB_BUILD_DIR" >/tmp/120_serve.log 2>&1 & echo $! > /tmp/120_serve.pid )
sleep 2
trap 'kill "$(cat /tmp/120_serve.pid)" 2>/dev/null || true' EXIT

echo ""
echo "=== Check 1: COOP/COEP headers (cause #1, most common) ==="
HEADERS="$(curl -sI "http://localhost:${SERVE_PORT}/index.html")"
echo "$HEADERS"
if echo "$HEADERS" | grep -qi "Cross-Origin-Opener-Policy: same-origin" && \
   echo "$HEADERS" | grep -qi "Cross-Origin-Embedder-Policy: require-corp"; then
  echo "PASS: both COOP and COEP headers present."
else
  echo "FAIL: one or both of COOP/COEP headers missing."
  echo "  -> See gray-screen-checklist.md #1 for the two fix options"
  echo "     (add headers to the server, OR disable Thread Support)."
fi

echo ""
echo "=== Check 2: asset 404s / console errors (causes #3, #1-symptom) ==="
node "${SKILL_ROOT}/scripts/check_console_errors.js" \
  --url "http://localhost:${SERVE_PORT}/index.html" \
  --out "${SKILL_ROOT}/state/gray_screen_console.log"
cat "${SKILL_ROOT}/state/gray_screen_console.log"

echo ""
echo "=== Done. Screenshot for visual confirmation: ==="
node "${SKILL_ROOT}/scripts/check_console_errors.js" \
  --url "http://localhost:${SERVE_PORT}/index.html" \
  --screenshot "${SKILL_ROOT}/state/gray_screen_capture.png" \
  --out /dev/null
echo "See ${SKILL_ROOT}/state/gray_screen_capture.png"
