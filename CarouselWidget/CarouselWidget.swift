import WidgetKit
import SwiftUI

// Carrousel, as a widget: one calm thing at a time — a photo, a quote, or the
// day's next event — that advances on the system's timeline. It can't do the
// app's continuous cross-fade (WidgetKit redraws on a budgeted schedule, not every
// frame), so instead it *is* a slow carousel: each refreshed entry shows the next
// item. This is also the surface that reaches the CarPlay Home Screen on iOS 26
// once the app runs on iPhone.

// MARK: - What a single slot shows

enum CarouselItem {
    case photo(path: String, caption: String?)
    case sampleLandscape                       // bundled, non-personal fallback
    case quote(text: String, author: String)
    case event(title: String, line: String)
}

struct CarouselEntry: TimelineEntry {
    let date: Date
    let item: CarouselItem
    let nightFactor: Double
}

// MARK: - Timeline

struct CarouselProvider: TimelineProvider {
    func placeholder(in context: Context) -> CarouselEntry {
        CarouselEntry(date: Date(), item: .sampleLandscape, nightFactor: nightFactor(Date()))
    }

    func getSnapshot(in context: Context, completion: @escaping (CarouselEntry) -> Void) {
        let items = Self.items(from: CarouselSnapshot.load() ?? .seeded(lang: CarouselSnapshot.deviceLang))
        completion(CarouselEntry(date: Date(), item: items.first ?? .sampleLandscape,
                                 nightFactor: nightFactor(Date())))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CarouselEntry>) -> Void) {
        let snap = CarouselSnapshot.load() ?? .seeded(lang: CarouselSnapshot.deviceLang)
        let items = Self.items(from: snap)
        let now = Date()
        let step: TimeInterval = 20 * 60        // advance every ~20 min (inside the refresh budget)
        let slots = 12

        var entries: [CarouselEntry] = []
        for i in 0..<slots {
            let date = now.addingTimeInterval(Double(i) * step)
            entries.append(CarouselEntry(date: date,
                                         item: items[i % items.count],
                                         nightFactor: nightFactor(date)))
        }
        // Ask to be rebuilt after the loop, so a freshly published snapshot is
        // picked up within one cycle even without an explicit reload.
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(step * Double(slots)))))
    }

    // Interleave photo → (event) → quote so the rotation feels like the app: a
    // face, then a thought, with the day's next thing sprinkled near the front.
    static func items(from snap: CarouselSnapshot) -> [CarouselItem] {
        let photos: [CarouselItem] = snap.photoFiles.isEmpty
            ? [.sampleLandscape]
            : snap.photoFiles.map { .photo(path: $0, caption: nil) }
        let quotes: [CarouselItem] = snap.quotes.map { .quote(text: $0.text, author: $0.author) }
        let event: CarouselItem? = snap.event.map { .event(title: $0.title, line: $0.line) }

        var out: [CarouselItem] = []
        let n = max(photos.count, quotes.count)
        for i in 0..<max(n, 1) {
            if i < photos.count { out.append(photos[i]) }
            if i == 0, let event { out.append(event) }
            if i < quotes.count { out.append(quotes[i]) }
        }
        return out.isEmpty ? [.sampleLandscape] : out
    }
}

// Amber by day, slate by night — a soft 30-minute ramp either side of 07:00 / 21:00,
// mirroring the app's default threshold (the widget doesn't read the owner's custom
// hours; a spike-level approximation).
private func nightFactor(_ date: Date) -> Double {
    let c = Calendar.current.dateComponents([.hour, .minute], from: date)
    let m = Double((c.hour ?? 0) * 60 + (c.minute ?? 0))
    let day = 7.0 * 60, night = 21.0 * 60, ramp = 30.0
    let isNight = m >= night || m < day
    func dist(_ t: Double) -> Double { let d = abs(m - t); return min(d, 1440 - d) }
    let edge = min(dist(day), dist(night))
    return isNight ? min(1, edge / ramp) : 0
}

// MARK: - Views

