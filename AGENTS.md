# Workspace Agent Guidelines

## Shell and Terminal Execution
- **PowerShell 7 (`pwsh`)** is installed and configured as the default terminal in Antigravity IDE and VS Code (`C:\Users\cyber\AppData\Local\Microsoft\WindowsApps\pwsh.exe`).
- When executing complex shell commands, scripts, or chained statements (`&&`, `||`, ternary operator, null-coalescing), use PowerShell 7 syntax via `pwsh -Command "..."` or run via `pwsh -File`.
- Avoid syntax that causes errors in older Windows PowerShell 5.1 when executing top-level commands, or wrap them in `pwsh`.
