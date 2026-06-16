import UIKit
import Vision

// Works out how to frame a photo: its aspect ratio, and the salient region to
// keep in view. Faces win (these are family photos); failing that, Vision's
// attention-based saliency picks the focal point. Used to bias the crop and the
// Ken Burns drift so a subject is never cropped out of frame.
struct PhotoFraming: Equatable {
    var aspect: CGFloat   // width / height
    var focus: CGPoint    // salient centre, normalised, SwiftUI top-left origin

    static let centered = PhotoFraming(aspect: 1, focus: CGPoint(x: 0.5, y: 0.5))

    static func analyze(_ image: UIImage) -> PhotoFraming {
        let aspect = image.size.height > 0 ? image.size.width / image.size.height : 1
        return PhotoFraming(aspect: aspect, focus: saliency(image))
    }

    private static func saliency(_ image: UIImage) -> CGPoint {
        guard let cg = image.cgImage else { return CGPoint(x: 0.5, y: 0.5) }
        let handler = VNImageRequestHandler(
            cgImage: cg, orientation: orientation(image.imageOrientation), options: [:])

        // Faces first — frame the people.
        let faces = VNDetectFaceRectanglesRequest()
        if (try? handler.perform([faces])) != nil, let results = faces.results, !results.isEmpty {
            var box = results[0].boundingBox
            for f in results.dropFirst() { box = box.union(f.boundingBox) }
            return point(box)
        }
        // Otherwise the most salient object.
        let sal = VNGenerateAttentionBasedSaliencyImageRequest()
        if (try? handler.perform([sal])) != nil,
           let obs = sal.results?.first as? VNSaliencyImageObservation,
           let obj = obs.salientObjects?.max(by: { $0.boundingBox.area < $1.boundingBox.area }) {
            return point(obj.boundingBox)
        }
        return CGPoint(x: 0.5, y: 0.5)
    }

    // Vision rects are normalised with a bottom-left origin; flip Y for SwiftUI.
    private static func point(_ r: CGRect) -> CGPoint {
        CGPoint(x: min(max(r.midX, 0), 1), y: min(max(1 - r.midY, 0), 1))
    }

    private static func orientation(_ o: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch o {
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        default: return .up
        }
    }
}

private extension CGRect { var area: CGFloat { width * height } }
