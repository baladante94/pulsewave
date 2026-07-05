import Combine
import Foundation

@MainActor
final class VisualizerViewModel: ObservableObject {
    @Published private(set) var smoothedResult: AnalysisResult = .empty
    @Published var activeRenderer: VisualizerRenderer

    let particleSystem = ParticleSystem()
    let audioSourceManager: AudioSourceManager

    private let analyzer = AudioAnalyzer()
    private var displayedBands: [Float] = []
    private var bufferSubscription: AnyCancellable?
    private var lastTickDate: Date?

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

    private func handle(_ result: AnalysisResult) {
        if displayedBands.count != result.spectrumBands.count {
            displayedBands = result.spectrumBands
        } else {
            for i in displayedBands.indices {
                displayedBands[i] = max(result.spectrumBands[i], displayedBands[i] * 0.85)
            }
        }

        var smoothed = result
        smoothed.spectrumBands = displayedBands
        smoothedResult = smoothed
    }
}
