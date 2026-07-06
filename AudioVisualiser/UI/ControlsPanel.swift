import SwiftUI

/// Equatable so SwiftUI skips re-laying out these AppKit-bridged segmented Pickers when the
/// parent view re-renders for unrelated reasons (e.g. VisualizerView's 40Hz audio updates).
/// Only the values actually shown here participate in equality -- the bindings/renderers list
/// never change identity, so they're excluded.
struct ControlsPanel: View, Equatable {
    let sourceKind: AudioSourceKind
    let activeRendererID: String
    let colorTheme: ColorTheme
    let lastError: String?
    let isMenuBarEnabled: Bool
    let menuBarSize: MenuBarVisualizerSize
    let menuBarColorTheme: ColorTheme
    let compact: Bool

    let renderers: [VisualizerRenderer]
    let sourceBinding: Binding<AudioSourceKind>
    let rendererBinding: Binding<String>
    let colorThemeBinding: Binding<ColorTheme>
    let menuBarEnabledBinding: Binding<Bool>
    let menuBarSizeBinding: Binding<MenuBarVisualizerSize>
    let menuBarColorThemeBinding: Binding<ColorTheme>

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.sourceKind == rhs.sourceKind
            && lhs.activeRendererID == rhs.activeRendererID
            && lhs.colorTheme == rhs.colorTheme
            && lhs.lastError == rhs.lastError
            && lhs.isMenuBarEnabled == rhs.isMenuBarEnabled
            && lhs.menuBarSize == rhs.menuBarSize
            && lhs.menuBarColorTheme == rhs.menuBarColorTheme
            && lhs.compact == rhs.compact
    }

    var body: some View {
        Group {
            Picker("Source", selection: sourceBinding) {
                ForEach(AudioSourceKind.allCases) { kind in
                    Text(kind.displayName).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            .panelWidth(260, compact: compact)

            Picker("Style", selection: rendererBinding) {
                ForEach(renderers, id: \.id) { renderer in
                    Text(renderer.displayName).tag(renderer.id)
                }
            }
            .pickerStyle(.menu)
            .panelWidth(180, compact: compact)

            Picker("Colors", selection: colorThemeBinding) {
                ForEach(ColorTheme.allCases) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
            .pickerStyle(.menu)
            .panelWidth(180, compact: compact)

            if let lastError {
                Text(lastError)
                    .font(compact ? .caption2 : .caption)
                    .foregroundStyle(.red)
            }

            Toggle("Show in menu bar", isOn: menuBarEnabledBinding)
                .toggleStyle(.switch)

            if isMenuBarEnabled {
                Picker("Menu Bar Size", selection: menuBarSizeBinding) {
                    ForEach(MenuBarVisualizerSize.allCases) { size in
                        Text(size.displayName).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .panelWidth(260, compact: compact)

                Picker("Menu Bar Colors", selection: menuBarColorThemeBinding) {
                    ForEach(ColorTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.menu)
                .panelWidth(180, compact: compact)
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func panelWidth(_ width: CGFloat, compact: Bool) -> some View {
        if compact {
            self.frame(maxWidth: .infinity, alignment: .leading)
        } else {
            self.frame(width: width)
        }
    }
}
