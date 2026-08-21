#!/usr/bin/env bash
# Preflight check for gauntlet-loop-120.
set -euo pipefail

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${SKILL_ROOT}/assets/config.yaml"
get_cfg () { yq -r ".$1" "$CONFIG"; }

GODOT_BIN="$(get_cfg godot_binary)"
echo "[doctor] Checking for Godot binary ('$GODOT_BIN')..."
command -v "$GODOT_BIN" >/dev/null 2>&1 || {
  echo "[doctor] '$GODOT_BIN' not found. Install Godot 4.3 (per Progress.md"
  echo "[doctor] Milestone 1) and ensure it's on PATH, or set godot_binary"
  echo "[doctor] in assets/config.yaml."
  exit 1
}
"$GODOT_BIN" --version

echo "[doctor] Checking GUT addon is present..."
if [[ ! -f "addons/gut/gut_cmdln.gd" ]]; then
  echo "[doctor] addons/gut/gut_cmdln.gd not found. Per Progress.md"
  echo "[doctor] Milestone 1 this should already be installed — check you're"
  echo "[doctor] running from the project root and the addon wasn't"
  echo "[doctor] accidentally gitignored (see the stale test_output.log"
  echo "[doctor] error in repo history for what this looks like when missing)."
  exit 1
fi

echo "[doctor] Checking node/npm/Playwright (repo already has tests/playwright/)..."
command -v node >/dev/null 2>&1 || { echo "[doctor] node not found."; exit 1; }
command -v npm  >/dev/null 2>&1 || { echo "[doctor] npm not found."; exit 1; }
if [[ ! -d "node_modules/playwright" && ! -d "node_modules/@playwright" ]]; then
  echo "[doctor] Playwright not found in node_modules — run 'npm install' first."
  exit 1
fi

echo "[doctor] Checking for yq, jq, curl..."
command -v yq   >/dev/null 2>&1 || { echo "[doctor] yq not found."; exit 1; }
command -v jq   >/dev/null 2>&1 || { echo "[doctor] jq not found."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "[doctor] curl not found."; exit 1; }

echo "[doctor] Checking project tracking docs are present..."
for f in Progress.md COMPLEXITY_GRAPH.md TASK_QUEUE.md E2E_EXPERIENCE_CHECKLIST.md; do
  [[ -f "$f" ]] || echo "[doctor] WARNING: $f not found at repo root — run from repo root."
done

echo "[doctor] Environment OK."
