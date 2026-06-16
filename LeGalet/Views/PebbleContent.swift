import SwiftUI

// Renders a single pebble by kind. Each is its own view with a fresh identity,
// so Ken Burns and any entrance state re-trigger on every dissolve.
struct PebbleContent: View {
    let pebble: Pebble
    let settings: GaletSettings
    let lang: Lang

    var body: some View {
        switch pebble.kind {
        case .photo: PhotoPebble(pebble: pebble, settings: settings)
        case .quote: QuotePebble(pebble: pebble, font: settings.quoteFont)
        case .reminder: ReminderPebble(pebble: pebble, kindIcon: "bell")
        case .event: ReminderPebble(pebble: pebble, kindIcon: "calendar")
        }
    }
}

private struct QuotePebble: View {
    @Environment(\.galetAccent) private var accent
    let pebble: Pebble
    let font: QuoteFont
    var body: some View {
        VStack(spacing: 28) {
            Text(pebble.text)
                .font(font.font(clampQuote))
                .tracking(font.tracking)
                .foregroundStyle(Color.quoteInk)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
            if !pebble.author.isEmpty {
                Text(pebble.author.uppercased())
                    .font(Typo.sans(13, .light))
                    .tracking(3)
                    .foregroundStyle(accent.opacity(0.85))
            }
        }
        .padding(.horizontal, 56)
        .frame(maxWidth: 880)
    }
    // Longer quotes set a touch smaller so they always breathe on screen.
    private var clampQuote: CGFloat { pebble.text.count > 120 ? 30 : 40 }
}

// Reminders and calendar events share a calm, sans-serif treatment with a thin
// accent rule and an optional time/context subtitle.
private struct ReminderPebble: View {
    @Environment(\.galetAccent) private var accent
    let pebble: Pebble
    let kindIcon: String
    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: kindIcon)
                .font(.system(size: 22, weight: .ultraLight))
                .foregroundStyle(accent.opacity(0.8))
            Rectangle()
                .fill(accent.opacity(0.5))
                .frame(width: 40, height: 1)
            Text(pebble.text)
                .font(Typo.sans(34, .light))
                .foregroundStyle(Color.mist)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            if !pebble.subtitle.isEmpty {
                Text(pebble.subtitle)
                    .font(Typo.sans(15, .regular))
                    .tracking(1)
                    .foregroundStyle(Color.mistSoft)
            }
        }
        .padding(.horizontal, 56)
        .frame(maxWidth: 760)
    }
}

// Photo framed intelligently for the current screen: it fills edge-to-edge when
// the photo's shape is close to the iPad's, and shows the WHOLE photo on a soft
// blurred bed when they clash (a portrait photo on a landscape iPad, say). When
// it does crop, Vision keeps the faces / subject in frame, and the Ken Burns
// drift leans toward them. A caption sits over a gradient floor for legibility.
private struct PhotoPebble: View {
    let pebble: Pebble
    let settings: GaletSettings
    @State private var image: UIImage?
    @State private var framing: PhotoFraming = .centered
    @State private var drifted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let image {
                    let p = plan(framing, geo.size)
                    if p.fit { bed(image, geo.size) }
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: p.base.width, height: p.base.height)
                        .offset(p.offset)
                        .scaleEffect(drifted ? p.zoomTo : 1.0, anchor: p.anchor)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()

                    LinearGradient(
                        colors: [.clear, Color.stoneDeep.opacity(0.7)],
                        startPoint: .center, endPoint: .bottom
                    )

