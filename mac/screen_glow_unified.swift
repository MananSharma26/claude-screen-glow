#!/usr/bin/env swift

import AppKit

let args = CommandLine.arguments
let mode = args.count > 1 ? args[1] : "stop"
let killFile = NSTemporaryDirectory() + "claude_glow_kill"

// NSPanel subclass that never steals focus (Mac equivalent of WS_EX_NOACTIVATE)
class GlowPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

class GlowView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        guard let gradient = NSGradient(colors: [
            NSColor.clear,
            NSColor(red: 1.0, green: 0.647, blue: 0.0, alpha: 1.0)
        ]) else { return }
        gradient.draw(in: bounds, angle: 0)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)   // No dock icon, no focus

let screen = NSScreen.main!.frame
let barWidth: CGFloat = 100

let panel = GlowPanel(
    contentRect: NSRect(x: screen.maxX - barWidth, y: screen.minY, width: barWidth, height: screen.height),
    styleMask: [.borderless, .nonactivatingPanel],
    backing: .buffered,
    defer: false
)
panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)) + 1)
panel.isOpaque = false
panel.backgroundColor = .clear
panel.hasShadow = false
panel.ignoresMouseEvents = true
panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

let glowView = GlowView(frame: panel.contentView!.bounds)
glowView.autoresizingMask = [.width, .height]
panel.contentView?.addSubview(glowView)
panel.orderFrontRegardless()

if mode == "persist" {
    // --- PERSIST mode: pulse until kill file or 90s timeout ---
    let startTime = Date()
    if FileManager.default.fileExists(atPath: killFile),
       let attrs = try? FileManager.default.attributesOfItem(atPath: killFile),
       let modDate = attrs[.modificationDate] as? Date, modDate < startTime {
        try? FileManager.default.removeItem(atPath: killFile)
    }

    var pulseStep: Double = 0
    Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
        if FileManager.default.fileExists(atPath: killFile),
           let attrs = try? FileManager.default.attributesOfItem(atPath: killFile),
           let modDate = attrs[.modificationDate] as? Date, modDate >= startTime {
            try? FileManager.default.removeItem(atPath: killFile)
            timer.invalidate()
            NSApp.terminate(nil)
            return
        }
        if Date().timeIntervalSince(startTime) > 90 {
            timer.invalidate()
            NSApp.terminate(nil)
            return
        }
        pulseStep += 1
        panel.alphaValue = CGFloat(0.85 + 0.15 * sin(pulseStep * 0.1))
    }

} else {
    // --- STOP mode: hold 2.5s then fade out over 3s ---
    let fadeSteps = 30
    let fadeInterval = 3.0 / Double(fadeSteps)
    var step = 0
    Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
        Timer.scheduledTimer(withTimeInterval: fadeInterval, repeats: true) { timer in
            step += 1
            let opacity = 1.0 - (Double(step) / Double(fadeSteps))
            if opacity <= 0 {
                timer.invalidate()
                NSApp.terminate(nil)
            } else {
                panel.alphaValue = CGFloat(opacity)
            }
        }
    }
}

app.run()
