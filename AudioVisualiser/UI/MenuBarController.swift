import AppKit
import SwiftUI

@MainActor
final class MenuBarController: NSObject, ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "menuBarVisualizerEnabled")
            updateStatusItemVisibility()
        }
    }

    private let viewModel: VisualizerViewModel
    private let audioSourceManager: AudioSourceManager
    private let onOpenFullScreen: () -> Void

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var iconTimer: Timer?

    init(viewModel: VisualizerViewModel, audioSourceManager: AudioSourceManager, onOpenFullScreen: @escaping () -> Void) {
        self.viewModel = viewModel
        self.audioSourceManager = audioSourceManager
        self.onOpenFullScreen = onOpenFullScreen
        self.isEnabled = (UserDefaults.standard.object(forKey: "menuBarVisualizerEnabled") as? Bool) ?? true
        super.init()
        updateStatusItemVisibility()
    }

    func openFullScreenAndClosePopover() {
        popover?.performClose(nil)
        onOpenFullScreen()
    }

    private func updateStatusItemVisibility() {
        if isEnabled {
            guard statusItem == nil else { return }
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            item.button?.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "AudioVisualiser")
            item.button?.target = self
            item.button?.action = #selector(togglePopover)
            statusItem = item
            startIconTimer()
        } else {
            stopIconTimer()
            if let statusItem {
                NSStatusBar.system.removeStatusItem(statusItem)
            }
            statusItem = nil
            popover?.performClose(nil)
        }
    }

    private func startIconTimer() {
        iconTimer?.invalidate()
        iconTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 15.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusIcon()
            }
        }
    }

    private func stopIconTimer() {
        iconTimer?.invalidate()
        iconTimer = nil
    }

    private func updateStatusIcon() {
        statusItem?.button?.image = renderStatusIcon()
    }

    private func renderStatusIcon() -> NSImage {
        let bands = viewModel.smoothedResult.spectrumBands
        let barCount = min(6, bands.count)
        let content = HStack(alignment: .bottom, spacing: 1.5) {
            ForEach(0..<max(barCount, 1), id: \.self) { index in
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(Color.primary)
                    .frame(width: 2, height: barCount > 0 ? max(1.5, CGFloat(bands[index]) * 60) : 1.5)
            }
        }
        .frame(width: 20, height: 16)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        return renderer.nsImage ?? NSImage(systemSymbolName: "waveform", accessibilityDescription: nil) ?? NSImage()
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if let popover, popover.isShown {
            popover.performClose(nil)
            return
        }

        let activePopover = popover ?? {
            let created = NSPopover()
            created.behavior = .transient
            popover = created
            return created
        }()

        activePopover.contentSize = NSSize(width: 280, height: 240)
        activePopover.contentViewController = NSHostingController(
            rootView: PopoverContentView(
                viewModel: viewModel,
                audioSourceManager: audioSourceManager,
                menuBarController: self
            )
        )
        activePopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
}
