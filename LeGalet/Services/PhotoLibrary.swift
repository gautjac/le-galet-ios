import SwiftUI
import Photos
import PhotosUI
import CoreLocation

// The quiet facts a photo carries: when it was taken and, if the camera saved a
// location, where. `place` is reverse-geocoded to a gentle "City, Region" once
// and memoised. Either field may be absent — a stripped or imported photo often
// has neither, and the caption simply doesn't appear.
struct PhotoMeta: Equatable {
    var date: Date?
    var place: String?

    static let empty = PhotoMeta(date: nil, place: nil)

    // The single subtle line shown under the photo, e.g. "14 juin 2024 · Montréal".
    func line(lang: Lang) -> String? {
        var parts: [String] = []
        if let date { parts.append(Self.dateString(date, lang: lang)) }
        if let place, !place.isEmpty { parts.append(place) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private static func dateString(_ date: Date, lang: Lang) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: lang == .fr ? "fr_CA" : "en_CA")
        f.dateStyle = .long
        f.timeStyle = .none
        return f.string(from: date)
    }
}

// Loads images by their Photos localIdentifier so the household's album bytes
// stay in the library — Le Galet only keeps a reference. Results are cached as
// downscaled UIImages so the cross-fade never hitches decoding a 12 MP photo.
@MainActor
final class PhotoLoader: ObservableObject {
    static let shared = PhotoLoader()
    // Keyed by localId AND the requested pixel size — a 90 px Composer thumbnail
    // must never satisfy a full-screen request (that was the low-res bug). NSCache
    // evicts under memory pressure so a big album can't balloon RAM.
    private let cache = NSCache<NSString, UIImage>()
    private var framingCache: [String: PhotoFraming] = [:]
    private var metaCache: [String: PhotoMeta] = [:]
    private let geocoder = CLGeocoder()
    private let manager = PHImageManager.default()

    init() { cache.countLimit = 24 }

