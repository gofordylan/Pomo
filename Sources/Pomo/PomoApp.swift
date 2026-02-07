import AppKit
import SwiftUI

@main
enum PomoApp {
    static let appDelegate = AppDelegate()

    static func main() {
        NSApplication.shared.delegate = appDelegate
        NSApplication.shared.setActivationPolicy(.accessory)
        NSApplication.shared.run()
    }
}

// MARK: - Borderless panel that can become key (for clicks/scrolling)

class PomoPanel: NSPanel {
    override var canBecomeKey: Bool { true }

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 440),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .statusBar
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: PomoPanel!
    private let sessionStore = SessionStore()
    private lazy var timerManager = TimerManager(sessionStore: sessionStore)
    private var clickMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: 30)

        if let button = statusItem.button {
            button.image = tomatoIcon()
            button.image?.size = NSSize(width: 16, height: 16)
            button.action = #selector(togglePanel)
            button.target = self
        }

        // Build the SwiftUI view
        let contentView = PopoverView(
            timerManager: timerManager,
            sessionStore: sessionStore
        )

        // Wrap in hosting view with rounded corners
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 340, height: 440)

        let wrapper = NSView(frame: hostingView.frame)
        wrapper.wantsLayer = true
        wrapper.layer?.cornerRadius = 12
        wrapper.layer?.masksToBounds = true
        wrapper.addSubview(hostingView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: wrapper.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
        ])

        panel = PomoPanel()
        panel.contentView = wrapper

        // Status bar updates
        timerManager.onDisplayUpdate = { [weak self] text in
            DispatchQueue.main.async {
                self?.updateStatusDisplay(text)
            }
        }
    }

    private func updateStatusDisplay(_ text: String) {
        guard let button = statusItem.button else { return }

        if text.contains(":") || text.contains("⏸") {
            // Timer active — show countdown text
            button.image = nil
            statusItem.length = 64
            let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
            button.attributedTitle = NSAttributedString(
                string: text,
                attributes: [
                    .font: font,
                    .paragraphStyle: centeredStyle(),
                ]
            )
        } else {
            // Idle — show tomato icon
            button.attributedTitle = NSAttributedString()
            button.title = ""
            statusItem.length = 30
            button.image = tomatoIcon()
            button.image?.size = NSSize(width: 16, height: 16)
        }
    }

    private func centeredStyle() -> NSParagraphStyle {
        let s = NSMutableParagraphStyle()
        s.alignment = .center
        return s
    }

    /// Draws a small white tomato silhouette as a template image
    private func tomatoIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { _ in
            NSColor.black.setFill()
            NSColor.black.setStroke()

            // Body — slightly wide oval
            let body = NSBezierPath(ovalIn: NSRect(x: 2, y: 0.5, width: 14, height: 12))
            body.fill()

            // Stem — short curved line
            let stem = NSBezierPath()
            stem.move(to: NSPoint(x: 9, y: 12.5))
            stem.curve(to: NSPoint(x: 10.5, y: 17),
                       controlPoint1: NSPoint(x: 9, y: 14.5),
                       controlPoint2: NSPoint(x: 10, y: 16))
            stem.lineWidth = 1.5
            stem.lineCapStyle = .round
            stem.stroke()

            // Leaf — small teardrop to the left
            let leaf = NSBezierPath()
            leaf.move(to: NSPoint(x: 9, y: 13.5))
            leaf.curve(to: NSPoint(x: 4.5, y: 15.5),
                       controlPoint1: NSPoint(x: 7, y: 15),
                       controlPoint2: NSPoint(x: 5.5, y: 16))
            leaf.curve(to: NSPoint(x: 9, y: 13.5),
                       controlPoint1: NSPoint(x: 5, y: 14),
                       controlPoint2: NSPoint(x: 7, y: 13))
            leaf.fill()

            return true
        }
        image.isTemplate = true // adapts to menu bar: white on dark, black on light
        return image
    }

    @objc private func togglePanel() {
        if panel.isVisible {
            closePanel()
        } else {
            openPanel()
        }
    }

    private func openPanel() {
        guard let button = statusItem.button,
              let buttonWindow = button.window else { return }

        let buttonRect = button.convert(button.bounds, to: nil)
        let screenRect = buttonWindow.convertToScreen(buttonRect)
        let x = screenRect.midX - 170
        let y = screenRect.minY - 444

        panel.setFrameOrigin(NSPoint(x: x, y: y))
        panel.makeKeyAndOrderFront(nil)

        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, self.panel.isVisible else { return }
            let loc = NSEvent.mouseLocation
            if !self.panel.frame.contains(loc) {
                self.closePanel()
            }
        }
    }

    private func closePanel() {
        panel.orderOut(nil)
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }
}
