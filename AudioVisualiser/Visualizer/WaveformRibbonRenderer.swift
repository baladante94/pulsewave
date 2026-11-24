import SwiftUI

final class WaveformRibbonRenderer: VisualizerRenderer {
    let id = "waveform-ribbon"
    let displayName = "Waveform Ribbon"

    func draw(context: inout GraphicsContext, size: CGSize, state: AnalysisResult, theme: ColorTheme) {
        drawWaveform(context: &context, size: size, state: state, theme: theme)
    }

    private func drawWaveform(context: inout GraphicsContext, size: CGSize, state: AnalysisResult, theme: ColorTheme) {
        let samples = state.timeDomainSamples
        guard samples.count > 1 else { return }

        let midY = size.height / 2
        let peak = samples.reduce(0) { max($0, abs($1)) }
        let gain = peak < 0.004 ? 0 : min(10, 0.7 / peak)
        let step = size.width / CGFloat(samples.count - 1)
        var path = Path()
        for (index, sample) in samples.enumerated() {
            let x = CGFloat(index) * step
            let y = midY - CGFloat(sample * gain) * midY
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        let beatGlow = CGFloat(state.beatPulse)
        let color = theme.color(forIndex: 0, count: 2)
        context.stroke(path, with: .color(color.opacity(0.9)), lineWidth: 2 + beatGlow * 4)
        context.stroke(path, with: .color(color.opacity(0.35)), lineWidth: 6 + beatGlow * 10)
    }
}
