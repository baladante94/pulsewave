import SwiftUI

final class TrippyRenderer: VisualizerRenderer {
    let id = "trippy"
    let displayName = "Trippy Tunnel"

    private let ringCount = 18
    private let pointCount = 120
    private let symmetry = 6.0

    func draw(context: inout GraphicsContext, size: CGSize, state: AnalysisResult, theme: ColorTheme) {
        let bands = state.spectrumBands
        guard bands.count > 1 else { return }

        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let maxRadius = hypot(size.width, size.height) / 2
        let phase = state.phase
        let pulse = CGFloat(state.beatPulse)
        let bass = CGFloat(state.bass)

        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .radialGradient(
                Gradient(colors: [theme.color(forIndex: 0, count: 2).opacity(Double(pulse) * 0.35), .clear]),
                center: center, startRadius: 0, endRadius: maxRadius * 0.8
            )
        )

        context.blendMode = .plusLighter

        for k in 0..<ringCount {
            let t = (phase * 0.35 + Double(k) / Double(ringCount)).truncatingRemainder(dividingBy: 1)
            let depth = CGFloat(pow(t, 2.2))
            let baseRadius = maxRadius * (0.04 + depth * 1.05) * (1 + pulse * 0.12)
            let spin = phase * (k.isMultiple(of: 2) ? 1 : -1) * 0.6
            let wobbleAmount = 0.10 + 0.55 * (1 - depth * 0.4)

            var path = Path()
            for p in 0...pointCount {
                let a = Double(p) / Double(pointCount) * 2 * .pi
                let x = a / (2 * .pi) * symmetry + spin / (2 * .pi)
                let fold = min(1, max(0, abs((x - x.rounded(.down)) * 2 - 1)))
                let value = interpolate(bands, at: Double(fold) * Double(bands.count - 1))
                let ripple = sin(a * 3 + phase * 2 + Double(k) * 0.5) * 0.02
                let r = baseRadius * (1 + CGFloat(value) * wobbleAmount + CGFloat(ripple))
                let point = CGPoint(x: center.x + cos(a + spin) * r, y: center.y + sin(a + spin) * r)
                if p == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()

            let color = theme.color(forIndex: (k + Int(phase * 6)) % ringCount, count: ringCount)
            let alpha = Double(min(1, (1 - t) * 1.4)) * Double(min(1, t * 8))
            let width = 1.5 + depth * 5 + pulse * 3
            context.stroke(path, with: .color(color.opacity(alpha * 0.9)), lineWidth: width)
            context.stroke(path, with: .color(color.opacity(alpha * 0.18)), lineWidth: width * 4)
        }

        let spokeCount = bands.count
        for i in 0..<spokeCount {
            let value = CGFloat(bands[i])
            let a = Double(i) / Double(spokeCount) * 2 * .pi - phase * 0.8
            let inner = maxRadius * 0.08 * (1 + bass * 1.5)
            let outer = inner + value * maxRadius * 0.42
            var spoke = Path()
            spoke.move(to: CGPoint(x: center.x + cos(a) * inner, y: center.y + sin(a) * inner))
            spoke.addLine(to: CGPoint(x: center.x + cos(a) * outer, y: center.y + sin(a) * outer))
            let color = theme.color(forIndex: i, count: spokeCount)
            context.stroke(spoke, with: .color(color.opacity(0.85)), style: StrokeStyle(lineWidth: 3 + value * 5, lineCap: .round))
        }

        let orb = maxRadius * (0.05 + bass * 0.10 + pulse * 0.08)
        context.fill(
            Path(ellipseIn: CGRect(x: center.x - orb, y: center.y - orb, width: orb * 2, height: orb * 2)),
            with: .radialGradient(
                Gradient(colors: [.white.opacity(0.95), theme.color(forIndex: 0, count: 2).opacity(0.6), .clear]),
                center: center, startRadius: 0, endRadius: orb * 1.6
            )
        )
    }

    private func interpolate(_ values: [Float], at position: Double) -> Float {
        let position = min(max(position, 0), Double(values.count - 1))
        let i = Int(position)
        let j = min(values.count - 1, i + 1)
        let f = Float(position - Double(i))
        return values[i] * (1 - f) + values[j] * f
    }
}
