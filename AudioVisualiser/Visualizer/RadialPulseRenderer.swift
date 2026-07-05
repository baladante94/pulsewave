import SwiftUI

final class RadialPulseRenderer: VisualizerRenderer {
    let id = "radial-pulse"
    let displayName = "Radial Pulse"

    func draw(context: inout GraphicsContext, size: CGSize, state: AnalysisResult, theme: ColorTheme) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let maxRadius = min(size.width, size.height) / 2 - 10
        let baseRadius = maxRadius * 0.35
        let energyBoost = CGFloat(min(state.overallEnergy * 40, 1)) * maxRadius * 0.4
        let beatBoost = state.isBeat ? CGFloat(state.beatIntensity) * maxRadius * 0.25 : 0
        let radius = baseRadius + energyBoost + beatBoost

        let ringColor = theme.color(forIndex: 0, count: 2)
        context.stroke(
            Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
            with: .color(ringColor),
            lineWidth: 3
        )

        let bandCount = state.spectrumBands.count
        guard bandCount > 0 else { return }
        for (index, value) in state.spectrumBands.enumerated() {
            let angle = (Double(index) / Double(bandCount)) * 2 * .pi
            let dotRadius = radius + CGFloat(value) * maxRadius * 0.6
            let point = CGPoint(
                x: center.x + cos(angle) * dotRadius,
                y: center.y + sin(angle) * dotRadius
            )
            let dotSize: CGFloat = 4
            context.fill(
                Path(ellipseIn: CGRect(x: point.x - dotSize / 2, y: point.y - dotSize / 2, width: dotSize, height: dotSize)),
                with: .color(theme.color(forIndex: index, count: bandCount))
            )
        }
    }
}
