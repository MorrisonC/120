#!/usr/bin/env bash
# Preflight check for post-task-visual-critic-120.
set -euo pipefail

echo "[doctor] Checking gauntlet-loop-120 is present (this skill calls"
echo "[doctor] its capture_web_e2e.sh directly)..."
if [[ ! -f "../gauntlet-loop-120/scripts/capture_web_e2e.sh" && ! -f "skills/gauntlet-loop-120/scripts/capture_web_e2e.sh" ]]; then
  echo "[doctor] gauntlet-loop-120/scripts/capture_web_e2e.sh not found."
  echo "[doctor] Install/place gauntlet-loop-120 alongside this skill first."
  exit 1
fi

echo "[doctor] Checking for yq..."
command -v yq >/dev/null 2>&1 || { echo "[doctor] yq not found."; exit 1; }

echo "[doctor] Checking TASK_QUEUE.md is present at repo root..."
[[ -f "TASK_QUEUE.md" ]] || echo "[doctor] WARNING: TASK_QUEUE.md not found — run from repo root."

echo "[doctor] Environment OK. Remember: the capture/config steps here"
echo "[doctor] are mechanical, but the actual visual judgment (step 2-3"
echo "[doctor] of SKILL.md) is an agent turn, not something this script"
echo "[doctor] does for you -- see run_visual_critic.sh's TODO hooks."
