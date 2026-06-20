import Foundation
import SwiftData

// The margin-quotes feed — the native counterpart of the web app's src/feed.ts.
//
// Quotes Jacques saves off a magazine's margin (the "Save to quotes" button in
// Les Marges) land in the vault at ~/Claude/wiki/quotes/*.md. A launchd job
// compiles them into le-galet.netlify.app/quotes-feed.json. This service is the
// receiving end on the iPad: on launch (and every few hours, since the kitchen
// display rarely relaunches) it pulls the feed and imports anything new.
//
// Two rules keep it gentle, matching the web:
//   1. Import only ids never seen before — deleting a quote on the display makes
//      it stay gone; the next sync won't resurrect it.
//   2. Skip any quote whose text already exists locally — a line typed by hand
//      (or seeded) never doubles up.
//
// The store is local (no CloudKit), so the per-device seen-set in UserDefaults is
// the right scope: each display tracks what it has imported independently.
enum MarginFeed {
    static let endpoint = URL(string: "https://le-galet.netlify.app/quotes-feed.json")!
    private static let seenKey = "le-galet.feed-seen-ids"
    private static let refreshInterval: Duration = .seconds(6 * 60 * 60)

    private struct FeedItem: Decodable {
        let id: String
        let text: String
        let author: String?
        let source: String?
    }

    // Re-entrancy guard. Isolated to the main actor (importIfNeeded is too), so
    // checking/flipping it is race-free; a second call during the network await
    // returns immediately instead of double-importing.
    @MainActor private static var inFlight = false

    /// Fetch the feed and import any new quotes. Safe to call repeatedly.
    /// Returns the number of quotes actually added.
    @MainActor
    @discardableResult
    static func importIfNeeded(_ context: ModelContext) async -> Int {
        if inFlight { return 0 }
        inFlight = true
        defer { inFlight = false }

        let feed: [FeedItem]
        do {
            var req = URLRequest(url: endpoint, cachePolicy: .reloadIgnoringLocalCacheData)
            req.timeoutInterval = 20
            let (data, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, http.statusCode >= 400 { return 0 }
            feed = try JSONDecoder().decode([FeedItem].self, from: data)
        } catch {
            return 0 // offline, or feed not deployed yet — silent, try again later
        }
        guard !feed.isEmpty else { return 0 }

        var seen = loadSeen()
        let fresh = feed.filter { !$0.id.isEmpty && !$0.text.isEmpty && !seen.contains($0.id) }
        guard !fresh.isEmpty else { return 0 }

        // Guard against re-adding a line the household already has by some other route.
        let existing = (try? context.fetch(FetchDescriptor<GaletItem>())) ?? []
        var existingText = Set(existing.filter { $0.kind == .quote }.map { normKey($0.text) })
        var order = (existing.map { $0.order }.max() ?? -1) + 1

        var added = 0
        for q in fresh {
            let text = q.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = normKey(text)
            if !text.isEmpty && !existingText.contains(key) {
                context.insert(GaletItem(
                    typeRaw: PebbleKind.quote.rawValue,
                    text: text,
                    author: (q.author ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                    order: order,
                    sourceRaw: "margin"
                ))
                existingText.insert(key)
                order += 1
                added += 1
            }
            seen.insert(q.id) // mark seen even if skipped, so we don't reconsider it
        }
        if added > 0 { try? context.save() }
        saveSeen(seen)
        return added
    }

    /// Import once now, then top up on a slow timer for as long as the display
    /// stays open. Cancelled automatically when the owning view goes away.
    @MainActor
    static func keepFresh(_ context: ModelContext) async {
        await importIfNeeded(context)
        while !Task.isCancelled {
            try? await Task.sleep(for: refreshInterval)
            if Task.isCancelled { break }
            await importIfNeeded(context)
        }
    }

    // MARK: - helpers

    private static func normKey(_ t: String) -> String {
        t.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private static func loadSeen() -> Set<String> {
        let arr = UserDefaults.standard.array(forKey: seenKey) as? [String] ?? []
        return Set(arr)
    }

    private static func saveSeen(_ seen: Set<String>) {
        UserDefaults.standard.set(Array(seen), forKey: seenKey)
    }
}
