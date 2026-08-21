import SwiftUI

/// Settings sheet for terminal appearance, used where preferences are modal —
/// iPad and Vision Pro. macOS opens ``SettingsForm`` in its own Settings window.
///
/// The sheet supplies its own title and Done button rather than a
/// `NavigationStack`: there is nothing to push, so a navigation container here
/// would be chrome with no destination behind it.
struct SettingsView: View {
    @Bindable var themeSettings: ThemeSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.headline)

                Spacer()

                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .help("Close settings")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()

            SettingsForm(themeSettings: themeSettings)
        }
        // See SampleProgramPicker: macOS sheets size to content, so Form needs
        // a floor to keep the sheet from collapsing.
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 520)
        #endif
    }
}

/// The appearance controls themselves, with no presentation chrome.
///
/// Both the sheet and the macOS Settings scene wrap this, so it owns no title,
/// no dismissal, and no window sizing — each presenter supplies its own.
struct SettingsForm: View {
    @Bindable var themeSettings: ThemeSettings

    var body: some View {
        Form {
            Section("Theme") {
                Picker("Color Theme", selection: $themeSettings.theme) {
                    ForEach(TerminalTheme.allCases) { theme in
                        HStack {
                            Circle()
                                .fill(theme.textColor)
                                .frame(width: 16, height: 16)
                                .overlay {
                                    Circle()
                                        .fill(theme.backgroundColor)
                                        .frame(width: 8, height: 8)
                                }
                            Text(theme.rawValue)
                        }
                        .tag(theme)
                    }
                }

                Toggle("Scanlines", isOn: $themeSettings.showScanlines)
            }

            Section("Font") {
                Picker("Font", selection: $themeSettings.font) {
                    ForEach(TerminalFont.allCases) { font in
                        Text(font.displayName)
                            .tag(font)
                    }
                }

                HStack {
                    Text("Size")
                    Slider(
                        value: $themeSettings.fontSize,
                        in: 12...32,
                        step: 1
                    )
                    Text("\(Int(themeSettings.fontSize))pt")
                        .monospacedDigit()
                        .frame(width: 40)
                }
            }

            Section("Preview") {
                previewBox
            }
        }
    }

    private var previewBox: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("]10 PRINT \"HELLO WORLD\"")
            Text("]RUN")
            Text("HELLO WORLD")
            Text("")
            Text("]_")
        }
        .font(themeSettings.font.font(size: themeSettings.fontSize))
        .foregroundStyle(themeSettings.theme.textColor)
        .shadow(
            color: themeSettings.theme.hasGlow ? themeSettings.theme.glowColor : .clear,
            radius: 3
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(themeSettings.theme.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
