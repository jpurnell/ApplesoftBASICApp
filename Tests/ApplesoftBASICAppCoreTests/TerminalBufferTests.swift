import Testing
@testable import ApplesoftBASICAppCore

@MainActor
struct TerminalBufferTests {

    @Test("Plain text lands on the first screen line")
    func writesPlainText() {
        let buffer = TerminalBuffer(columns: 80, rows: 24)
        buffer.write("HELLO")
        #expect(buffer.screenLines()[0] == "HELLO")
    }

    @Test("Trailing whitespace is trimmed from screen lines")
    func trimsTrailingWhitespace() {
        let buffer = TerminalBuffer(columns: 80, rows: 24)
        buffer.write("HI")
        // The underlying grid pads with spaces; the string form is trimmed.
        #expect(buffer.screenLines()[0] == "HI")
        #expect(buffer.screenLines()[0].count == 2)
    }

    @Test("Newline advances the cursor to the next row")
    func newlineAdvancesRow() {
        let buffer = TerminalBuffer(columns: 80, rows: 24)
        buffer.write("A\nB")
        let lines = buffer.screenLines()
        #expect(lines[0] == "A")
        #expect(lines[1] == "B")
        #expect(buffer.cursorRow == 1)
    }

    @Test("Carriage return moves the cursor to column zero without a new row")
    func carriageReturnResetsColumn() {
        let buffer = TerminalBuffer(columns: 80, rows: 24)
        buffer.write("ABC\rX")
        #expect(buffer.screenLines()[0] == "XBC")
        #expect(buffer.cursorRow == 0)
    }

    @Test("Backspace moves the cursor back one column")
    func backspaceMovesCursorBack() {
        let buffer = TerminalBuffer(columns: 80, rows: 24)
        buffer.write("AB\u{08}C")
        #expect(buffer.screenLines()[0] == "AC")
    }

    @Test("Writing past the last row scrolls content into scrollback")
    func scrollsIntoScrollback() {
        let buffer = TerminalBuffer(columns: 80, rows: 3)
        buffer.write("one\ntwo\nthree\nfour")
        // "one" scrolled off the top into scrollback.
        #expect(buffer.scrollback == ["one"])
        #expect(buffer.screenLines() == ["two", "three", "four"])
        #expect(buffer.cursorRow == 2)
    }

    @Test("Column overflow wraps to the next line")
    func columnOverflowWraps() {
        let buffer = TerminalBuffer(columns: 3, rows: 4)
        buffer.write("ABCD")
        let lines = buffer.screenLines()
        #expect(lines[0] == "ABC")
        #expect(lines[1] == "D")
    }

    @Test("clearScreen moves non-empty rows into scrollback and resets the cursor")
    func clearScreenSavesToScrollback() {
        let buffer = TerminalBuffer(columns: 80, rows: 24)
        buffer.write("KEEP ME")
        buffer.clearScreen()
        #expect(buffer.scrollback == ["KEEP ME"])
        #expect(buffer.screenLines().allSatisfy { $0.isEmpty })
        #expect(buffer.cursorRow == 0)
        #expect(buffer.cursorCol == 0)
    }

    @Test("reset clears the screen and cursor")
    func resetClearsScreenAndCursor() {
        let buffer = TerminalBuffer(columns: 80, rows: 24)
        buffer.write("SOMETHING\nMORE")
        buffer.reset()
        #expect(buffer.screenLines().allSatisfy { $0.isEmpty })
        #expect(buffer.cursorRow == 0)
        #expect(buffer.cursorCol == 0)
    }

    @Test("reset fully clears scrollback, including the visible screen")
    func resetClearsScrollback() {
        let buffer = TerminalBuffer(columns: 80, rows: 3)
        // Force real scrollback: "old" scrolls off the top; a/b/c stay visible.
        buffer.write("old\na\nb\nc")
        #expect(buffer.scrollback == ["old"])
        buffer.reset()
        // reset() discards prior scrollback AND the visible screen — nothing
        // should be re-captured into scrollback.
        #expect(buffer.scrollback.isEmpty)
        #expect(buffer.screenLines().allSatisfy { $0.isEmpty })
    }

    // MARK: - ANSI CSI escape sequences

    @Test("CSI cursor-position places text at the requested 1-indexed coordinate")
    func csiCursorPosition() {
        let buffer = TerminalBuffer(columns: 80, rows: 24)
        buffer.write("\u{1B}[2;3HX")
        // Row 2, column 3 (1-indexed) -> grid row 1, col 2.
        #expect(buffer.cursorRow == 1)
        #expect(buffer.screenLines()[1] == "  X")
    }

    @Test("CSI erase-display mode 2 clears the screen")
    func csiEraseDisplay() {
        let buffer = TerminalBuffer(columns: 80, rows: 24)
        buffer.write("DIRTY\u{1B}[2J")
        #expect(buffer.screenLines().allSatisfy { $0.isEmpty })
    }

    @Test("CSI erase-line mode 0 clears from the cursor to end of line")
    func csiEraseLine() {
        let buffer = TerminalBuffer(columns: 80, rows: 24)
        // Write ABCDE, move cursor back to column 3, erase to end of line.
        buffer.write("ABCDE\u{1B}[1;3H\u{1B}[0K")
        #expect(buffer.screenLines()[0] == "AB")
    }

    @Test("CSI inverse then reset toggles the cell's inverse flag")
    func csiInverseMode() {
        let buffer = TerminalBuffer(columns: 80, rows: 24)
        buffer.write("\u{1B}[7mA\u{1B}[0mB")
        #expect(buffer.grid[0][0].isInverse == true)
        #expect(buffer.grid[0][1].isInverse == false)
    }

    @Test("CSI relative cursor moves (A/B/C/D) are clamped to the grid")
    func csiRelativeCursorMoves() {
        let buffer = TerminalBuffer(columns: 80, rows: 24)
        buffer.write("\u{1B}[5;5H")   // row 4, col 4 (0-indexed)
        buffer.write("\u{1B}[2A")      // up 2 -> row 2
        buffer.write("\u{1B}[1B")      // down 1 -> row 3
        buffer.write("\u{1B}[3C")      // forward 3 -> col 7
        buffer.write("\u{1B}[2D")      // back 2 -> col 5
        buffer.write("Z")
        #expect(buffer.cursorRow == 3)
        #expect(buffer.screenLines()[3] == "     Z")
    }

    @Test("Unknown escape sequences are ignored")
    func ignoresUnknownEscape() {
        let buffer = TerminalBuffer(columns: 80, rows: 24)
        buffer.write("\u{1B}ZA")
        // ESC Z is unknown; the 'A' still prints.
        #expect(buffer.screenLines()[0] == "A")
    }
}
