import Photos
import Combine

// Resolves the household's chosen albums into live photo pebbles — the album's
// own bytes stay in the library; only identifiers are referenced. It re-resolves
// whenever the chosen albums change AND whenever the Photos library changes, so a
// freshly added family photo drifts in on its own. Each album's per-item weight
// rides along, so the Composer's frequency dial scales all of its photos.
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
        var out: [Pebble] = []
        var seen = Set<String>()   // a photo in two albums shows once
        for spec in specs {
            let ids = PhotoLoader.shared.albumAssetIDs(collectionID: spec.id, limit: perAlbumLimit)
            for assetID in ids where !seen.contains(assetID) {
                seen.insert(assetID)
                out.append(Pebble(id: "alb-\(spec.id)-\(assetID)", kind: .photo,
                                  text: "", photoLocalId: assetID,
                                  weight: max(1, min(3, spec.weight))))
            }
        }
        pebbles = out
    }
}

extension AlbumLibrary: PHPhotoLibraryChangeObserver {
    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in self.resolve() }
    }
}
