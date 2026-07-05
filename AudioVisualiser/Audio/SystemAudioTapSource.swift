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
        print("[SystemAudioTapSource] tap created, id=\(tap.id)")

        var asbd = try tap.format
        print("[SystemAudioTapSource] tap format: sampleRate=\(asbd.mSampleRate) channels=\(asbd.mChannelsPerFrame) formatID=\(asbd.mFormatID) flags=\(asbd.mFormatFlags)")
        guard let format = AVAudioFormat(streamDescription: &asbd) else {
            throw AudioSourceError.setupFailed("Failed to build AVAudioFormat from tap format")
        }
        pcmFormat = format

        let tapUID = try tap.uid
        print("[SystemAudioTapSource] tap uid: \(tapUID)")
        var aggregateDescription: [String: Any] = [
            "uid": UUID().uuidString,
            "name": "AudioVisualiser Aggregate",
            "private": true,
            "tapautostart": true,
            "taps": [["uid": tapUID]]
        ]
        if let outputDevice = try? system.defaultOutputDevice {
            let outputUID = try? outputDevice.uid
            let outputName = try? outputDevice.name
            print("[SystemAudioTapSource] default output device: name=\(outputName ?? "?") uid=\(outputUID ?? "?") — NOT anchoring (experiment)")
        } else {
            print("[SystemAudioTapSource] WARNING: no default output device found to anchor aggregate")
        }

        guard let aggregateDevice = try system.makeAggregateDevice(description: aggregateDescription) else {
            throw AudioSourceError.setupFailed("Failed to create aggregate device for system audio tap")
        }
        self.aggregateDevice = aggregateDevice
        print("[SystemAudioTapSource] aggregate device created, id=\(aggregateDevice.id)")

        var procID: AudioDeviceIOProcID?
        let status = AudioDeviceCreateIOProcIDWithBlock(&procID, aggregateDevice.id, nil) { [weak self] _, inputData, inputTime, _, _ in
            self?.handleIO(inputData: inputData, inputTime: inputTime)
        }
        guard status == noErr, let procID else {
            throw AudioSourceError.setupFailed("AudioDeviceCreateIOProcIDWithBlock failed (status \(status))")
        }
        ioProcID = procID
        print("[SystemAudioTapSource] IOProc created, starting device")

        try aggregateDevice.start(IOProcID: procID)
        isRunning = true
        print("[SystemAudioTapSource] started")

        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            let running = (try? aggregateDevice.isRunning) ?? false
            let streams = (try? aggregateDevice.streams.count) ?? -1
            let inputConfig = (try? aggregateDevice.inputStreamConfiguration.count) ?? -1
            let subtaps = (try? aggregateDevice.subtaps.count) ?? -1
            let activeSubtaps = (try? aggregateDevice.activeSubtaps.count) ?? -1
            let subdevices = (try? aggregateDevice.subdevices.count) ?? -1
            let activeSubdevices = (try? aggregateDevice.activeSubdevices.count) ?? -1
            print("[SystemAudioTapSource] diagnostic: isRunning=\(running) streams=\(streams) inputStreamConfigCount=\(inputConfig) subtaps=\(subtaps) activeSubtaps=\(activeSubtaps) subdevices=\(subdevices) activeSubdevices=\(activeSubdevices) ioCallCount=\(self.ioCallCount)")
        }
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

    private var ioCallCount = 0

    private func handleIO(inputData: UnsafePointer<AudioBufferList>, inputTime: UnsafePointer<AudioTimeStamp>) {
        ioCallCount += 1

        if ioCallCount % 50 == 1 {
            let abl = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: inputData))
            var rawPeak: Float = 0
            var bufDescriptions: [String] = []
            for buf in abl {
                bufDescriptions.append("channels=\(buf.mNumberChannels) bytes=\(buf.mDataByteSize)")
                if let data = buf.mData {
                    let floatCount = Int(buf.mDataByteSize) / MemoryLayout<Float>.size
                    let floatPtr = data.bindMemory(to: Float.self, capacity: floatCount)
                    for i in 0..<floatCount {
                        rawPeak = max(rawPeak, abs(floatPtr[i]))
                    }
                }
            }
            print("[SystemAudioTapSource] IOProc call #\(ioCallCount): rawBufferCount=\(abl.count) \(bufDescriptions) rawPeak=\(rawPeak)")
        }

        guard let pcmFormat else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: pcmFormat, bufferListNoCopy: inputData, deallocator: nil) else {
            print("[SystemAudioTapSource] IOProc call #\(ioCallCount): failed to build AVAudioPCMBuffer")
            return
        }
        buffer.frameLength = buffer.frameCapacity
        let peak = buffer.floatChannelData.map { ptr -> Float in
            var m: Float = 0
            for i in 0..<Int(buffer.frameLength) { m = max(m, abs(ptr[0][i])) }
            return m
        } ?? -1
        if peak > 0.0001 || ioCallCount % 50 == 1 {
            print("[SystemAudioTapSource] IOProc call #\(ioCallCount): frames=\(buffer.frameLength) peak=\(peak)")
        }
        let time = AVAudioTime(audioTimeStamp: inputTime, sampleRate: pcmFormat.sampleRate)
        onAudioBuffer?(buffer, time)
    }
}
