import AppKit
import SwiftUI

struct PopoverContentView: View {
    @ObservedObject var viewModel: VisualizerViewModel
    @ObservedObject var audioSourceManager: AudioSourceManager
    @ObservedObject var menuBarController: MenuBarController

    var body: some View {
        VStack(spacing: 10) {
            VisualizerView(viewModel: viewModel)
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Picker("Source", selection: sourceBinding) {
                ForEach(AudioSourceKind.allCases) { kind in
                    Text(kind.displayName).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            Picker("Style", selection: rendererBinding) {
                ForEach(viewModel.availableRenderers, id: \.id) { renderer in
                    Text(renderer.displayName).tag(renderer.id)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

            Picker("Colors", selection: $viewModel.colorTheme) {
                ForEach(ColorTheme.allCases) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

            if let error = audioSourceManager.lastError {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }

            Toggle("Show in menu bar", isOn: $menuBarController.isEnabled)
                .toggleStyle(.switch)

            if menuBarController.isEnabled {
                Picker("Menu Bar Size", selection: $menuBarController.size) {
                    ForEach(MenuBarVisualizerSize.allCases) { size in
                        Text(size.displayName).tag(size)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Menu Bar Colors", selection: $menuBarController.colorTheme) {
                    ForEach(ColorTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Button("Open Main Window") {
                    menuBarController.showMainWindow()
                }
                Button("Open Full Screen") {
                    menuBarController.openFullScreenAndClosePopover()
                }
            }
            .frame(maxWidth: .infinity)

            Button("Quit AudioVisualiser") {
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
