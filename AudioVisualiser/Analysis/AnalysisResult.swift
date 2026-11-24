import Foundation

struct AnalysisResult {
    var spectrumBands: [Float]
    var timeDomainSamples: [Float]
    var overallEnergy: Float
    var isBeat: Bool
    var beatIntensity: Float
    var bass: Float = 0
    var mid: Float = 0
    var treble: Float = 0
    var beatPulse: Float = 0
    var phase: Double = 0

    static let empty = AnalysisResult(
        spectrumBands: Array(repeating: 0, count: 28),
        timeDomainSamples: [],
        overallEnergy: 0,
        isBeat: false,
        beatIntensity: 0
    )
}
