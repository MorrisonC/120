#!/usr/bin/env bash
# Usage: run_visual_critic.sh <task_id> [sanity|script] [walk_script_path]
#
# Runs (or resumes) the visual critic loop for one task. No fixed round
# cap -- exits on the critic passing or a STOP file, same as every
# other loop in this family. Research/integration only happens on a
# FAIL, per SKILL.md steps 4-5.
set -euo pipefail

TASK_ID="${1:?Usage: run_visual_critic.sh <task_id> [sanity|script] [walk_script_path]}"
MODE="${2:-sanity}"
WALK_SCRIPT="${3:-}"

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${SKILL_ROOT}/assets/config.yaml"
get_cfg () { yq -r ".$1" "$CONFIG"; }

STATE_DIR="$(get_cfg state_dir)"
STOP_FILE="$(get_cfg stop_file)"
STATE_FILE="${STATE_DIR}/${TASK_ID}.yaml"
mkdir -p "$STATE_DIR"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "status: not_started" > "$STATE_FILE"
  echo "rounds: 0" >> "$STATE_FILE"
  echo "last_gap: \"\"" >> "$STATE_FILE"
  echo "research_used: false" >> "$STATE_FILE"
fi

# ---- Hooks: these are agent turns, not bash logic. A script cannot
# read an image or judge whether a screenshot satisfies a goal -- see
# SKILL.md steps 2-5. These functions are where that happens; wire them
# to your agent runtime the same way every other skill in this family
# marks its builder/critic hooks as TODO. ----
invoke_capture () {
  local task_id="$1" mode="$2" walk_script="$3"
  bash "${SKILL_ROOT}/scripts/capture_for_task.sh" "$task_id" "$mode" "$walk_script"
}

invoke_visual_critic () {
  local task_id="$1"
  local capture_dir
  capture_dir="$(get_cfg capture_dir)/${task_id}"
  echo "[visual_critic] Evaluating captures for ${task_id} in ${capture_dir}"
  python3 "${SKILL_ROOT}/../gauntlet-loop-120/scripts/critique_visuals.py" \
    --target "$task_id" \
    --capture-dir "$capture_dir" \
    --bar "Task Goal Acceptance"

  if [[ -f "${capture_dir}/verdict.txt" ]]; then
    VERDICT_LINE="$(head -n1 "${capture_dir}/verdict.txt")"
    if [[ "$VERDICT_LINE" == "OURS" ]]; then
      echo "PASS" > "${STATE_DIR}/${task_id}_verdict.txt"
    else
      GAP_LINE="$(sed -n '2p' "${capture_dir}/verdict.txt")"
      echo "FAIL" > "${STATE_DIR}/${task_id}_verdict.txt"
      echo "${GAP_LINE:-Visual acceptance criteria not met}" >> "${STATE_DIR}/${task_id}_verdict.txt"
    fi
  else
    echo "FAIL" > "${STATE_DIR}/${task_id}_verdict.txt"
    echo "NO_VERDICT_FILE" >> "${STATE_DIR}/${task_id}_verdict.txt"
  fi
}

invoke_research_and_integrate () {
  local task_id="$1" gap="$2"
  echo "[research] TODO: agent turn -- per resources/github-research-guide.md,"
  echo "[research] search on the specific gap: \"${gap}\""
  echo "[research] Then per resources/integration-guardrails.md: confirm an"
  echo "[research] explicit permissive license on anything before integrating"
  echo "[research] it. Never skip the license check."
  python3 -c "import yaml; d=yaml.safe_load(open('$STATE_FILE')); d['research_used']=True; yaml.dump(d, open('$STATE_FILE','w'))"
}
# ---- end hooks ----

if [[ -f "$STOP_FILE" ]]; then
  echo "[run_visual_critic] STOP file present — not starting ${TASK_ID}."
  exit 0
fi

ROUND="$(python3 -c "import yaml; print(yaml.safe_load(open('$STATE_FILE')).get('rounds', 0))")"
GAP="$(python3 -c "import yaml; print(yaml.safe_load(open('$STATE_FILE')).get('last_gap', ''))")"

while true; do
  if [[ -f "$STOP_FILE" ]]; then
    echo "[run_visual_critic] STOP file present — halting ${TASK_ID} at round ${ROUND}."
    python3 -c "import yaml; d=yaml.safe_load(open('$STATE_FILE')); d['status']='stopped'; yaml.dump(d, open('$STATE_FILE','w'))"
    exit 0
  fi

  ROUND=$((ROUND + 1))
  echo "=== ${TASK_ID} visual critic round ${ROUND} (no cap — exits on pass or STOP) ==="

  invoke_capture "$TASK_ID" "$MODE" "$WALK_SCRIPT"
  invoke_visual_critic "$TASK_ID"

  VERDICT="$(head -n1 "${STATE_DIR}/${TASK_ID}_verdict.txt")"
  python3 -c "import yaml; d=yaml.safe_load(open('$STATE_FILE')); d['rounds']=$ROUND; yaml.dump(d, open('$STATE_FILE','w'))"

  if [[ "$VERDICT" == "PASS" ]]; then
    python3 -c "import yaml; d=yaml.safe_load(open('$STATE_FILE')); d['status']='passed'; yaml.dump(d, open('$STATE_FILE','w'))"
    echo "[run_visual_critic] ${TASK_ID} PASSED on round ${ROUND}."
    echo "[run_visual_critic] Now mark it DONE in TASK_QUEUE.md."
    exit 0
  fi

  GAP="$(sed -n '2p' "${STATE_DIR}/${TASK_ID}_verdict.txt")"
  python3 -c "import yaml; d=yaml.safe_load(open('$STATE_FILE')); d['last_gap']='$GAP'; d['status']='in_progress'; yaml.dump(d, open('$STATE_FILE','w'))"
  echo "[run_visual_critic] ${TASK_ID} FAILED round ${ROUND}. Gap: ${GAP}"

  echo "[run_visual_critic] Researching before the next attempt..."
  invoke_research_and_integrate "$TASK_ID" "$GAP"
done
