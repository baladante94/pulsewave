import SwiftUI

final class DotGridRenderer: VisualizerRenderer {
    let id = "dot-grid"
    let displayName = "Dot Grid"

    private let rows = 12

    func draw(context: inout GraphicsContext, size: CGSize, state: AnalysisResult, particles: ParticleSystem) {
        let bands = state.spectrumBands
        guard !bands.isEmpty else { return }

        let columns = bands.count
        let cellWidth = size.width / CGFloat(columns)
        let cellHeight = size.height / CGFloat(rows)
        let beatFlash = state.isBeat ? Double(state.beatIntensity) : 0

        for column in 0..<columns {
            let value = CGFloat(bands[column])
            let litRows = Int(value * CGFloat(rows) * 6)
            let hue = 0.55 + (Double(column) / Double(columns)) * 0.35

            for row in 0..<rows {
                let rowFromBottom = rows - 1 - row
                let isLit = rowFromBottom < litRows
                let x = CGFloat(column) * cellWidth + cellWidth / 2
                let y = CGFloat(row) * cellHeight + cellHeight / 2
                let dotSize = min(cellWidth, cellHeight) * 0.6
                let brightness = (isLit ? 1.0 : 0.12) + beatFlash * 0.25
                let color = Color(hue: hue, saturation: 0.8, brightness: min(brightness, 1))

                context.fill(
                    Path(ellipseIn: CGRect(x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize)),
                    with: .color(color)
                )
            }
        }

        context.drawParticles(particles)
    }
}
