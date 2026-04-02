import SwiftUI

/// Green-on-black terminal output view with INPUT/GET handling and optional REPL.
struct TerminalView: View {
    @Bindable var viewModel: TerminalViewModel
    let themeSettings: ThemeSettings
    @State private var replInput: String = ""
    @State private var userInput: String = ""
    @State private var showREPL = false
    @FocusState private var inputFocused: Bool

    private var theme: TerminalTheme { themeSettings.theme }
    private var termFont: Font { themeSettings.font.font(size: themeSettings.fontSize) }

    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // Terminal output
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(viewModel.outputLines) { line in
                                terminalLine(line.text)
                                    .id(line.id)
                            }
                            // Invisible anchor at the very bottom
                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onChange(of: viewModel.displayText) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }

                Divider().background(theme.dimTextColor)

                // Input area — context-dependent
                if viewModel.isWaitingForInput {
                    programInputField
                } else if showREPL {
                    replField
                }
            }
        }
        .overlay {
            if themeSettings.showScanlines && theme.hasGlow {
                ScanlinesOverlay()
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showREPL.toggle()
                } label: {
                    Label(
                        showREPL ? "Hide Console" : "Console",
                        systemImage: showREPL ? "chevron.down" : "terminal"
                    )
                }
            }
        }
    }

    // MARK: - Terminal Line

    @ViewBuilder
    private func terminalLine(_ text: String) -> some View {
        let styledText = Text(text)
            .font(termFont)
            .foregroundStyle(theme.textColor)

        if theme.hasGlow {
            styledText
                .shadow(color: theme.glowColor, radius: 3)
                .shadow(color: theme.glowColor.opacity(0.2), radius: 6)
        } else {
            styledText
        }
    }

    // MARK: - INPUT/GET Field (during program execution)

    private var programInputField: some View {
        HStack(spacing: 4) {
            Text(viewModel.inputPrompt)
                .font(termFont)
                .foregroundStyle(theme.textColor)

            if viewModel.inputMode == .character {
                // GET mode — single character, submit immediately
                TextField("", text: $userInput)
                    .font(termFont)
                    .foregroundStyle(theme.textColor)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    #if os(iOS)
                .textInputAutocapitalization(.characters)
                #endif
                    .focused($inputFocused)
                    .onChange(of: userInput) {
                        if !userInput.isEmpty {
                            viewModel.submitInput(String(userInput.prefix(1)))
                            userInput = ""
                        }
                    }
                    .task { inputFocused = true }
            } else {
                // INPUT mode — full line with explicit submit button
                TextField("", text: $userInput)
                    .font(termFont)
                    .foregroundStyle(theme.textColor)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    #if os(iOS)
                .textInputAutocapitalization(.characters)
                #endif
                    .focused($inputFocused)
                    .onSubmit { submitUserInput() }
                    .task { inputFocused = true }

                Button {
                    submitUserInput()
                } label: {
                    Image(systemName: "return")
                        .foregroundStyle(theme.textColor)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(theme.inputFieldBackground)
    }

    private func submitUserInput() {
        let text = userInput
        userInput = ""
        viewModel.submitInput(text)
        // Re-focus in case another INPUT follows
        inputFocused = true
    }

    // MARK: - REPL Input Field

    private var replField: some View {
        HStack(spacing: 4) {
            Text("]")
                .font(termFont)
                .foregroundStyle(theme.textColor)

            TextField("", text: $replInput)
                .font(termFont)
                .foregroundStyle(theme.textColor)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.characters)
                #endif
                .focused($inputFocused)
                .onSubmit { submitREPL() }
                .disabled(viewModel.isRunning)
                .task { inputFocused = true }

            Button {
                submitREPL()
            } label: {
                Image(systemName: "return")
                    .foregroundStyle(theme.textColor)
            }
            .disabled(viewModel.isRunning)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(theme.inputFieldBackground)
    }

    private func submitREPL() {
        let line = replInput
        replInput = ""
        viewModel.submitREPLLine(line)
        inputFocused = true
    }
}

/// Subtle CRT scanline overlay effect.
struct ScanlinesOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for y in stride(from: 0, to: size.height, by: 3) {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                    context.fill(Path(rect), with: .color(.black.opacity(0.1)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
