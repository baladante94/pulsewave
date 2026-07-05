import SwiftUI

@main
struct AudioVisualiserApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var audioSourceManager: AudioSourceManager
    @StateObject private var viewModel: VisualizerViewModel

    init() {
        let manager = AudioSourceManager()
        _audioSourceManager = StateObject(wrappedValue: manager)
        _viewModel = StateObject(wrappedValue: VisualizerViewModel(audioSourceManager: manager))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel, audioSourceManager: audioSourceManager)
                .frame(minWidth: 480, minHeight: 320)
        }
    }
}
