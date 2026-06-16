import SwiftUI
import SwiftData

enum Screen { case galet, composer, settings, souffleur }

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \GaletItem.order) private var items: [GaletItem]
    @Query private var settingsRows: [GaletSettings]

    @StateObject private var events = EventBridge()
    @State private var screen: Screen = .galet
    @State private var idleTask: Task<Void, Never>?

    private var settings: GaletSettings { settingsRows.first ?? placeholder }
    private let placeholder = GaletSettings()

    var body: some View {
        ZStack {
            Color.stoneBase.ignoresSafeArea()

            if settingsRows.first == nil {
                // First frame before the settings row exists.
                Color.stoneBase.ignoresSafeArea()
            } else {
                content
                    .environment(\.lang, settings.lang)
            }

            if let s = settingsRows.first, !s.onboarded {
                OnboardingView { s.onboarded = true; try? context.save() }
                    .environment(\.lang, settings.lang)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: settingsRows.first?.onboarded)
        .task {
            ensureSettings()
            SeedContent.seedIfNeeded(context)
            events.lang = settings.lang
            await events.refresh()
        }
        .onChange(of: screen) { _, newValue in armIdleReturn(newValue) }
        .onChange(of: settings.langRaw) { _, _ in
            events.lang = settings.lang
            Task { await events.refresh() }
        }
    }

    @ViewBuilder private var content: some View {
        switch screen {
        case .galet:
            GaletView(
                items: items,
                settings: settings,
                live: events.livePebbles(useCalendar: settings.useCalendar,
                                         useReminders: settings.useReminders),
                onCompose: { screen = .composer },
                onSettings: { screen = .settings },
                onSouffleur: { screen = .souffleur }
            )
            .task { await events.refresh() }
        case .composer:
            ComposerView(items: items, settings: settings, events: events) { screen = .galet }
        case .settings:
            ReglagesView(settings: settings, events: events) { screen = .galet }
        case .souffleur:
            SouffleurView(items: items, settings: settings) { screen = .galet }
        }
    }

    private func ensureSettings() {
        if settingsRows.isEmpty {
            context.insert(GaletSettings())
            try? context.save()
        }
    }

    // A curation screen left untouched drifts back to the display after a while.
    private func armIdleReturn(_ s: Screen) {
        idleTask?.cancel()
        guard s != .galet else { return }
        idleTask = Task {
            try? await Task.sleep(for: .seconds(120))
            if !Task.isCancelled { await MainActor.run { screen = .galet } }
        }
    }
}

// The display language, threaded through the view tree.
private struct LangKey: EnvironmentKey { static let defaultValue: Lang = .fr }
extension EnvironmentValues {
    var lang: Lang {
        get { self[LangKey.self] }
        set { self[LangKey.self] = newValue }
    }
}
