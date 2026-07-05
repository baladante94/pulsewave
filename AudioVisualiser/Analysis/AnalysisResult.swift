import Foundation

struct AnalysisResult {
    var spectrumBands: [Float]
    var timeDomainSamples: [Float]
    var overallEnergy: Float
    var isBeat: Bool
    var beatIntensity: Float

    static let empty = AnalysisResult(
        spectrumBands: Array(repeating: 0, count: 28),
        timeDomainSamples: [],
        overallEnergy: 0,
        isBeat: false,
        beatIntensity: 0
    )
}
