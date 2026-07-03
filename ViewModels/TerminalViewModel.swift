import Foundation
import ApplesoftBASICLib
import ApplesoftBASICAppCore

/// Central coordinator for the BASIC interpreter in SwiftUI.
///
/// Manages program storage, interpreter execution, terminal output,
/// and user input bridging between the synchronous interpreter and
/// the async SwiftUI world.
@MainActor
@Observable
final class TerminalViewModel {

    // MARK: - Terminal Display

    /// The terminal character buffer.
    let terminal = TerminalBuffer(columns: 80, rows: 24)

    /// Text content for display (rebuilt from terminal buffer).
    private(set) var displayText: String = ""

    /// Scrollback + screen lines for the ScrollView.
    private(set) var outputLines: [OutputLine] = []

    /// Whether the interpreter is currently running.
    private(set) var isRunning = false

    /// Whether the interpreter is waiting for user input.
    private(set) var isWaitingForInput = false

    /// The current input prompt text.
    private(set) var inputPrompt = ""

    /// The current input mode (line or character).
    private(set) var inputMode: SwiftUIInputHandler.InputMode = .line

    // MARK: - Program Storage

    /// The stored BASIC program: line storage, LIST/DEL, and source rendering.
    private(set) var program = ProgramStore()

    /// The editor text — kept in sync with the stored program.
    var editorText: String = ""

    // MARK: - Dependencies

    /// Sound handler for the interpreter (blocking, runs on interpreter thread).
    private let soundAdapter = iPadSoundAdapter()

    // MARK: - Private State

    private var runTask: Task<Void, Never>?
    private var inputHandler: SwiftUIInputHandler?

    /// A simple counter for generating unique line IDs.
    private var lineCounter = 0

    // MARK: - Output Line Model

    /// A single line of terminal output for the ScrollView.
    struct OutputLine: Identifiable {
        let id: Int
        let text: String
    }

    // MARK: - REPL Commands

    /// Processes a line entered at the REPL prompt.
    func submitREPLLine(_ line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        // Echo the input
        appendToTerminal("] \(trimmed)\n")

        switch REPLParser.parse(trimmed) {
        case .run:
            run()
        case .list(let range):
            list(range: range)
        case .new:
            new()
        case .delete(let range):
            program.deleteLines(range: range)
        case .store(let lineNumber, let content):
            program.store(lineNumber: lineNumber, content: content)
        case .direct(let statement):
            executeDirect(statement)
        case .empty:
            break
        }
    }

    /// Submits input when the interpreter is waiting (INPUT/GET).
    func submitInput(_ text: String) {
        guard isWaitingForInput else { return }
        appendToTerminal("\(text)\n")
        isWaitingForInput = false
        inputHandler?.provideInput(text)
    }

    // MARK: - Program Execution

    /// Runs the program. Always syncs from the editor first.
    func run() {
        // Always load from editor to keep in sync
        if !editorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            program.load(from: editorText)
        }

        let source = program.source()

        guard !source.isEmpty else {
            appendToTerminal("?NO PROGRAM IN MEMORY\n")
            return
        }

        appendToTerminal("RUN\n")
        executeSource(source)
    }

    /// Stops the currently running program.
    func stop() {
        inputHandler?.cancel()
        runTask?.cancel()
        isRunning = false
        isWaitingForInput = false
        appendToTerminal("\n?BREAK\n")
    }

    /// Lists the stored program.
    func list(range: String? = nil) {
        for line in program.listing(range: range) {
            appendToTerminal("\(line)\n")
        }
    }

    /// Clears the stored program and editor.
    func new() {
        program.removeAll()
        editorText = ""
        appendToTerminal("\n")
    }

    /// Clears the editor text and stored program (without echoing to the terminal).
    func clearEditor() {
        editorText = ""
        program.removeAll()
    }

    /// Loads source code into the stored program by parsing line numbers.
    /// Also updates the editor text to stay in sync.
    func loadProgram(_ source: String) {
        program.load(from: source)
        editorText = program.source()
    }

    /// Returns the program as a source string (for the code editor).
    func programSource() -> String {
        program.source()
    }

    /// Stops any running program and clears the terminal display.
    func clearTerminal() {
        if isRunning {
            stop()
        }
        terminal.reset()
        outputLines = []
        displayText = ""
    }

    // MARK: - Private

    private func executeDirect(_ line: String) {
        let source = "0 \(line)"
        executeSource(source)
    }

    private func executeSource(_ source: String) {
        isRunning = true

        let outputHandler = SwiftUIOutputHandler { [weak self] action in
            Task { @MainActor [weak self] in
                self?.handleOutputAction(action)
            }
        }

        let inputHandler = SwiftUIInputHandler { [weak self] prompt, mode in
            Task { @MainActor [weak self] in
                self?.isWaitingForInput = true
                self?.inputPrompt = prompt
                self?.inputMode = mode
            }
        }
        self.inputHandler = inputHandler

        let soundHandler = soundAdapter
        runTask = Task.detached(priority: .userInitiated) { [weak self] in
            do {
                var lexer = Lexer(source: source)
                let tokens = try lexer.tokenize()
                var parser = Parser(tokens: tokens)
                let program = try parser.parse()
                let interpreter = Interpreter(
                    program: program,
                    output: outputHandler,
                    input: inputHandler,
                    sound: soundHandler,
                    maxSteps: 10_000_000
                )
                try interpreter.run()
            } catch let error as BASICError {
                let msg = error.applesoftMessage
                await MainActor.run { [weak self] in
                    self?.appendToTerminal("\(msg)\n")
                }
            } catch {
                // Task cancelled or other error
            }

            await MainActor.run { [weak self] in
                self?.isRunning = false
                self?.isWaitingForInput = false
            }
        }
    }

    private func handleOutputAction(_ action: SwiftUIOutputHandler.Action) {
        switch action {
        case .print(let text):
            terminal.write(text)
        case .printLine(let text):
            terminal.write(text)
            terminal.write("\n")
        case .clearScreen:
            terminal.clearScreen()
        }
        refreshDisplay()
    }

    private func appendToTerminal(_ text: String) {
        terminal.write(text)
        refreshDisplay()
    }

    private func refreshDisplay() {
        let allLines = terminal.scrollback + terminal.screenLines()
        var result: [OutputLine] = []
        for (index, line) in allLines.enumerated() {
            result.append(OutputLine(id: index, text: line))
        }
        outputLines = result
        displayText = allLines.joined(separator: "\n")
    }
}
