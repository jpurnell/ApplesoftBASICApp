import SwiftUI

@main
struct ApplesoftBASICiPadApp: App {
    // The interpreter and the appearance settings live at the scene level
    // rather than inside ContentView. The menu bar commands and the macOS
    // Settings window are siblings of the window, not children of it, and all
    // three have to drive the same interpreter the toolbar drives.
    @State private var viewModel = TerminalViewModel()
    @State private var themeSettings = ThemeSettings()
    @State private var showingSamples = false

    var body: some Scene {
        WindowGroup {
            ContentView(
                viewModel: viewModel,
                themeSettings: themeSettings,
                showingSamples: $showingSamples
            )
        }
        .commands {
            ProgramCommands(viewModel: viewModel, showingSamples: $showingSamples)
        }

        // Cmd-, on macOS, where preferences belong in their own window rather
        // than a sheet. The toolbar button opens this scene there; iPad and
        // Vision Pro keep the sheet, which is the convention on those platforms.
        #if os(macOS)
        Settings {
            SettingsForm(themeSettings: themeSettings)
                .frame(width: 420)
        }
        #endif
    }
}

/// Menu bar commands for the interpreter.
///
/// Everything the toolbar can do is reachable from the menu bar and from the
/// keyboard — on a Mac the menu bar is the discoverable list of what the app
/// does, and on iPad these become the shortcuts in the Command-key overlay.
struct ProgramCommands: Commands {
    let viewModel: TerminalViewModel
    @Binding var showingSamples: Bool

    var body: some Commands {
        // BASIC here has no documents, so File's default New Item would open a
        // second window onto the same interpreter. Replace the group: New
        // clears the program, and Open reaches the bundled samples.
        CommandGroup(replacing: .newItem) {
            Button("New Program") {
                viewModel.new()
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("Open Sample…") {
                showingSamples = true
            }
            .keyboardShortcut("o", modifiers: .command)
        }

        CommandMenu("Program") {
            Button("Run") {
                viewModel.run()
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(viewModel.isRunning)

            Button("Stop") {
                viewModel.stop()
            }
            .keyboardShortcut(".", modifiers: .command)
            .disabled(!viewModel.isRunning)

            Divider()

            Button("List Program") {
                viewModel.list()
            }
            .disabled(viewModel.isRunning)

            Divider()

            Button("Clear Editor") {
                viewModel.clearEditor()
            }

            Button("Clear Terminal") {
                viewModel.clearTerminal()
            }
            .keyboardShortcut("k", modifiers: .command)
        }
    }
}
