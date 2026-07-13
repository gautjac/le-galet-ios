import Foundation
import SwiftData

// A few quiet quotes so a brand-new display has something to breathe with before
// the household has added a single photo. Seeded once, on first launch.
enum SeedContent {
    // All public-domain: every author died well over 70 years ago (or it's a
    // proverb), so the app ships no copyrighted text. A calm, home-and-light mix
    // of French and English voices.
    static let quotes: [(fr: String, en: String, author: String)] = [
        ("Rien n'est plus doux que la lumière du matin sur une maison tranquille.",
         "Nothing is gentler than morning light on a quiet house.", "Proverbe"),
        ("La vie est une fleur dont l'amour est le miel.",
         "Life is a flower of which love is the honey.", "Victor Hugo"),
        ("Ce n'est qu'une fois perdus que nous commençons à nous retrouver.",
         "Not till we are lost do we begin to find ourselves.", "Henry David Thoreau"),
        ("L'éternité est faite d'instants présents.",
         "Forever is composed of nows.", "Emily Dickinson"),
        ("Le vrai voyage de découverte n'est pas de chercher de nouveaux paysages, mais d'avoir de nouveaux yeux.",
         "The real voyage of discovery lies not in seeking new landscapes, but in having new eyes.", "Marcel Proust"),
        ("Grave dans ton cœur que chaque jour est le plus beau de l'année.",
         "Write it on your heart that every day is the best day in the year.", "Ralph Waldo Emerson"),
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
