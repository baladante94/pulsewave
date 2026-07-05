import SwiftUI

@main
struct AudioVisualiserApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(
                viewModel: appDelegate.viewModel,
                audioSourceManager: appDelegate.audioSourceManager,
                menuBarController: appDelegate.menuBarController
            )
            .frame(minWidth: 480, minHeight: 360)
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
