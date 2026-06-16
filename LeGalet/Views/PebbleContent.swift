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
                    if shouldFill(framing.aspect, geo.size) {
                        fillView(image, geo.size)
                    } else {
                        fitView(image, geo.size)
                    }

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
                // A touch larger than the screen so the Ken Burns zoom never
                // magnifies past the photo's native pixels.
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

    // Fill when the photo's aspect is within ~35% of the screen's; otherwise show
    // the whole photo (no decapitated portraits on a landscape iPad).
    private func shouldFill(_ imgAspect: CGFloat, _ screen: CGSize) -> Bool {
        guard screen.height > 0, imgAspect > 0 else { return true }
        let ratio = imgAspect / (screen.width / screen.height)
        return max(ratio, 1 / ratio) < 1.35
    }

    // Immersive aspect-fill, the crop biased toward the salient region, gentle zoom.
    private func fillView(_ image: UIImage, _ frame: CGSize) -> some View {
        let a = max(framing.aspect, 0.01)
        var w = frame.height * a
        var h = frame.height
        if w < frame.width { w = frame.width; h = frame.width / a }
        let overflowX = max(0, w - frame.width)
        let overflowY = max(0, h - frame.height)
        let offX = clampCG((0.5 - framing.focus.x) * w, -overflowX / 2, overflowX / 2)
        let offY = clampCG((0.5 - framing.focus.y) * h, -overflowY / 2, overflowY / 2)

        return Image(uiImage: image)
            .resizable()
            .frame(width: w, height: h)
            .scaleEffect(driftOn ? (drifted ? 1.12 : 1.03) : 1.0)
            .offset(x: offX, y: offY)
            .frame(width: frame.width, height: frame.height)
            .clipped()
    }

    // Whole photo, centred and un-cropped, on a soft blurred bed of itself.
    private func fitView(_ image: UIImage, _ frame: CGSize) -> some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: frame.width, height: frame.height)
                .clipped()
                .blur(radius: 44)
                .opacity(0.45)
                .overlay(Color.stoneDeep.opacity(0.28))

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(driftOn ? (drifted ? 1.05 : 1.0) : 1.0)
                .frame(width: frame.width, height: frame.height)
        }
    }

    private var driftOn: Bool { settings.kenBurns && !reduceMotion }

    private func startDrift() {
        guard driftOn else { return }
        drifted = false
        let span = settings.dwellSeconds + settings.fadeSeconds * 2
        withAnimation(.easeInOut(duration: span)) { drifted = true }
    }
}

private func clampCG(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
    min(max(v, lo), hi)
}
