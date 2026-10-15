---
name: local-control
description: Control mouse, keyboard, screenshots, and windows on the local Windows machine. Use when the task requires operating the desktop UI.
---

# Local Control

Wraps PowerShell + Win32 APIs. No dependencies.

## Commands

Run via PowerShell:
`powershell -ExecutionPolicy Bypass -NoProfile -File control.ps1 <action> [args...]`

Actions:
- move x y
- pos
- click [x y] [left|right|middle|double]
- scroll delta (positive=up)
- type text...
- key combo (e.g. ctrl+c, alt+tab, win+r, ctrl+shift+esc)
- screenshot [path]
- windows
- activate windowTitle
- stop-file / clear-stop

## Emergency stop

Run `watchdog.ps1` in a background terminal; pressing Ctrl+Alt+Shift+Esc creates the stop flag and aborts further actions. Alternatively run `control.ps1 stop-file` then `clear-stop`.

## Notes

- All input is real (moves actual cursor). Confirm with user before destructive actions.
- Screenshots saved to temp; read the returned path.
- Do not bypass UAC/secure desktop.

## Batch mode (faster)

Avoids one process per action. Create a JSON array and run:
`powershell -ExecutionPolicy Bypass -NoProfile -File run.ps1 -File batch.json`

Example batch.json:
[
  {"action":"activate","args":["Edge"],"delay":500},
  {"action":"key","args":["ctrl+t"],"delay":300},
  {"action":"type","args":["hello"],"delay":200},
  {"action":"key","args":["enter"],"delay":2000},
  {"action":"screenshot"}
]
