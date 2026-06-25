import SwiftUI

// Le Galet — a candle-lit shelf at dusk. The app is always dark (forced in
// Info.plist): near-black charcoal washed with warm grey and riverbed taupe,
// with one muted amber for day that cools to slate-blue at night.
extension Color {
    init(hex: UInt) {
        self = Color(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    static let stoneBase = Color(hex: 0x1C1D22)
    static let stoneDeep = Color(hex: 0x141519)
    static let stoneRaise = Color(hex: 0x23242A)
    static let stoneCard = Color(hex: 0x2B2C33)
    static let stoneLine = Color(hex: 0x3E3F48)

    static let mist = Color(hex: 0xD9D3C8)       // warm grey body text
    static let mistSoft = Color(hex: 0xA8A298)
    static let mistFaint = Color(hex: 0x7C766D)
    static let quoteInk = Color(hex: 0xECE6DB)   // serif quotes

    static let amber = Color(hex: 0xCD9A5C)      // daytime warmth
    static let amberSoft = Color(hex: 0xE0C39B)
    static let slate = Color(hex: 0x6F8190)      // night cool
    static let slateSoft = Color(hex: 0x9AA9B5)

    // Live day-info pebbles (calendar + reminders) sit on a deep teal card — the
    // complement of the amber accent — so they're noticed against the borderless
    // quotes and full-bleed photos. Calendar runs cooler (blue-teal), reminders
    // a touch greener, so the two read as kin but distinct.
    static let eventCardTop = Color(hex: 0x1C3D49)
    static let eventCardBottom = Color(hex: 0x142D37)
    static let reminderCardTop = Color(hex: 0x1E3F39)
    static let reminderCardBottom = Color(hex: 0x15302B)
}

// The live accent: amber by day, slate by night, blended across the threshold.
enum Accent {
    private static let amberRGB = (205.0, 154.0, 92.0)
    private static let slateRGB = (111.0, 129.0, 144.0)

    static func color(nightFactor f: Double) -> Color {
        let t = max(0, min(1, f))
        let r = amberRGB.0 + (slateRGB.0 - amberRGB.0) * t
        let g = amberRGB.1 + (slateRGB.1 - amberRGB.1) * t
        let b = amberRGB.2 + (slateRGB.2 - amberRGB.2) * t
        return Color(red: r / 255, green: g / 255, blue: b / 255)
    }
}

enum Typo {
    // Quotes carry the soul of the display: a humanist serif, large and airy.
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    static func sans(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}
