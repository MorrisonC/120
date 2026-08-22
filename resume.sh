#!/usr/bin/env bash
# Mechanical part of SKILL.md's steps 1-2 (orient + find next action).
# Steps 3-7 (do the work, verify, update state, log, stop) are
# inherently task-specific and happen in the calling agent's own
# reasoning, not in this script -- this just gathers what's needed to
# start.
set -euo pipefail

echo "############################################"
echo "# continue-120-build: orienting"
echo "############################################"

echo ""
echo "=== Progress.md (tail) ==="
tail -n 30 Progress.md 2>/dev/null || echo "Progress.md not found -- run from repo root."

echo ""
echo "=== SESSION_LOG.md (last entry) ==="
if [[ -f SESSION_LOG.md ]]; then
  # Print from the last "## Session" header to end of file.
  awk '/^## Session/{p=1; s=""} {if(p) s = s $0 "\n"} END{print s}' SESSION_LOG.md | tail -n 40
else
  echo "SESSION_LOG.md not found -- this looks like the first session."
  echo "See project-120-docs/session-log-format.md to create it."
fi

echo ""
echo "=== Lane A test status ==="
if [[ -f skills/gauntlet-loop-120/state/lane_a_status.yaml ]]; then
  cat skills/gauntlet-loop-120/state/lane_a_status.yaml
else
  echo "No lane_a_status.yaml yet -- run"
  echo "  bash skills/gauntlet-loop-120/scripts/run_godot_tests.sh"
  echo "before trusting any Lane B gauntlet target's gate status below."
fi

echo ""
echo "############################################"
echo "# Next action (from gauntlet-loop-120's own resolver)"
echo "############################################"
python3 skills/gauntlet-loop-120/scripts/list_targets.py

echo ""
echo "############################################"
echo "# Reminder: verify at the right tier before marking anything DONE"
echo "# Write a SESSION_LOG.md entry before ending this session."
echo "############################################"
