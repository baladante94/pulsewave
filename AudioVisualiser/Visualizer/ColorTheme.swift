import SwiftUI

enum ColorTheme: String, CaseIterable, Identifiable, Equatable {
    case spectrum
    case mono
    case fire
    case ocean
    case sunset
    case neonPink
    case iceBlue
    case matrix
    case purpleHaze
    case gold
    case candy
    case cyberpunk
    case rainbow
    case aurora
    case lava
    case vaporwave
    case toxic
    case roseGold
    case deepSpace
    case synthwave

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spectrum: return "Spectrum"
        case .mono: return "Mono"
        case .fire: return "Fire"
        case .ocean: return "Ocean"
        case .sunset: return "Sunset"
        case .neonPink: return "Neon Pink"
        case .iceBlue: return "Ice Blue"
        case .matrix: return "Matrix"
        case .purpleHaze: return "Purple Haze"
        case .gold: return "Gold"
        case .candy: return "Candy"
        case .cyberpunk: return "Cyberpunk"
        case .rainbow: return "Rainbow"
        case .aurora: return "Aurora"
        case .lava: return "Lava"
        case .vaporwave: return "Vaporwave"
        case .toxic: return "Toxic"
        case .roseGold: return "Rose Gold"
        case .deepSpace: return "Deep Space"
        case .synthwave: return "Synthwave"
        }
    }

    /// Whether this theme should render as a template image in the menu bar (auto-contrasts with
    /// light/dark menu bars). Only makes sense for single-color themes.
    var isTemplate: Bool { self == .mono }

    func color(forIndex index: Int, count: Int) -> Color {
        let progress = Double(index) / Double(max(count - 1, 1))
        switch self {
        case .spectrum:
            return Color(hue: 0.55 + progress * 0.35, saturation: 0.85, brightness: 1)
        case .mono:
            return Color.primary
        case .fire:
            return Color(hue: 0.14 - progress * 0.14, saturation: 1, brightness: 1)
        case .ocean:
            return Color(hue: 0.5 + progress * 0.12, saturation: 0.75, brightness: 0.95)
        case .sunset:
            return Color(hue: 0.78 + progress * 0.15, saturation: 0.8, brightness: 1)
        case .neonPink:
            return Color(red: 1.0, green: 0.15 + progress * 0.3, blue: 0.65 + progress * 0.25)
        case .iceBlue:
            return Color(red: 0.3 + progress * 0.3, green: 0.8 + progress * 0.15, blue: 1.0)
        case .matrix:
            return Color(hue: 0.33, saturation: 0.9, brightness: 0.5 + progress * 0.5)
        case .purpleHaze:
            return Color(hue: 0.72 + progress * 0.1, saturation: 0.8, brightness: 0.85 + progress * 0.15)
        case .gold:
            return Color(hue: 0.11 + progress * 0.04, saturation: 0.85, brightness: 0.85 + progress * 0.15)
        case .candy:
            return Color(hue: 0.85 - progress * 0.5, saturation: 0.55, brightness: 1)
        case .cyberpunk:
            return progress < 0.5
                ? Color(red: 1.0, green: 0.1, blue: 0.6)
                : Color(red: 0.1, green: 0.9, blue: 1.0)
        case .rainbow:
            return Color(hue: progress * 0.92, saturation: 0.9, brightness: 1)
        case .aurora:
            return Color(hue: 0.45 - progress * 0.2 + (progress > 0.7 ? 0.1 : 0), saturation: 0.75, brightness: 0.95)
        case .lava:
            return Color(red: 1.0, green: 0.05 + progress * 0.45, blue: progress > 0.8 ? 0.2 : 0.02)
        case .vaporwave:
            return Color(red: 1.0 - progress * 0.6, green: 0.45 + progress * 0.45, blue: 0.95)
        case .toxic:
            return Color(hue: 0.22 + progress * 0.1, saturation: 1, brightness: 1)
        case .roseGold:
            return Color(red: 0.95, green: 0.55 + progress * 0.2, blue: 0.5 + progress * 0.2)
        case .deepSpace:
            return Color(hue: 0.65 + progress * 0.2, saturation: 0.9 - progress * 0.3, brightness: 0.6 + progress * 0.4)
        case .synthwave:
            return progress < 0.5
                ? Color(hue: 0.83, saturation: 0.9 - progress * 0.4, brightness: 1)
                : Color(hue: 0.08 + (1 - progress) * 0.1, saturation: 0.95, brightness: 1)
        }
    }
}
