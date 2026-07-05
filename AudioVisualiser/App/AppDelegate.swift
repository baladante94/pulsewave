import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let audioSourceManager = AudioSourceManager()
    lazy var viewModel = VisualizerViewModel(audioSourceManager: audioSourceManager)
    lazy var menuBarController = MenuBarController(
        viewModel: viewModel,
        audioSourceManager: audioSourceManager,
        onOpenFullScreen: { [weak self] in self?.showFullScreen() }
    )

    private var fullScreenController: FullScreenWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        _ = menuBarController

        Task { await audioSourceManager.start() }
    }

    func showFullScreen() {
        if fullScreenController == nil {
            fullScreenController = FullScreenWindowController(viewModel: viewModel)
        }
        fullScreenController?.show()
    }
}
