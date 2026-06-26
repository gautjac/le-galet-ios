import SwiftUI
import SwiftData
import Photos

// A gentle, *actionable* first run: it doesn't just describe Le Galet, it sets it
// up — pick a few photos and connect the calendar/reminders right here — so the
// very first drift after "Commencer" already has the household's own moments and
// the day's events in it. Every step is skippable; nothing is required.
struct OnboardingView: View {
    @Environment(\.lang) private var lang
    let context: ModelContext
    @ObservedObject var events: EventBridge
    @Bindable var settings: GaletSettings
    let onDone: () -> Void

    @State private var step = 0
    @State private var showPhotoPicker = false
    @State private var photosAdded = 0

    private let stepCount = 4
    private var isLast: Bool { step == stepCount - 1 }

    var body: some View {
        ZStack {
            Color.stoneBase.ignoresSafeArea()
            RadialGradient(colors: [.clear, Color.stoneDeep.opacity(0.34)],
                           center: .init(x: 0.5, y: 0.45), startRadius: 280, endRadius: 760)
                .ignoresSafeArea()

            VStack {
                header
                Spacer()
                pageContent
                    .id(step)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.45), value: step)
                Spacer()
                dots
                primaryButton
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker { ids in addPhotos(ids) }.ignoresSafeArea()
        }
    }

    // ── Chrome ──────────────────────────────────────────────────────────────────
    private var header: some View {
        HStack {
            Spacer()
            Button(action: onDone) {
                Text(S.skip(lang).uppercased())
                    .font(Typo.sans(11)).tracking(3)
                    .foregroundStyle(Color.mistFaint)
            }
            .accessibilityLabel(S.skip(lang))
        }
        .padding(24)
    }

    private var dots: some View {
        HStack(spacing: 10) {
            ForEach(0..<stepCount, id: \.self) { i in
                Capsule()
                    .fill(i == step ? Color.amber : Color.stoneLine)
                    .frame(width: i == step ? 22 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.4), value: step)
            }
        }
        .padding(.bottom, 36)
        .accessibilityHidden(true)
    }

    private var primaryButton: some View {
        Button {
            if isLast { onDone() } else { withAnimation { step += 1 } }
        } label: {
            Text(isLast ? S.obBegin(lang) : S.next(lang))
                .font(Typo.sans(15, .medium)).tracking(1)
                .foregroundStyle(Color.stoneDeep)
                .padding(.horizontal, 40).padding(.vertical, 14)
                .background(Color.amber, in: Capsule())
        }
        .padding(.bottom, 60)
    }

    // ── Pages ───────────────────────────────────────────────────────────────────
    @ViewBuilder private var pageContent: some View {
        switch step {
        case 0:
            page("water.waves", S.ob1Title(lang), S.ob1Body(lang)) { EmptyView() }
        case 1:
            page("photo.on.rectangle.angled", S.obPhotosTitle(lang), S.obPhotosBody(lang)) {
                VStack(spacing: 14) {
                    outlineButton(S.obAddPhotos(lang)) { choosePhotos() }
                    if photosAdded > 0 {
                        Label(addedLabel, systemImage: "checkmark.circle.fill")
                            .font(Typo.sans(13, .medium)).foregroundStyle(Color.amber)
                    }
                }
                .padding(.top, 30)
            }
        case 2:
            page("calendar", S.obDayTitle(lang), S.obDayBody(lang)) {
                HStack(spacing: 12) {
                    connectPill(S.obConnectCalendar(lang), granted: events.calendarGranted) { connectCalendar() }
                    connectPill(S.obConnectReminders(lang), granted: events.reminderGranted) { connectReminders() }
                }
                .padding(.top, 30)
            }
        default:
            page("sparkles", S.obDoneTitle(lang), S.obDoneBody(lang)) { EmptyView() }
        }
    }

    private func page<Extra: View>(_ icon: String, _ title: String, _ body: String,
                                   @ViewBuilder extra: () -> Extra) -> some View {
        VStack(spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 46, weight: .ultraLight))
                .foregroundStyle(Color.amber)
                .padding(.bottom, 30)
            Text(title)
                .font(Typo.serif(30, .light))
                .foregroundStyle(Color.mist)
                .multilineTextAlignment(.center)
            Text(body)
                .font(Typo.sans(15, .light))
                .foregroundStyle(Color.mistSoft)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.top, 18)
                .frame(maxWidth: 460)
            extra()
        }
        .padding(.horizontal, 32)
    }

    // ── Controls ────────────────────────────────────────────────────────────────
    private func outlineButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Typo.sans(14, .medium)).tracking(0.5)
                .foregroundStyle(Color.amber)
                .padding(.horizontal, 26).padding(.vertical, 12)
                .overlay(Capsule().strokeBorder(Color.amber.opacity(0.6), lineWidth: 1.2))
        }
        .buttonStyle(.plain)
    }

    private func connectPill(_ title: String, granted: Bool, action: @escaping () -> Void) -> some View {
        Button(action: granted ? {} : action) {
            HStack(spacing: 8) {
                Image(systemName: granted ? "checkmark" : "plus")
                    .font(.system(size: 13, weight: .semibold))
                Text(title).font(Typo.sans(14, .medium))
            }
            .foregroundStyle(granted ? Color.stoneDeep : Color.amber)
            .padding(.horizontal, 22).padding(.vertical, 12)
            .background(granted ? Color.amber : Color.clear, in: Capsule())
            .overlay(Capsule().strokeBorder(granted ? Color.clear : Color.amber.opacity(0.6), lineWidth: 1.2))
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!granted)
        .accessibilityLabel(title)
        .accessibilityValue(granted ? S.connected(lang) : "")
    }

    private var addedLabel: String {
        photosAdded == 1 ? S.obOnePhotoAdded(lang) : String(format: S.obPhotosAdded(lang), photosAdded)
    }

    // ── Actions ─────────────────────────────────────────────────────────────────
    private func choosePhotos() {
        Task {
            var status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            if status == .notDetermined { status = await PhotoLoader.requestAccess() }
            if status != .denied && status != .restricted { showPhotoPicker = true }
        }
    }

    private func addPhotos(_ ids: [String]) {
        let maxOrder = (try? context.fetch(FetchDescriptor<GaletItem>()))?.map(\.order).max() ?? -1
        var order = maxOrder + 1
        for id in ids {
            context.insert(GaletItem(typeRaw: PebbleKind.photo.rawValue, photoLocalId: id, order: order))
            order += 1
        }
        try? context.save()
        photosAdded += ids.count
    }

    private func connectCalendar() {
        Task {
            if !events.calendarGranted { await events.requestCalendar() }
            if events.calendarGranted { settings.useCalendar = true; try? context.save() }
        }
    }

    private func connectReminders() {
        Task {
            if !events.reminderGranted { await events.requestReminders() }
            if events.reminderGranted { settings.useReminders = true; try? context.save() }
        }
    }
}
