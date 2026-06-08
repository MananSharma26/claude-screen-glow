# claude-screen-glow

A visual notification system for Claude Code — shows an orange glow on the right edge of your screen to indicate Claude's state. Works on Windows and Mac.

Inspired by a community project on GitHub, modified for my own workflow.

## What it does

- **Orange pulse** (persist mode): Claude is waiting for your input or permission
- **Orange fade** (stop mode): Claude has finished and output is ready
- Glow auto-times out after 90 seconds if not dismissed
- Does **not** steal focus — you can start typing immediately when the glow appears

---

## Windows

### Files
| File | Purpose |
|---|---|
| `screen_glow_unified.ps1` | Main glow script — accepts `-Mode stop` or `-Mode persist` |
| `screen_glow_kill.ps1` | Kills the persistent glow immediately |

### Setup

Add to `~/.claude/settings.json` under `"hooks"`:

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

### Requirements
- Windows with PowerShell
- Claude Code CLI

---

## Mac

### Files
| File | Purpose |
|---|---|
| `mac/screen_glow_unified.swift` | Main glow script — accepts `stop` or `persist` as argument |
| `mac/screen_glow_kill.sh` | Kills the persistent glow immediately |

### Install

**1. Install Xcode Command Line Tools** (if not already installed):
```bash
xcode-select --install
```

**2. Compile the Swift script** (do this once — compiled binary starts instantly):
```bash
swiftc mac/screen_glow_unified.swift -o /usr/local/bin/claude-screen-glow
chmod +x mac/screen_glow_kill.sh
cp mac/screen_glow_kill.sh /usr/local/bin/claude-screen-glow-kill
chmod +x /usr/local/bin/claude-screen-glow-kill
```

**3. Add to `~/.claude/settings.json`** under `"hooks"`:

```json
"hooks": {
  "PermissionRequest": [
    { "hooks": [{ "type": "command", "command": "claude-screen-glow persist &", "timeout": 60, "async": true }] }
  ],
  "PreToolUse": [
    { "hooks": [{ "type": "command", "command": "claude-screen-glow-kill", "timeout": 5, "async": true }] }
  ],
  "PostToolUse": [
    { "hooks": [{ "type": "command", "command": "claude-screen-glow-kill", "timeout": 5, "async": true }] }
  ],
  "Stop": [
    { "hooks": [{ "type": "command", "command": "claude-screen-glow stop &", "timeout": 10, "async": true }] }
  ]
}
```

### Requirements
- macOS (uses AppKit — built into the OS, no dependencies)
- Xcode Command Line Tools (for `swiftc`)
- Claude Code CLI
