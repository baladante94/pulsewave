# Pulsewave

A real-time audio visualizer for macOS. It listens to your system audio (or microphone) and draws it in the app window, full screen, and live in your menu bar.

## Features
- Six styles, including the Trippy Tunnel kaleidoscope
- 20 colour themes, set separately for the app and the menu bar
- Beat-synced visuals using bass onset detection
- Now Playing title, artist and controls for Music and Spotify
- Menu bar visualizer in Compact or Wide size

## Install
1. Download `Pulsewave-1.1.0.dmg` from the [latest release](../../releases/latest)
2. Drag Pulsewave to Applications
3. The app is not notarized, so the first time, right-click Pulsewave and choose Open, then Open again. If macOS still blocks it, run:
   ```
   xattr -dr com.apple.quarantine /Applications/Pulsewave.app
   ```
4. Allow the permissions it asks for: system audio capture, microphone (only if you use it) and Automation for Music or Spotify

Requires macOS 15 or later.

## Build from source
```
brew install xcodegen
xcodegen generate
open Pulsewave.xcodeproj
```

See [CHANGELOG.md](CHANGELOG.md) for version history.
