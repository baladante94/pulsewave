import AppKit
import SwiftUI

enum MenuBarVisualizerSize: String, CaseIterable, Identifiable, Equatable {
    case compact
    case wide

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .compact: return "Compact"
        case .wide: return "Wide"
        }
    }

    var statusItemLength: CGFloat {
        switch self {
        case .compact: return NSStatusItem.squareLength
        case .wide: return 180
        }
    }

    var barCount: Int {
        switch self {
        case .compact: return 6
        case .wide: return 28
        }
    }
}

@MainActor
final class MenuBarController: NSObject, ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "menuBarVisualizerEnabled")
            updateStatusItemVisibility()
        }
    }

    @Published var size: MenuBarVisualizerSize {
        didSet {
            UserDefaults.standard.set(size.rawValue, forKey: "menuBarVisualizerSize")
            statusItem?.length = size.statusItemLength
            updateStatusIcon()
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
        let storedSize = UserDefaults.standard.string(forKey: "menuBarVisualizerSize")
        self.size = MenuBarVisualizerSize(rawValue: storedSize ?? "") ?? .wide
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
            let item = NSStatusBar.system.statusItem(withLength: size.statusItemLength)
            item.button?.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "AudioVisualiser")
            item.button?.imagePosition = .imageOnly
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
        iconTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 20.0, repeats: true) { [weak self] _ in
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
        let barCount = min(size.barCount, bands.count)
        let width = size.statusItemLength
        let height: CGFloat = 18
        let spacing: CGFloat = size == .wide ? 2 : 1.5
        let barWidth = size == .wide ? max(2, (width - spacing * CGFloat(barCount - 1)) / CGFloat(barCount)) : 2

        let content = HStack(alignment: .bottom, spacing: spacing) {
            ForEach(0..<max(barCount, 1), id: \.self) { index in
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(Color.primary)
                    .frame(width: barWidth, height: barCount > 0 ? max(1.5, min(height, CGFloat(bands[index]) * 60)) : 1.5)
            }
        }
        .frame(width: width, height: height)

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

        activePopover.contentSize = NSSize(width: 280, height: 260)
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
