# Signal persistent glow to stop - creates kill file, glow checks every 80ms
New-Item -ItemType File -Path "$env:TEMP\claude_glow_kill" -Force >$null
