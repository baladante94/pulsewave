import SwiftUI

struct NowPlayingView: View {
    @ObservedObject var manager: NowPlayingManager

    var body: some View {
        Group {
            if let title = manager.title {
                HStack(spacing: 10) {
                    Image(systemName: "music.note")
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .background(Color.primary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                        if let artist = manager.artist {
                            Text(artist)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 4)

                    HStack(spacing: 14) {
                        Button(action: manager.previousTrack) {
                            Image(systemName: "backward.fill")
                        }
                        Button(action: manager.togglePlayPause) {
                            Image(systemName: manager.isPlaying ? "pause.fill" : "play.fill")
                        }
                        Button(action: manager.nextTrack) {
                            Image(systemName: "forward.fill")
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 13))
                }
            } else {
                HStack {
                    Image(systemName: "music.note")
                        .foregroundStyle(.secondary)
                    Text("Nothing playing")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(8)
        .frame(height: 52)
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
