import UIKit
import Vision

// Works out how to frame a photo: its aspect, the subject, and what kind of
// subject it is. People and pets are *protected* — never cropped (the display
// shows the whole photo). For everything else we may crop toward the focal point.
struct PhotoFraming: Equatable {
    enum Kind: Equatable { case person, pet, salient, none }

    var aspect: CGFloat   // width / height
    var subject: CGRect   // normalised, SwiftUI top-left origin; padded
    var kind: Kind

    var protectSubject: Bool { kind == .person || kind == .pet }
    var hasSubject: Bool { kind != .none }

    static let centered = PhotoFraming(
        aspect: 1, subject: CGRect(x: 0, y: 0, width: 1, height: 1), kind: .none)

    // Just the aspect — no Vision pass, for the whole-photo (no-crop) mode.
    static func justAspect(_ image: UIImage) -> PhotoFraming {
        PhotoFraming(aspect: image.size.height > 0 ? image.size.width / image.size.height : 1,
                     subject: CGRect(x: 0, y: 0, width: 1, height: 1), kind: .none)
    }

    static func analyze(_ image: UIImage) -> PhotoFraming {
        let aspect = image.size.height > 0 ? image.size.width / image.size.height : 1
        guard let cg = image.cgImage else {
            return PhotoFraming(aspect: aspect, subject: unit, kind: .none)
        }
        let handler = VNImageRequestHandler(
            cgImage: cg, orientation: orientation(image.imageOrientation), options: [:])

        // ── People (faces + bodies) — the dominant person, not background diners ──
        if let box = personBox(handler) {
            return PhotoFraming(aspect: aspect, subject: toTopLeft(box), kind: .person)
        }
        // ── Pets — the dog is family ──
        if let animals = try? perform(handler, VNRecognizeAnimalsRequest()) as? [VNRecognizedObjectObservation],
           let biggest = animals.max(by: { $0.boundingBox.area < $1.boundingBox.area }) {
            return PhotoFraming(aspect: aspect,
                                subject: toTopLeft(pad(biggest.boundingBox, top: 0.12, sides: 0.1, bottom: 0.1)),
                                kind: .pet)
        }
        // ── Otherwise the focal point, unless it covers most of the frame ──
        let sal = VNGenerateAttentionBasedSaliencyImageRequest()
        if (try? handler.perform([sal])) != nil,
           let obs = sal.results?.first as? VNSaliencyImageObservation,
           let obj = obs.salientObjects?.max(by: { $0.boundingBox.area < $1.boundingBox.area }),
           obj.boundingBox.area <= 0.7 {
            return PhotoFraming(aspect: aspect,
                                subject: toTopLeft(pad(obj.boundingBox, top: 0.12, sides: 0.12, bottom: 0.12)),
                                kind: .salient)
        }
        return PhotoFraming(aspect: aspect, subject: unit, kind: .none)
    }

    // The dominant person: prefer the largest body (head→torso) so the head is
    // always inside the box; fall back to the foreground faces. Background people
    // (much smaller than the main subject) are ignored.
    private static func personBox(_ handler: VNImageRequestHandler) -> CGRect? {
        let humans = (try? perform(handler, VNDetectHumanRectanglesRequest()) as? [VNHumanObservation]) ?? []
        let faces = (try? perform(handler, VNDetectFaceRectanglesRequest()) as? [VNFaceObservation]) ?? []
        let humanBoxes = humans.map { $0.boundingBox }
        let faceBoxes = faces.map { $0.boundingBox }

        if let biggestHuman = humanBoxes.max(by: { $0.area < $1.area }) {
            // Include the matching face's head if a real face sits inside the body.
            var box = biggestHuman
            if let headFace = faceBoxes
                .filter({ $0.intersects(biggestHuman) })
                .max(by: { $0.area < $1.area }) {
                box = box.union(pad(headFace, top: 0.6, sides: 0.1, bottom: 0.0))
            }
            return pad(box, top: 0.04, sides: 0.04, bottom: 0.02).intersection(unit)
        }

        guard let biggestFace = faceBoxes.max(by: { $0.area < $1.area }) else { return nil }
        // Keep only foreground faces (>=40% of the largest); union them.
        let foreground = faceBoxes.filter { $0.area >= 0.4 * biggestFace.area }
        var box = foreground.first ?? biggestFace
        for f in foreground.dropFirst() { box = box.union(f) }
        return pad(box, top: 0.8, sides: 0.3, bottom: 0.35)
    }

    // MARK: helpers
    private static let unit = CGRect(x: 0, y: 0, width: 1, height: 1)

    private static func perform(_ handler: VNImageRequestHandler, _ req: VNImageBasedRequest) throws -> Any? {
        try handler.perform([req])
        return req.results
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
