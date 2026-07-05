import Foundation

enum DebugLog {
    private static let url = URL(fileURLWithPath: NSHomeDirectory() + "/audiovisualiser_debug.log")

    static func log(_ message: String) {
        let line = "\(Date()) \(message)\n"
        print(message)
        guard let data = line.data(using: .utf8) else { return }
        if FileManager.default.fileExists(atPath: url.path) {
            if let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                handle.write(data)
                try? handle.close()
            }
        } else {
            try? data.write(to: url)
        }
    }
}
