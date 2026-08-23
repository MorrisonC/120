#!/usr/bin/env bash
# Preflight check for godot-mcp-bridge. Checks prerequisites; does NOT
# install the MCP server plugin itself -- see resources/setup-guide.md
# for that (it involves copying a third-party plugin into the project,
# which is a deliberate one-time step, not something to automate blindly).
set -euo pipefail

echo "[doctor] Checking for Godot 4 binary..."
GODOT_BIN="${GODOT_BINARY:-godot4}"
command -v "$GODOT_BIN" >/dev/null 2>&1 || {
  echo "[doctor] '$GODOT_BIN' not found. Set GODOT_BINARY if your binary"
  echo "[doctor] has a different name, or install Godot 4.3 per"
  echo "[doctor] Progress.md Milestone 1."
  exit 1
}
"$GODOT_BIN" --version

echo "[doctor] Checking for Node.js (most Godot MCP servers run as a"
echo "[doctor] Node.js process bridging the AI client and the editor)..."
command -v node >/dev/null 2>&1 || { echo "[doctor] node not found."; exit 1; }
command -v npm  >/dev/null 2>&1 || { echo "[doctor] npm not found."; exit 1; }

echo "[doctor] Checking whether the default server's plugin is installed..."
if [[ -d "addons/godot_mcp" ]]; then
  echo "[doctor] addons/godot_mcp/ found — plugin appears installed."
  echo "[doctor] Confirm it's enabled: Project Settings -> Plugins -> Godot MCP."
else
  echo "[doctor] addons/godot_mcp/ NOT found."
  echo "[doctor] This is a one-time manual step -- see resources/setup-guide.md."
  echo "[doctor] (Not auto-installed here since it means pulling a"
  echo "[doctor]  third-party plugin into your committed project — a"
  echo "[doctor]  deliberate choice, not something to do silently.)"
fi

echo "[doctor] Environment check complete."
