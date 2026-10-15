import Foundation

// The one small thing the app and its widget both know about.
//
// The widget runs in a separate process and can't open the app's SwiftData store
// (that would mean migrating the live store into a shared container — a real
// migration, not a spike). Instead the app publishes a tiny JSON "snapshot" of
// the current carousel into a shared App Group container, plus a few downscaled
// photo JPEGs, and the widget reads only that. Cheap to write, cheap to read, and
// it never touches the display engine or the store's location.

enum CarouselShared {
    // Must match the App Group added to both targets' entitlements.
    static let appGroup = "group.com.jac.LeGalet"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
    }
    static var snapshotURL: URL? {
        containerURL?.appendingPathComponent("carousel-snapshot.json")
    }
    // Where the app drops downscaled JPEGs of the curated photos for the widget.
    static var photosDirURL: URL? {
        guard let c = containerURL else { return nil }
        let d = c.appendingPathComponent("widget-photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }
    static func photoURL(_ name: String) -> URL? {
        photosDirURL?.appendingPathComponent(name)
    }
}

struct CarouselSnapshot: Codable {
    struct Quote: Codable, Hashable { var text: String; var author: String }
    struct Event: Codable, Hashable { var title: String; var line: String }

    var lang: String = "fr"
    var quotes: [Quote] = []
    var photoFiles: [String] = []   // filenames inside CarouselShared.photosDirURL
    var event: Event?               // today's next event, pre-formatted
    var updatedAt: Date = Date()

    // MARK: Persistence

    static func load() -> CarouselSnapshot? {
        guard let url = CarouselShared.snapshotURL,
              let data = try? Data(contentsOf: url),
              let snap = try? JSONDecoder().decode(CarouselSnapshot.self, from: data)
        else { return nil }
        return snap
    }

    func save() {
        guard let url = CarouselShared.snapshotURL,
              let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: url, options: .atomic)
    }

    // MARK: Fallback content

    // The device's best-guess language when there's no snapshot yet.
    static var deviceLang: String {
        (Locale.current.language.languageCode?.identifier == "fr") ? "fr" : "en"
    }

    // Public-domain seed quotes (mirrors SeedContent), so a freshly added widget
    // has something to breathe with before the household has curated anything.
    static func seeded(lang: String) -> CarouselSnapshot {
        let fr = lang == "fr"
        let q: [Quote] = [
            .init(text: fr ? "Rien n'est plus doux que la lumière du matin sur une maison tranquille."
                           : "Nothing is gentler than morning light on a quiet house.",
                  author: fr ? "Proverbe" : "Proverb"),
            .init(text: fr ? "La vie est une fleur dont l'amour est le miel."
                           : "Life is a flower of which love is the honey.", author: "Victor Hugo"),
            .init(text: fr ? "L'éternité est faite d'instants présents."
                           : "Forever is composed of nows.", author: "Emily Dickinson"),
            .init(text: fr ? "Grave dans ton cœur que chaque jour est le plus beau de l'année."
                           : "Write it on your heart that every day is the best day in the year.",
                  author: "Ralph Waldo Emerson"),
        ]
        return CarouselSnapshot(lang: lang, quotes: q, photoFiles: [], event: nil)
    }
}
