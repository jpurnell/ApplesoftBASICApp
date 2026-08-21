import ApplesoftBASICLib
import AVFoundation

/// Sound handler for the iPad app.
///
/// Uses the library's AudioSoundHandler directly since playTone is now
/// blocking (synchronous) and AVAudioEngine works from any thread.
///
/// `SoundHandler` already requires `Sendable`, and the compiler can check this
/// one: the only stored property is an immutable `AudioSoundHandler`, which
/// vouches for its own thread safety. Nothing here needs `@unchecked`.
#if canImport(AVFoundation)
final class iPadSoundAdapter: SoundHandler {
    private let handler = AudioSoundHandler()

    /// Creates the sound adapter.
    init() {}

    /// Plays a short beep. Blocks for ~150ms.
    func beep() {
        handler.beep()
    }

    /// Plays a tone at the given frequency. Blocks for the duration.
    func playTone(frequency: Double, duration: Double) {
        handler.playTone(frequency: frequency, duration: duration)
    }
}
#else
final class iPadSoundAdapter: SoundHandler {
    init() {}
    func beep() {}
    func playTone(frequency: Double, duration: Double) {}
}
#endif
