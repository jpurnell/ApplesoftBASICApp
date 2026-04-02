import Foundation
import ApplesoftBASICLib

/// Bridges the interpreter's synchronous InputHandler to SwiftUI.
///
/// When the interpreter calls `readLine(prompt:)` or `getChar()`, this handler:
/// 1. Posts the prompt to the main actor via the `onPrompt` callback
/// 2. Blocks the interpreter's background thread with a semaphore
/// 3. Waits for the UI to call `provideInput(_:)` or `cancel()`
/// 4. Returns the input string to the interpreter
final class SwiftUIInputHandler: InputHandler, @unchecked Sendable {

    private let semaphore = DispatchSemaphore(value: 0)
    private var pendingInput: String?
    private let onPrompt: @Sendable (String, InputMode) -> Void

    /// Whether the handler is waiting for a single character or a full line.
    enum InputMode: Sendable {
        case line
        case character
    }

    /// Creates an input handler that posts prompts to the given callback.
    ///
    /// - Parameter onPrompt: Called on the interpreter's background thread
    ///   when input is needed. The callback should dispatch to `@MainActor`
    ///   to show an input field in the UI.
    init(onPrompt: @escaping @Sendable (String, InputMode) -> Void) {
        self.onPrompt = onPrompt
    }

    func readLine(prompt: String) -> String? {
        onPrompt(prompt, .line)
        semaphore.wait()
        return pendingInput
    }

    func getChar() -> Character? {
        onPrompt("", .character)
        semaphore.wait()
        return pendingInput?.first
    }

    /// Called from the UI when the user submits input.
    func provideInput(_ text: String) {
        pendingInput = text
        semaphore.signal()
    }

    /// Called to cancel input (e.g., user hits STOP).
    /// Returns nil to the interpreter, which handles it gracefully.
    func cancel() {
        pendingInput = nil
        semaphore.signal()
    }
}
