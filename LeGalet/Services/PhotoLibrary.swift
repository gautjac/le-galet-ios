import SwiftUI
import Photos
import PhotosUI

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
    private let manager = PHImageManager.default()

    init() { cache.countLimit = 24 }

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
