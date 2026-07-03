import Foundation

/// A character-grid terminal buffer that supports ANSI escape sequences.
///
/// Models an 80x24 character display with cursor tracking, supporting
/// cursor positioning (`ESC[row;colH`), clear screen (`ESC[2J`),
/// and text modes (`ESC[7m` inverse, `ESC[0m` reset).
@MainActor
public final class TerminalBuffer {

    /// A single character cell in the terminal grid.
    public struct Cell: Sendable, Equatable {
        /// The glyph displayed in this cell.
        public var character: Character = " "
        /// Whether the cell is rendered with inverse (reversed) video.
        public var isInverse: Bool = false
    }

    /// The number of character columns in the display.
    public let columns: Int
    /// The number of character rows in the display.
    public let rows: Int

    /// The character grid, indexed `grid[row][column]`.
    public private(set) var grid: [[Cell]]

    /// The current cursor row (0-indexed).
    public private(set) var cursorRow: Int = 0
    /// The current cursor column (0-indexed).
    public private(set) var cursorCol: Int = 0

    /// Current text mode.
    private var inverseMode: Bool = false

    /// Scrollback buffer — completed lines that scrolled off the top.
    public private(set) var scrollback: [String] = []

    /// Maximum scrollback lines.
    private let maxScrollback = 5000

    /// ANSI escape sequence parser state.
    private var escapeState: EscapeState = .normal
    private var escapeParams: String = ""

    private enum EscapeState {
        case normal
        case escape       // received ESC
        case csi          // received ESC[
    }

    /// Creates a terminal buffer with the given dimensions.
    /// - Parameters:
    ///   - columns: The number of character columns (default 80).
    ///   - rows: The number of character rows (default 24).
    public init(columns: Int = 80, rows: Int = 24) {
        self.columns = columns
        self.rows = rows
        self.grid = Array(
            repeating: Array(repeating: Cell(), count: columns),
            count: rows
        )
    }

    /// Writes a string to the terminal, interpreting ANSI escape sequences.
    public func write(_ text: String) {
        for char in text {
            processCharacter(char)
        }
    }

    /// Clears the entire screen and resets cursor to top-left.
    public func clearScreen() {
        // Save current screen content to scrollback
        for row in 0..<rows {
            let line = gridRowToString(row)
            if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                appendScrollback(line)
            }
        }
        grid = Array(
            repeating: Array(repeating: Cell(), count: columns),
            count: rows
        )
        cursorRow = 0
        cursorCol = 0
    }

    /// Returns just the visible screen content as an array of strings.
    public func screenLines() -> [String] {
        (0..<rows).map { gridRowToString($0) }
    }

    /// Resets the terminal completely.
    public func reset() {
        scrollback.removeAll()
        clearScreen()
        inverseMode = false
        escapeState = .normal
        escapeParams = ""
    }

    // MARK: - Character Processing

    private func processCharacter(_ char: Character) {
        switch escapeState {
        case .normal:
            if char == "\u{1B}" { // ESC
                escapeState = .escape
                escapeParams = ""
            } else if char == "\n" {
                newline()
            } else if char == "\r" {
                cursorCol = 0
            } else if char == "\u{07}" { // BEL (handled by sound layer)
                // No-op in the buffer
            } else if char == "\u{08}" { // Backspace
                if cursorCol > 0 { cursorCol -= 1 }
            } else {
                putChar(char)
            }

        case .escape:
            if char == "[" {
                escapeState = .csi
            } else {
                // Unknown escape — ignore and return to normal
                escapeState = .normal
            }

        case .csi:
            if char.isNumber || char == ";" {
                escapeParams.append(char)
            } else {
                executeCSI(char)
                escapeState = .normal
            }
        }
    }

    private func putChar(_ char: Character) {
        guard cursorRow >= 0 && cursorRow < rows else { return }
        if cursorCol >= columns {
            newline()
        }
        guard cursorCol < columns else { return }
        grid[cursorRow][cursorCol] = Cell(character: char, isInverse: inverseMode)
        cursorCol += 1
    }

    private func newline() {
        cursorCol = 0
        cursorRow += 1
        if cursorRow >= rows {
            scrollUp()
            cursorRow = rows - 1
        }
    }

    private func scrollUp() {
        let topLine = gridRowToString(0)
        if !topLine.trimmingCharacters(in: .whitespaces).isEmpty {
            appendScrollback(topLine)
        }
        grid.removeFirst()
        grid.append(Array(repeating: Cell(), count: columns))
    }

    private func appendScrollback(_ line: String) {
        scrollback.append(line)
        if scrollback.count > maxScrollback {
            scrollback.removeFirst()
        }
    }

    // MARK: - ANSI CSI Commands

    private func executeCSI(_ command: Character) {
        let params = escapeParams.split(separator: ";").compactMap { Int($0) }

        switch command {
        case "H", "f": // Cursor Position
            let row = (params.count > 0 ? params[0] : 1) - 1
            let col = (params.count > 1 ? params[1] : 1) - 1
            cursorRow = max(0, min(rows - 1, row))
            cursorCol = max(0, min(columns - 1, col))

        case "J": // Erase in Display
            let mode = params.first ?? 0
            if mode == 2 {
                clearScreen()
            }

        case "K": // Erase in Line
            let mode = params.first ?? 0
            if mode == 0 {
                // Clear from cursor to end of line
                for col in cursorCol..<columns {
                    grid[cursorRow][col] = Cell()
                }
            }

        case "m": // Select Graphic Rendition
            let code = params.first ?? 0
            switch code {
            case 0: inverseMode = false  // Reset
            case 7: inverseMode = true   // Inverse
            default: break
            }

        case "A": // Cursor Up
            let n = params.first ?? 1
            cursorRow = max(0, cursorRow - n)

        case "B": // Cursor Down
            let n = params.first ?? 1
            cursorRow = min(rows - 1, cursorRow + n)

        case "C": // Cursor Forward
            let n = params.first ?? 1
            cursorCol = min(columns - 1, cursorCol + n)

        case "D": // Cursor Back
            let n = params.first ?? 1
            cursorCol = max(0, cursorCol - n)

        default:
            break // Unknown CSI command
        }
    }

    // MARK: - Helpers

    private func gridRowToString(_ row: Int) -> String {
        let chars = grid[row].map { $0.character }
        return String(chars).replacingOccurrences(
            of: "\\s+$",
            with: "",
            options: .regularExpression
        )
    }
}
