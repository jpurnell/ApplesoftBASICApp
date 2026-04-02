import AVFoundation

/// Generates square-wave tones for BEEP and SOUND statements.
///
/// Uses AVAudioEngine with a source node to produce retro-style
/// square wave tones at arbitrary frequencies.
@MainActor
final class ToneGenerator {

    private var audioEngine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var isPlaying = false

    /// Current frequency in Hz.
    private var frequency: Double = 440.0

    /// Phase accumulator for waveform generation.
    private nonisolated(unsafe) var phase: Double = 0.0

    /// Thread-safe frequency access for the audio render callback.
    private nonisolated(unsafe) var currentFrequency: Double = 440.0

    /// Plays a BEEP — short 880Hz square wave tone.
    func beep() {
        playTone(frequency: 880, duration: 0.15)
    }

    /// Plays a tone at the specified frequency for the given duration.
    ///
    /// - Parameters:
    ///   - frequency: Frequency in Hz (200-5000 range is reasonable).
    ///   - duration: Duration in seconds.
    func playTone(frequency: Double, duration: Double) {
        let clampedFreq = max(20, min(frequency, 20000))
        self.frequency = clampedFreq
        self.currentFrequency = clampedFreq

        startEngine()

        // Schedule stop after duration
        let durationMs = Int(duration * 1000)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(max(10, durationMs))) {
            self.stopEngine()
        }
    }

    private func startEngine() {
        guard !isPlaying else { return }

        let engine = AVAudioEngine()
        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)

        guard let format else { return }

        phase = 0.0

        let sourceNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, bufferList -> OSStatus in
            guard let self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(bufferList)
            let freq = self.currentFrequency
            let phaseIncrement = freq / sampleRate

            for frame in 0..<Int(frameCount) {
                // Square wave: +0.15 or -0.15 (low volume to avoid harshness)
                let sample: Float = self.phase < 0.5 ? 0.15 : -0.15
                for buffer in ablPointer {
                    let buf = buffer.mData?.assumingMemoryBound(to: Float.self)
                    buf?[frame] = sample
                }
                self.phase += phaseIncrement
                if self.phase >= 1.0 { self.phase -= 1.0 }
            }
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
            self.audioEngine = engine
            self.sourceNode = sourceNode
            self.isPlaying = true
        } catch {
            // Silently fail — sound is non-essential
        }
    }

    private func stopEngine() {
        audioEngine?.stop()
        if let sourceNode {
            audioEngine?.detach(sourceNode)
        }
        sourceNode = nil
        audioEngine = nil
        isPlaying = false
    }
}
