import ApplesoftBASICLib

/// Bridges the iPad app's ToneGenerator to the library's SoundHandler protocol.
///
/// The interpreter calls SoundHandler methods from a background thread.
/// This adapter dispatches to @MainActor for the ToneGenerator.
final class iPadSoundAdapter: SoundHandler, @unchecked Sendable {
    private let toneGenerator: ToneGenerator

    /// Creates an adapter wrapping the given tone generator.
    @MainActor
    init(toneGenerator: ToneGenerator) {
        self.toneGenerator = toneGenerator
    }

    /// Plays a short beep via the tone generator.
    func beep() {
        Task { @MainActor [toneGenerator] in
            toneGenerator.beep()
        }
    }

    /// Plays a tone at the given frequency and duration.
    func playTone(frequency: Double, duration: Double) {
        Task { @MainActor [toneGenerator] in
            toneGenerator.playTone(frequency: frequency, duration: duration)
        }
    }
}
