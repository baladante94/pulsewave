import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let audioSourceManager = AudioSourceManager()
    lazy var viewModel = VisualizerViewModel(audioSourceManager: audioSourceManager)
    let nowPlayingManager = NowPlayingManager()
    lazy var menuBarController = MenuBarController(
        viewModel: viewModel,
        audioSourceManager: audioSourceManager,
        nowPlayingManager: nowPlayingManager,
        onOpenFullScreen: { [weak self] in self?.showFullScreen() },
        onOpenMainWindow: { [weak self] in self?.showMainWindow() }
    )

    private var fullScreenController: FullScreenWindowController?
    private lazy var mainWindowController = MainWindowController(
        viewModel: viewModel,
        audioSourceManager: audioSourceManager,
        menuBarController: menuBarController,
        nowPlayingManager: nowPlayingManager,
        onVisibilityChange: { [weak self] visible in
            NSApp.setActivationPolicy(visible ? .regular : .accessory)
        }
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        _ = menuBarController
        mainWindowController.show()

        Task { await audioSourceManager.start() }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func showFullScreen() {
        if fullScreenController == nil {
            fullScreenController = FullScreenWindowController(viewModel: viewModel)
        }
        fullScreenController?.show()
    }

    func showMainWindow() {
        mainWindowController.show()
    }
}
