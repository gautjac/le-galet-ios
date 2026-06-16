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
        case .quote: QuotePebble(pebble: pebble)
        case .reminder: ReminderPebble(pebble: pebble, kindIcon: "bell")
        case .event: ReminderPebble(pebble: pebble, kindIcon: "calendar")
        }
    }
}

private struct QuotePebble: View {
    @Environment(\.galetAccent) private var accent
    let pebble: Pebble
    var body: some View {
        VStack(spacing: 28) {
            Text(pebble.text)
                .font(Typo.serif(clampQuote, .light))
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

// Photo with a slow Ken Burns drift on a softly-blurred bed, plus an optional
// italic serif caption over a gradient floor for legibility.
private struct PhotoPebble: View {
    let pebble: Pebble
    let settings: GaletSettings
    @State private var image: UIImage?
    @State private var drifted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var variant: Int { abs(pebble.id.hashValue) % 4 }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let image {
                    // Blurred bed so any aspect ratio sits on a calm ground.
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .blur(radius: 40)
                        .opacity(0.4)

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .scaleEffect(kenBurnsScale)
                        .offset(kenBurnsOffset)
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
            .task(id: pebble.id) {
                image = await PhotoLoader.shared.image(
                    for: pebble.photoLocalId,
                    target: CGSize(width: geo.size.width, height: geo.size.height))
                startDrift()
            }
        }
        .ignoresSafeArea()
    }

    private var driftOn: Bool { settings.kenBurns && !reduceMotion }
    private var kenBurnsScale: CGFloat {
        guard driftOn else { return 1.04 }
        let from: CGFloat = variant % 2 == 0 ? 1.06 : 1.15
        let to: CGFloat = variant % 2 == 0 ? 1.16 : 1.05
        return drifted ? to : from
    }
    private var kenBurnsOffset: CGSize {
        guard driftOn else { return .zero }
        let dirs: [CGSize] = [
            .init(width: 18, height: 14), .init(width: -16, height: -16),
            .init(width: -18, height: 12), .init(width: 16, height: -14)
        ]
        return drifted ? dirs[variant] : .zero
    }

    private func startDrift() {
        guard driftOn else { return }
        drifted = false
        let span = settings.dwellSeconds + settings.fadeSeconds * 2
        withAnimation(.easeInOut(duration: span)) { drifted = true }
    }
}
