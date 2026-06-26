import SwiftUI
import SwiftData

enum Screen { case galet, composer, settings, souffleur }

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \GaletItem.order) private var items: [GaletItem]
    @Query private var settingsRows: [GaletSettings]

    @StateObject private var events = EventBridge()
    @StateObject private var albums = AlbumLibrary()
    @State private var screen: Screen = .galet
    @State private var idleTask: Task<Void, Never>?
    // True while the Composer has a modal open (photo picker, file importer, or
    // editor). The idle-return is suspended while it is, so browsing a large
    // photo library can never bounce you back to the display mid-selection.
    @State private var composerModalOpen = false

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
                OnboardingView(context: context, events: events, settings: s) {
                    s.onboarded = true; try? context.save()
                }
                .environment(\.lang, settings.lang)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: settingsRows.first?.onboarded)
        .task {
            ensureSettings()
            SeedContent.seedIfNeeded(context)
            events.lang = settings.lang
            events.selectedCalendarIDs = settings.selectedCalendarIDs
            events.selectedReminderListIDs = settings.selectedReminderListIDs
            albums.update(albumSpecs)
            await events.refresh()
        }
        // Pull margin quotes saved from the magazines (Les Marges → wiki → feed),
        // then top up on a slow timer for as long as the display stays open.
        .task { await MarginFeed.keepFresh(context) }
        .onChange(of: screen) { _, _ in composerModalOpen = false; armIdleReturn() }
        // A modal opening pauses the countdown; closing it re-arms a fresh one.
        .onChange(of: composerModalOpen) { _, _ in armIdleReturn() }
        // Adding or removing items is active curation — keep the screen alive.
        .onChange(of: items.count) { _, _ in armIdleReturn() }
        .onChange(of: settings.langRaw) { _, _ in
            events.lang = settings.lang
            Task { await events.refresh() }
        }
        // A changed calendar / list selection re-pulls the live pebbles.
        .onChange(of: settings.selectedCalendarIDs) { _, v in
            events.selectedCalendarIDs = v
            Task { await events.refresh() }
        }
        .onChange(of: settings.selectedReminderListIDs) { _, v in
            events.selectedReminderListIDs = v
            Task { await events.refresh() }
        }
        // Added / removed an album, or changed its frequency dial → re-resolve.
        .onChange(of: albumSpecKey) { _, _ in albums.update(albumSpecs) }
    }

    // The stored album items, as resolver specs (collection id + weight dial).
    private var albumSpecs: [AlbumLibrary.Spec] {
        items.filter { $0.kind == .album }
             .map { AlbumLibrary.Spec(id: $0.photoLocalId, weight: $0.weight) }
    }
    private var albumSpecKey: String {
        albumSpecs.map { "\($0.id):\($0.weight)" }.joined(separator: ",")
    }

    @ViewBuilder private var content: some View {
        switch screen {
        case .galet:
            GaletView(
                items: items,
                settings: settings,
                live: events.livePebbles(useCalendar: settings.useCalendar,
                                         useReminders: settings.useReminders),
                albumPhotos: albums.pebbles,
                onCompose: { screen = .composer },
                onSettings: { screen = .settings },
                onSouffleur: { screen = .souffleur }
            )
            .task { await events.refresh() }
        case .composer:
            ComposerView(items: items, settings: settings, events: events,
                         modalOpen: $composerModalOpen) { screen = .galet }
        case .settings:
            ReglagesView(settings: settings, events: events) { screen = .galet }
        case .souffleur:
            SouffleurView(items: items, settings: settings) { screen = .galet }
        }
    }

    // Exactly one settings row should ever exist. Create it if missing, and if a
    // race ever produced duplicates, keep the first and delete the rest so the app
    // never drifts onto an orphan copy.
    private func ensureSettings() {
        if settingsRows.isEmpty {
            context.insert(GaletSettings())
            try? context.save()
        } else if settingsRows.count > 1 {
            for extra in settingsRows.dropFirst() { context.delete(extra) }
            try? context.save()
        }
    }

    // A curation screen left genuinely idle drifts back to the display after a
    // while — but never while a modal is open (the photo picker can take minutes)
    // and the countdown restarts on each interaction, so active use never bounces.
    private func armIdleReturn() {
        idleTask?.cancel()
        guard screen != .galet, !composerModalOpen else { return }
        idleTask = Task {
            try? await Task.sleep(for: .seconds(180))
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
