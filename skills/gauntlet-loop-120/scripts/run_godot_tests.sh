#!/usr/bin/env bash
# Runs the full GUT suite headless, exporting JUnit XML
# (-gjunit_xml_file) rather than scraping stdout — same reliable
# machine-parseable pattern used for EscapeChime's NUnit results.
# Updates state/lane_a_status.yaml so list_targets.py can gate Lane B.
set -euo pipefail

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${SKILL_ROOT}/assets/config.yaml"
get_cfg () { yq -r ".$1" "$CONFIG"; }

GODOT_BIN="$(get_cfg godot_binary)"
PROJECT_PATH="$(get_cfg project_path)"
LANE_A_STATUS="$(get_cfg lane_a_status_file)"
JUNIT_REL="$(get_cfg gut_junit_file)"
JUNIT_OUT="$(pwd)/${JUNIT_REL}"
mkdir -p "$(dirname "$LANE_A_STATUS")"
mkdir -p "$(dirname "$JUNIT_OUT")"
mkdir -p ./logs

echo "[run_godot_tests] Running GUT suite headless..."
# -d (debug mode) is required for gut_cmdln.gd to execute per GUT's own
# docs; -gdir=res://tests specifies test location; -gjunit_xml_file gives us a parseable result.
"$GODOT_BIN" --path "$PROJECT_PATH" --headless -d -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests \
  -gjunit_xml_file="$JUNIT_OUT" \
  -gexit \
  2>&1 | tee ./logs/gut_run.log

GUT_EXIT=${PIPESTATUS[0]}

python3 "${SKILL_ROOT}/scripts/parse_gut_results.py" \
  --junit "$JUNIT_OUT" \
  --out "$LANE_A_STATUS"

echo "[run_godot_tests] GUT exit code: $GUT_EXIT"
cat "$LANE_A_STATUS"
exit "$GUT_EXIT"
