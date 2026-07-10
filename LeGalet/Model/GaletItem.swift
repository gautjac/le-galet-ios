import Foundation
import SwiftData

// One curated pebble the household composed by hand (or imported from the margin
// quotes feed): a photo (referenced by its Photos localIdentifier — bytes stay in
// the library),
// a quote, or a manual time-aware reminder. Live Calendar/Reminders pebbles are
// NOT stored here — they're merged in at playlist time from EventKit.
@Model
final class GaletItem {
    var id: UUID = UUID()
    var typeRaw: String = "quote"   // "photo" | "quote" | "reminder"
    var text: String = ""           // quote body, reminder text, or photo caption
    var author: String = ""         // quote attribution
    var photoLocalId: String = ""   // PHAsset.localIdentifier for photos
    var weight: Int = 1             // 1–3: how often this pebble surfaces
    var order: Int = 0             // manual sort position
    var startAt: Date?             // reminder window
    var endAt: Date?
    var recurrenceRaw: String = "once" // "once" | "daily" | "weekly" | "yearly"
    var active: Bool = true
    var sourceRaw: String = "hand"  // "hand" | "margin"
    var createdAt: Date = Date()

    init(typeRaw: String, text: String = "", author: String = "", photoLocalId: String = "",
         weight: Int = 1, order: Int = 0, startAt: Date? = nil, endAt: Date? = nil,
         recurrenceRaw: String = "once", active: Bool = true, sourceRaw: String = "hand") {
        self.id = UUID()
        self.typeRaw = typeRaw
        self.text = text
        self.author = author
        self.photoLocalId = photoLocalId
        self.weight = weight
        self.order = order
        self.startAt = startAt
        self.endAt = endAt
        self.recurrenceRaw = recurrenceRaw
        self.active = active
        self.sourceRaw = sourceRaw
        self.createdAt = Date()
    }

    var kind: PebbleKind { PebbleKind(rawValue: typeRaw) ?? .quote }
    var recurrence: Recurrence { Recurrence(rawValue: recurrenceRaw) ?? .once }
}

enum Recurrence: String, CaseIterable { case once, daily, weekly, yearly }
