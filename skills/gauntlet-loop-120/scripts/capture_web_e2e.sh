#!/usr/bin/env bash
# Usage: capture_web_e2e.sh <target_id> [seed]
#
# Walks a deterministic seeded run in the served web build and captures
# screenshots at each biome/checkpoint transition. Extends this repo's
# EXISTING serve_and_test.js / test_harness.js / tests/playwright/
# rather than standing up a parallel harness -- check those files
# first; this script assumes test_harness.js exposes (or can be
# extended to expose) a way to drive the game via a fixed seed for
# reproducible captures.
set -euo pipefail

TARGET="${1:?Usage: capture_web_e2e.sh <target_id> [seed]}"
SEED="${2:-120}"   # arbitrary fixed default -- log whatever seed is
                    # actually used so a critic/reviewer can reproduce it

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${SKILL_ROOT}/assets/config.yaml"
get_cfg () { yq -r ".$1" "$CONFIG"; }

GODOT_BIN="$(get_cfg godot_binary)"
PROJECT_PATH="$(get_cfg project_path)"
EXPORT_PRESET="$(get_cfg web_export_preset)"
WEB_BUILD_DIR_REL="$(get_cfg web_build_dir)"
WEB_BUILD_DIR="$(pwd)/${WEB_BUILD_DIR_REL}"
SERVE_PORT="$(get_cfg serve_port)"
CAPTURE_DIR="$(pwd)/$(get_cfg capture_dir)/${TARGET}"
mkdir -p "$CAPTURE_DIR"
mkdir -p "$WEB_BUILD_DIR"

echo "[capture_web_e2e] Exporting web build..."
"$GODOT_BIN" --path "$PROJECT_PATH" --headless --export-release "$EXPORT_PRESET" "${WEB_BUILD_DIR}/index.html"

echo "[capture_web_e2e] Serving on port ${SERVE_PORT}..."
( node "${SKILL_ROOT}/scripts/serve_with_headers.js" "$SERVE_PORT" "$WEB_BUILD_DIR" >/tmp/120_serve.log 2>&1 & echo $! > /tmp/120_serve.pid )
sleep 2
trap 'kill "$(cat /tmp/120_serve.pid)" 2>/dev/null || true' EXIT

echo "[capture_web_e2e] Walking seed ${SEED} for target ${TARGET}..."
echo "seed: ${SEED}" > "${CAPTURE_DIR}/run_metadata.yaml"
echo "target: ${TARGET}" >> "${CAPTURE_DIR}/run_metadata.yaml"
echo "timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "${CAPTURE_DIR}/run_metadata.yaml"

# NOTE: this calls a project-specific Playwright script this skill does
# NOT define, because the actual in-page hooks needed to drive a
# deterministic seeded run (setting the RNG seed, advancing through
# checkpoints, waiting for specific game-state signals) depend on
# test_harness.js's real API, which should be extended rather than
# guessed at here. See README.md's "Honest caveat" section.
node "${SKILL_ROOT}/scripts/playwright_walk_run.js" \
  --url "http://localhost:${SERVE_PORT}/index.html" \
  --seed "$SEED" \
  --out "$CAPTURE_DIR"

echo "[capture_web_e2e] Done. Artifacts in ${CAPTURE_DIR}"
ls "$CAPTURE_DIR"
