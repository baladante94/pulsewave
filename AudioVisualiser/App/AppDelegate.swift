import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let audioSourceManager = AudioSourceManager()
    lazy var viewModel = VisualizerViewModel(audioSourceManager: audioSourceManager)

    private var menuBarController: MenuBarController?
    private var fullScreenController: FullScreenWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        menuBarController = MenuBarController(
            viewModel: viewModel,
            audioSourceManager: audioSourceManager,
            onOpenFullScreen: { [weak self] in self?.showFullScreen() }
        )

        Task { await audioSourceManager.start() }
    }

    func showFullScreen() {
        if fullScreenController == nil {
            fullScreenController = FullScreenWindowController(viewModel: viewModel)
        }
        fullScreenController?.show()
    }
}
