import AVFoundation

final class MicrophoneSource: AudioSource {
    private let engine = AVAudioEngine()
    private(set) var isRunning = false
    var onAudioBuffer: ((AVAudioPCMBuffer, AVAudioTime) -> Void)?

    func start() async throws {
        guard !isRunning else { return }
        try await requestMicPermission()

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, time in
            self?.onAudioBuffer?(buffer, time)
        }

        engine.prepare()
        try engine.start()
        isRunning = true
    }

    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
    }

    private func requestMicPermission() async throws {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            return
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            if !granted {
                throw AudioSourceError.permissionDenied
            }
        default:
            throw AudioSourceError.permissionDenied
        }
    }
}

enum AudioSourceError: Error {
    case permissionDenied
    case setupFailed(String)
}
