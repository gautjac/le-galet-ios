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

        // Weighted deck. Stored items use their per-item frequency dial (1–3);
        // live events/reminders are scaled by the household's frequency setting —
        // a whole multiplier adds that many copies, a fraction adds one more with
        // that probability. One RNG, seeded per deal, keeps the deck stable for a
        // few minutes and drives both the fractional choice and the shuffle.
        var rng = SeededRNG(seed: seed(now: now, n: all.count))

        var pool: [Pebble] = []
        for p in stored { for _ in 0..<clampWeight(p.weight) { pool.append(p) } }

        let freq = max(0, settings.liveFrequency)
        for p in live {
            var copies = Int(freq)
            if rng.unit() < (freq - Double(copies)) { copies += 1 }
            for _ in 0..<copies { pool.append(p) }
        }

        guard !pool.isEmpty else { return all }   // never blank the display
        return decluster(seededShuffle(pool, rng: &rng))
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

    private static func clampWeight(_ w: Int) -> Int { max(1, min(3, w)) }

    private static func seededShuffle(_ arr: [Pebble], rng: inout SeededRNG) -> [Pebble] {
        var a = arr
        if a.count > 1 {
            for i in stride(from: a.count - 1, to: 0, by: -1) {
                let j = Int(rng.unit() * Double(i + 1))
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

// A tiny deterministic xorshift generator so a deal stays stable within its time
// bucket (no flicker between rebuilds) yet re-deals when the bucket rolls over.
private struct SeededRNG {
    private var s: UInt32
    init(seed: UInt32) { s = seed == 0 ? 0x9E3779B9 : seed }
    mutating func unit() -> Double {
        s ^= s << 13; s ^= s >> 17; s ^= s << 5
        return Double(s % 100_000) / 100_000
    }
}
