import SwiftUI

final class DotGridRenderer: VisualizerRenderer {
    let id = "dot-grid"
    let displayName = "Dot Grid"

    private let rows = 12

    func draw(context: inout GraphicsContext, size: CGSize, state: AnalysisResult, theme: ColorTheme) {
        let bands = state.spectrumBands
        guard !bands.isEmpty else { return }

        let columns = bands.count
        let cellWidth = size.width / CGFloat(columns)
        let cellHeight = size.height / CGFloat(rows)
        let beatFlash = Double(state.beatPulse)

        for column in 0..<columns {
            let value = CGFloat(bands[column])
            let litRows = Int((value * CGFloat(rows)).rounded())
            let baseColor = theme.color(forIndex: column, count: columns)

            for row in 0..<rows {
                let rowFromBottom = rows - 1 - row
                let isLit = rowFromBottom < litRows
                let x = CGFloat(column) * cellWidth + cellWidth / 2
                let y = CGFloat(row) * cellHeight + cellHeight / 2
                let dotSize = min(cellWidth, cellHeight) * 0.6
                let opacity = min(1, (isLit ? 1.0 : 0.12) + beatFlash * 0.25)

                context.fill(
                    Path(ellipseIn: CGRect(x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize)),
                    with: .color(baseColor.opacity(opacity))
                )
            }
        }
    }
}
