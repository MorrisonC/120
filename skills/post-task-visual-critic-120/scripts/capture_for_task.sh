#!/usr/bin/env bash
# Usage: capture_for_task.sh <task_id> [sanity|script] [walk_script_path]
#
# Pulls the task's Scope + Acceptance text out of TASK_QUEUE.md, writes
# it to task_goal.md alongside the capture, then calls
# gauntlet-loop-120's (already-fixed, real-input) capture_web_e2e.sh.
set -euo pipefail

TASK_ID="${1:?Usage: capture_for_task.sh <task_id> [sanity|script] [walk_script_path]}"
MODE="${2:-sanity}"
WALK_SCRIPT="${3:-}"

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GAUNTLET_120_ROOT="${SKILL_ROOT}/../gauntlet-loop-120"
CONFIG="${SKILL_ROOT}/assets/config.yaml"
GAUNTLET_120_CONFIG="${GAUNTLET_120_ROOT}/assets/config.yaml"
get_cfg () { yq -r ".$1" "$CONFIG"; }
get_gauntlet_cfg () { yq -r ".$1" "$GAUNTLET_120_CONFIG"; }

TASK_QUEUE="$(get_cfg task_queue_file)"
# IMPORTANT: capture_web_e2e.sh (called below) writes screenshots to
# gauntlet-loop-120's OWN capture_dir, not this skill's -- read that
# same path here so task_goal.md lands next to the actual screenshots
# instead of in a separate, empty directory.
CAPTURE_DIR="$(get_gauntlet_cfg capture_dir)/${TASK_ID}"
mkdir -p "$CAPTURE_DIR"

echo "[capture_for_task] Extracting goal text for ${TASK_ID} from ${TASK_QUEUE}..."
python3 "${SKILL_ROOT}/scripts/extract_task_goal.py" \
  --task-queue "$TASK_QUEUE" \
  --task-id "$TASK_ID" \
  --out "${CAPTURE_DIR}/task_goal.md"

if [[ ! -s "${CAPTURE_DIR}/task_goal.md" ]]; then
  echo "[capture_for_task] No entry found for ${TASK_ID} in ${TASK_QUEUE}." >&2
  exit 1
fi
cat "${CAPTURE_DIR}/task_goal.md"

echo ""
echo "[capture_for_task] Capturing via gauntlet-loop-120's Playwright harness (mode=${MODE})..."
if [[ "$MODE" == "script" ]]; then
  bash "${GAUNTLET_120_ROOT}/scripts/capture_web_e2e.sh" "$TASK_ID" script "$WALK_SCRIPT"
else
  bash "${GAUNTLET_120_ROOT}/scripts/capture_web_e2e.sh" "$TASK_ID" sanity
fi

echo "[capture_for_task] Done. Screenshots + task_goal.md in ${CAPTURE_DIR}"
echo "[capture_for_task] Next: read the screenshots + task_goal.md and judge per"
echo "[capture_for_task] resources/visual-critic-instructions.md."
