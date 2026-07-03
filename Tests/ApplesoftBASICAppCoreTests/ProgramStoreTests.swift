import Testing
@testable import ApplesoftBASICAppCore

struct ProgramStoreTests {

    // MARK: - Storing lines

    @Test("store normalizes to \"<number> <content>\"")
    func storeNormalizes() {
        var store = ProgramStore()
        store.store(lineNumber: 10, content: "PRINT \"HI\"")
        #expect(store.lines[10] == "10 PRINT \"HI\"")
    }

    @Test("store trims surrounding whitespace from content")
    func storeTrimsContent() {
        var store = ProgramStore()
        store.store(lineNumber: 20, content: "   GOTO 10   ")
        #expect(store.lines[20] == "20 GOTO 10")
    }

    @Test("store with empty content removes the line")
    func storeEmptyRemoves() {
        var store = ProgramStore(lines: [10: "10 PRINT"])
        store.store(lineNumber: 10, content: "   ")
        #expect(store.lines[10] == nil)
        #expect(store.isEmpty)
    }

    @Test("store replaces an existing line")
    func storeReplaces() {
        var store = ProgramStore()
        store.store(lineNumber: 10, content: "PRINT 1")
        store.store(lineNumber: 10, content: "PRINT 2")
        #expect(store.lines[10] == "10 PRINT 2")
    }

    @Test("remove and removeAll clear lines")
    func removeAndRemoveAll() {
        var store = ProgramStore(lines: [10: "10 A", 20: "20 B"])
        store.remove(lineNumber: 10)
        #expect(store.lines[10] == nil)
        store.removeAll()
        #expect(store.isEmpty)
    }

    // MARK: - Loading source

    @Test("load parses numbered lines and stores them verbatim (trimmed)")
    func loadParses() {
        var store = ProgramStore()
        store.load(from: "10 PRINT \"A\"\n  20   GOTO 10  \n")
        #expect(store.lines[10] == "10 PRINT \"A\"")
        // Interior spacing of a loaded line is preserved; only ends are trimmed.
        #expect(store.lines[20] == "20   GOTO 10")
    }

    @Test("load ignores blank and non-numbered lines")
    func loadIgnoresNonNumbered() {
        var store = ProgramStore()
        store.load(from: "REM header\n10 PRINT\n\nnot a line")
        #expect(store.lines.count == 1)
        #expect(store.lines[10] == "10 PRINT")
    }

    @Test("load replaces any previous program")
    func loadReplaces() {
        var store = ProgramStore(lines: [99: "99 END"])
        store.load(from: "10 PRINT")
        #expect(store.lines[99] == nil)
        #expect(store.lines[10] == "10 PRINT")
    }

    // MARK: - Rendering

    @Test("source renders lines ascending by line number")
    func sourceIsSorted() {
        let store = ProgramStore(lines: [30: "30 C", 10: "10 A", 20: "20 B"])
        #expect(store.source() == "10 A\n20 B\n30 C")
    }

    // MARK: - LIST

    @Test("listing with no range returns all lines in order")
    func listingAll() {
        let store = ProgramStore(lines: [20: "20 B", 10: "10 A"])
        #expect(store.listing() == ["10 A", "20 B"])
    }

    @Test("listing with a start-end range filters inclusively")
    func listingRange() {
        let store = ProgramStore(lines: [10: "10 A", 20: "20 B", 30: "30 C", 40: "40 D"])
        #expect(store.listing(range: "20-30") == ["20 B", "30 C"])
    }

    @Test("listing with a single number returns just that line")
    func listingSingle() {
        let store = ProgramStore(lines: [10: "10 A", 20: "20 B"])
        #expect(store.listing(range: "20") == ["20 B"])
    }

    // MARK: - DEL

    @Test("deleteLines removes an inclusive range")
    func deleteRange() {
        var store = ProgramStore(lines: [10: "10 A", 20: "20 B", 30: "30 C"])
        store.deleteLines(range: "10-20")
        #expect(store.lines.keys.sorted() == [30])
    }

    @Test("deleteLines with a single number removes just that line")
    func deleteSingle() {
        var store = ProgramStore(lines: [10: "10 A", 20: "20 B"])
        store.deleteLines(range: "10")
        #expect(store.lines.keys.sorted() == [20])
    }
}

struct REPLParserTests {

    @Test("RUN is case-insensitive")
    func parsesRun() {
        #expect(REPLParser.parse("RUN") == .run)
        #expect(REPLParser.parse("run") == .run)
    }

    @Test("LIST with and without a range")
    func parsesList() {
        #expect(REPLParser.parse("LIST") == .list(range: nil))
        #expect(REPLParser.parse("list 10-20") == .list(range: "10-20"))
    }

    @Test("NEW and DEL")
    func parsesNewAndDel() {
        #expect(REPLParser.parse("NEW") == .new)
        #expect(REPLParser.parse("DEL 10-20") == .delete(range: "10-20"))
    }

    @Test("A numbered line becomes a store command with its body")
    func parsesStore() {
        #expect(REPLParser.parse("10 PRINT \"HI\"") == .store(lineNumber: 10, content: "PRINT \"HI\""))
    }

    @Test("A bare line number stores empty content (which removes the line)")
    func parsesBareLineNumber() {
        #expect(REPLParser.parse("10") == .store(lineNumber: 10, content: ""))
    }

    @Test("Line content preserves its original case")
    func preservesContentCase() {
        #expect(REPLParser.parse("10 print \"MixedCase\"") == .store(lineNumber: 10, content: "print \"MixedCase\""))
    }

    @Test("A non-numbered statement is a direct-execution command")
    func parsesDirect() {
        #expect(REPLParser.parse("PRINT 2 + 2") == .direct("PRINT 2 + 2"))
    }

    @Test("Empty input is classified as empty")
    func parsesEmpty() {
        #expect(REPLParser.parse("   ") == .empty)
    }
}
