import Foundation
import Testing
@testable import ApplesoftBASICAppCore

/// Tests for the blocking input handoff between the UI and the interpreter.
///
/// Every test here is written so its outcome depends on the inputs, never on
/// scheduling. The channel latches `provide`/`cancel` into locked state rather
/// than relying on a semaphore signal landing while someone happens to be
/// parked, so a waiter that starts *after* the value arrives sees the same
/// result as one that was already waiting. That property is what makes the
/// concurrent tests below deterministic instead of merely usually-green.
struct BlockingInputChannelTests {

    // MARK: - Polling the state machine

    @Test("A fresh channel has nothing to report")
    func freshChannelKeepsWaiting() {
        let channel = BlockingInputChannel()
        #expect(channel.poll() == .keepWaiting)
    }

    @Test("provide makes the input available to the next poll")
    func provideDeliversInput() {
        let channel = BlockingInputChannel()
        channel.provide("HELLO")
        #expect(channel.poll() == .received("HELLO"))
    }

    @Test("Input is consumed by the poll that reads it")
    func inputIsConsumedOnce() {
        let channel = BlockingInputChannel()
        channel.provide("HELLO")
        #expect(channel.poll() == .received("HELLO"))
        #expect(channel.poll() == .keepWaiting)
    }

    @Test("Empty input is delivered, not treated as absent")
    func emptyInputIsDelivered() {
        let channel = BlockingInputChannel()
        channel.provide("")
        #expect(channel.poll() == .received(""))
    }

    @Test("A second provide replaces input that was never read")
    func laterProvideReplacesUnreadInput() {
        let channel = BlockingInputChannel()
        channel.provide("FIRST")
        channel.provide("SECOND")
        #expect(channel.poll() == .received("SECOND"))
        #expect(channel.poll() == .keepWaiting)
    }

    // MARK: - Cancellation

    @Test("cancel is reported to the next poll")
    func cancelIsReported() {
        let channel = BlockingInputChannel()
        channel.cancel()
        #expect(channel.poll() == .cancelled)
    }

    @Test("cancel latches so every later poll still reports it")
    func cancelLatches() {
        let channel = BlockingInputChannel()
        channel.cancel()
        #expect(channel.poll() == .cancelled)
        #expect(channel.poll() == .cancelled)
        #expect(channel.isCancelled)
    }

    @Test("cancel discards input that was provided but never read")
    func cancelDiscardsUnreadInput() {
        let channel = BlockingInputChannel()
        channel.provide("HELLO")
        channel.cancel()
        #expect(channel.poll() == .cancelled)
    }

    @Test("Input provided after cancel does not revive the channel")
    func provideAfterCancelStaysCancelled() {
        let channel = BlockingInputChannel()
        channel.cancel()
        channel.provide("HELLO")
        #expect(channel.poll() == .cancelled)
    }

    // MARK: - Blocking waits

    @Test("awaitInput returns input that was already waiting", .timeLimit(.minutes(1)))
    func awaitInputReturnsLatchedInput() {
        let channel = BlockingInputChannel()
        channel.provide("HELLO")
        #expect(channel.awaitInput() == "HELLO")
    }

    @Test("awaitInput returns nil when the channel was already cancelled", .timeLimit(.minutes(1)))
    func awaitInputReturnsNilWhenAlreadyCancelled() {
        let channel = BlockingInputChannel()
        channel.cancel()
        #expect(channel.awaitInput() == nil)
    }

    @Test("awaitInput wakes when input arrives from another thread", .timeLimit(.minutes(1)))
    func awaitInputWakesOnProvide() async {
        let channel = BlockingInputChannel(waitSlice: .milliseconds(10))
        let waiter = Task.detached { channel.awaitInput() }
        channel.provide("HELLO")
        #expect(await waiter.value == "HELLO")
    }

    @Test("awaitInput wakes when cancel arrives from another thread", .timeLimit(.minutes(1)))
    func awaitInputWakesOnCancel() async {
        let channel = BlockingInputChannel(waitSlice: .milliseconds(10))
        let waiter = Task.detached { channel.awaitInput() }
        channel.cancel()
        #expect(await waiter.value == nil)
    }

    @Test("An expired wait slice keeps waiting instead of giving up", .timeLimit(.minutes(1)))
    func expiredSliceDoesNotEndTheWait() async throws {
        let channel = BlockingInputChannel(waitSlice: .milliseconds(10))
        let waiter = Task.detached { channel.awaitInput() }

        // Outlast several slices before answering. However many actually
        // elapse, the wait must still be live and must still return the input.
        try await Task.sleep(for: .milliseconds(120))
        channel.provide("LATE")

        #expect(await waiter.value == "LATE")
    }

    @Test("A signal banked with no waiter cannot hand back stale input", .timeLimit(.minutes(1)))
    func bankedSignalCannotReplayStaleInput() {
        // The regression this guards: the UI signals when nobody is parked, a
        // counting semaphore banks that signal, and the next wait spends it and
        // returns instantly with input meant for the previous prompt.
        let channel = BlockingInputChannel(waitSlice: .milliseconds(10))
        channel.provide("STALE")

        // Returns without ever parking, so the signal is still banked.
        #expect(channel.awaitInput() == "STALE")

        // The next wait inherits that banked signal. It must still find the
        // channel empty rather than replaying the answer to the last prompt.
        #expect(channel.poll() == .keepWaiting)
    }
}
