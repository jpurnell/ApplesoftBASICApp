import SwiftUI

/// Browser for bundled sample BASIC programs.
///
/// A sidebar of samples beside a preview of the listing, rather than a list
/// that loads on tap: these programs are the app's documentation as much as its
/// content, and reading one before it replaces the editor's contents is the
/// point. The split layout also matches the main window on iPad and Mac.
struct SampleProgramPicker: View {
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selection: Sample.ID?
    @State private var previewSource = ""

    /// A sample program bundled with the app.
    struct Sample: Identifiable, Hashable {
        /// The resource name, which also identifies the sample.
        let id: String
        let name: String
        let summary: String
    }

    private static let samples: [Sample] = [
        Sample(id: "birthday", name: "Happy Birthday",
               summary: "Apple's 50th birthday song with counting"),
        Sample(id: "astrochart", name: "Astrochart",
               summary: "Steve Jobs' 1975 Atari horoscope program"),
        Sample(id: "guess", name: "Guess the Number",
               summary: "Classic number guessing game"),
        Sample(id: "fibonacci", name: "Fibonacci & Primes",
               summary: "Math: Fibonacci, primes, trig tables"),
        Sample(id: "sinewave", name: "Sine Wave Art",
               summary: "ASCII art: sine waves and bar charts"),
        Sample(id: "adventure", name: "Cupertino Quest",
               summary: "Text adventure: build the Apple I"),
        Sample(id: "graphics", name: "Graphics Demo",
               summary: "Lo-res rainbow, checkerboard, hi-res starburst"),
        Sample(id: "lores-art", name: "Lo-Res Art",
               summary: "Color palette, diamonds, random pixel art"),
        Sample(id: "hires-draw", name: "Hi-Res Drawing",
               summary: "Spiral, box, circle — 280x192 graphics"),
        Sample(id: "music", name: "Music",
               summary: "Musical scale, siren, Happy Birthday melody"),
        Sample(id: "ddpsa", name: "Drunk Driving PSA",
               summary: "D. Goldstein's 1984 animated PSA"),
    ]

    private var selectedSample: Sample? {
        Self.samples.first { $0.id == selection }
    }

    var body: some View {
        NavigationSplitView {
            List(Self.samples, selection: $selection) { sample in
                VStack(alignment: .leading, spacing: 4) {
                    Text(sample.name)
                        .font(.headline)
                    Text(sample.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                .tag(sample.id)
                .contextMenu {
                    Button("Load Program") { load(sample) }
                }
            }
            // "Sample Programs" truncates to "Sample Pro…" beside the Cancel
            // button and the sidebar toggle at this column width.
            .navigationTitle("Samples")
            .navigationSplitViewColumnWidth(min: 240, ideal: 280)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                        .help("Close without loading a program")
                }
            }
        } detail: {
            if let sample = selectedSample {
                detailPane(for: sample)
            } else {
                ContentUnavailableView(
                    "No Sample Selected",
                    systemImage: "book",
                    description: Text("Choose a program to read its listing.")
                )
            }
        }
        // Both columns are worth seeing at once here — the sidebar should sit
        // beside the listing rather than overlay it.
        .navigationSplitViewStyle(.balanced)
        .task(id: selection) {
            previewSource = selection.flatMap(loadSample) ?? ""
        }
        // A macOS sheet sizes itself to its content, and neither a List nor a
        // ScrollView has an intrinsic height — without a minimum the sheet
        // collapses to just its chrome.
        #if os(macOS)
        .frame(minWidth: 720, minHeight: 520)
        #endif
    }

    // MARK: - Detail

    private func detailPane(for sample: Sample) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(sample.summary)
                .foregroundStyle(.secondary)

            ScrollView {
                Text(previewSource.isEmpty ? "Listing unavailable — this sample is missing from the app bundle." : previewSource)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                load(sample)
            } label: {
                Label("Load Program", systemImage: "arrow.down.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(previewSource.isEmpty)
            .help("Replace the editor's contents with \(sample.name)")
        }
        .padding(20)
        .navigationTitle(sample.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Loading

    private func load(_ sample: Sample) {
        guard let source = loadSample(sample.id) else { return }
        onSelect(source)
    }

    private func loadSample(_ filename: String) -> String? {
        // Folder-reference layout: Samples/ is preserved inside the bundle.
        if let url = Bundle.main.url(
            forResource: filename,
            withExtension: "bas",
            subdirectory: "Samples"
        ) {
            return try? String(contentsOf: url, encoding: .utf8)
        }
        // Flattened layout: resources copied to the bundle root.
        if let url = Bundle.main.url(forResource: filename, withExtension: "bas") {
            return try? String(contentsOf: url, encoding: .utf8)
        }
        return nil
    }
}
