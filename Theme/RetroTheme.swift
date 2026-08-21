import SwiftUI

/// Available terminal color themes.
///
/// The phosphor colours are deliberate — they are the product, not a default
/// anyone should override — but they live in the asset catalogue rather than in
/// literals here so each one can carry a High Contrast variant. With Increase
/// Contrast on, the phosphors brighten and Paper goes to pure black on white.
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
            return Color("PaperBackground")
        }
    }

    var textColor: Color {
        switch self {
        case .greenPhosphor:
            return Color("GreenPhosphorText")
        case .amberPhosphor:
            return Color("AmberPhosphorText")
        case .whitePhosphor:
            return Color("WhitePhosphorText")
        case .paper:
            return Color("PaperText")
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

    var inputFieldBackground: Color {
        switch self {
        case .paper:
            return Color("PaperInputField")
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

    /// The font at the user's chosen point size.
    ///
    /// `relativeTo: .body` layers Dynamic Type on top of that choice, so the
    /// size slider sets the base and the system text-size setting still moves
    /// it. The monospaced option names Menlo rather than asking for
    /// `.system(size:design:)`, because only the `.custom` form takes
    /// `relativeTo:` — a system font pinned to a point size does not scale.
    func font(size: CGFloat) -> Font {
        switch self {
        case .printChar21:
            return .custom("PrintChar21", size: size, relativeTo: .body)
        case .prNumber3:
            return .custom("PRNumber3", size: size, relativeTo: .body)
        case .systemMono:
            return .custom("Menlo", size: size, relativeTo: .body)
        }
    }
}
