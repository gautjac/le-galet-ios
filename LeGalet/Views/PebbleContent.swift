import SwiftUI

// Renders a single pebble by kind. Each is its own view with a fresh identity,
// so Ken Burns and any entrance state re-trigger on every dissolve.
struct PebbleContent: View {
    let pebble: Pebble
    let settings: GaletSettings
    let lang: Lang

    var body: some View {
        switch pebble.kind {
        case .photo: PhotoPebble(pebble: pebble, settings: settings, lang: lang)
        case .quote: QuotePebble(pebble: pebble, font: settings.quoteFont, scale: settings.textScale)
        case .reminder: ReminderPebble(pebble: pebble, kindIcon: "bell", scale: settings.textScale)
        case .event: ReminderPebble(pebble: pebble, kindIcon: "calendar", scale: settings.textScale)
        }
    }
}

private struct QuotePebble: View {
    @Environment(\.galetAccent) private var accent
    let pebble: Pebble
    let font: QuoteFont
    var scale: Double = 1.0
    var body: some View {
        VStack(spacing: 28 * scale) {
            Text(pebble.text)
                .font(font.font(clampQuote * scale))
                .tracking(font.tracking)
                .foregroundStyle(Color.quoteInk)
                .multilineTextAlignment(.center)
                .lineSpacing(8 * scale)
                .fixedSize(horizontal: false, vertical: true)
            if !pebble.author.isEmpty {
                Text(pebble.author.uppercased())
                    .font(Typo.sans(13 * scale, .light))
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
    var scale: Double = 1.0
    var body: some View {
        VStack(spacing: 22 * scale) {
            Image(systemName: kindIcon)
                .font(.system(size: 22 * scale, weight: .ultraLight))
                .foregroundStyle(accent.opacity(0.8))
            Rectangle()
                .fill(accent.opacity(0.5))
                .frame(width: 40, height: 1)
            Text(pebble.text)
                .font(Typo.sans(34 * scale, .light))
                .foregroundStyle(Color.mist)
                .multilineTextAlignment(.center)
                .lineSpacing(4 * scale)
                .fixedSize(horizontal: false, vertical: true)
            if !pebble.subtitle.isEmpty {
                Text(pebble.subtitle)
                    .font(Typo.sans(15 * scale, .regular))
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
    var lang: Lang = .fr
    @State private var image: UIImage?
    @State private var framing: PhotoFraming = .centered
    @State private var drifted = false
    @State private var metaLine: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let image {
                    let p = plan(framing, geo.size)
                    let scale = driftOn ? (drifted ? p.toScale : p.fromScale) : 1.0
                    if p.fit { bed(image, geo.size) }
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: p.base.width, height: p.base.height)
                        .offset(p.offset)
                        .scaleEffect(scale, anchor: p.anchor)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()

                    LinearGradient(
                        colors: [.clear, Color.stoneDeep.opacity(0.7)],
                        startPoint: .center, endPoint: .bottom
                    )

                    let caption = pebble.text.isEmpty ? nil : pebble.text
                    let meta = (settings.showPhotoMeta ? metaLine : nil)
                    if caption != nil || meta != nil {
                        VStack(spacing: 10) {
                            Spacer()
                            if let caption {
                                Text(caption)
                                    .font(Typo.serif(19 * settings.textScale, .light).italic())
                                    .foregroundStyle(Color.quoteInk.opacity(0.92))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            if let meta {
                                // A quiet photo-credit line: small, low-contrast,
                                // gently tracked so it sits under the image without
                                // competing with it.
                                Text(meta)
                                    .font(Typo.sans(12.5, .regular))
                                    .tracking(1.5)
                                    .foregroundStyle(Color.mist.opacity(0.55))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                        }
                        // Sit the footer clear of the resting clock when it's shown,
                        // so the date/place line never collides with the time.
                        .padding(.bottom, settings.showClock ? 58 : 40)
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
                    // Vision (subject detection) is only needed when a mode may crop —
                    // fill or smart crop; the whole-photo default skips it to save battery.
                    framing = needsVision
                        ? await PhotoLoader.shared.framing(for: pebble.photoLocalId, image: img)
                        : PhotoFraming.justAspect(img)
                    image = img
                }
                startDrift()
                await loadMeta()
            }
            // Toggling the caption on mid-display fills it in for the current photo.
            .task(id: settings.showPhotoMeta) { await loadMeta() }
            // Turning fill / smart crop on mid-display recomputes the subject so the
            // current photo re-frames immediately rather than on the next dissolve.
            .task(id: needsVision) {
                guard needsVision, let img = image else { return }
                framing = await PhotoLoader.shared.framing(for: pebble.photoLocalId, image: img)
            }
        }
        .ignoresSafeArea()
    }

    // Pull the photo's date + place only when the caption is enabled; PhotoLoader
    // memoises both, so this is cheap on every photo after the first look.
    private func loadMeta() async {
        guard settings.showPhotoMeta, !pebble.photoLocalId.isEmpty else { return }
        metaLine = await PhotoLoader.shared.meta(for: pebble.photoLocalId).line(lang: lang)
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

    // Both crop modes lean on Vision to keep the subject in frame.
    private var needsVision: Bool { settings.fillScreen || settings.smartCrop }

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
        var base: CGSize       // size to render the image at (before scaling)
        var offset: CGSize     // shift to centre the subject
        var anchor: UnitPoint  // scale pivots here
        var fromScale: CGFloat // drift start
        var toScale: CGFloat   // drift end
    }

    private func plan(_ framing: PhotoFraming, _ frame: CGSize) -> FramePlan {
        let a = max(framing.aspect, 0.01)
        var fitW = frame.width, fitH = frame.width / a
        if fitH > frame.height { fitH = frame.height; fitW = frame.height * a }
        let fitSize = CGSize(width: fitW, height: fitH)

        let screenA = frame.width / max(frame.height, 1)

        // SMART CROP (opt-in) — when the photo's orientation clashes with the
        // screen's (a portrait photo on a landscape iPad, or the reverse), crop it
        // to fill rather than letterbox, with Vision keeping the subject centred.
        // This is the one path that crops even a protected subject (a face or pet),
        // because cropping the portrait into landscape is exactly what's asked.
        let orientationClash = (a >= 1) != (screenA >= 1)
        if settings.smartCrop && orientationClash {
            var w = frame.height * a, h = frame.height
            if w < frame.width { w = frame.width; h = frame.width / a }
            return make(CGSize(width: w, height: h), fit: false, frame: frame, s: framing).plan
        }

        // DEFAULT — show the whole photo, never cropping. The gentle drift "settles
        // in": the photo grows from a hair small to exact fit, so it can never
        // exceed the frame and nothing is ever cut. No Vision needed.
        if !settings.fillScreen {
            return FramePlan(fit: true, base: fitSize, offset: .zero, anchor: .center,
                             fromScale: 0.965, toScale: 1.0)
        }

        // FILL (opt-in) — immersive, with best-effort subject protection.
        let wantFit = max(a / screenA, screenA / a) >= 1.35
        var fillW = frame.height * a, fillH = frame.height
        if fillW < frame.width { fillW = frame.width; fillH = frame.width / a }

        if framing.protectSubject || wantFit {
            return make(fitSize, fit: true, frame: frame, s: framing).plan
        }
        let fill = make(CGSize(width: fillW, height: fillH), fit: false, frame: frame, s: framing)
        if fill.subjectFits { return fill.plan }
        return make(fitSize, fit: true, frame: frame, s: framing).plan
    }

    private func make(_ base: CGSize, fit: Bool, frame: CGSize, s: PhotoFraming)
        -> (plan: FramePlan, subjectFits: Bool) {
        let subj = s.subject
        let ovX = max(0, base.width - frame.width), ovY = max(0, base.height - frame.height)
        let offX = clampCG((0.5 - subj.midX) * base.width, -ovX / 2, ovX / 2)
        let offY = clampCG((0.5 - subj.midY) * base.height, -ovY / 2, ovY / 2)

        let px = frame.width / 2 + (subj.midX - 0.5) * base.width + offX
        let py = frame.height / 2 + (subj.midY - 0.5) * base.height + offY
        let halfW = max(1, subj.width * base.width / 2)
        let halfH = max(1, subj.height * base.height / 2)

        let zSubject = min(px / halfW, (frame.width - px) / halfW,
                           py / halfH, (frame.height - py) / halfH)
        let subjectFits = !s.hasSubject || zSubject >= 1.0
        let ceiling: CGFloat = fit ? 1.04 : 1.06
        let cap = s.hasSubject ? min(ceiling, max(1.0, zSubject)) : ceiling

        return (FramePlan(fit: fit, base: base,
                          offset: CGSize(width: offX, height: offY),
                          anchor: UnitPoint(x: subj.midX, y: subj.midY),
                          fromScale: 1.0, toScale: cap),
                subjectFits)
    }
}

private func clampCG(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
    min(max(v, lo), hi)
}
