import Foundation

final class BeatDetector {
    private var energyHistory: [Float] = []
    private let historySize: Int
    private let sensitivity: Float
    private let refractoryPeriod: TimeInterval
    private let minimumEnergy: Float
    private var lastBeatTime: TimeInterval = -.infinity

    init(historySize: Int = 43, sensitivity: Float = 1.4, refractoryPeriod: TimeInterval = 0.12, minimumEnergy: Float = 0.0005) {
        self.historySize = historySize
        self.sensitivity = sensitivity
        self.refractoryPeriod = refractoryPeriod
        self.minimumEnergy = minimumEnergy
    }

    func detect(energy: Float, at time: TimeInterval) -> (isBeat: Bool, intensity: Float) {
        let localAverage = energyHistory.isEmpty ? energy : energyHistory.reduce(0, +) / Float(energyHistory.count)

        energyHistory.append(energy)
        if energyHistory.count > historySize {
            energyHistory.removeFirst()
        }

        let threshold = max(localAverage * sensitivity, minimumEnergy)
        let sinceLastBeat = time - lastBeatTime
        guard energy > threshold, sinceLastBeat > refractoryPeriod else {
            return (false, 0)
        }

        lastBeatTime = time
        let intensity = min(1.0, (energy - threshold) / max(threshold, minimumEnergy))
        return (true, intensity)
    }
}
