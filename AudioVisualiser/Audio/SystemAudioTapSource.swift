import AVFoundation

// Placeholder for Milestone 3 — Core Audio Tap (CATapDescription -> AudioHardwareCreateProcessTap
// -> AudioHardwareCreateAggregateDevice -> AudioDeviceCreateIOProcIDWithBlock) implementation.
final class SystemAudioTapSource: AudioSource {
    private(set) var isRunning = false
    var onAudioBuffer: ((AVAudioPCMBuffer, AVAudioTime) -> Void)?

    func start() async throws {
        throw AudioSourceError.setupFailed("System audio capture not yet implemented")
    }

    func stop() {
        isRunning = false
    }
}
