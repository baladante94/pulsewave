import Accelerate
import AVFoundation

final class AudioAnalyzer {
    private let fftSize: Int
    private let log2n: vDSP_Length
    private let fftSetup: FFTSetup
    private let bandCount: Int
    private var window: [Float]

    private var ringBuffer: [Float] = []
    private var sampleRate: Double = 44100
    private var bandRanges: [(Int, Int)] = []

    private let queue = DispatchQueue(label: "audio.analysis", qos: .userInteractive)

    var onResult: ((AnalysisResult) -> Void)?

    init(fftSize: Int = 2048, bandCount: Int = 28) {
        self.fftSize = fftSize
        self.bandCount = bandCount
        self.log2n = vDSP_Length(round(log2(Double(fftSize))))
        self.fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))!
        self.window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
    }

    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }

    func reset() {
        queue.async { [weak self] in
            self?.ringBuffer.removeAll(keepingCapacity: true)
        }
    }

    func process(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        queue.async { [weak self] in
            self?.processInternal(buffer: buffer)
        }
    }

    private func processInternal(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        sampleRate = buffer.format.sampleRate
        let frameCount = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameCount))
        ringBuffer.append(contentsOf: samples)

        while ringBuffer.count >= fftSize {
            let windowSamples = Array(ringBuffer.prefix(fftSize))
            ringBuffer.removeFirst(fftSize / 2)
            let result = analyze(samples: windowSamples)
            DispatchQueue.main.async { [weak self] in
                self?.onResult?(result)
            }
        }

        if ringBuffer.count > fftSize * 4 {
            ringBuffer.removeFirst(ringBuffer.count - fftSize * 2)
        }
    }

    private func analyze(samples: [Float]) -> AnalysisResult {
        var windowed = [Float](repeating: 0, count: fftSize)
        vDSP_vmul(samples, 1, window, 1, &windowed, 1, vDSP_Length(fftSize))

        var realp = [Float](repeating: 0, count: fftSize / 2)
        var imagp = [Float](repeating: 0, count: fftSize / 2)
        var magnitudes = [Float](repeating: 0, count: fftSize / 2)

        realp.withUnsafeMutableBufferPointer { realPtr in
            imagp.withUnsafeMutableBufferPointer { imagPtr in
                var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
                windowed.withUnsafeBufferPointer { windowedPtr in
                    windowedPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: fftSize / 2) { complexPtr in
                        vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(fftSize / 2))
                    }
                }
                vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
                vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(fftSize / 2))
            }
        }

        var normalized = [Float](repeating: 0, count: fftSize / 2)
        var scale = Float(1.0 / Float(fftSize))
        vDSP_vsmul(magnitudes, 1, &scale, &normalized, 1, vDSP_Length(fftSize / 2))
        for i in 0..<normalized.count {
            normalized[i] = sqrt(normalized[i])
        }

        if bandRanges.count != bandCount {
            computeBandRanges(binCount: fftSize / 2)
        }

        var bands = [Float](repeating: 0, count: bandCount)
        for (i, range) in bandRanges.enumerated() {
            guard range.0 < range.1 else { continue }
            var sum: Float = 0
            for bin in range.0..<range.1 {
                sum += normalized[bin]
            }
            bands[i] = sum / Float(max(1, range.1 - range.0))
        }

        let overallEnergy = normalized.reduce(0, +) / Float(max(1, normalized.count))

        return AnalysisResult(
            spectrumBands: bands,
            timeDomainSamples: samples,
            overallEnergy: overallEnergy,
            isBeat: false,
            beatIntensity: 0
        )
    }

    private func computeBandRanges(binCount: Int) {
        let minFreq = 20.0
        let nyquist = sampleRate / 2
        let maxFreq = min(nyquist, 20000)
        let logMin = log2(minFreq)
        let logMax = log2(maxFreq)

        var ranges: [(Int, Int)] = []
        for i in 0..<bandCount {
            let f0 = pow(2, logMin + (logMax - logMin) * Double(i) / Double(bandCount))
            let f1 = pow(2, logMin + (logMax - logMin) * Double(i + 1) / Double(bandCount))
            let bin0 = max(0, min(binCount - 1, Int(f0 / nyquist * Double(binCount))))
            let bin1 = max(bin0 + 1, min(binCount, Int(f1 / nyquist * Double(binCount))))
            ranges.append((bin0, bin1))
        }
        bandRanges = ranges
    }
}
