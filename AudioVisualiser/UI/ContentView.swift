import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: VisualizerViewModel
    @ObservedObject var audioSourceManager: AudioSourceManager
    @ObservedObject var menuBarController: MenuBarController

    var body: some View {
        ZStack(alignment: .topLeading) {
            VisualizerView(viewModel: viewModel)

            VStack(alignment: .leading, spacing: 8) {
                ControlsPanel(
                    sourceKind: audioSourceManager.currentKind,
                    activeRendererID: viewModel.activeRenderer.id,
                    colorTheme: viewModel.colorTheme,
                    lastError: audioSourceManager.lastError,
                    isMenuBarEnabled: menuBarController.isEnabled,
                    menuBarSize: menuBarController.size,
                    menuBarColorTheme: menuBarController.colorTheme,
                    compact: false,
                    renderers: viewModel.availableRenderers,
                    sourceBinding: sourceBinding,
                    rendererBinding: rendererBinding,
                    colorThemeBinding: $viewModel.colorTheme,
                    menuBarEnabledBinding: $menuBarController.isEnabled,
                    menuBarSizeBinding: $menuBarController.size,
                    menuBarColorThemeBinding: $menuBarController.colorTheme
                )
                .equatable()
            }
            .padding()
        }
    }

    private var sourceBinding: Binding<AudioSourceKind> {
        Binding(
            get: { audioSourceManager.currentKind },
            set: { newValue in
                Task { await audioSourceManager.switchTo(newValue) }
            }
        )
    }

    private var rendererBinding: Binding<String> {
        Binding(
            get: { viewModel.activeRenderer.id },
            set: { newValue in viewModel.selectRenderer(id: newValue) }
        )
    }
}
