import UIKit
import Vision

// Works out how to frame a photo: its aspect ratio and the subject to protect —
// the region that must never be cropped. People win (these are family photos),
// then pets (Vision animal detection — the dog is family too), then the visual
// focal point. The box is padded to include heads/hair. `hasSubject` is false
// when nothing specific stands out (then any gentle crop is fine).
struct PhotoFraming: Equatable {
    var aspect: CGFloat        // width / height
    var subject: CGRect        // normalised, SwiftUI top-left origin; padded
    var hasSubject: Bool

    static let centered = PhotoFraming(
        aspect: 1, subject: CGRect(x: 0, y: 0, width: 1, height: 1), hasSubject: false)

    static func analyze(_ image: UIImage) -> PhotoFraming {
        let aspect = image.size.height > 0 ? image.size.width / image.size.height : 1
        if let box = subjectBox(image) {
            return PhotoFraming(aspect: aspect, subject: box, hasSubject: true)
        }
        return PhotoFraming(aspect: aspect,
                            subject: CGRect(x: 0, y: 0, width: 1, height: 1), hasSubject: false)
    }

    private static let unit = CGRect(x: 0, y: 0, width: 1, height: 1)

    private static func subjectBox(_ image: UIImage) -> CGRect? {
        guard let cg = image.cgImage else { return nil }
        let handler = VNImageRequestHandler(
            cgImage: cg, orientation: orientation(image.imageOrientation), options: [:])

        // 1. Human faces — pad generously upward to keep hair/forehead in frame.
        let faces = VNDetectFaceRectanglesRequest()
        if (try? handler.perform([faces])) != nil, let r = faces.results, !r.isEmpty {
            var box = r[0].boundingBox
            for f in r.dropFirst() { box = box.union(f.boundingBox) }
            // Vision origin is bottom-left, so "up" (hair) is +y / more height.
            return toTopLeft(pad(box, top: 0.75, sides: 0.30, bottom: 0.30))
        }

        // 2. Pets — the dog is family. Vision recognises cats & dogs.
        let animals = VNRecognizeAnimalsRequest()
        if (try? handler.perform([animals])) != nil, let r = animals.results, !r.isEmpty {
            var box = r[0].boundingBox
            for a in r.dropFirst() { box = box.union(a.boundingBox) }
            return toTopLeft(pad(box, top: 0.18, sides: 0.12, bottom: 0.12))
        }

        // 3. Otherwise the most salient object — unless it covers most of the frame,
        // in which case there's no single subject to protect.
        let sal = VNGenerateAttentionBasedSaliencyImageRequest()
        if (try? handler.perform([sal])) != nil,
           let obs = sal.results?.first as? VNSaliencyImageObservation,
           let obj = obs.salientObjects?.max(by: { $0.boundingBox.area < $1.boundingBox.area }) {
            let b = obj.boundingBox
            if b.width * b.height > 0.7 { return nil }
            return toTopLeft(pad(b, top: 0.12, sides: 0.12, bottom: 0.12))
        }
        return nil
    }

    private static func pad(_ r: CGRect, top: CGFloat, sides: CGFloat, bottom: CGFloat) -> CGRect {
        CGRect(x: r.minX - r.width * sides,
               y: r.minY - r.height * bottom,
               width: r.width * (1 + sides * 2),
               height: r.height * (1 + top + bottom)).intersection(unit)
    }

    // Vision rects are normalised with a bottom-left origin; flip Y for SwiftUI.
    private static func toTopLeft(_ r: CGRect) -> CGRect {
        CGRect(x: r.minX, y: 1 - r.maxY, width: r.width, height: r.height).intersection(unit)
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
