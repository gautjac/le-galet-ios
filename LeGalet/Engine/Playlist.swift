import Foundation

// Merge the household's stored pebbles with the live EventKit pebbles, drop
// anything outside its time window, then weight + decluster into the sequence
// the engine drifts through.
enum Playlist {
    static func build(items: [GaletItem], live: [Pebble], settings: GaletSettings, now: Date) -> [Pebble] {
        let stored: [Pebble] = items
            .filter { $0.active }
            .filter { TimeOfDay.reminderActive($0, now) }
            .sorted { $0.order < $1.order }
            .map { item in
                Pebble(
                    id: item.id.uuidString,
                    kind: item.kind,
                    text: item.text,
                    author: item.author,
                    photoLocalId: item.photoLocalId,
                    weight: max(1, min(3, item.weight))
                )
            }

        let all = stored + live
        guard !all.isEmpty else { return [] }
        guard settings.shuffle else { return all }

        // Weighted: a higher-weight pebble takes more slots in the deck.
        var pool: [Pebble] = []
        for p in all { for _ in 0..<max(1, min(3, p.weight)) { pool.append(p) } }

        let shuffled = seededShuffle(pool, seed: seed(now: now, n: all.count))
        return decluster(shuffled)
    }

    // Avoid the same pebble — and, softly, the same kind — landing back to back.
    private static func decluster(_ items: [Pebble]) -> [Pebble] {
        var out: [Pebble] = []
        var rem = items
        while !rem.isEmpty {
            var idx = rem.firstIndex { p in out.last == nil || p.id != out.last!.id } ?? 0
            if let prev = out.last {
                if rem[idx].kind == prev.kind,
                   let alt = rem.firstIndex(where: { $0.id != prev.id && $0.kind != prev.kind }) {
                    idx = alt
                }
            }
            out.append(rem.remove(at: idx))
        }
        return out
    }

    private static func seededShuffle(_ arr: [Pebble], seed: UInt32) -> [Pebble] {
        var a = arr
        var s = seed == 0 ? 0x9E3779B9 : seed
        func rnd() -> Double {
            s ^= s << 13; s ^= s >> 17; s ^= s << 5
            return Double(s % 100_000) / 100_000
        }
        if a.count > 1 {
            for i in stride(from: a.count - 1, to: 0, by: -1) {
                let j = Int(rnd() * Double(i + 1))
                a.swapAt(i, j)
            }
        }
        return a
    }

    // Re-deal roughly every few minutes on a long-idle display, never mid-cycle.
    private static func seed(now: Date, n: Int) -> UInt32 {
        let bucket = UInt32(truncatingIfNeeded: Int(now.timeIntervalSince1970) / 240)
        return bucket &* 2_654_435_761 &+ UInt32(n &* 40_503)
    }
}
