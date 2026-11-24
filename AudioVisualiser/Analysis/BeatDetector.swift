import Foundation

/// Onset detector on bass spectral flux: fires when flux rises well above its recent mean + spread,
/// so it follows the groove rather than one loud peak.
final class BeatDetector {
    private var history: [Float] = []
    private let historySize: Int
    private let k: Float
    private let refractoryPeriod: TimeInterval
    private let minimumFlux: Float
    private var lastBeatTime: TimeInterval = -.infinity

    init(historySize: Int = 60, k: Float = 1.3, refractoryPeriod: TimeInterval = 0.2, minimumFlux: Float = 0.25) {
        self.historySize = historySize
        self.k = k
        self.refractoryPeriod = refractoryPeriod
        self.minimumFlux = minimumFlux
    }

    func detect(flux: Float, at time: TimeInterval) -> (isBeat: Bool, intensity: Float) {
        let mean = history.isEmpty ? 0 : history.reduce(0, +) / Float(history.count)
        let variance = history.isEmpty ? 0 : history.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Float(history.count)
        history.append(flux)
        if history.count > historySize { history.removeFirst() }

        let threshold = max(mean + k * sqrt(variance), minimumFlux)
        guard flux > threshold, time - lastBeatTime > refractoryPeriod else { return (false, 0) }
        lastBeatTime = time
        return (true, min(1, 0.5 + (flux - threshold) / threshold))
    }
}