    // The photo's capture date and (reverse-geocoded) place. Read straight off the
    // PHAsset — no pixels needed — then memoised, so a place name is looked up once
    // per photo for the life of the run. Only called when the caption is enabled.
    func meta(for localId: String) async -> PhotoMeta {
        guard !localId.isEmpty else { return .empty }
        if let hit = metaCache[localId] { return hit }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localId], options: nil)
        guard let asset = assets.firstObject else { return .empty }

        var meta = PhotoMeta(date: asset.creationDate, place: nil)
        if let location = asset.location {
            meta.place = await reverseGeocode(location)
        }
        metaCache[localId] = meta
        return meta
    }

    // A gentle "City, Region" (or the best available subset). CLGeocoder is network-
    // backed and rate-limited; results are cached by the caller above so the display
    // never re-asks for a photo it has already placed. A failure just yields nil.
    private func reverseGeocode(_ location: CLLocation) async -> String? {
        guard let placemark = try? await geocoder.reverseGeocodeLocation(location).first
        else { return nil }
        let city = placemark.locality ?? placemark.subAdministrativeArea ?? placemark.name
        let region = placemark.administrativeArea ?? placemark.country
        let parts = [city, region].compactMap { $0 }.filter { !$0.isEmpty }
        // Drop a duplicate (e.g. a city-state where locality == region).
        return parts.count == 2 && parts[0] == parts[1]
            ? parts[0]
            : (parts.isEmpty ? nil : parts.joined(separator: ", "))
    }

    // How to frame a photo (aspect + salient focus), computed once off the main
    // thread via Vision and memoised so a cycling display never recomputes it.
    func framing(for localId: String, image: UIImage) async -> PhotoFraming {
        if let hit = framingCache[localId] { return hit }
        let result = await Task.detached(priority: .userInitiated) {
            PhotoFraming.analyze(image)
        }.value
        framingCache[localId] = result
        return result
    }

    func image(for localId: String, target: CGSize) async -> UIImage? {
        guard !localId.isEmpty else { return nil }

        // Request the WHOLE photo, uncropped: a square max-edge target plus
        // .aspectFit returns the full image scaled to good resolution for any
        // orientation. (.aspectFill here would pre-crop the photo to the target's
        // aspect — which silently chopped portrait photos on a landscape iPad,
        // before the framing layer ever saw them.) A fixed 2× is the iPad's
        // native scale and avoids the deprecated UIScreen.main lookup.
        let edge = (max(target.width, target.height) * 2).rounded()
        let pixel = CGSize(width: edge, height: edge)
        let key = "\(localId)@fit\(Int(edge))" as NSString
        if let hit = cache.object(forKey: key) { return hit }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localId], options: nil)
        guard let asset = assets.firstObject else { return nil }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact

        let img: UIImage? = await withCheckedContinuation { cont in
            var resumed = false
            manager.requestImage(for: asset, targetSize: pixel, contentMode: .aspectFit,
                                 options: options) { image, info in
                // highQualityFormat delivers one final image; guard against any
                // stray degraded/duplicate callback so we resume exactly once.
                let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if degraded || resumed { return }
                resumed = true
                cont.resume(returning: image)
            }
        }
        if let img { cache.setObject(img, forKey: key) }
        return img
    }

    static func requestAccess() async -> PHAuthorizationStatus {
        await withCheckedContinuation { cont in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { cont.resume(returning: $0) }
        }
    }

    // ── Albums ──────────────────────────────────────────────────────────────────
    static func authorizationStatus() -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    // The albums offered in the picker: All Photos (always present, so there's
    // something to pick even with no custom albums), Favorites, then every
    // user-made album. Sorted in Swift — a fetch-level sort on "localizedTitle"
    // is unsupported for collections and can fail on device. Note: enumerating
    // user albums needs FULL library access; under "Selected Photos" (limited)
    // it returns nothing, which is why the picker can look empty.
    func userAlbums() -> [PHAssetCollection] {
        var out: [PHAssetCollection] = []
        PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
            .enumerateObjects { c, _, _ in out.append(c) }   // "Recents" / All Photos
        PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: nil)
            .enumerateObjects { c, _, _ in if c.estimatedAssetCount != 0 { out.append(c) } }
        var userMade: [PHAssetCollection] = []
        PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            .enumerateObjects { c, _, _ in userMade.append(c) }
        userMade.sort {
            ($0.localizedTitle ?? "").localizedCaseInsensitiveCompare($1.localizedTitle ?? "") == .orderedAscending
        }
        out.append(contentsOf: userMade)
        return out
    }

    func collection(for id: String) -> PHAssetCollection? {
        PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [id], options: nil).firstObject
    }

    func assetCount(collectionID: String) -> Int {
        guard let c = collection(for: collectionID) else { return 0 }
        return PHAsset.fetchAssets(in: c, options: imageOptions()).count
    }

    // The most-recent image identifiers in an album, capped — what we resolve to
    // photo pebbles. Newest-first so a freshly added family photo surfaces soon.
    func albumAssetIDs(collectionID: String, limit: Int) -> [String] {
        guard let c = collection(for: collectionID) else { return [] }
        let opts = imageOptions()
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let assets = PHAsset.fetchAssets(in: c, options: opts)
        var ids: [String] = []
        assets.enumerateObjects { a, _, stop in
            if ids.count >= limit { stop.pointee = true; return }
            ids.append(a.localIdentifier)
        }
        return ids
    }

    func albumCover(collectionID: String, target: CGSize) async -> UIImage? {
        guard let first = albumAssetIDs(collectionID: collectionID, limit: 1).first else { return nil }
        return await image(for: first, target: target)
    }

    private func imageOptions() -> PHFetchOptions {
        let o = PHFetchOptions()
        o.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        return o
    }
}

// A multi-select picker that returns Photos localIdentifiers (requires the
// shared library so identifiers come back). The caller persists them as photo
// pebbles; the bytes are never copied out of the library.
struct PhotoPicker: UIViewControllerRepresentable {
    var onPicked: ([String]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 0
        config.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPicked: onPicked) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPicked: ([String]) -> Void
        init(onPicked: @escaping ([String]) -> Void) { self.onPicked = onPicked }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            let ids = results.compactMap { $0.assetIdentifier }
            picker.dismiss(animated: true)
            onPicked(ids)
        }
    }
}
