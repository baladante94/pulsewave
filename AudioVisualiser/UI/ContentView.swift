import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: VisualizerViewModel
    @ObservedObject var audioSourceManager: AudioSourceManager
    @ObservedObject var menuBarController: MenuBarController

    var body: some View {
        ZStack(alignment: .topLeading) {
            VisualizerView(viewModel: viewModel)

            VStack(alignment: .leading, spacing: 8) {
                Picker("Source", selection: sourceBinding) {
                    ForEach(AudioSourceKind.allCases) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 260)

                Picker("Style", selection: rendererBinding) {
                    ForEach(viewModel.availableRenderers, id: \.id) { renderer in
                        Text(renderer.displayName).tag(renderer.id)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 180)

                if let error = audioSourceManager.lastError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Divider()
                    .frame(width: 260)

                Toggle("Show in menu bar", isOn: $menuBarController.isEnabled)
                    .toggleStyle(.switch)

                if menuBarController.isEnabled {
                    Picker("Menu Bar Size", selection: $menuBarController.size) {
                        ForEach(MenuBarVisualizerSize.allCases) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 260)

                    Picker("Colors", selection: $menuBarController.colorMode) {
                        ForEach(MenuBarColorMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 180)
                }
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
