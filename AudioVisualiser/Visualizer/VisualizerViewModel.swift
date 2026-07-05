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

    init(audioSourceManager: AudioSourceManager) {
        self.audioSourceManager = audioSourceManager
        self.activeRenderer = SpectrumBarsRenderer()
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
        if displayedBands.count != result.spectrumBands.count {
            displayedBands = result.spectrumBands
        } else {
            for i in displayedBands.indices {
                displayedBands[i] = max(result.spectrumBands[i], displayedBands[i] * 0.85)
            }
        }

        let (isBeat, intensity) = beatDetector.detect(
            energy: result.overallEnergy,
            at: ProcessInfo.processInfo.systemUptime
        )

        var smoothed = result
        smoothed.spectrumBands = displayedBands
        smoothed.isBeat = isBeat
        smoothed.beatIntensity = intensity
        smoothedResult = smoothed
    }
}
