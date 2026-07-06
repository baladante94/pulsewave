import SwiftUI

@main
struct PulsewaveApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(after: .windowArrangement) {
                Button("Enter Full Screen Visualizer") {
                    appDelegate.showFullScreen()
                }
                .keyboardShortcut("f", modifiers: [.command])

                Button("Show Main Window") {
                    appDelegate.showMainWindow()
                }
                .keyboardShortcut("m", modifiers: [.command])
            }
        }
    }
}
