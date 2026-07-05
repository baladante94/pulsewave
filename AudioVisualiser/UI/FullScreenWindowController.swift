import AppKit
import SwiftUI

@MainActor
final class FullScreenWindowController: NSWindowController, NSWindowDelegate {
    private var escapeMonitor: Any?

    init(viewModel: VisualizerViewModel) {
        let screen = NSScreen.main
        let window = NSWindow(
            contentRect: screen?.frame ?? NSRect(x: 0, y: 0, width: 1280, height: 800),
            styleMask: [.titled, .resizable, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = .black
        window.isOpaque = true
        window.hasShadow = false
        window.level = .normal
        window.collectionBehavior = [.fullScreenPrimary]
        window.contentView = NSHostingView(rootView: VisualizerView(viewModel: viewModel))

        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        guard let window else { return }
        window.makeKeyAndOrderFront(nil)
        if !window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }
        NSCursor.hide()
        installEscapeMonitor()
    }

    private func installEscapeMonitor() {
        guard escapeMonitor == nil else { return }
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.window?.toggleFullScreen(nil)
                return nil
            }
            return event
        }
    }

    private func removeEscapeMonitor() {
        if let escapeMonitor {
            NSEvent.removeMonitor(escapeMonitor)
        }
        escapeMonitor = nil
    }

    func windowWillExitFullScreen(_ notification: Notification) {
        NSCursor.unhide()
        removeEscapeMonitor()
    }

    func windowWillClose(_ notification: Notification) {
        NSCursor.unhide()
        removeEscapeMonitor()
    }
}
