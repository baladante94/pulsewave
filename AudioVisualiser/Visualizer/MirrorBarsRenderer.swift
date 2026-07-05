import SwiftUI

final class MirrorBarsRenderer: VisualizerRenderer {
    let id = "mirror-bars"
    let displayName = "Mirror Bars"

    private let barSpacing: CGFloat = 4
    private let maxBarWidth: CGFloat = 10
    private let heightScale: CGFloat = 0.92

    func draw(context: inout GraphicsContext, size: CGSize, state: AnalysisResult, particles: ParticleSystem) {
        drawBars(context: &context, size: size, bands: state.spectrumBands)
        context.drawParticles(particles)
    }

    private func drawBars(context: inout GraphicsContext, size: CGSize, bands: [Float]) {
        guard !bands.isEmpty else { return }
        let midY = size.height / 2
        let barCount = CGFloat(bands.count)
        let totalSpacing = barSpacing * (barCount - 1)
        let barWidth = min(maxBarWidth, max(2, (size.width - totalSpacing) / barCount))
        let contentWidth = barWidth * barCount + totalSpacing
        let startX = max(0, (size.width - contentWidth) / 2)

        for (index, value) in bands.enumerated() {
            let halfHeight = max(1, min(midY, CGFloat(value) * midY * heightScale))
            let x = startX + CGFloat(index) * (barWidth + barSpacing)
            let rect = CGRect(x: x, y: midY - halfHeight, width: barWidth, height: halfHeight * 2)
            let hue = 0.5 + (Double(index) / Double(bands.count)) * 0.4
            let color = Color(hue: hue, saturation: 0.75, brightness: 0.95)
            context.fill(Path(roundedRect: rect, cornerRadius: barWidth / 3), with: .color(color))
        }
    }
}
