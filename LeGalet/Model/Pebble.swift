import Foundation

// `album` is a stored container, never a runtime pebble: its photos are resolved
// into individual `photo` pebbles at playlist time (see AlbumLibrary).
enum PebbleKind: String { case photo, quote, reminder, event, album }

// A runtime item the engine actually drifts. Produced from stored GaletItems and
// from live EventKit (reminders + calendar). Deliberately value-typed and cheap
// so the playlist can be rebuilt freely.
struct Pebble: Identifiable, Equatable {
    let id: String
    let kind: PebbleKind
    let text: String
    var author: String = ""       // quote attribution
    var subtitle: String = ""     // event time / context line, e.g. "18 h · chez Mamie"
    var notes: String = ""        // the free-text details on an event / reminder
    var photoLocalId: String = "" // for photos
    var weight: Int = 1

    static func == (lhs: Pebble, rhs: Pebble) -> Bool { lhs.id == rhs.id }
}
