param(
    [string]$Mode = "stop"   # "stop" or "persist"
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$barWidth = 100

$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = 'None'
$form.TopMost = $true
$form.ShowInTaskbar = $false
$form.StartPosition = 'Manual'
$form.BackColor = [System.Drawing.Color]::Black
$form.TransparencyKey = [System.Drawing.Color]::Black
$form.Opacity = 1.0
$form.Width = $barWidth
$form.Height = $screen.Height
$form.Left = $screen.Width - $barWidth
$form.Top = 0

$form.Add_Paint({
    param($sender, $e)
    $rect = New-Object System.Drawing.Rectangle(0, 0, $sender.Width, $sender.Height)
    $leftColor  = [System.Drawing.Color]::FromArgb(0, 0, 0)
    $rightColor = [System.Drawing.Color]::FromArgb(255, 165, 0)
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect, $leftColor, $rightColor,
        [System.Drawing.Drawing2D.LinearGradientMode]::Horizontal
    )
    $e.Graphics.FillRectangle($brush, $rect)
    $brush.Dispose()
})

if ($Mode -eq "persist") {
    # --- PERSIST mode: pulse until kill file or 90s timeout ---
    $killFile = "$env:TEMP\claude_glow_kill"
    $startTime = Get-Date
    if (Test-Path $killFile) {
        $killFileTime = (Get-Item $killFile).LastWriteTime
        if ($killFileTime -lt $startTime) { Remove-Item $killFile -Force }
    }

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 80
    $script:pulseStep = 0

    $timer.Add_Tick({
        if (Test-Path $killFile) {
            $killFileTime = (Get-Item $killFile -ErrorAction SilentlyContinue).LastWriteTime
            if ($killFileTime -ge $startTime) {
                Remove-Item $killFile -Force -ErrorAction SilentlyContinue
                $timer.Stop()
                $form.Close()
                return
            }
        }
        if ((Get-Date) -gt $startTime.AddSeconds(90)) {
            $timer.Stop()
            $form.Close()
            return
        }
        $script:pulseStep++
        $pulse = 0.85 + 0.15 * [math]::Sin($script:pulseStep * 0.1)
        $form.Opacity = $pulse
    })

    $form.Add_Shown({ $timer.Start() })

} else {
    # --- STOP mode: hold 2.5s then fade out ---
    $holdMs = 2500
    $fadeDurationMs = 3000
    $fadeSteps = 30

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = [math]::Floor($fadeDurationMs / $fadeSteps)
    $script:step = 0

    $timer.Add_Tick({
        $script:step++
        $newOpacity = 1.0 * (1 - ($script:step / $fadeSteps))
        if ($newOpacity -le 0) {
            $timer.Stop()
            $form.Close()
        } else {
            $form.Opacity = $newOpacity
        }
    })

    $holdTimer = New-Object System.Windows.Forms.Timer
    $holdTimer.Interval = $holdMs
    $holdTimer.Add_Tick({
        $holdTimer.Stop()
        $timer.Start()
    })

    $form.Add_Shown({ $holdTimer.Start() })
}

$form.ShowDialog() | Out-Null
