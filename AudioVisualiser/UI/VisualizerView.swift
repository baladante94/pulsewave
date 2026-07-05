import SwiftUI

struct VisualizerView: View {
    @ObservedObject var viewModel: VisualizerViewModel

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { _ in
            Canvas { context, size in
                viewModel.tick()
                viewModel.updateCanvasSize(size)
                viewModel.activeRenderer.draw(
                    context: &context,
                    size: size,
                    state: viewModel.smoothedResult,
                    particles: viewModel.particleSystem,
                    theme: viewModel.colorTheme
                )
            }
            .background(Color.black)
        }
    }
}
