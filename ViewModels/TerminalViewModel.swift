import Foundation
import ApplesoftBASICLib

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

    /// Stored program lines, keyed by line number.
    var programLines: [Int: String] = [:]

    /// The editor text — kept in sync with programLines.
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

        let upper = trimmed.uppercased()

        if upper == "RUN" {
            run()
            return
        }
        if upper == "LIST" {
            list()
            return
        }
        if upper.hasPrefix("LIST ") {
            list(range: String(upper.dropFirst(5)))
            return
        }
        if upper == "NEW" {
            new()
            return
        }
        if upper.hasPrefix("DEL ") {
            deleteLines(range: String(upper.dropFirst(4)))
            return
        }

        // Check for line number → store/delete
        if let firstChar = trimmed.first, firstChar.isNumber {
            var numStr = ""
            var rest = trimmed[trimmed.startIndex...]
            while let char = rest.first, char.isNumber {
                numStr.append(char)
                rest = rest.dropFirst()
            }
            if let lineNum = Int(numStr) {
                let content = String(rest).trimmingCharacters(in: .whitespaces)
                if content.isEmpty {
                    programLines.removeValue(forKey: lineNum)
                } else {
                    programLines[lineNum] = "\(lineNum) \(content)"
                }
                return
            }
        }

        // Direct execution
        executeDirect(trimmed)
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
            loadProgramWithoutEditorSync(editorText)
        }

        let source = programLines.keys.sorted()
            .compactMap { programLines[$0] }
            .joined(separator: "\n")

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
        let sortedKeys = programLines.keys.sorted()

        if let range {
            let parts = range.split(separator: "-")
            let start = Int(parts.first ?? "") ?? 0
            let end = parts.count > 1 ? (Int(parts.last ?? "") ?? Int.max) : start
            for key in sortedKeys where key >= start && key <= end {
                if let line = programLines[key] {
                    appendToTerminal("\(line)\n")
                }
            }
        } else {
            for key in sortedKeys {
                if let line = programLines[key] {
                    appendToTerminal("\(line)\n")
                }
            }
        }
    }

    /// Clears the stored program and editor.
    func new() {
        programLines.removeAll()
        editorText = ""
        appendToTerminal("\n")
    }

    /// Loads source code into programLines by parsing line numbers.
    /// Also updates the editor text to stay in sync.
    func loadProgram(_ source: String) {
        programLines.removeAll()
        for line in source.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            guard let firstChar = trimmed.first, firstChar.isNumber else { continue }

            var numStr = ""
            var rest = trimmed[trimmed.startIndex...]
            while let char = rest.first, char.isNumber {
                numStr.append(char)
                rest = rest.dropFirst()
            }
            if let lineNum = Int(numStr) {
                programLines[lineNum] = trimmed
            }
        }
        editorText = programSource()
    }

    /// Returns the program as a source string (for the code editor).
    func programSource() -> String {
        programLines.keys.sorted()
            .compactMap { programLines[$0] }
            .joined(separator: "\n")
    }

    /// Resets the terminal display.
    func clearTerminal() {
        terminal.reset()
        refreshDisplay()
    }

    // MARK: - Private

    /// Loads program without syncing back to editorText (avoids circular update).
    private func loadProgramWithoutEditorSync(_ source: String) {
        programLines.removeAll()
        for line in source.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            guard let firstChar = trimmed.first, firstChar.isNumber else { continue }

            var numStr = ""
            var rest = trimmed[trimmed.startIndex...]
            while let char = rest.first, char.isNumber {
                numStr.append(char)
                rest = rest.dropFirst()
            }
            if let lineNum = Int(numStr) {
                programLines[lineNum] = trimmed
            }
        }
    }

    private func deleteLines(range: String) {
        let parts = range.split(separator: "-")
        let start = Int(parts.first ?? "") ?? 0
        let end = parts.count > 1 ? (Int(parts.last ?? "") ?? start) : start
        for key in programLines.keys where key >= start && key <= end {
            programLines.removeValue(forKey: key)
        }
    }

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
