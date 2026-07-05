import AVFoundation
import Combine

@MainActor
final class AudioSourceManager: ObservableObject {
    @Published private(set) var currentKind: AudioSourceKind
    @Published private(set) var isRunning = false
    @Published private(set) var lastError: String?

    let bufferPublisher = PassthroughSubject<(AVAudioPCMBuffer, AVAudioTime), Never>()

    private var currentSource: AudioSource?

    init() {
        let stored = UserDefaults.standard.string(forKey: "lastAudioSourceKind")
        currentKind = AudioSourceKind(rawValue: stored ?? "") ?? .microphone
    }

    func start() async {
        await switchTo(currentKind)
    }

    func switchTo(_ kind: AudioSourceKind) async {
        currentSource?.stop()
        currentSource = nil
        isRunning = false

        let source = makeSource(for: kind)
        source.onAudioBuffer = { [bufferPublisher] buffer, time in
            bufferPublisher.send((buffer, time))
        }

        do {
            try await source.start()
            currentSource = source
            currentKind = kind
            isRunning = true
            lastError = nil
            UserDefaults.standard.set(kind.rawValue, forKey: "lastAudioSourceKind")
        } catch {
            lastError = error.localizedDescription
            isRunning = false
        }
    }

    func stop() {
        currentSource?.stop()
        currentSource = nil
        isRunning = false
    }

    private func makeSource(for kind: AudioSourceKind) -> AudioSource {
        switch kind {
        case .microphone:
            return MicrophoneSource()
        case .systemAudio:
            return SystemAudioTapSource()
        }
    }
}
