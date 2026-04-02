import SwiftUI
import UniformTypeIdentifiers

/// Code editor panel for writing and editing BASIC programs.
struct CodeEditorView: View {
    @Bindable var viewModel: TerminalViewModel
    let themeSettings: ThemeSettings
    @Binding var showingSamples: Bool
    @State private var showingFileImporter = false
    @State private var showingFileExporter = false

    private var theme: TerminalTheme { themeSettings.theme }
    private var termFont: Font { themeSettings.font.font(size: themeSettings.fontSize) }

    var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: $viewModel.editorText)
                .font(termFont)
                .foregroundStyle(theme.textColor)
                .scrollContentBackground(.hidden)
                .background(theme.backgroundColor.opacity(0.95))
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.characters)
                #endif
                .frame(maxWidth: CGFloat.infinity, maxHeight: CGFloat.infinity)

            Divider()

            HStack(spacing: 20) {
                Button { showingSamples = true } label: {
                    Image(systemName: "book")
                }
                .help("Examples")

                Button { showingFileImporter = true } label: {
                    Image(systemName: "folder")
                }
                .help("Open")

                Button { showingFileExporter = true } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .help("Save")

                Spacer()

                Menu {
                    Button("Clear Editor") {
                        viewModel.editorText = ""
                        viewModel.programLines.removeAll()
                    }
                    Button("Clear Terminal") {
                        viewModel.clearTerminal()
                    }
                    Button("Clear Both") {
                        viewModel.editorText = ""
                        viewModel.programLines.removeAll()
                        viewModel.clearTerminal()
                    }
                } label: {
                    Image(systemName: "trash")
                } primaryAction: {
                    viewModel.editorText = ""
                    viewModel.programLines.removeAll()
                }
                .help("Clear (long press for options)")
            }
            .font(.title3)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(theme.backgroundColor.opacity(0.8))
        }
        .background(theme.backgroundColor)
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.plainText],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                if let source = try? String(contentsOf: url) {
                    viewModel.loadProgram(source)
                }
            }
        }
        .fileExporter(
            isPresented: $showingFileExporter,
            document: BASICDocument(text: viewModel.editorText),
            contentType: .plainText,
            defaultFilename: "program.bas"
        ) { _ in }
    }
}

/// A simple text document for file export.
struct BASICDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }

    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(data: data, encoding: .utf8) ?? ""
        } else {
            text = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}
