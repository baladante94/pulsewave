import AVFoundation

protocol AudioSource: AnyObject {
    var isRunning: Bool { get }
    var onAudioBuffer: ((AVAudioPCMBuffer, AVAudioTime) -> Void)? { get set }
    func start() async throws
    func stop()
}

enum AudioSourceKind: String, CaseIterable, Identifiable {
    case microphone
    case systemAudio

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .microphone: return "Microphone"
        case .systemAudio: return "System Audio"
        }
    }
}
