import SwiftUI

/// Root view — split layout with code editor on left, terminal on right.
struct ContentView: View {
    // Owned by the App scene so the menu bar commands and the macOS Settings
    // window address the same interpreter and appearance this window does.
    let viewModel: TerminalViewModel
    let themeSettings: ThemeSettings
    @Binding var showingSamples: Bool
    @State private var showingSettings = false
    // The editor is half the app, not an inspector. Left to its default the
    // split view opens collapsed on macOS, so a first launch shows a bare
    // terminal with no visible way to reach the editor at all.
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            CodeEditorView(
                viewModel: viewModel,
                themeSettings: themeSettings,
                showingSamples: $showingSamples
            )
                .navigationTitle("Editor")
                .navigationSplitViewColumnWidth(min: 320, ideal: 460)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
        } detail: {
            TerminalView(viewModel: viewModel, themeSettings: themeSettings)
                .navigationTitle("Terminal")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItemGroup(placement: .automatic) {
                        // Run and Stop take their key equivalents from the
                        // Program menu rather than declaring their own, so a
                        // keystroke has exactly one owner. The tooltip still
                        // names the shortcut, the way a Mac toolbar does.
                        if viewModel.isRunning {
                            Button {
                                viewModel.stop()
                            } label: {
                                Label("Stop", systemImage: "stop.fill")
                                    .foregroundStyle(.red)
                            }
                            .help("Stop the running program (⌘.)")
                        } else {
                            Button {
                                viewModel.run()
                            } label: {
                                Label("Run", systemImage: "play.fill")
                                    .foregroundStyle(.green)
                            }
                            .help("Run the program (⌘R)")
                        }
                    }

                    ToolbarItem(placement: .automatic) {
                        // On macOS the Settings scene owns Cmd-comma, so the
                        // button opens that window instead of a sheet. It also
                        // owns the shortcut: binding Command-comma here as well
                        // would be a second claim on a system-reserved key.
                        #if os(macOS)
                        SettingsLink {
                            Label("Settings", systemImage: "gearshape")
                        }
                        .help("Terminal appearance (⌘,)")
                        #else
                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                        .help("Terminal appearance")
                        #endif
                    }
                }
        }
        // Both panes are primary, so the sidebar should displace the detail
        // rather than overlay it or be treated as a hideable inspector.
        .navigationSplitViewStyle(.balanced)
        // The phosphor themes paint a black background, but system chrome — the
        // navigation title, toolbar glyphs, dividers, sheet backgrounds — draws
        // in the window's appearance. Left light, that chrome is dark-on-black
        // and effectively invisible.
        .preferredColorScheme(themeSettings.theme == .paper ? .light : .dark)
        .sheet(isPresented: $showingSettings) {
            SettingsView(themeSettings: themeSettings)
        }
        .sheet(isPresented: $showingSamples) {
            SampleProgramPicker { source in
                viewModel.loadProgram(source)
                showingSamples = false
            }
        }
    }
}
