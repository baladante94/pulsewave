import Combine
import CoreGraphics
import Foundation

@MainActor
final class VisualizerViewModel: ObservableObject {
    @Published private(set) var smoothedResult: AnalysisResult = .empty
    @Published var activeRenderer: VisualizerRenderer
    @Published var colorTheme: ColorTheme {
        didSet {
            UserDefaults.standard.set(colorTheme.rawValue, forKey: "appColorTheme")
        }
    }

    let audioSourceManager: AudioSourceManager
    let availableRenderers: [VisualizerRenderer] = [
        TrippyRenderer(),
        SpectrumBarsRenderer(),
        MirrorBarsRenderer(),
        RadialPulseRenderer(),
        WaveformRibbonRenderer(),
        DotGridRenderer()
    ]

    private let analyzer = AudioAnalyzer()
    private let beatDetector = BeatDetector()
    private var displayedBands: [Float] = []
    private var bufferSubscription: AnyCancellable?
    private var wasSilent = false
    private var previousRaw: [Float] = []
    private var beatPulse: Float = 0
    private var phase: Double = 0

    init(audioSourceManager: AudioSourceManager) {
        self.audioSourceManager = audioSourceManager
        self.activeRenderer = TrippyRenderer()
        let storedTheme = UserDefaults.standard.string(forKey: "appColorTheme")
        self.colorTheme = ColorTheme(rawValue: storedTheme ?? "") ?? .spectrum

        analyzer.onResult = { [weak self] result in
            self?.handle(result)
        }
        bufferSubscription = audioSourceManager.bufferPublisher.sink { [weak self] buffer, time in
            self?.analyzer.process(buffer: buffer, time: time)
        }
    }

    func selectRenderer(id: String) {
        guard let renderer = availableRenderers.first(where: { $0.id == id }) else { return }
        activeRenderer = renderer
    }

    private func handle(_ result: AnalysisResult) {
        let raw = result.spectrumBands
        if displayedBands.count != raw.count {
            displayedBands = raw
            previousRaw = raw
        }

        for i in displayedBands.indices {
            let target = raw[i]
            if target > displayedBands[i] {
                displayedBands[i] += (target - displayedBands[i]) * 0.8
            } else {
                displayedBands[i] = max(target, displayedBands[i] * 0.88)
            }
        }

        let bassEnd = min(10, raw.count)
        var flux: Float = 0
        for i in 0..<bassEnd {
            flux += max(0, raw[i] - previousRaw[i])
        }
        previousRaw = raw

        let (isBeat, intensity) = beatDetector.detect(flux: flux, at: ProcessInfo.processInfo.systemUptime)
        beatPulse *= 0.87
        if isBeat { beatPulse = max(beatPulse, 0.55 + 0.45 * intensity) }

        let n = displayedBands.count
        let bassAvg = displayedBands[0..<min(10, n)].reduce(0, +) / Float(max(1, min(10, n)))
        let midAvg = n > 10 ? displayedBands[10..<min(20, n)].reduce(0, +) / Float(min(20, n) - 10) : 0
        let trebleAvg = n > 20 ? displayedBands[20..<n].reduce(0, +) / Float(n - 20) : 0
        let level = (bassAvg + midAvg + trebleAvg) / 3
        phase += 0.004 + Double(level) * 0.03 + Double(beatPulse) * 0.025

        var smoothed = result
        smoothed.spectrumBands = displayedBands
        smoothed.isBeat = isBeat
        smoothed.beatIntensity = intensity
        smoothed.bass = bassAvg
        smoothed.mid = midAvg
        smoothed.treble = trebleAvg
        smoothed.beatPulse = beatPulse
        smoothed.phase = phase

        // Skip the publish once audio has fully decayed to silence and stayed there --
        // otherwise the UI keeps re-rendering ~40x/sec forever even with nothing to show.
        let isSilent = !isBeat && beatPulse < 0.01 && displayedBands.allSatisfy { $0 < 0.01 }
        if isSilent && wasSilent {
            return
        }
        wasSilent = isSilent
        smoothedResult = smoothed
    }
}
