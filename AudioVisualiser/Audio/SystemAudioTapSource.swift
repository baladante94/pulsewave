import AVFoundation
import CoreAudio

// Uses the macOS 15+ Swift-native Core Audio Tap API (AudioHardwareSystem/AudioHardwareTap/
// AudioHardwareAggregateDevice) rather than the older raw C AudioHardwareCreateProcessTap path.
// The IOProc itself has no Swift-overlay equivalent, so that piece still uses the C API.
final class SystemAudioTapSource: AudioSource {
    private(set) var isRunning = false
    var onAudioBuffer: ((AVAudioPCMBuffer, AVAudioTime) -> Void)?

    private var tap: AudioHardwareTap?
    private var aggregateDevice: AudioHardwareAggregateDevice?
    private var ioProcID: AudioDeviceIOProcID?
    private var pcmFormat: AVAudioFormat?

    func start() async throws {
        guard !isRunning else { return }

        let system = AudioHardwareSystem.shared

        let description = CATapDescription(stereoGlobalTapButExcludeProcesses: [])
        description.name = "AudioVisualiser Tap"
        description.isPrivate = true
        description.muteBehavior = .unmuted

        guard let tap = try system.makeProcessTap(description: description) else {
            throw AudioSourceError.setupFailed("Failed to create system audio process tap")
        }
        self.tap = tap

        var asbd = try tap.format
        guard let format = AVAudioFormat(streamDescription: &asbd) else {
            throw AudioSourceError.setupFailed("Failed to build AVAudioFormat from tap format")
        }
        pcmFormat = format

        let tapUID = try tap.uid
        let aggregateDescription: [String: Any] = [
            "uid": UUID().uuidString,
            "name": "AudioVisualiser Aggregate",
            "private": true,
            "tapautostart": true,
            "taps": [["uid": tapUID]]
        ]

        guard let aggregateDevice = try system.makeAggregateDevice(description: aggregateDescription) else {
            throw AudioSourceError.setupFailed("Failed to create aggregate device for system audio tap")
        }
        self.aggregateDevice = aggregateDevice

        var procID: AudioDeviceIOProcID?
        let status = AudioDeviceCreateIOProcIDWithBlock(&procID, aggregateDevice.id, nil) { [weak self] _, inputData, inputTime, _, _ in
            self?.handleIO(inputData: inputData, inputTime: inputTime)
        }
        guard status == noErr, let procID else {
            throw AudioSourceError.setupFailed("AudioDeviceCreateIOProcIDWithBlock failed (status \(status))")
        }
        ioProcID = procID

        try aggregateDevice.start(IOProcID: procID)
        isRunning = true
    }

    func stop() {
        guard isRunning else { return }

        if let aggregateDevice, let ioProcID {
            try? aggregateDevice.stop(IOProcID: ioProcID)
            AudioDeviceDestroyIOProcID(aggregateDevice.id, ioProcID)
        }
        if let aggregateDevice {
            try? AudioHardwareSystem.shared.destroyAggregateDevice(aggregateDevice)
        }
        if let tap {
            try? AudioHardwareSystem.shared.destroyProcessTap(tap)
        }

        ioProcID = nil
        aggregateDevice = nil
        tap = nil
        pcmFormat = nil
        isRunning = false
    }

    private func handleIO(inputData: UnsafePointer<AudioBufferList>, inputTime: UnsafePointer<AudioTimeStamp>) {
        guard let pcmFormat else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: pcmFormat, bufferListNoCopy: inputData, deallocator: nil) else {
            return
        }
        buffer.frameLength = buffer.frameCapacity
        let time = AVAudioTime(audioTimeStamp: inputTime, sampleRate: pcmFormat.sampleRate)
        onAudioBuffer?(buffer, time)
    }
}
