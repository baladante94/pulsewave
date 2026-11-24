import SwiftUI

final class SpectrumBarsRenderer: VisualizerRenderer {
    let id = "spectrum-bars"
    let displayName = "Spectrum Bars"

    private let barSpacing: CGFloat = 4

    func draw(context: inout GraphicsContext, size: CGSize, state: AnalysisResult, theme: ColorTheme) {
        drawBars(context: &context, size: size, bands: state.spectrumBands, theme: theme)
    }

    private func drawBars(context: inout GraphicsContext, size: CGSize, bands: [Float], theme: ColorTheme) {
        guard !bands.isEmpty else { return }
        let barCount = CGFloat(bands.count)
        let totalSpacing = barSpacing * (barCount - 1)
        let barWidth = max(2, (size.width - totalSpacing) / barCount)

        for (index, value) in bands.enumerated() {
            let barHeight = max(2, min(size.height, CGFloat(value) * size.height * 0.95))
            let x = CGFloat(index) * (barWidth + barSpacing)
            let rect = CGRect(x: x, y: size.height - barHeight, width: barWidth, height: barHeight)
            let color = theme.color(forIndex: index, count: bands.count)
            context.fill(Path(roundedRect: rect, cornerRadius: barWidth / 3), with: .color(color))
        }
    }
}
