import SwiftUI

/// Persisted user preferences for terminal appearance.
@Observable
final class ThemeSettings {
    var theme: TerminalTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "terminalTheme") }
    }
    var font: TerminalFont {
        didSet { UserDefaults.standard.set(font.rawValue, forKey: "terminalFont") }
    }
    var fontSize: CGFloat {
        didSet { UserDefaults.standard.set(fontSize, forKey: "terminalFontSize") }
    }
    var showScanlines: Bool {
        didSet { UserDefaults.standard.set(showScanlines, forKey: "showScanlines") }
    }

    init() {
        let savedTheme = UserDefaults.standard.string(forKey: "terminalTheme") ?? ""
        self.theme = TerminalTheme(rawValue: savedTheme) ?? .greenPhosphor

        let savedFont = UserDefaults.standard.string(forKey: "terminalFont") ?? ""
        self.font = TerminalFont(rawValue: savedFont) ?? .printChar21

        let savedSize = UserDefaults.standard.double(forKey: "terminalFontSize")
        self.fontSize = savedSize > 0 ? savedSize : 18

        self.showScanlines = UserDefaults.standard.bool(forKey: "showScanlines")
    }
}
