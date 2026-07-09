import AppKit
import Foundation

/// Reads "now playing" title/artist for Music.app and Spotify via AppleScript (both are
/// officially scriptable), falling back to the frontmost browser's active tab title for
/// things like a YouTube video -- there's no public API that exposes a browser tab's media
/// session. Playback is controlled by simulating the hardware media keys, which macOS routes
/// to whatever app currently owns the system's Now Playing session, so it works regardless of
/// which of the above is actually playing.
///
/// Note: direct access to the system-wide Now Playing info via the private MediaRemote
/// framework was tried first and rejected by mediaremoted with "Operation not permitted" --
/// confirmed via Console, not a bug in this app. Apple restricts that API to first-party/
/// entitled apps on this OS version, so this AppleScript + media-key approach is the fix.
@MainActor
final class NowPlayingManager: ObservableObject {
    @Published private(set) var title: String?
    @Published private(set) var artist: String?
    @Published private(set) var isPlaying = false

    private var refreshTimer: Timer?

    private static let musicBundleID = "com.apple.Music"
    private static let spotifyBundleID = "com.spotify.client"
    private static let browsers: [(name: String, bundleID: String, script: String)] = [
        ("Safari", "com.apple.Safari", "get name of current tab of front window"),
        ("Google Chrome", "com.google.Chrome", "get title of active tab of front window"),
        ("Microsoft Edge", "com.microsoft.edgemac", "get title of active tab of front window")
    ]

    init() {
        refresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.refresh() }
        }
    }

    func refresh() {
        if isRunning(Self.musicBundleID),
           let state = runAppleScript("tell application \"Music\" to get player state as string"),
           state == "playing",
           let name = runAppleScript("tell application \"Music\" to get name of current track"), !name.isEmpty {
            title = name
            artist = runAppleScript("tell application \"Music\" to get artist of current track")
            isPlaying = true
            return
        }

        if isRunning(Self.spotifyBundleID),
           let state = runAppleScript("tell application \"Spotify\" to get player state as string"),
           state == "playing",
           let name = runAppleScript("tell application \"Spotify\" to get name of current track"), !name.isEmpty {
            title = name
            artist = runAppleScript("tell application \"Spotify\" to get artist of current track")
            isPlaying = true
            return
        }

        for browser in Self.browsers where isRunning(browser.bundleID) {
            guard let tabTitle = runAppleScript("tell application \"\(browser.name)\" to \(browser.script)"), !tabTitle.isEmpty else { continue }
            title = tabTitle.replacingOccurrences(of: " - YouTube", with: "")
            artist = nil
            isPlaying = true
            return
        }

        title = nil
        artist = nil
        isPlaying = false
    }

    func togglePlayPause() { sendMediaKey(NX_KEYTYPE_PLAY) }
    func nextTrack() { sendMediaKey(NX_KEYTYPE_NEXT) }
    func previousTrack() { sendMediaKey(NX_KEYTYPE_PREVIOUS) }

    private func isRunning(_ bundleID: String) -> Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bundleID }
    }

    private func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let result = script.executeAndReturnError(&error)
        guard error == nil else { return nil }
        return result.stringValue
    }
}

// Standard NX_KEYTYPE_* media key codes, used system-wide by every "now playing" style utility
// to simulate hardware media key presses.
private let NX_KEYTYPE_PLAY: Int32 = 16
private let NX_KEYTYPE_NEXT: Int32 = 17
private let NX_KEYTYPE_PREVIOUS: Int32 = 18

private func sendMediaKey(_ key: Int32) {
    sendMediaKeyEvent(key, down: true)
    sendMediaKeyEvent(key, down: false)
}

private func sendMediaKeyEvent(_ key: Int32, down: Bool) {
    let flags = down ? 0xa00 : 0xb00
    let data1 = Int((Int(key) << 16) | (flags << 8))
    guard let event = NSEvent.otherEvent(
        with: .systemDefined,
        location: .zero,
        modifierFlags: NSEvent.ModifierFlags(rawValue: UInt(flags)),
        timestamp: 0,
        windowNumber: 0,
        context: nil,
        subtype: 8,
        data1: data1,
        data2: -1
    ), let cgEvent = event.cgEvent else { return }
    cgEvent.post(tap: .cghidEventTap)
}
