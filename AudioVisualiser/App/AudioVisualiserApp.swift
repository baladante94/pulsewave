import SwiftUI

@main
struct AudioVisualiserApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: appDelegate.viewModel, audioSourceManager: appDelegate.audioSourceManager)
                .frame(minWidth: 480, minHeight: 320)
        }
        .commands {
            CommandGroup(after: .windowArrangement) {
                Button("Enter Full Screen Visualizer") {
                    appDelegate.showFullScreen()
                }
                .keyboardShortcut("f", modifiers: [.command])
            }
        }
    }
}
