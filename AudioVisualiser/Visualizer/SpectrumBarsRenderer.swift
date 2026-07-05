import SwiftUI

final class SpectrumBarsRenderer: VisualizerRenderer {
    let id = "spectrum-bars"
    let displayName = "Spectrum Bars"

    private let barSpacing: CGFloat = 4
    private let maxBarWidth: CGFloat = 10
    private let heightScale: CGFloat = 0.92

    func draw(context: inout GraphicsContext, size: CGSize, state: AnalysisResult, particles: ParticleSystem) {
        drawBars(context: &context, size: size, bands: state.spectrumBands)
        context.drawParticles(particles)
    }

    private func drawBars(context: inout GraphicsContext, size: CGSize, bands: [Float]) {
        guard !bands.isEmpty else { return }
        let barCount = CGFloat(bands.count)
        let totalSpacing = barSpacing * (barCount - 1)
        let barWidth = min(maxBarWidth, max(2, (size.width - totalSpacing) / barCount))
        let contentWidth = barWidth * barCount + totalSpacing
        let startX = max(0, (size.width - contentWidth) / 2)

        for (index, value) in bands.enumerated() {
            let barHeight = max(2, min(size.height, CGFloat(value) * size.height * heightScale))
            let x = startX + CGFloat(index) * (barWidth + barSpacing)
            let rect = CGRect(x: x, y: size.height - barHeight, width: barWidth, height: barHeight)
            let hue = 0.55 + (Double(index) / Double(bands.count)) * 0.3
            let color = Color(hue: hue, saturation: 0.7, brightness: 0.95)
            context.fill(Path(roundedRect: rect, cornerRadius: barWidth / 3), with: .color(color))
        }
    }
}
