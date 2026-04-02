import SwiftUI

/// Available terminal color themes.
enum TerminalTheme: String, CaseIterable, Identifiable, Sendable {
    case greenPhosphor = "Green Phosphor"
    case amberPhosphor = "Amber Phosphor"
    case whitePhosphor = "White Phosphor"
    case paper = "Paper"

    var id: String { rawValue }

    var backgroundColor: Color {
        switch self {
        case .greenPhosphor, .amberPhosphor, .whitePhosphor:
            return .black
        case .paper:
            return Color(red: 1.0, green: 0.97, blue: 0.91)
        }
    }

    var textColor: Color {
        switch self {
        case .greenPhosphor:
            return Color(red: 0.2, green: 1.0, blue: 0.2)
        case .amberPhosphor:
            return Color(red: 1.0, green: 0.69, blue: 0.0)
        case .whitePhosphor:
            return Color(red: 0.9, green: 0.9, blue: 0.9)
        case .paper:
            return Color(red: 0.2, green: 0.2, blue: 0.2)
        }
    }

    var dimTextColor: Color {
        textColor.opacity(0.5)
    }

    var glowColor: Color {
        textColor.opacity(0.4)
    }

    var hasGlow: Bool {
        self != .paper
    }

    var cursorColor: Color {
        textColor
    }

    var inputFieldBackground: Color {
        switch self {
        case .paper:
            return Color(red: 0.95, green: 0.93, blue: 0.87)
        default:
            return Color.white.opacity(0.05)
        }
    }
}

/// Available terminal fonts.
enum TerminalFont: String, CaseIterable, Identifiable, Sendable {
    case printChar21 = "PrintChar21"
    case prNumber3 = "PRNumber3"
    case systemMono = "System Mono"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .printChar21: return "Print Char 21"
        case .prNumber3: return "PR Number 3"
        case .systemMono: return "System Mono"
        }
    }

    func font(size: CGFloat) -> Font {
        switch self {
        case .printChar21:
            return .custom("PrintChar21", size: size)
        case .prNumber3:
            return .custom("PRNumber3", size: size)
        case .systemMono:
            return .system(size: size, design: .monospaced)
        }
    }
}
