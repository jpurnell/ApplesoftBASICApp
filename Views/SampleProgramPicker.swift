import SwiftUI

/// Browser for bundled sample BASIC programs.
struct SampleProgramPicker: View {
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    private let samples: [(name: String, filename: String, description: String)] = [
        ("Happy Birthday", "birthday",
         "Apple's 50th birthday song with counting"),
        ("Astrochart", "astrochart",
         "Steve Jobs' 1975 Atari horoscope program"),
        ("Guess the Number", "guess",
         "Classic number guessing game"),
        ("Fibonacci & Primes", "fibonacci",
         "Math: Fibonacci, primes, trig tables"),
        ("Sine Wave Art", "sinewave",
         "ASCII art: sine waves and bar charts"),
        ("Cupertino Quest", "adventure",
         "Text adventure: build the Apple I"),
        ("Graphics Demo", "graphics",
         "Lo-res rainbow, checkerboard, hi-res starburst"),
        ("Lo-Res Art", "lores-art",
         "Color palette, diamonds, random pixel art"),
        ("Hi-Res Drawing", "hires-draw",
         "Spiral, box, circle — 280x192 graphics"),
        ("Music", "music",
         "Musical scale, siren, Happy Birthday melody"),
        ("Drunk Driving PSA", "ddpsa",
         "D. Goldstein's 1984 animated PSA"),
    ]

    var body: some View {
        NavigationStack {
            List(samples, id: \.filename) { sample in
                Button {
                    if let source = loadSample(sample.filename) {
                        onSelect(source)
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sample.name)
                            .font(.headline)
                        Text(sample.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Sample Programs")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func loadSample(_ filename: String) -> String? {
        // Xcode project resource bundle
        if let url = Bundle.main.url(
            forResource: filename,
            withExtension: "bas",
            subdirectory: "Samples"
        ) {
            return try? String(contentsOf: url)
        }
        // Fallback: main bundle
        if let url = Bundle.main.url(
            forResource: filename,
            withExtension: "bas",
            subdirectory: "Samples"
        ) {
            return try? String(contentsOf: url)
        }
        return nil
    }
}
