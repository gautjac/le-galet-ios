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
    // Show a subtle caption under each photo with its capture date and place,
    // read from the photo's own metadata (absent on photos that carry neither).
    var showPhotoMeta: Bool = true
    // Off (default): always show the whole photo, never cropping. On: fill the
    // screen edge-to-edge, with a slight crop and subject protection.
    var fillScreen: Bool = false
    // When a photo's orientation clashes with the screen's (a portrait photo on a
    // landscape iPad, or the reverse), crop it to fill using Vision to keep the
    // subject — a face, a pet, the focal point — centred, instead of letterboxing.
    var smartCrop: Bool = false
    // Multiplies every pebble's text size (quotes, reminders, captions). 1.0 = the
    // tuned default; the slider runs from cosy (0.8) to across-the-room (1.6).
    var textScale: Double = 1.0
    var tone: String = ""
    var quoteFontRaw: String = "serif"
    var langRaw: String = "fr"
    var onboarded: Bool = false
    var useCalendar: Bool = false        // drift in the day's events
    var useReminders: Bool = false       // drift in reminders
    // Which calendars / reminder lists to draw from, by EKCalendar identifier.
    // Empty means "all of them" — the forgiving default and what new ones inherit.
    var selectedCalendarIDs: [String] = []
    var selectedReminderListIDs: [String] = []

    init() {}

    var lang: Lang { Lang(rawValue: langRaw) ?? .fr }
    var quoteFont: QuoteFont { QuoteFont(rawValue: quoteFontRaw) ?? .serif }
}
