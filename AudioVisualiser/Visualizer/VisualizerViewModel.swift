import Combine
import CoreGraphics
import Foundation

@MainActor
final class VisualizerViewModel: ObservableObject {
    @Published private(set) var smoothedResult: AnalysisResult = .empty
    @Published var activeRenderer: VisualizerRenderer

    let particleSystem = ParticleSystem()
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
    private var lastTickDate: Date?
    private var lastKnownSize = CGSize(width: 400, height: 300)

    init(audioSourceManager: AudioSourceManager) {
        self.audioSourceManager = audioSourceManager
        self.activeRenderer = SpectrumBarsRenderer()

        analyzer.onResult = { [weak self] result in
            self?.handle(result)
        }
        bufferSubscription = audioSourceManager.bufferPublisher.sink { [weak self] buffer, time in
            self?.analyzer.process(buffer: buffer, time: time)
        }
    }

    func tick() {
        let now = Date()
        let deltaTime = lastTickDate.map { now.timeIntervalSince($0) } ?? (1.0 / 60.0)
        lastTickDate = now
        particleSystem.update(deltaTime: deltaTime)
    }

    func updateCanvasSize(_ size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        lastKnownSize = size
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

        if isBeat {
            let spawnPoint = CGPoint(x: lastKnownSize.width / 2, y: lastKnownSize.height * 0.85)
            particleSystem.spawnBurst(at: spawnPoint, intensity: intensity)
        }

        var smoothed = result
        smoothed.spectrumBands = displayedBands
        smoothed.isBeat = isBeat
        smoothed.beatIntensity = intensity
        smoothedResult = smoothed
    }
}
