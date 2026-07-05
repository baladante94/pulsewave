import CoreGraphics
import Foundation

struct Particle {
    var position: CGPoint
    var velocity: CGVector
    var size: CGFloat
    var age: Double = 0
    var lifetime: Double
    var color: (r: Double, g: Double, b: Double)

    var alpha: Double {
        max(0, 1 - age / lifetime)
    }
}

final class ParticleSystem {
    private(set) var particles: [Particle] = []

    func spawnBurst(at point: CGPoint, intensity: Float, count: Int = 14) {
        let clampedIntensity = CGFloat(max(0.2, min(intensity, 1.0)))
        for _ in 0..<count {
            let angle = Double.random(in: 0..<(2 * .pi))
            let speed = Double(60 + 220 * clampedIntensity) * Double.random(in: 0.5...1.2)
            let velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
            let particle = Particle(
                position: point,
                velocity: velocity,
                size: 2 + 4 * clampedIntensity * CGFloat.random(in: 0.6...1.4),
                lifetime: Double.random(in: 0.4...0.8),
                color: (r: 1.0, g: Double.random(in: 0.3...0.9), b: 1.0)
            )
            particles.append(particle)
        }
    }

    func update(deltaTime: TimeInterval) {
        guard deltaTime > 0 else { return }
        for i in particles.indices {
            particles[i].age += deltaTime
            particles[i].position.x += particles[i].velocity.dx * deltaTime
            particles[i].position.y += particles[i].velocity.dy * deltaTime
        }
        particles.removeAll { $0.age >= $0.lifetime }
    }
}
