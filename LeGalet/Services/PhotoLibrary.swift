import SwiftUI
import Photos
import PhotosUI

// Loads images by their Photos localIdentifier so the household's album bytes
// stay in the library — Le Galet only keeps a reference. Results are cached as
// downscaled UIImages so the cross-fade never hitches decoding a 12 MP photo.
@MainActor
final class PhotoLoader: ObservableObject {
    static let shared = PhotoLoader()
    private var cache: [String: UIImage] = [:]
    private let manager = PHImageManager.default()

    func image(for localId: String, target: CGSize) async -> UIImage? {
        if let hit = cache[localId] { return hit }
        guard !localId.isEmpty else { return nil }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localId], options: nil)
        guard let asset = assets.firstObject else { return nil }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact

        // A fixed 2× is plenty for a propped-up display and avoids the
        // context-dependent UIScreen.main lookup (deprecated in iOS 26).
        let scale: CGFloat = 2
        let size = CGSize(width: target.width * scale, height: target.height * scale)

        let img: UIImage? = await withCheckedContinuation { cont in
            manager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill,
                                 options: options) { image, info in
                // The manager may call back twice (degraded then full); only
                // resume on the final, non-degraded delivery.
                let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if degraded { return }
                cont.resume(returning: image)
            }
        }
        if let img { cache[localId] = img }
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
