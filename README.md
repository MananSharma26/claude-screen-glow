# claude-screen-glow

A visual notification system for Claude Code on Windows — shows an orange glow on the right edge of your screen to indicate Claude's state.

Inspired by a community project on GitHub, modified for my own workflow.

## What it does

- **Orange pulse** (persist mode): Claude is waiting for your input or permission
- **Orange fade** (stop mode): Claude has finished and output is ready
- Glow auto-times out after 90 seconds if not dismissed

## Files

| File | Purpose |
|---|---|
| `screen_glow_unified.ps1` | Main glow script — accepts `-Mode stop` or `-Mode persist` |
| `screen_glow_kill.ps1` | Kills the persistent glow immediately |

## Setup

Requires Claude Code with hooks configured in `~/.claude/settings.json`:

```json
"hooks": {
  "PermissionRequest": [
    { "hooks": [{ "type": "command", "command": "bash -c 'cmd.exe /c start /b powershell.exe -ExecutionPolicy Bypass -File \"C:/path/to/screen_glow_unified.ps1\" -Mode persist 2>/dev/null || true'", "timeout": 60, "async": true }] }
  ],
  "PreToolUse": [
    { "hooks": [{ "type": "command", "command": "bash -c 'cmd.exe /c start /b powershell.exe -ExecutionPolicy Bypass -File \"C:/path/to/screen_glow_kill.ps1\" 2>/dev/null || true'", "timeout": 5, "async": true }] }
  ],
  "PostToolUse": [
    { "hooks": [{ "type": "command", "command": "bash -c 'cmd.exe /c start /b powershell.exe -ExecutionPolicy Bypass -File \"C:/path/to/screen_glow_kill.ps1\" 2>/dev/null || true'", "timeout": 5, "async": true }] }
  ],
  "Stop": [
    { "hooks": [{ "type": "command", "command": "bash -c 'cmd.exe /c start /b powershell.exe -ExecutionPolicy Bypass -File \"C:/path/to/screen_glow_unified.ps1\" -Mode stop 2>/dev/null || true'", "timeout": 10, "async": true }] }
  ]
}
```

Replace `C:/path/to/` with the actual path to the scripts.

## Requirements

- Windows (uses `System.Windows.Forms`)
- Claude Code CLI
- PowerShell execution policy that allows local scripts (`-ExecutionPolicy Bypass` handles this per-invocation)
