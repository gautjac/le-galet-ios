import Foundation
import SwiftData

// The whole "souffle" of the display. A single row, fetched-or-created at launch.
@Model
final class GaletSettings {
    var id: Int = 1
    var fadeSeconds: Double = 2.6
    var dwellSeconds: Double = 11
    var shuffle: Bool = true
    var dayStartMinutes: Int = 7 * 60    // 07:00
    var nightStartMinutes: Int = 21 * 60 // 21:00
    var nightDim: Double = 0.6           // 0–1 brightness drop at the heart of night
    var kenBurns: Bool = true
    var showClock: Bool = true
    var tone: String = ""
    var quoteFontRaw: String = "serif"
    var langRaw: String = "fr"
    var onboarded: Bool = false
    var useCalendar: Bool = false        // drift in the day's events
    var useReminders: Bool = false       // drift in reminders

    init() {}

    var lang: Lang { Lang(rawValue: langRaw) ?? .fr }
    var quoteFont: QuoteFont { QuoteFont(rawValue: quoteFontRaw) ?? .serif }
}
