import SwiftUI

struct VisualizerView: View {
    @ObservedObject var viewModel: VisualizerViewModel

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { _ in
            Canvas { context, size in
                viewModel.activeRenderer.draw(
                    context: &context,
                    size: size,
                    state: viewModel.smoothedResult,
                    theme: viewModel.colorTheme
                )
            }
            .background(Color.black)
        }
    }
}
