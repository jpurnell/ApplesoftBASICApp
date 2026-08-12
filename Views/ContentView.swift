import SwiftUI

/// Root view — split layout with code editor on left, terminal on right.
struct ContentView: View {
    @State private var viewModel = TerminalViewModel()
    @State private var themeSettings = ThemeSettings()
    @State private var showingSettings = false
    @State private var showingSamples = false
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
                        if viewModel.isRunning {
                            Button {
                                viewModel.stop()
                            } label: {
                                Label("Stop", systemImage: "stop.fill")
                                    .foregroundStyle(.red)
                            }
                        } else {
                            Button {
                                viewModel.run()
                            } label: {
                                Label("Run", systemImage: "play.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }

                    ToolbarItem(placement: .automatic) {
                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
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
