import Photos
import Combine

// Pure PhotoKit album queries with NO actor isolation, so they can run on a
// background thread. A large iCloud library makes listing/counting/fetching slow,
// and doing any of it on the main thread froze the picker for many seconds — so
// these never touch the main thread, use the instant *estimated* count, and ask
// Photos for only as many assets as we actually need (fetchLimit).
enum AlbumKit {
    struct Info: Identifiable, Hashable {
        let id: String       // PHAssetCollection.localIdentifier
        let title: String
        let count: Int       // estimated; -1 when unknown
    }

    static func albums() -> [Info] {
        // Accurate image count via a predicated fetch — PHFetchResult.count doesn't
        // enumerate, so it's quick, and this whole call already runs off the main
        // thread, so a large library can't freeze the UI.
        func info(_ c: PHAssetCollection) -> Info {
            Info(id: c.localIdentifier, title: c.localizedTitle ?? "Album",
                 count: PHAsset.fetchAssets(in: c, options: imageOptions()).count)
        }
        var out: [Info] = []
        // "Recents" / the whole library first, so there's always something to pick.
        PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
            .enumerateObjects { c, _, _ in out.append(info(c)) }
        PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: nil)
            .enumerateObjects { c, _, _ in if c.estimatedAssetCount != 0 { out.append(info(c)) } }
        var made: [PHAssetCollection] = []
        PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            .enumerateObjects { c, _, _ in made.append(c) }
        made.sort {
            ($0.localizedTitle ?? "").localizedCaseInsensitiveCompare($1.localizedTitle ?? "") == .orderedAscending
        }
        out.append(contentsOf: made.map(info))
        return out
    }

    static func imageCount(collectionID: String) -> Int {
        guard let c = collection(collectionID) else { return 0 }
        return PHAsset.fetchAssets(in: c, options: imageOptions()).count
    }

    // The newest image identifiers in an album, capped — Photos returns at most
    // `limit`, so this stays fast no matter how large the album is.
    static func assetIDs(collectionID: String, limit: Int) -> [String] {
        guard let c = collection(collectionID) else { return [] }
        let opts = imageOptions()
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        if limit > 0 { opts.fetchLimit = limit }
        var ids: [String] = []
        PHAsset.fetchAssets(in: c, options: opts).enumerateObjects { a, _, _ in ids.append(a.localIdentifier) }
        return ids
    }

    static func collection(_ id: String) -> PHAssetCollection? {
        PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [id], options: nil).firstObject
    }

    private static func imageOptions() -> PHFetchOptions {
        let o = PHFetchOptions()
        o.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        return o
    }
}

// Resolves the household's chosen albums into live photo pebbles — the album's
// own bytes stay in the library; only identifiers are referenced. It re-resolves
// whenever the chosen albums change AND whenever the Photos library changes, so a
// freshly added family photo drifts in on its own. Each album's per-item weight
// rides along, so the Composer's frequency dial scales all of its photos. All the
// PhotoKit work happens off the main thread.
@MainActor
final class AlbumLibrary: NSObject, ObservableObject {
    @Published private(set) var pebbles: [Pebble] = []

    struct Spec: Equatable { let id: String; let weight: Int }
    private var specs: [Spec] = []
    private let perAlbumLimit = 80
    private var observing = false

    // Called by RootView with the current album items. No-ops if nothing changed.
    func update(_ newSpecs: [Spec]) {
        guard newSpecs != specs else { return }
        specs = newSpecs
        registerIfNeeded()
        resolve()
    }

    private func registerIfNeeded() {
        guard !observing, !specs.isEmpty else { return }
        observing = true
        PHPhotoLibrary.shared().register(self)
    }

    func resolve() {
        let specsCopy = specs
        let limit = perAlbumLimit
        Task { [weak self] in
            let result = await Task.detached(priority: .userInitiated) { () -> [Pebble] in
                var out: [Pebble] = []
                var seen = Set<String>()   // a photo in two albums shows once
                for spec in specsCopy {
                    for assetID in AlbumKit.assetIDs(collectionID: spec.id, limit: limit)
                    where !seen.contains(assetID) {
                        seen.insert(assetID)
                        out.append(Pebble(id: "alb-\(spec.id)-\(assetID)", kind: .photo,
                                          text: "", photoLocalId: assetID,
                                          weight: max(1, min(3, spec.weight))))
                    }
                }
                return out
            }.value
            self?.pebbles = result
        }
    }
}

extension AlbumLibrary: PHPhotoLibraryChangeObserver {
    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in self.resolve() }
    }
}
