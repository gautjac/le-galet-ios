import SwiftUI

// Four contrasting voices for the words on the hearth. All drawn from Apple's
// system families (San Francisco / New York) so nothing needs bundling and they
// stay crisp at any size — but each carries a genuinely different feel.
enum QuoteFont: String, CaseIterable, Identifiable {
    case serif    // New York — literary, classic
    case sans     // SF Pro, ultra-light — airy, modern, gallery-quiet
    case rounded  // SF Rounded — warm, soft, friendly
    case mono     // SF Mono — deliberate, typewriter

    var id: String { rawValue }

    private var design: Font.Design {
        switch self {
        case .serif: return .serif
        case .sans: return .default
        case .rounded: return .rounded
        case .mono: return .monospaced
        }
    }

    private var weight: Font.Weight {
        switch self {
        case .serif: return .light
        case .sans: return .ultraLight
        case .rounded: return .regular
        case .mono: return .light
        }
    }

    // Mono runs wide and rounded reads large, so each is nudged to sit evenly.
    private var sizeScale: CGFloat {
        switch self {
        case .mono: return 0.82
        case .rounded: return 0.95
        default: return 1
        }
    }

    var tracking: CGFloat {
        switch self {
        case .sans: return 1.5    // a touch of air suits the thin sans
        case .mono: return 0.5
        default: return 0
        }
    }

    func font(_ size: CGFloat) -> Font {
        .system(size: size * sizeScale, weight: weight, design: design)
    }

    var name: L {
        switch self {
        case .serif: return L(fr: "Élégante", en: "Elegant")
        case .sans: return L(fr: "Claire", en: "Clean")
        case .rounded: return L(fr: "Tendre", en: "Soft")
        case .mono: return L(fr: "Machine", en: "Typewriter")
        }
    }
}
