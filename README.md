# Local Control Skill + MCP (Windows)

Give an AI agent real hands on your Windows desktop: move/click the mouse, type, send keys, take screenshots, manage windows, and orchestrate multi-step flows. Ships as both an **opencode Agent Skill** and a **local MCP server**.

## What it does

- Mouse: move, click (left/right/middle/double), scroll
- Keyboard: type text (Unicode), hotkeys/combos (ctrl+c, alt+tab, win+r, ...)
- Screen: screenshots (saved path returned)
- Windows: list and activate by title substring
- Safety: Ctrl+Alt+Shift+Esc emergency stop (`watchdog.ps1` / stop flag)
- Orchestration: batch runner (`run.ps1`) and warm daemon (`daemon.ps1`) for speed
- MCP: direct function-calling server (`mcp_server.py`) for fast tool calls

## How it works

- PowerShell + Win32 APIs (`SetCursorPos`, `mouse_event`, `keybd_event`, GDI screenshots)
- Python + ctypes MCP wrapper for direct, low-overhead calls (no PowerShell per action)
- No external dependencies beyond built-in Windows/Python

## Compatible apps

Works anywhere that can run local tools:
- **opencode** (skill via `SKILL.md`, and/or MCP)
- Any MCP client (Claude Desktop, Cursor, Continue, etc.)
- Any agent that can invoke shell commands
- Also usable as plain PowerShell scripts/CLI

## Install

Exact PowerShell one-liners (Windows):

```powershell
# 1. Clone/download into opencode skill folder
$skill = "$env:USERPROFILE\.agents\skills\local-control"
git clone https://github.com/Legitcraft/local-control-mcp.git $skill

# 2. Or copy from an downloaded folder:
New-Item -ItemType Directory -Force "$env:USERPROFILE\.config\opencode\skills\local-control"
Copy-Item -Recurse -Force "C:\path\to\local-control-skill\*" "$env:USERPROFILE\.config\opencode\skills\local-control\"
```

For opencode MCP, add this object under `mcp` in `%USERPROFILE%\.config\opencode\opencode.jsonc`:

```json
"local-control": {
  "type": "local",
  "command": ["python", "C:\\path\\to\\local-control\\mcp_server.py"],
  "enabled": true
}
```

Then restart opencode.

Then restart opencode.

## Usage

Single action:
```
powershell -ExecutionPolicy Bypass -NoProfile -File control.ps1 <action> [args]
```

Batch (faster):
```
powershell -ExecutionPolicy Bypass -NoProfile -File run.ps1 -File batch.json
```

Emergency stop daemon:
```
powershell -ExecutionPolicy Bypass -NoProfile -File daemon.ps1
```

MCP tools: `mouse_move`, `mouse_click`, `mouse_scroll`, `type_text`, `press_key`, `screenshot`, `run_powershell`.

## Speed tips

- Prefer one `run.ps1` batch per task
- Avoid screenshots unless needed (this model may not read images)
- Launch apps/URLs directly, then focus the window
- Use the warm daemon or MCP server to avoid per-call startup

## Safety

- Real desktop input (moves actual cursor). Confirm before destructive actions.
- Do not bypass UAC/secure desktop.
- Use emergency stop (Ctrl+Alt+Shift+Esc) if needed.

## Use cases

- Open an app or URL, wait, and click a button (e.g., Edge -> gmail.com -> compose -> send)
- Automate repetitive data entry/forms on desktop/web apps
- Send notifications or follow-up emails (Gmail compose via URL + Ctrl+Enter)
- Open File Explorer to specific project folders quickly
- Regression/UI smoke tests for desktop or web apps (click, type, screenshot)
- Troubleshoot visually with screenshots (vision-capable agents)
- Run a multi-step desktop workflow in one batch or daemon call
- Quick window activation ("activate Slack", "activate VS Code")
- Scroll, copy/paste analysis, and collect on-screen info
- Schedule routines via task scheduler calling run.ps1


## License

MIT
