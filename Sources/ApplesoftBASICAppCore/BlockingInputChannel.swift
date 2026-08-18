import Foundation

/// Hands a line of input from the UI to a thread that is blocked waiting for
/// it, independent of any UI framework or interpreter.
///
/// The interpreter runs synchronously on a background thread. When it reaches
/// an `INPUT` or `GET`, it has to stop until the user types something, so the
/// thread genuinely blocks. This channel is the handoff: the UI calls
/// ``provide(_:)`` or ``cancel()``, and the parked thread wakes.
///
/// Two properties matter more than they look:
///
/// - **Each wait carries a deadline.** Input itself never times out — a user
///   may take as long as they like to type — but the thread wakes every
///   ``waitSlice`` to re-read its state rather than sleeping forever on a
///   signal that may never arrive.
/// - **The locked state is the source of truth, not the semaphore.** The
///   semaphore is only a wake-up hint. ``cancel()`` can be called when nobody
///   is parked, and a counting semaphore would bank that signal and spend it on
///   the *next* wait, which would return immediately with stale input. Reading
///   consumes, so a wait can only return what was provided for it.
///
/// A channel is single-use with respect to cancellation: once cancelled it
/// stays cancelled, so a stop issued between two prompts still ends the next
/// one. Callers create a fresh channel per program run.
// Justification: mutable state is guarded by `stateLock`; the semaphore is only a wake-up hint.
public final class BlockingInputChannel: @unchecked Sendable {

    /// What a single step of the channel's state machine found.
    public enum Outcome: Equatable, Sendable {
        /// Input is available and has been consumed by this step.
        case received(String)
        /// The channel was cancelled; the waiter should give up.
        case cancelled
        /// Nothing has arrived yet; the waiter should park again.
        case keepWaiting
    }

    /// How long a single blocking wait parks before re-reading the state.
    public let waitSlice: DispatchTimeInterval

    private let semaphore = DispatchSemaphore(value: 0)
    private let stateLock = NSLock()
    private var pendingInput: String?
    private var cancelled = false

    /// Creates an input channel.
    /// - Parameter waitSlice: How long each blocking wait parks before
    ///   re-reading the channel's state. The default is short enough that a
    ///   stop feels immediate and long enough that an idle prompt costs
    ///   nothing. Tests shorten it to exercise the loop.
    public init(waitSlice: DispatchTimeInterval = .milliseconds(250)) {
        self.waitSlice = waitSlice
    }

    /// Whether the channel has been cancelled.
    public var isCancelled: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return cancelled
    }

    /// Blocks the calling thread until input arrives or the channel is
    /// cancelled.
    ///
    /// - Returns: The provided input, or `nil` if the channel was cancelled.
    public func awaitInput() -> String? {
        var outcome = poll()
        while outcome == .keepWaiting {
            _ = semaphore.wait(timeout: .now() + waitSlice)
            outcome = poll()
        }

        if case .received(let input) = outcome {
            return input
        }
        return nil
    }

    /// Delivers input to whoever is waiting, waking them.
    ///
    /// Input that is never read is replaced by a later call rather than
    /// queued — the waiter wants the answer to the prompt it is showing now.
    /// - Parameter text: The text the user entered.
    public func provide(_ text: String) {
        stateLock.lock()
        pendingInput = text
        stateLock.unlock()
        semaphore.signal()
    }

    /// Cancels the channel, waking any waiter with `nil`.
    ///
    /// Any unread input is discarded: a stop supersedes an answer the waiter
    /// has not picked up yet. Cancellation latches.
    public func cancel() {
        stateLock.lock()
        pendingInput = nil
        cancelled = true
        stateLock.unlock()
        semaphore.signal()
    }

    /// Reads the channel's state once, without blocking, consuming any input
    /// it finds.
    ///
    /// This is the whole decision the blocking loop makes, separated out so it
    /// can be tested without threads.
    /// - Returns: What the caller should do next.
    func poll() -> Outcome {
        stateLock.lock()
        defer { stateLock.unlock() }

        if cancelled { return .cancelled }
        if let input = pendingInput {
            pendingInput = nil
            return .received(input)
        }
        return .keepWaiting
    }
}
