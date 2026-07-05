import SwiftUI

final class MirrorBarsRenderer: VisualizerRenderer {
    let id = "mirror-bars"
    let displayName = "Mirror Bars"

    private let barSpacing: CGFloat = 4
    private let heightScale: CGFloat = 4

    func draw(context: inout GraphicsContext, size: CGSize, state: AnalysisResult, theme: ColorTheme) {
        drawBars(context: &context, size: size, bands: state.spectrumBands, theme: theme)
    }

    private func drawBars(context: inout GraphicsContext, size: CGSize, bands: [Float], theme: ColorTheme) {
        guard !bands.isEmpty else { return }
        let midY = size.height / 2
        let barCount = CGFloat(bands.count)
        let totalSpacing = barSpacing * (barCount - 1)
        let barWidth = max(2, (size.width - totalSpacing) / barCount)

        for (index, value) in bands.enumerated() {
            let halfHeight = max(1, min(midY, CGFloat(value) * size.height * heightScale))
            let x = CGFloat(index) * (barWidth + barSpacing)
            let rect = CGRect(x: x, y: midY - halfHeight, width: barWidth, height: halfHeight * 2)
            let color = theme.color(forIndex: index, count: bands.count)
            context.fill(Path(roundedRect: rect, cornerRadius: barWidth / 3), with: .color(color))
        }
    }
}
