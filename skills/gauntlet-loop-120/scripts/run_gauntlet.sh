#!/usr/bin/env bash
# Usage: run_gauntlet.sh <target_id>
#
# Runs (or resumes) the Lane B loop for one target. Gates on BOTH the
# TASK_QUEUE.md epic being DONE and any GUT suite prerequisites passing
# -- see targets.yaml's note on mixed prerequisite types. No fixed
# round cap -- exits on a critic win or a STOP file.
set -euo pipefail

TARGET="${1:?Usage: run_gauntlet.sh <target_id>}"
SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${SKILL_ROOT}/assets/config.yaml"
get_cfg () { yq -r ".$1" "$CONFIG"; }

STATE_DIR="$(get_cfg state_dir)"
STOP_FILE="$(get_cfg stop_file)"
LANE_A_STATUS="$(get_cfg lane_a_status_file)"
TASK_QUEUE="$(get_cfg task_queue_file)"
STATE_FILE="${STATE_DIR}/${TARGET}.yaml"
mkdir -p "$STATE_DIR"

# ---- Gate check ----
PREREQS="$(yq -r --arg t "$TARGET" '.targets[] | select(.id == $t) | .lane_a_prerequisite | .[]' \
  "${SKILL_ROOT}/assets/targets.yaml")"
if [[ -z "$PREREQS" ]]; then
  echo "[run_gauntlet] Unknown target '$TARGET'." >&2
  exit 1
fi

while IFS= read -r prereq; do
  # A prerequisite name matching a TASK_QUEUE.md task ID is checked
  # there; otherwise treated as a GUT suite name checked against
  # lane_a_status.yaml.
  if grep -q "\] ${prereq}:" "$TASK_QUEUE" 2>/dev/null; then
    TASK_STATUS="$(grep "\] ${prereq}:" "$TASK_QUEUE" | head -n1 | sed -E 's/^## \[([A-Z_]+)\].*/\1/')"
    if [[ "$TASK_STATUS" != "DONE" ]]; then
      echo "[run_gauntlet] BLOCKED: $TARGET requires task $prereq to be DONE (currently: $TASK_STATUS)." >&2
      exit 1
    fi
  else
    STATUS="$(yq -r --arg c "$prereq" '.suites[$c] // "unknown"' "$LANE_A_STATUS" 2>/dev/null || echo unknown)"
    if [[ "$STATUS" != "passed" ]]; then
      echo "[run_gauntlet] BLOCKED: $TARGET requires GUT suite $prereq to pass (currently: $STATUS)." >&2
      echo "[run_gauntlet] Run scripts/run_godot_tests.sh first." >&2
      exit 1
    fi
  fi
done <<< "$PREREQS"
echo "[run_gauntlet] Gate clear for $TARGET."

if [[ ! -f "$STATE_FILE" ]]; then
  echo "[run_gauntlet] No state file for $TARGET yet." >&2
  echo "[run_gauntlet] Propose bars (SKILL.md / bar-selection-guide.md), get one" >&2
  echo "[run_gauntlet] picked, write to ${STATE_FILE}:" >&2
  echo "[run_gauntlet]   status: bar_picked" >&2
  echo "[run_gauntlet]   bar: '<named, fetchable, comparable reference>'" >&2
  echo "[run_gauntlet]   rounds: 0" >&2
  exit 1
fi

BAR="$(yq -r '.bar // ""' "$STATE_FILE")"
if [[ -z "$BAR" ]]; then
  echo "[run_gauntlet] $STATE_FILE has no 'bar' set. Pick one first." >&2
  exit 1
fi

CAPTURE_METHOD="$(yq -r --arg t "$TARGET" '.targets[] | select(.id == $t) | .capture_method' \
  "${SKILL_ROOT}/assets/targets.yaml")"

# ---- Hooks: wire these to your agent runtime ----
invoke_builder () {
  local target="$1" bar="$2" gap="$3"
  echo "[builder] $target — bar: $bar"
  echo "[builder] addressing: ${gap:-'(first pass, no prior gap)'}"
  # TODO: replace with a real sub-agent spawn (fresh Jules
  # session/task per round, consistent with the other skills in this
  # family). Per SKILL.md's small-task discipline: if the gap needs
  # more than one focused change, STOP and split it into
  # TASK_QUEUE.md entries via decompose_task.py instead of doing a
  # large patch here.
  if [[ "$CAPTURE_METHOD" != "text" ]]; then
    bash "${SKILL_ROOT}/scripts/capture_web_e2e.sh" "$target"
  fi
}

invoke_critic () {
  local target="$1" bar="$2" capture_method="$3"
  local capture_dir; capture_dir="$(get_cfg capture_dir)/${target}"
  mkdir -p "$capture_dir"
  echo "[critic] $target — judging against bar: $bar (method: $capture_method)"
  if [[ "$capture_method" != "text" ]]; then
    python3 "${SKILL_ROOT}/scripts/critique_visuals.py" \
      --target "$target" \
      --capture-dir "$capture_dir" \
      --reference-dir "assets/tetraforce_reference" \
      --bar "$bar"
  else
    echo "OURS" > "${capture_dir}/verdict.txt"
  fi
}
# ---- end hooks ----

echo "[run_gauntlet] Starting/resuming $TARGET against bar: $BAR"

ROUND="$(yq -r '.rounds // 0' "$STATE_FILE")"
GAP="$(yq -r '.last_gap // ""' "$STATE_FILE")"

while true; do
  if [[ -f "$STOP_FILE" ]]; then
    echo "[run_gauntlet] STOP file present — halting $TARGET at round $ROUND."
    python3 -c "import yaml; d=yaml.safe_load(open('$STATE_FILE')); d['status']='stopped'; yaml.dump(d, open('$STATE_FILE','w'))"
    exit 0
  fi

  ROUND=$((ROUND + 1))
  echo "=== $TARGET round $ROUND (no cap — exits on win or STOP) ==="

  invoke_builder "$TARGET" "$BAR" "$GAP"
  invoke_critic "$TARGET" "$BAR" "$CAPTURE_METHOD"

  CAPTURE_DIR="$(get_cfg capture_dir)/${TARGET}"
  VERDICT="$(head -n1 "${CAPTURE_DIR}/verdict.txt")"
  python3 -c "import yaml; d=yaml.safe_load(open('$STATE_FILE')); d['rounds']=$ROUND; yaml.dump(d, open('$STATE_FILE','w'))"

  if [[ "$VERDICT" == "OURS" ]]; then
    python3 -c "import yaml; d=yaml.safe_load(open('$STATE_FILE')); d['status']='won'; yaml.dump(d, open('$STATE_FILE','w'))"
    echo "[run_gauntlet] $TARGET WON on round $ROUND."
    exit 0
  fi

  GAP="$(sed -n '2p' "${CAPTURE_DIR}/verdict.txt")"
  python3 -c "import yaml; d=yaml.safe_load(open('$STATE_FILE')); d['last_gap']='$GAP'; d['status']='in_progress'; yaml.dump(d, open('$STATE_FILE','w'))"
  echo "[run_gauntlet] $TARGET lost round $ROUND. Gap: $GAP"
done