                    if !pebble.text.isEmpty {
                        VStack {
                            Spacer()
                            Text(pebble.text)
                                .font(Typo.serif(19, .light).italic())
                                .foregroundStyle(Color.quoteInk.opacity(0.92))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .padding(.bottom, 64)
                        }
                    }
                } else {
                    Color.stoneBase
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .task(id: pebble.id) {
                let target = CGSize(width: geo.size.width * 1.25,
                                    height: geo.size.height * 1.25)
                if let img = await PhotoLoader.shared.image(for: pebble.photoLocalId, target: target) {
                    framing = await PhotoLoader.shared.framing(for: pebble.photoLocalId, image: img)
                    image = img
                }
                startDrift()
            }
        }
        .ignoresSafeArea()
    }

    // A soft blurred bed of the photo itself, for the fit (letterboxed) case.
    private func bed(_ image: UIImage, _ frame: CGSize) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: frame.width, height: frame.height)
            .clipped()
            .blur(radius: 44)
            .opacity(0.45)
            .overlay(Color.stoneDeep.opacity(0.28))
    }

    private var driftOn: Bool { settings.kenBurns && !reduceMotion }

    private func startDrift() {
        guard driftOn else { return }
        drifted = false
        let span = settings.dwellSeconds + settings.fadeSeconds * 2
        withAnimation(.easeInOut(duration: span)) { drifted = true }
    }

    // ── Framing decision ────────────────────────────────────────────────────────
    private struct FramePlan {
        var fit: Bool          // letterbox the whole photo on a bed?
        var base: CGSize       // size to render the image at (before zoom)
        var offset: CGSize     // shift to centre the subject
        var anchor: UnitPoint  // zoom pivots here (the subject) so it never leaves
        var zoomTo: CGFloat    // Ken Burns target (1.0 = no zoom)
    }

    // Fill when the photo's shape is close to the screen's AND the subject fits;
    // otherwise show the whole photo. Either way, cap the zoom so the (padded)
    // subject — face, pet, focal point — is never cropped.
    private func plan(_ framing: PhotoFraming, _ frame: CGSize) -> FramePlan {
        let a = max(framing.aspect, 0.01)
        let screenA = frame.width / max(frame.height, 1)
        let wantFit = max(a / screenA, screenA / a) >= 1.35

        var fillW = frame.height * a, fillH = frame.height
        if fillW < frame.width { fillW = frame.width; fillH = frame.width / a }
        var fitW = frame.width, fitH = frame.width / a
        if fitH > frame.height { fitH = frame.height; fitW = frame.height * a }
        let fitSize = CGSize(width: fitW, height: fitH)

        // A person or pet is never cropped — always show the whole photo.
        if framing.protectSubject || wantFit {
            return make(fitSize, fit: true, frame: frame, s: framing).plan
        }
        let fill = make(CGSize(width: fillW, height: fillH), fit: false, frame: frame, s: framing)
        if fill.subjectFits { return fill.plan }
        // Filling would crop the subject — show the whole photo instead.
        return make(fitSize, fit: true, frame: frame, s: framing).plan
    }

    private func make(_ base: CGSize, fit: Bool, frame: CGSize, s: PhotoFraming)
        -> (plan: FramePlan, subjectFits: Bool) {
        let subj = s.subject
        let ovX = max(0, base.width - frame.width), ovY = max(0, base.height - frame.height)
        let offX = clampCG((0.5 - subj.midX) * base.width, -ovX / 2, ovX / 2)
        let offY = clampCG((0.5 - subj.midY) * base.height, -ovY / 2, ovY / 2)

        // Subject centre in frame coords, and how far it sits from each edge.
        let px = frame.width / 2 + (subj.midX - 0.5) * base.width + offX
        let py = frame.height / 2 + (subj.midY - 0.5) * base.height + offY
        let halfW = max(1, subj.width * base.width / 2)
        let halfH = max(1, subj.height * base.height / 2)

        // Largest zoom that keeps the whole subject inside the frame.
        let zSubject = min(px / halfW, (frame.width - px) / halfW,
                           py / halfH, (frame.height - py) / halfH)
        let subjectFits = !s.hasSubject || zSubject >= 1.0
        let ceiling: CGFloat = fit ? 1.04 : 1.06
        let cap = s.hasSubject ? min(ceiling, max(1.0, zSubject)) : ceiling
        let zoomTo = driftOn ? cap : 1.0

        return (FramePlan(fit: fit, base: base,
                          offset: CGSize(width: offX, height: offY),
                          anchor: UnitPoint(x: subj.midX, y: subj.midY),
                          zoomTo: zoomTo),
                subjectFits)
    }
}

private func clampCG(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
    min(max(v, lo), hi)
}
