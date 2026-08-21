import Foundation
import ApplesoftBASICLib

/// Bridges the interpreter's synchronous OutputHandler to SwiftUI.
///
/// Receives PRINT calls on the interpreter's background thread and
/// dispatches them to a callback for the main actor to process.
///
/// `OutputHandler` already requires `Sendable`, and the compiler can check this
/// one: the single stored property is an immutable `@Sendable` closure, so there
/// is nothing here for an `@unchecked` conformance to paper over.
final class SwiftUIOutputHandler: OutputHandler {

    /// Actions the terminal can receive.
    enum Action: Sendable {
        case print(String)
        case printLine(String)
        case clearScreen
    }

    private let onAction: @Sendable (Action) -> Void

    /// Creates an output handler that forwards actions to the given callback.
    ///
    /// - Parameter onAction: Called on the interpreter's background thread.
    ///   The callback is responsible for dispatching to `@MainActor`.
    init(onAction: @escaping @Sendable (Action) -> Void) {
        self.onAction = onAction
    }

    func print(_ text: String) {
        onAction(.print(text))
    }

    func printLine(_ text: String) {
        onAction(.printLine(text))
    }

    func clearScreen() {
        onAction(.clearScreen)
    }
}
