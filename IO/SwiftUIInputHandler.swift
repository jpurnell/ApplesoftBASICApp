import Foundation
import ApplesoftBASICLib
import ApplesoftBASICAppCore

/// Bridges the interpreter's synchronous InputHandler to SwiftUI.
///
/// When the interpreter calls `readLine(prompt:)` or `getChar()`, this handler:
/// 1. Posts the prompt to the main actor via the `onPrompt` callback
/// 2. Blocks the interpreter's background thread on a `BlockingInputChannel`
/// 3. Waits for the UI to call `provideInput(_:)` or `cancel()`
/// 4. Returns the input string to the interpreter
///
/// The blocking handoff itself — bounded waits, consuming reads, latched
/// cancellation — lives in ``BlockingInputChannel``, which is testable without
/// SwiftUI or the interpreter. This type is only the protocol conformance and
/// the prompt callback.
// Justification: immutable stored properties; the blocking state lives in BlockingInputChannel.
final class SwiftUIInputHandler: InputHandler, @unchecked Sendable {

    private let channel = BlockingInputChannel()
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
        return channel.awaitInput()
    }

    func getChar() -> Character? {
        onPrompt("", .character)
        return channel.awaitInput()?.first
    }

    /// Called from the UI when the user submits input.
    func provideInput(_ text: String) {
        channel.provide(text)
    }

    /// Called to cancel input (e.g., user hits STOP).
    /// Returns nil to the interpreter, which handles it gracefully.
    ///
    /// Cancellation latches, so a STOP issued while the interpreter is between
    /// prompts still ends the next one. The view model creates a fresh handler
    /// per run, so a cancelled handler is never reused.
    func cancel() {
        channel.cancel()
    }
}
