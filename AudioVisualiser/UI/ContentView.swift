import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: VisualizerViewModel
    @ObservedObject var audioSourceManager: AudioSourceManager
    @ObservedObject var menuBarController: MenuBarController
    @ObservedObject var nowPlayingManager: NowPlayingManager

    @State private var isFullScreen = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            VisualizerView(viewModel: viewModel)

            if !isFullScreen {
            VStack(alignment: .leading, spacing: 8) {
                NowPlayingView(manager: nowPlayingManager)
                    .frame(width: 260)

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
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEnterFullScreenNotification)) { _ in isFullScreen = true }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didExitFullScreenNotification)) { _ in isFullScreen = false }
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
