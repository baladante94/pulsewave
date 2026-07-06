import AppKit
import SwiftUI

@MainActor
final class MainWindowController: NSWindowController, NSWindowDelegate {
    private let onVisibilityChange: (Bool) -> Void

    init(
        viewModel: VisualizerViewModel,
        audioSourceManager: AudioSourceManager,
        menuBarController: MenuBarController,
        onVisibilityChange: @escaping (Bool) -> Void
    ) {
        self.onVisibilityChange = onVisibilityChange
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Pulsewave"
        window.center()
        window.minSize = NSSize(width: 480, height: 360)
        window.contentView = NSHostingView(
            rootView: ContentView(
                viewModel: viewModel,
                audioSourceManager: audioSourceManager,
                menuBarController: menuBarController
            )
        )
        window.isReleasedWhenClosed = false

        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        onVisibilityChange(true)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    /// Keep the app alive as a menu-bar utility when the main window is closed -- just hide it
    /// instead of destroying it, so it can be reopened instantly from the menu bar.
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        onVisibilityChange(false)
        return false
    }
}
