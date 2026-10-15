import WidgetKit
import SwiftUI

@main
struct CarouselWidgetBundle: WidgetBundle {
    var body: some Widget { CarouselWidget() }
}

struct CarouselWidget: Widget {
    let kind = "CarouselWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CarouselProvider()) { entry in
            CarouselWidgetView(entry: entry)
        }
        .configurationDisplayName(CarouselSnapshot.deviceLang == "fr" ? "Carrousel" : "Carousel")
        .description(CarouselSnapshot.deviceLang == "fr"
            ? "Une chose calme à la fois — une photo, une citation ou le prochain rendez-vous."
            : "One calm thing at a time — a photo, a quote, or the day's next event.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge,
                            .accessoryRectangular, .accessoryInline])
        // A quiet display, not a glanceable stat — always keep its dark backdrop
        // (including in StandBy), never let the Home Screen strip it to bare text.
        .containerBackgroundRemovable(false)
    }
}
