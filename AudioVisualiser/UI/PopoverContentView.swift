import AppKit
import SwiftUI

struct PopoverContentView: View {
    @ObservedObject var viewModel: VisualizerViewModel
    @ObservedObject var audioSourceManager: AudioSourceManager
    @ObservedObject var menuBarController: MenuBarController
    @ObservedObject var nowPlayingManager: NowPlayingManager

    var body: some View {
        VStack(spacing: 10) {
            NowPlayingView(manager: nowPlayingManager)

            ControlsPanel(
                sourceKind: audioSourceManager.currentKind,
                activeRendererID: viewModel.activeRenderer.id,
                colorTheme: viewModel.colorTheme,
                lastError: audioSourceManager.lastError,
                isMenuBarEnabled: menuBarController.isEnabled,
                menuBarSize: menuBarController.size,
                menuBarColorTheme: menuBarController.colorTheme,
                compact: true,
                renderers: viewModel.availableRenderers,
                sourceBinding: sourceBinding,
                rendererBinding: rendererBinding,
                colorThemeBinding: $viewModel.colorTheme,
                menuBarEnabledBinding: $menuBarController.isEnabled,
                menuBarSizeBinding: $menuBarController.size,
                menuBarColorThemeBinding: $menuBarController.colorTheme
            )
            .equatable()

            HStack {
                Button("Open Main Window") {
                    menuBarController.showMainWindow()
                }
                Button("Open Full Screen") {
                    menuBarController.openFullScreenAndClosePopover()
                }
            }
            .frame(maxWidth: .infinity)

            Button("Quit Pulsewave") {
                NSApp.terminate(nil)
            }
            .foregroundStyle(.red)
        }
        .padding(12)
        .frame(width: 280)
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
