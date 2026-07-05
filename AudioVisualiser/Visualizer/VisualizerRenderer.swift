import SwiftUI

protocol VisualizerRenderer: AnyObject {
    var id: String { get }
    var displayName: String { get }
    func draw(context: inout GraphicsContext, size: CGSize, state: AnalysisResult, particles: ParticleSystem)
}
