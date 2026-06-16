import Foundation

enum PebbleKind: String { case photo, quote, reminder, event }

// A runtime item the engine actually drifts. Produced from stored GaletItems and
// from live EventKit (reminders + calendar). Deliberately value-typed and cheap
// so the playlist can be rebuilt freely.
struct Pebble: Identifiable, Equatable {
    let id: String
    let kind: PebbleKind
    let text: String
    var author: String = ""       // quote attribution
    var subtitle: String = ""     // event time / context line, e.g. "18 h · chez Mamie"
    var photoLocalId: String = "" // for photos
    var weight: Int = 1

    static func == (lhs: Pebble, rhs: Pebble) -> Bool { lhs.id == rhs.id }
}
