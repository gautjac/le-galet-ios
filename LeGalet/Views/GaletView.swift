import SwiftUI
import UIKit
import Combine

// The signature pebble engine: each item dwells, then cross-dissolves into the
// next over several seconds, with gentle Ken Burns drift on photos and a
// time-aware wash that eases the whole display darker and cooler at night.
struct GaletView: View {
    let items: [GaletItem]
    let settings: GaletSettings
    let live: [Pebble]
    var albumPhotos: [Pebble] = []
    let onCompose: () -> Void
    let onSettings: () -> Void
    let onSouffleur: () -> Void

    @Environment(\.lang) private var lang

    @State private var playlist: [Pebble] = []
    @State private var index = 0
    @State private var now = Date()
    @State private var chromeVisible = false
    @State private var chromeHideTask: Task<Void, Never>?

    private let clock = Timer.publish(every: 20, on: .main, in: .common).autoconnect()

    private var displayed: Pebble? {
        guard !playlist.isEmpty else { return nil }
        return playlist[index % playlist.count]
    }
    private var nightF: Double { TimeOfDay.nightFactor(now, settings) }
    private var accent: Color { Accent.color(nightFactor: nightF) }
    private var brightness: Double { 1 - nightF * settings.nightDim }

    private var contentKey: String {
        let ids = items.filter { $0.active }.map { "\($0.id.uuidString):\($0.order):\($0.weight)" }.joined(separator: ",")
        // Include the live text/details so edits to a reminder or event (same id,
        // new notes) actually re-render rather than showing the stale pebble.
        let liveIds = live.map { "\($0.id):\($0.subtitle):\($0.notes)" }.joined(separator: ",")
        let albumIds = albumPhotos.map { $0.id }.joined(separator: ",")
        return ids + "|" + liveIds + "|" + albumIds + "|\(settings.shuffle)|\(settings.liveFrequency)"
    }
    private var advanceKey: String { "\(playlist.count)|\(settings.dwellSeconds)|\(settings.fadeSeconds)" }

    var body: some View {
        ZStack {
            Color.stoneBase.ignoresSafeArea()

            if displayed == nil {
                EmptyGalet(accent: accent, onCompose: onCompose)
            } else {
                pebbleStack
                vignette
                nightWash
                if settings.showClock { clockLabel }
                chrome
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { revealChrome() }
        .onAppear {
            rebuild()
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .onReceive(clock) { now = $0; rebuild() }
        .onChange(of: contentKey) { _, _ in rebuild() }
        .task(id: advanceKey) { await runAdvance() }
        .environment(\.galetAccent, accent)
    }

    // ── Layers ────────────────────────────────────────────────────────────────
    @ViewBuilder private var pebbleStack: some View {
        ZStack {
            if let p = displayed {
                PebbleContent(pebble: p, settings: settings, lang: lang)
                    .id(p.id)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: settings.fadeSeconds), value: displayed?.id)
        .ignoresSafeArea()
    }

    private var vignette: some View {
        RadialGradient(
            colors: [.clear, Color.stoneDeep.opacity(0.34)],
            center: .init(x: 0.5, y: 0.45), startRadius: 280, endRadius: 760
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var nightWash: some View {
        Color.stoneDeep
            .opacity(1 - brightness)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 4), value: brightness)
    }

    private var clockLabel: some View {
        VStack {
            Spacer()
            Text(TimeOfDay.clockLabel(now, lang))
                .font(Typo.fixedSans(42, .thin))
                .tracking(1)
                .foregroundStyle(Color.mist.opacity(0.6))
                .padding(.bottom, 34)
        }
        .allowsHitTesting(false)
    }

    private var chrome: some View {
        VStack {
            HStack {
                Spacer()
                if chromeVisible {
                    HStack(spacing: 10) {
                        CircleButton(symbol: "sparkles", label: S.souffleur(lang), action: onSouffleur)
                        CircleButton(symbol: "pencil", label: S.compose(lang), action: onCompose)
                        CircleButton(symbol: "gearshape", label: S.settings(lang), action: onSettings)
                    }
                    .transition(.opacity)
                }
            }
            .padding(20)
            Spacer()
            if chromeVisible {
                Text(S.tapToCurate(lang).uppercased())
                    .font(Typo.sans(11))
                    .tracking(3)
                    .foregroundStyle(Color.mistFaint.opacity(0.6))
                    .padding(.bottom, 60)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: chromeVisible)
    }

    // ── Engine ────────────────────────────────────────────────────────────────
    private func rebuild() {
        let currentId = displayed?.id
        let next = Playlist.build(items: items, live: live, albumPhotos: albumPhotos,
                                  settings: settings, now: now)
        playlist = next
        if let cid = currentId, let pos = next.firstIndex(where: { $0.id == cid }) {
            index = pos
        } else if !next.isEmpty {
            index = index % next.count
        } else {
            index = 0
        }
    }

    private func runAdvance() async {
        guard playlist.count > 1 else { return }
        while !Task.isCancelled {
            let dwell = settings.dwellSeconds
            try? await Task.sleep(for: .seconds(max(2.5, dwell)))
            if Task.isCancelled { break }
            withAnimation(.easeInOut(duration: settings.fadeSeconds)) {
                index = (index + 1) % max(1, playlist.count)
            }
        }
    }

    private func revealChrome() {
        chromeVisible = true
        chromeHideTask?.cancel()
        chromeHideTask = Task {
            try? await Task.sleep(for: .seconds(4.5))
            if !Task.isCancelled { await MainActor.run { chromeVisible = false } }
        }
    }
}

// ── Empty state ─────────────────────────────────────────────────────────────
private struct EmptyGalet: View {
    @Environment(\.lang) private var lang
    let accent: Color
    let onCompose: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "water.waves")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(Color.mistFaint)
                .padding(.bottom, 28)
            Text(S.emptyTitle(lang))
                .font(Typo.serif(26, .light))
                .foregroundStyle(Color.mist)
                .multilineTextAlignment(.center)
            Text(S.emptyBody(lang))
                .font(Typo.sans(15, .light))
                .foregroundStyle(Color.mistSoft)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 16)
                .frame(maxWidth: 420)
            Button(action: onCompose) {
                Text(S.begin(lang))
                    .font(Typo.sans(14))
                    .tracking(1.5)
                    .foregroundStyle(Color.mist)
                    .padding(.horizontal, 28).padding(.vertical, 11)
                    .overlay(Capsule().strokeBorder(accent.opacity(0.7), lineWidth: 1))
            }
            .padding(.top, 34)
        }
        .padding(40)
    }
}

// Pass the live accent down to pebble subviews.
private struct GaletAccentKey: EnvironmentKey { static let defaultValue: Color = .amber }
extension EnvironmentValues {
    var galetAccent: Color {
        get { self[GaletAccentKey.self] }
        set { self[GaletAccentKey.self] = newValue }
    }
}
