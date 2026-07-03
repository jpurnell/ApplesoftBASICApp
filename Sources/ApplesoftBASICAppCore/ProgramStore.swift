import Foundation

/// Stores an Applesoft BASIC program as a map of line numbers to source lines,
/// independent of any UI or interpreter.
///
/// This is the platform-independent program-editing model extracted from the
/// app's view model: it handles storing and removing numbered lines, parsing a
/// full source listing, rendering the program back to text, and `LIST`/`DEL`
/// range operations.
public struct ProgramStore: Equatable, Sendable {

    /// The stored program lines, keyed by line number. Each value is the full
    /// source text of the line (including its leading line number).
    public private(set) var lines: [Int: String]

    /// Creates a program store, optionally seeded with existing lines.
    /// - Parameter lines: Initial line-number-to-source mapping (default empty).
    public init(lines: [Int: String] = [:]) {
        self.lines = lines
    }

    /// Whether the program has no stored lines.
    public var isEmpty: Bool { lines.isEmpty }

    /// Stores (or replaces) a numbered line.
    ///
    /// The stored text is normalized to `"<number> <content>"`. Storing empty
    /// content removes the line, matching Applesoft's behavior where typing a
    /// bare line number deletes that line.
    /// - Parameters:
    ///   - lineNumber: The BASIC line number.
    ///   - content: The line body (without its line number).
    public mutating func store(lineNumber: Int, content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            lines.removeValue(forKey: lineNumber)
        } else {
            lines[lineNumber] = "\(lineNumber) \(trimmed)"
        }
    }

    /// Removes the line with the given number, if present.
    /// - Parameter lineNumber: The BASIC line number to remove.
    public mutating func remove(lineNumber: Int) {
        lines.removeValue(forKey: lineNumber)
    }

    /// Removes all stored lines.
    public mutating func removeAll() {
        lines.removeAll()
    }

    /// Replaces the program by parsing a full source listing.
    ///
    /// Each non-empty line that begins with a line number is stored verbatim
    /// (trimmed of surrounding whitespace), keyed by its parsed line number.
    /// Lines without a leading number are ignored.
    /// - Parameter source: The multi-line program source.
    public mutating func load(from source: String) {
        lines.removeAll()
        for rawLine in source.components(separatedBy: .newlines) {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            guard let lineNumber = Self.leadingLineNumber(of: trimmed) else { continue }
            lines[lineNumber] = trimmed
        }
    }

    /// Renders the program as source text, one line per line number in order.
    /// - Returns: The program source, ascending by line number.
    public func source() -> String {
        lines.keys.sorted()
            .compactMap { lines[$0] }
            .joined(separator: "\n")
    }

    /// Returns the program lines to display for a `LIST` command.
    ///
    /// - Parameter range: An optional `"start-end"` (or single `"start"`) range
    ///   string. When `nil`, every line is listed. A single number lists just
    ///   that line; an open range without a trailing bound lists only the start.
    /// - Returns: The matching source lines, ascending by line number.
    public func listing(range: String? = nil) -> [String] {
        let sortedKeys = lines.keys.sorted()
        guard let range else {
            return sortedKeys.compactMap { lines[$0] }
        }
        let parts = range.split(separator: "-")
        let start = Int(parts.first ?? "") ?? 0
        let end = parts.count > 1 ? (Int(parts.last ?? "") ?? Int.max) : start
        return sortedKeys
            .filter { $0 >= start && $0 <= end }
            .compactMap { lines[$0] }
    }

    /// Deletes lines within a `"start-end"` (or single `"start"`) range.
    /// - Parameter range: The range string, e.g. `"10-50"` or `"30"`.
    public mutating func deleteLines(range: String) {
        let parts = range.split(separator: "-")
        let start = Int(parts.first ?? "") ?? 0
        let end = parts.count > 1 ? (Int(parts.last ?? "") ?? start) : start
        for key in lines.keys where key >= start && key <= end {
            lines.removeValue(forKey: key)
        }
    }

    /// Parses the leading line number from a trimmed source line, or `nil` if it
    /// does not begin with a digit.
    static func leadingLineNumber(of trimmed: String) -> Int? {
        guard let first = trimmed.first, first.isNumber else { return nil }
        var digits = ""
        for char in trimmed {
            guard char.isNumber else { break }
            digits.append(char)
        }
        return Int(digits)
    }

    /// The body of a numbered line (everything after the leading digits),
    /// trimmed of surrounding whitespace.
    static func lineBody(of trimmed: String) -> String {
        var rest = Substring(trimmed)
        while let char = rest.first, char.isNumber {
            rest = rest.dropFirst()
        }
        return rest.trimmingCharacters(in: .whitespaces)
    }
}

/// A command entered at the BASIC REPL prompt, classified from raw input.
public enum REPLCommand: Equatable, Sendable {
    /// Run the stored program (`RUN`).
    case run
    /// List the program, optionally restricted to a range string (`LIST`, `LIST 10-20`).
    case list(range: String?)
    /// Clear the stored program (`NEW`).
    case new
    /// Delete a range of lines (`DEL 10-20`).
    case delete(range: String)
    /// Store or remove a numbered line; empty content removes it.
    case store(lineNumber: Int, content: String)
    /// Execute a line of BASIC immediately (no line number).
    case direct(String)
    /// The input was empty after trimming.
    case empty
}

/// Classifies raw REPL input into a ``REPLCommand`` without side effects.
public enum REPLParser {

    /// Parses a line of REPL input into a command.
    ///
    /// Command keywords are matched case-insensitively; stored line content and
    /// direct-execution text preserve their original case.
    /// - Parameter line: The raw input line.
    /// - Returns: The classified command.
    public static func parse(_ line: String) -> REPLCommand {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .empty }

        let upper = trimmed.uppercased()

        if upper == "RUN" { return .run }
        if upper == "LIST" { return .list(range: nil) }
        if upper.hasPrefix("LIST ") {
            return .list(range: String(trimmed.dropFirst(5)))
        }
        if upper == "NEW" { return .new }
        if upper.hasPrefix("DEL ") {
            return .delete(range: String(trimmed.dropFirst(4)))
        }

        if let lineNumber = ProgramStore.leadingLineNumber(of: trimmed) {
            return .store(lineNumber: lineNumber, content: ProgramStore.lineBody(of: trimmed))
        }

        return .direct(trimmed)
    }
}
