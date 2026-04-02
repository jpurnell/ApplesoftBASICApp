import SwiftUI

/// Root view — split layout with code editor on left, terminal on right.
struct ContentView: View {
    @State private var viewModel = TerminalViewModel()
    @State private var themeSettings = ThemeSettings()
    @State private var showingSettings = false
    @State private var showingSamples = false

    var body: some View {
        NavigationSplitView {
            CodeEditorView(
                viewModel: viewModel,
                themeSettings: themeSettings,
                showingSamples: $showingSamples
            )
                .navigationTitle("Editor")
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