struct CarouselWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CarouselEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular, .accessoryInline:
                lockScreen
            default:
                homeScreen
            }
        }
    }

    private var accent: Color { Accent.color(nightFactor: entry.nightFactor) }

    // Home Screen / StandBy / (iPhone →) CarPlay
    @ViewBuilder private var homeScreen: some View {
        switch entry.item {
        case .photo(let path, let caption):
            PhotoCard(uiImage: loadPhoto(path), caption: caption, family: family)
        case .sampleLandscape:
            PhotoCard(uiImage: UIImage(named: "SampleLandscape"), caption: nil, family: family)
        case .quote(let text, let author):
            QuoteCard(text: text, author: author, accent: accent, family: family)
                .containerBackground(Color.stoneBase, for: .widget)
        case .event(let title, let line):
            EventCard(title: title, line: line, accent: accent, family: family)
                .containerBackground(Color.stoneBase, for: .widget)
        }
    }

    // Lock Screen complication — tintable, text-only.
    @ViewBuilder private var lockScreen: some View {
        switch entry.item {
        case .event(let title, let line):
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).lineLimit(1)
                Text(line).font(.caption).lineLimit(1)
            }.widgetAccentable().containerBackground(.clear, for: .widget)
        case .quote(let text, let author):
            VStack(alignment: .leading, spacing: 2) {
                Text(text).font(.system(.footnote, design: .serif)).lineLimit(3)
                if !author.isEmpty { Text(author).font(.caption2).opacity(0.7).lineLimit(1) }
            }.containerBackground(.clear, for: .widget)
        default:
            // Photos can't render on the Lock Screen → show the wordmark.
            Text("Carrousel").font(.system(.headline, design: .serif))
                .widgetAccentable().containerBackground(.clear, for: .widget)
        }
    }

    private func loadPhoto(_ name: String) -> UIImage? {
        guard let url = CarouselShared.photoURL(name) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}

// A photo, shown whole on a soft blurred bed (the app's rule: never crop a face),
// with an optional caption on a gentle bottom scrim.
private struct PhotoCard: View {
    let uiImage: UIImage?
    let caption: String?
    let family: WidgetFamily

    var body: some View {
        ZStack {
            if let uiImage {
                GeometryReader { geo in
                    Image(uiImage: uiImage).resizable().scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .blur(radius: 24).opacity(0.5).clipped()
                    Image(uiImage: uiImage).resizable().scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            } else {
                Color.stoneBase
            }
            if let caption, !caption.isEmpty {
                VStack {
                    Spacer()
                    LinearGradient(colors: [.clear, .black.opacity(0.55)],
                                   startPoint: .center, endPoint: .bottom)
                        .frame(height: 56)
                        .overlay(alignment: .bottomLeading) {
                            Text(caption).font(.caption2).foregroundStyle(.white.opacity(0.9))
                                .padding(.horizontal, 12).padding(.bottom, 8).lineLimit(1)
                        }
                }
            }
        }
        .containerBackground(Color.black, for: .widget)
    }
}

private struct QuoteCard: View {
    let text: String
    let author: String
    let accent: Color
    let family: WidgetFamily

    private var size: CGFloat {
        switch family { case .systemSmall: return 15; case .systemLarge: return 26; default: return 19 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 10) {
            Text(text)
                .font(.system(size: size, weight: .regular, design: .serif))
                .foregroundStyle(Color.quoteInk)
                .lineLimit(family == .systemSmall ? 4 : 7)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
            if !author.isEmpty {
                Text(author.uppercased())
                    .font(.system(size: family == .systemSmall ? 9 : 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(accent)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct EventCard: View {
    let title: String
    let line: String
    let accent: Color
    let family: WidgetFamily

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(line).font(.system(size: 12, weight: .semibold)).tracking(0.5)
            } icon: {
                Image(systemName: "calendar").font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(accent)
            .lineLimit(1)

            Text(title)
                .font(.system(size: family == .systemSmall ? 16 : 22, weight: .regular, design: .serif))
                .foregroundStyle(Color.quoteInk)
                .lineLimit(family == .systemSmall ? 3 : 4)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
        }
        .padding(family == .systemSmall ? 2 : 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(colors: [Color.eventCardTop, Color.eventCardBottom],
                           startPoint: .top, endPoint: .bottom)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(accent.opacity(0.25), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(-4)
        )
    }
}
