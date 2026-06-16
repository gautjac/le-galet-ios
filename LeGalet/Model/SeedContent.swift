import Foundation
import SwiftData

// A few quiet quotes so a brand-new display has something to breathe with before
// the household has added a single photo. Seeded once, on first launch.
enum SeedContent {
    static let quotes: [(fr: String, en: String, author: String)] = [
        ("La mer, qu'on voit danser le long des golfes clairs.",
         "The sea, that we see dancing along the clear gulfs.", "Charles Trenet"),
        ("Le bonheur est la seule chose qui se double si on le partage.",
         "Happiness is the only thing that doubles when you share it.", "Albert Schweitzer"),
        ("Rien n'est plus doux que la lumière du matin sur une maison tranquille.",
         "Nothing is gentler than morning light on a quiet house.", "Proverbe"),
        ("On n'habite pas un pays, on habite une langue.",
         "We do not live in a country, we live in a language.", "Emil Cioran"),
    ]

    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<GaletItem>())) ?? 0
        guard count == 0 else { return }
        let lang = currentLang(context)
        for (i, q) in quotes.enumerated() {
            let item = GaletItem(
                typeRaw: PebbleKind.quote.rawValue,
                text: lang == .fr ? q.fr : q.en,
                author: q.author,
                order: i
            )
            context.insert(item)
        }
        try? context.save()
    }

    private static func currentLang(_ context: ModelContext) -> Lang {
        let s = try? context.fetch(FetchDescriptor<GaletSettings>()).first
        return s?.lang ?? .fr
    }
}
