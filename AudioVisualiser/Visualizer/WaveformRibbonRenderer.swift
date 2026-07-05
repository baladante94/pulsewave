import SwiftUI

final class WaveformRibbonRenderer: VisualizerRenderer {
    let id = "waveform-ribbon"
    let displayName = "Waveform Ribbon"

    func draw(context: inout GraphicsContext, size: CGSize, state: AnalysisResult, particles: ParticleSystem) {
        drawWaveform(context: &context, size: size, state: state)
        context.drawParticles(particles)
    }

    private func drawWaveform(context: inout GraphicsContext, size: CGSize, state: AnalysisResult) {
        let samples = state.timeDomainSamples
        guard samples.count > 1 else { return }

        let midY = size.height / 2
        let step = size.width / CGFloat(samples.count - 1)
        var path = Path()
        for (index, sample) in samples.enumerated() {
            let x = CGFloat(index) * step
            let y = midY - CGFloat(sample) * midY * 3.5
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        let beatGlow = state.isBeat ? CGFloat(state.beatIntensity) : 0
        let color = Color(hue: 0.52, saturation: 0.75, brightness: 1)
        context.stroke(path, with: .color(color.opacity(0.9)), lineWidth: 2 + beatGlow * 4)
        context.stroke(path, with: .color(color.opacity(0.35)), lineWidth: 6 + beatGlow * 10)
    }
}
