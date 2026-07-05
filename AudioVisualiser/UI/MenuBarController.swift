import AppKit
import SwiftUI

enum MenuBarVisualizerSize: String, CaseIterable, Identifiable, Equatable {
    case compact
    case wide
    case full

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .compact: return "Compact"
        case .wide: return "Wide"
        case .full: return "Full"
        }
    }

    var statusItemLength: CGFloat {
        switch self {
        case .compact: return NSStatusItem.squareLength
        case .wide: return 180
        case .full: return 600
        }
    }

    var barCount: Int {
        switch self {
        case .compact: return 6
        case .wide, .full: return 28
        }
    }
}

enum MenuBarColorMode: String, CaseIterable, Identifiable, Equatable {
    case spectrum
    case mono
    case neonPink
    case iceBlue

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spectrum: return "Spectrum"
        case .mono: return "Mono"
        case .neonPink: return "Neon Pink"
        case .iceBlue: return "Ice Blue"
        }
    }

    var isTemplate: Bool { self == .mono }

    func color(forIndex index: Int, count: Int) -> NSColor {
        switch self {
        case .spectrum:
            let hue = 0.55 + (Double(index) / Double(max(count, 1))) * 0.35
            return NSColor(calibratedHue: hue, saturation: 0.85, brightness: 1, alpha: 1)
        case .mono:
            return NSColor.labelColor
        case .neonPink:
            return NSColor(calibratedRed: 1.0, green: 0.2, blue: 0.75, alpha: 1)
        case .iceBlue:
            return NSColor(calibratedRed: 0.35, green: 0.85, blue: 1.0, alpha: 1)
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

    @Published var colorMode: MenuBarColorMode {
        didSet {
            UserDefaults.standard.set(colorMode.rawValue, forKey: "menuBarVisualizerColorMode")
            updateStatusIcon()
        }
    }

    private let viewModel: VisualizerViewModel
    private let audioSourceManager: AudioSourceManager
    private let onOpenFullScreen: () -> Void

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var iconTimer: Timer?
    private var globalClickMonitor: Any?
    private var iconBandCeilings: [Float] = []

    init(viewModel: VisualizerViewModel, audioSourceManager: AudioSourceManager, onOpenFullScreen: @escaping () -> Void) {
        self.viewModel = viewModel
        self.audioSourceManager = audioSourceManager
        self.onOpenFullScreen = onOpenFullScreen
        self.isEnabled = (UserDefaults.standard.object(forKey: "menuBarVisualizerEnabled") as? Bool) ?? true
        let storedSize = UserDefaults.standard.string(forKey: "menuBarVisualizerSize")
        self.size = MenuBarVisualizerSize(rawValue: storedSize ?? "") ?? .wide
        let storedColorMode = UserDefaults.standard.string(forKey: "menuBarVisualizerColorMode")
        self.colorMode = MenuBarColorMode(rawValue: storedColorMode ?? "") ?? .spectrum
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

    /// Local auto-gain for the menu bar icon only: tracks a slowly-decaying peak per band and
    /// scales against it, so the compact strip shows real variation instead of clipping to
    /// near-max. Kept separate from AudioAnalyzer so the main window's visualizer (already tuned)
    /// is unaffected.
    private func normalizedIconBands(_ bands: [Float]) -> [Float] {
        if iconBandCeilings.count != bands.count {
            iconBandCeilings = bands
        }
        var result = [Float](repeating: 0, count: bands.count)
        for i in 0..<bands.count {
            let raw = bands[i]
            iconBandCeilings[i] = max(raw, iconBandCeilings[i] * 0.995)
            let ceiling = max(iconBandCeilings[i], 0.0005)
            let ratio = min(1, raw / ceiling)
            result[i] = pow(ratio, 0.7)
        }
        return result
    }

    private func renderStatusIcon() -> NSImage {
        let bands = normalizedIconBands(viewModel.smoothedResult.spectrumBands)
        let barCount = max(min(size.barCount, bands.count), 1)
        let width = size.statusItemLength
        let height: CGFloat = 18
        let spacing: CGFloat = size == .compact ? 1.5 : 2
        let maxBarWidth: CGFloat = 6
        let barWidth = size == .compact ? 2 : min(maxBarWidth, max(1.5, (width - spacing * CGFloat(barCount - 1)) / CGFloat(barCount)))
        let contentWidth = barWidth * CGFloat(barCount) + spacing * CGFloat(barCount - 1)
        let startX = size == .compact ? 0 : max(0, (width - contentWidth) / 2)
        let colorMode = colorMode
        let scale: CGFloat = 2

        let pixelWidth = max(1, Int(width * scale))
        let pixelHeight = max(1, Int(height * scale))

        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelWidth,
            pixelsHigh: pixelHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return NSImage(systemSymbolName: "waveform", accessibilityDescription: nil) ?? NSImage()
        }
        bitmapRep.size = NSSize(width: width, height: height)

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }

        guard let context = NSGraphicsContext(bitmapImageRep: bitmapRep) else {
            return NSImage()
        }
        NSGraphicsContext.current = context
        let cgContext = context.cgContext
        cgContext.clear(CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))
        cgContext.scaleBy(x: scale, y: scale)

        for index in 0..<barCount {
            let value = index < bands.count ? CGFloat(bands[index]) : 0
            let barHeight = max(1.5, min(height, value * height * 0.92))
            let x = startX + CGFloat(index) * (barWidth + spacing)
            let barRect = CGRect(x: x, y: 0, width: barWidth, height: barHeight)
            let path = CGPath(roundedRect: barRect, cornerWidth: barWidth / 3, cornerHeight: barWidth / 3, transform: nil)
            cgContext.addPath(path)
            cgContext.setFillColor(colorMode.color(forIndex: index, count: barCount).cgColor)
            cgContext.fillPath()
        }

        let image = NSImage(size: NSSize(width: width, height: height))
        image.addRepresentation(bitmapRep)
        image.isTemplate = colorMode.isTemplate
        return image
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
            created.delegate = self
            popover = created
            return created
        }()

        activePopover.contentSize = NSSize(width: 280, height: 320)
        activePopover.contentViewController = NSHostingController(
            rootView: PopoverContentView(
                viewModel: viewModel,
                audioSourceManager: audioSourceManager,
                menuBarController: self
            )
        )
        activePopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.popover?.performClose(nil)
        }
    }
}

extension MenuBarController: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
        }
        globalClickMonitor = nil
    }
}
