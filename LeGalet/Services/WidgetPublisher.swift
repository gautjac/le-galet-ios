import SwiftUI
import SwiftData
import WidgetKit

// Hands the widget a small snapshot of the current carousel. Best-effort and
// entirely additive: it reads the already-loaded items + live events, writes a
// tiny JSON file and a few downscaled JPEGs into the App Group, and asks WidgetKit
// to reload. It never mutates the model or the display engine, so it is safe to
// call on launch and on any change.
@MainActor
enum WidgetPublisher {
    static func publish(items: [GaletItem], settings: GaletSettings, events: EventBridge) async {
        var snap = CarouselSnapshot(lang: settings.langRaw)

        // Quotes: the household's active quotes in manual order; seed set if none.
        let quotes = items
            .filter { $0.kind == .quote && $0.active && !$0.text.isEmpty }
            .sorted { $0.order < $1.order }
            .prefix(12)
            .map { CarouselSnapshot.Quote(text: $0.text, author: $0.author) }
        snap.quotes = quotes.isEmpty
            ? CarouselSnapshot.seeded(lang: settings.langRaw).quotes
            : Array(quotes)

        // The day's next event, pre-formatted, when calendar drift is on.
        if settings.useCalendar, let ev = events.eventPebbles.first {
            snap.event = .init(title: ev.text, line: ev.subtitle)
        }

        // Up to 4 active photos → downscaled JPEGs the widget can load directly.
        if let dir = CarouselShared.photosDirURL {
            (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil))?
                .forEach { try? FileManager.default.removeItem(at: $0) }

            let ids = items
                .filter { $0.kind == .photo && $0.active && !$0.photoLocalId.isEmpty }
                .sorted { $0.order < $1.order }
                .prefix(4)
                .map { $0.photoLocalId }

            var files: [String] = []
            for (i, id) in ids.enumerated() {
                guard let img = await PhotoLoader.shared.image(for: id,
                                                               target: CGSize(width: 600, height: 600)),
                      let data = img.jpegData(compressionQuality: 0.82) else { continue }
                let name = "p\(i).jpg"
                try? data.write(to: dir.appendingPathComponent(name), options: .atomic)
                files.append(name)
            }
            snap.photoFiles = files
        }

        snap.updatedAt = Date()
        snap.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
