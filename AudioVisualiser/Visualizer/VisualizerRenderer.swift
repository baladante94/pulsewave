import SwiftUI

protocol VisualizerRenderer: AnyObject {
    var id: String { get }
    var displayName: String { get }
    func draw(context: inout GraphicsContext, size: CGSize, state: AnalysisResult, particles: ParticleSystem, theme: ColorTheme)
}

extension GraphicsContext {
    mutating func drawParticles(_ particles: ParticleSystem) {
        for particle in particles.particles {
            let rect = CGRect(
                x: particle.position.x - particle.size / 2,
                y: particle.position.y - particle.size / 2,
                width: particle.size,
                height: particle.size
            )
            let color = Color(red: particle.color.r, green: particle.color.g, blue: particle.color.b, opacity: particle.alpha)
            fill(Path(ellipseIn: rect), with: .color(color))
        }
    }
}
