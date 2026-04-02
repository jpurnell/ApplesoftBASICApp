import SwiftUI

/// Settings sheet for terminal appearance.
struct SettingsView: View {
    @Bindable var themeSettings: ThemeSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
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
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
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
