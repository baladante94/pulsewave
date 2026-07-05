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
        let timer = Timer(timeInterval: 1.0 / 20.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusIcon()
            }
        }
        // Scheduled via RunLoop directly (in .common mode) instead of Timer.scheduledTimer, which
        // only registers in .default mode -- that pauses while the popover/menu is being tracked,
        // making the icon appear frozen exactly while someone is looking at the popover.
        RunLoop.main.add(timer, forMode: .common)
        iconTimer = timer
    }

    private func stopIconTimer() {
        iconTimer?.invalidate()
        iconTimer = nil
    }

    private func updateStatusIcon() {
        statusItem?.button?.image = renderStatusIcon()
    }

    /// Linearly interpolates between adjacent bands so we can show more visual bars than we have
    /// FFT bands (28) -- otherwise a wide strip just stretches 28 bars into fat blocks.
    private func interpolatedBandValue(_ bands: [Float], at position: Double) -> Float {
        guard !bands.isEmpty else { return 0 }
        let clamped = max(0, min(Double(bands.count - 1), position))
        let lowerIndex = Int(clamped)
        let upperIndex = min(bands.count - 1, lowerIndex + 1)
        let fraction = Float(clamped - Double(lowerIndex))
        return bands[lowerIndex] * (1 - fraction) + bands[upperIndex] * fraction
    }

    private func renderStatusIcon() -> NSImage {
        let bands = viewModel.smoothedResult.spectrumBands
        let width = size.statusItemLength
        let height: CGFloat = 18
        let spacing: CGFloat = size == .compact ? 1.5 : 1.5
        let barWidth: CGFloat = size == .compact ? 2 : 3
        let barCount = size == .compact
            ? max(min(size.barCount, bands.count), 1)
            : max(1, Int(width / (barWidth + spacing)))
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
            let value: CGFloat
            if size == .compact {
                value = index < bands.count ? CGFloat(bands[index]) : 0
            } else {
                let position = bands.isEmpty ? 0 : Double(index) / Double(max(barCount - 1, 1)) * Double(bands.count - 1)
                value = CGFloat(interpolatedBandValue(bands, at: position))
            }
            let barHeight = max(1.5, min(height, value * 60))
            let x = CGFloat(index) * (barWidth + spacing)
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
