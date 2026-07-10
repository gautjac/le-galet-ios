import SwiftUI
import SwiftData
import Photos
import EventKit
import UIKit
import UniformTypeIdentifiers

struct ComposerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.lang) private var lang
    let items: [GaletItem]
    let settings: GaletSettings
    @ObservedObject var events: EventBridge
    // Mirrors whether any modal is open up to RootView, which suspends the
    // idle-return so a slow photo selection never bounces back to the display.
    @Binding var modalOpen: Bool
    let onBack: () -> Void

    @State private var editing: EditorDraft?
    @State private var showingPhotoPicker = false
    @State private var showingAlbumPicker = false
    @State private var showingImporter = false
    @State private var importMessage: String?
    @State private var pickerKind: SourceKind?
    @State private var photoAccessDenied = false

    // Which live source the calendar/list picker is choosing for.
    private enum SourceKind: String, Identifiable {
        case calendar, reminders
        var id: String { rawValue }
        var isCalendar: Bool { self == .calendar }
    }

    private var anyModalOpen: Bool {
        showingPhotoPicker || showingAlbumPicker || showingImporter || editing != nil || pickerKind != nil
    }

    private var sorted: [GaletItem] { items.sorted { $0.order < $1.order } }
    private var activeCount: Int { items.filter { $0.active }.count }

    var body: some View {
        ZStack {
            Color.stoneBase.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                addRow
                liveSources
                if sorted.isEmpty { emptyList } else { list }
            }
        }
        .sheet(item: $editing) { draft in
            EditorView(draft: draft) { result in save(draft: draft, result: result) }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPicker { ids in addPhotos(ids) }
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showingAlbumPicker) {
            AlbumPickerView(fullAccess: PhotoLoader.authorizationStatus() == .authorized) { infos in
                addAlbums(infos)
            }
            .environment(\.lang, lang)
        }
        .fileImporter(isPresented: $showingImporter,
                      allowedContentTypes: [.plainText, .text, .json, .commaSeparatedText],
                      allowsMultipleSelection: false) { result in handleImport(result) }
        .sheet(item: $pickerKind) { kind in
            SourcePickerView(
                isCalendar: kind.isCalendar,
                calendars: kind.isCalendar ? events.eventCalendars() : events.reminderLists(),
                selectedIDs: kind.isCalendar ? settings.selectedCalendarIDs
                                             : settings.selectedReminderListIDs
            ) { ids in
                if kind.isCalendar { settings.selectedCalendarIDs = ids }
                else { settings.selectedReminderListIDs = ids }
                try? context.save()
            }
            .environment(\.lang, lang)
        }
        .alert(S.importFile(lang),
               isPresented: Binding(get: { importMessage != nil },
                                    set: { if !$0 { importMessage = nil } }),
               presenting: importMessage) { _ in
            Button("OK") { importMessage = nil }
        } message: { Text($0) }
        .alert(S.photosDenied(lang), isPresented: $photoAccessDenied) {
            Button(S.openSettings(lang)) { openAppSettings() }
            Button(S.cancel(lang), role: .cancel) {}
        }
        // Tell RootView whenever a modal opens or closes so it can pause/resume
        // the idle-return. .task seeds the initial value; onChange tracks it.
        .onChange(of: anyModalOpen) { _, open in modalOpen = open }
        .onDisappear { modalOpen = false }
    }

    private var header: some View {
        HStack(spacing: 14) {
            BackButton(action: onBack)
            VStack(alignment: .leading, spacing: 2) {
                Text(S.composerTitle(lang)).font(Typo.serif(24, .light)).foregroundStyle(Color.mist)
                Text(items.isEmpty ? S.composerSub(lang) : countLabel)
                    .font(Typo.sans(13)).foregroundStyle(Color.mistFaint)
            }
            Spacer()
        }
        .padding(.horizontal, 22).padding(.top, 24).padding(.bottom, 14)
    }

    private var countLabel: String {
        activeCount == 1 ? S.oneItem(lang) : String(format: S.itemsCount(lang), activeCount)
    }

    private var addRow: some View {
        HStack(spacing: 10) {
            addButton("photo.on.rectangle", S.addPhoto(lang)) { openPhotos() }
            addButton("rectangle.stack", S.addAlbum(lang)) { openAlbums() }
            addButton("quote.bubble", S.addQuote(lang)) { editing = EditorDraft(kind: .quote) }
            addButton("bell", S.addReminder(lang)) { editing = EditorDraft(kind: .reminder) }
            addButton("square.and.arrow.down", S.importFile(lang)) { showingImporter = true }
        }
        .padding(.horizontal, 22).padding(.bottom, 14)
    }

    private func addButton(_ symbol: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: symbol).font(.system(size: 19, weight: .light))
                Text(title).font(Typo.sans(12)).tracking(0.5)
            }
            .foregroundStyle(Color.mistSoft)
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(Color.stoneRaise, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.stoneLine.opacity(0.7), lineWidth: 1))
        }
    }

    // ── Live sources: Calendar + Reminders ──────────────────────────────────────
    private var liveSources: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: S.liveSources(lang))
            sourceRow(symbol: "calendar", title: S.calendarToggle(lang),
                      granted: events.calendarGranted, denied: events.calendarStatus == .denied,
                      isOn: settings.useCalendar, summary: calendarSummary(),
                      toggle: { toggleCalendar() }, configure: { pickerKind = .calendar })
            sourceRow(symbol: "checklist", title: S.remindersToggle(lang),
                      granted: events.reminderGranted, denied: events.reminderStatus == .denied,
                      isOn: settings.useReminders, summary: reminderSummary(),
                      toggle: { toggleReminders() }, configure: { pickerKind = .reminders })
            if liveSourceOn { frequencyControl }
        }
        .padding(16)
        .background(Color.stoneRaise.opacity(0.5), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.stoneLine.opacity(0.4), lineWidth: 1))
        .padding(.horizontal, 22).padding(.bottom, 14)
    }

    private func sourceRow(symbol: String, title: String, granted: Bool, denied: Bool,
                           isOn: Bool, summary: String,
                           toggle: @escaping () -> Void, configure: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 16, weight: .light))
                .foregroundStyle(Color.mistSoft).frame(width: 22)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(Typo.sans(14)).foregroundStyle(Color.mist)
                // When the source is on, a tappable summary opens the calendar /
                // list picker so the household can narrow what drifts in.
                if granted && isOn {
                    Button(action: configure) {
                        HStack(spacing: 4) {
                            Text(summary).font(Typo.sans(12)).foregroundStyle(Color.amber)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(Color.amber.opacity(0.7))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
            if denied {
                Text(S.denied(lang)).font(Typo.sans(11)).foregroundStyle(Color.mistFaint)
            } else if granted {
                Toggle("", isOn: Binding(get: { isOn }, set: { _ in toggle() })).labelsHidden().tint(.amber)
            } else {
                Button(action: toggle) {
                    Text(S.connect(lang)).font(Typo.sans(12, .medium)).tracking(0.5)
                        .foregroundStyle(Color.amber)
                        .padding(.horizontal, 14).padding(.vertical, 6)
                        .overlay(Capsule().strokeBorder(Color.amber.opacity(0.6), lineWidth: 1))
                }
            }
        }
    }

    // "All calendars", "1 list", or "3 calendars" — what the picker has narrowed to.
    private func calendarSummary() -> String {
        sourceSummary(settings.selectedCalendarIDs, available: events.eventCalendars(),
                      all: S.allCalendars(lang), one: S.oneCalendar(lang), many: S.someCalendars(lang))
    }
    private func reminderSummary() -> String {
        sourceSummary(settings.selectedReminderListIDs, available: events.reminderLists(),
                      all: S.allReminders(lang), one: S.oneReminderList(lang), many: S.someReminders(lang))
    }
    private func sourceSummary(_ selected: [String], available: [EKCalendar],
                               all: String, one: String, many: String) -> String {
        let ids = Set(available.map { $0.calendarIdentifier })
        let picked = selected.isEmpty ? ids : Set(selected).intersection(ids)
        if picked.isEmpty || picked.count == ids.count { return all }
        return picked.count == 1 ? one : String(format: many, picked.count)
    }

    // Shown once at least one live source is on: how often events/reminders
    // surface relative to the photos and quotes (scales their weight in the deck).
    private var liveSourceOn: Bool {
        (events.calendarGranted && settings.useCalendar) ||
        (events.reminderGranted && settings.useReminders)
    }

    private var frequencyControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            Rectangle().fill(Color.stoneLine.opacity(0.4)).frame(height: 1).padding(.vertical, 2)
            HStack {
                Text(S.liveFrequency(lang)).font(Typo.sans(13)).foregroundStyle(Color.mistSoft)
                Spacer()
                Text(String(format: "%g×", settings.liveFrequency))
                    .font(Typo.sans(13)).foregroundStyle(Color.amber).monospacedDigit()
            }
            Slider(value: Binding(get: { settings.liveFrequency },
                                  set: { settings.liveFrequency = $0; try? context.save() }),
                   in: 0.25...3, step: 0.25).tint(.amber)
            Text(S.liveFrequencyHint(lang)).font(Typo.sans(11)).foregroundStyle(Color.mistFaint).lineSpacing(2)
        }
        .padding(.top, 2)
    }

    private var emptyList: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "water.waves").font(.system(size: 30, weight: .ultraLight))
                .foregroundStyle(Color.mistFaint.opacity(0.5))
            Text(S.nothingYet(lang)).font(Typo.sans(14)).foregroundStyle(Color.mistFaint)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var list: some View {
        List {
            ForEach(sorted) { item in
                ComposerRow(item: item, lang: lang)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 5, leading: 22, bottom: 5, trailing: 22))
                    // Swipe LEFT to reveal Remove + Hide. Full-swipe is OFF so the
                    // trash must be tapped — an accidental drag can't delete a
                    // hand-typed quote or album with no undo.
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) { delete(item) } label: {
                            Label(S.remove(lang), systemImage: "trash")
                        }
                        Button { item.active.toggle(); try? context.save() } label: {
                            Label(item.active ? S.hide(lang) : S.show(lang),
                                  systemImage: item.active ? "eye.slash" : "eye")
                        }.tint(.stoneLine)
                    }
                    // Swipe RIGHT to reveal Remove too — either direction works.
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button(role: .destructive) { delete(item) } label: {
                            Label(S.remove(lang), systemImage: "trash")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if item.kind == .quote || item.kind == .reminder {
                            editing = EditorDraft(kind: item.kind == .reminder ? .reminder : .quote, item: item)
                        }
                    }
            }
            .onMove(perform: move)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        // No forced edit mode — that disabled swipe actions. Reordering still works
        // by press-and-hold on a row.
    }

    // ── Mutations ───────────────────────────────────────────────────────────────
    private func nextOrder() -> Int { (items.map { $0.order }.max() ?? -1) + 1 }

    private func openPhotos() {
        Task {
            var status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            if status == .notDetermined { status = await PhotoLoader.requestAccess() }
            // Denied → a dead-end empty picker helps no one; point to Settings.
            // Limited and authorized both let the picker return photos.
            if status == .denied || status == .restricted { photoAccessDenied = true }
            else { showingPhotoPicker = true }
        }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }

    private func addPhotos(_ ids: [String]) {
        var order = nextOrder()
        for id in ids {
            context.insert(GaletItem(typeRaw: PebbleKind.photo.rawValue, photoLocalId: id, order: order))
            order += 1
        }
        try? context.save()
    }

    private func openAlbums() {
        Task {
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            if status == .notDetermined { _ = await PhotoLoader.requestAccess() }
            showingAlbumPicker = true
        }
    }

    private func addAlbums(_ infos: [AlbumKit.Info]) {
        let existing = Set(items.filter { $0.kind == .album }.map { $0.photoLocalId })
        var order = nextOrder()
        for info in infos where !existing.contains(info.id) {
            context.insert(GaletItem(typeRaw: PebbleKind.album.rawValue,
                                     text: info.title.isEmpty ? S.addAlbum(lang) : info.title,
                                     photoLocalId: info.id, order: order))
            order += 1
        }
        try? context.save()
    }

    // Import a file of quotes — text / markdown / CSV / JSON — bulk-adding the
    // new ones (deduped against what's already in the galet and within the file).
    private func handleImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url) else {
            importMessage = S.importFailed(lang); return
        }
        let parsed = QuoteImport.parse(data: data, filename: url.lastPathComponent).prefix(1000)
        var seen = Set(items.filter { $0.kind == .quote }.map { normalize($0.text) })
        var order = nextOrder()
        var added = 0
        for q in parsed {
            let text = q.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = normalize(text)
            guard !text.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            context.insert(GaletItem(typeRaw: PebbleKind.quote.rawValue, text: text,
                                     author: q.author, order: order, sourceRaw: "import"))
            order += 1; added += 1
        }
        try? context.save()
        importMessage = added == 0 ? S.importNone(lang)
            : (added == 1 ? S.importOne(lang) : String(format: S.importDone(lang), added))
    }

    private func normalize(_ s: String) -> String {
        s.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save(draft: EditorDraft, result: EditorResult) {
        if let item = draft.item {
            item.text = result.text
            item.author = result.author
            item.startAt = result.startAt
            item.endAt = result.endAt
            item.recurrenceRaw = result.recurrence.rawValue
        } else {
            let kind: PebbleKind = draft.kind == .reminder ? .reminder : .quote
            let item = GaletItem(typeRaw: kind.rawValue, text: result.text, author: result.author,
                                 order: nextOrder(), startAt: result.startAt, endAt: result.endAt,
                                 recurrenceRaw: result.recurrence.rawValue)
            context.insert(item)
        }
        try? context.save()
    }

    private func delete(_ item: GaletItem) {
        context.delete(item)
        try? context.save()
    }

    private func move(from: IndexSet, to: Int) {
        var arr = sorted
        arr.move(fromOffsets: from, toOffset: to)
        for (i, item) in arr.enumerated() { item.order = i }
        try? context.save()
    }

    private func toggleCalendar() {
        if events.calendarGranted {
            settings.useCalendar.toggle(); try? context.save()
            Task { await events.refresh() }
            if settings.useCalendar { pickerKind = .calendar }   // just turned on → choose
        } else {
            Task {
                await events.requestCalendar()
                if events.calendarGranted {
                    settings.useCalendar = true; try? context.save()
                    pickerKind = .calendar
                }
            }
        }
    }

    private func toggleReminders() {
        if events.reminderGranted {
            settings.useReminders.toggle(); try? context.save()
            Task { await events.refresh() }
            if settings.useReminders { pickerKind = .reminders }
        } else {
            Task {
                await events.requestReminders()
                if events.reminderGranted {
                    settings.useReminders = true; try? context.save()
                    pickerKind = .reminders
                }
            }
        }
    }
}

// A sheet to choose which calendars (or reminder lists) drift into the display.
// Every source starts checked; unchecking narrows it. All checked is stored as an
// empty selection, so a calendar added later is included without re-visiting this.
private struct SourcePickerView: View {
    @Environment(\.lang) private var lang
    @Environment(\.dismiss) private var dismiss
    let isCalendar: Bool
    let calendars: [EKCalendar]
    let onSave: ([String]) -> Void
    @State private var selected: Set<String>

    init(isCalendar: Bool, calendars: [EKCalendar], selectedIDs: [String],
         onSave: @escaping ([String]) -> Void) {
        self.isCalendar = isCalendar
        self.calendars = calendars
        self.onSave = onSave
        let allIDs = Set(calendars.map { $0.calendarIdentifier })
        _selected = State(initialValue: selectedIDs.isEmpty ? allIDs
                                                            : Set(selectedIDs).intersection(allIDs))
    }

    var body: some View {
        ZStack {
            Color.stoneBase.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                if calendars.isEmpty {
                    Spacer()
                    Text(isCalendar ? S.noCalendars(lang) : S.noReminderLists(lang))
                        .font(Typo.sans(14)).foregroundStyle(Color.mistFaint)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(S.sourcePickerHint(lang))
                                .font(Typo.sans(12)).foregroundStyle(Color.mistFaint)
                                .padding(.bottom, 4)
                            ForEach(calendars, id: \.calendarIdentifier) { row($0) }
                        }
                        .padding(22)
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text(isCalendar ? S.whichCalendars(lang) : S.whichReminders(lang))
                .font(Typo.serif(22, .light)).foregroundStyle(Color.mist)
            Spacer()
            Button(S.done(lang)) {
                let allIDs = Set(calendars.map { $0.calendarIdentifier })
                onSave(selected == allIDs ? [] : Array(selected))   // all → store empty (= all)
                dismiss()
            }
            .font(Typo.sans(15, .medium)).foregroundStyle(Color.amber)
        }
        .padding(.horizontal, 22).padding(.top, 24).padding(.bottom, 16)
    }

    private func row(_ cal: EKCalendar) -> some View {
        let on = selected.contains(cal.calendarIdentifier)
        let cg: CGColor? = cal.cgColor
        let dot: Color = cg.map { Color(cgColor: $0) } ?? Color.mistSoft
        return Button {
            if on { selected.remove(cal.calendarIdentifier) }
            else { selected.insert(cal.calendarIdentifier) }
        } label: {
            HStack(spacing: 12) {
                Circle().fill(dot).frame(width: 12, height: 12)
                Text(cal.title).font(Typo.sans(15)).foregroundStyle(Color.mist)
                Spacer()
                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(on ? Color.amber : Color.stoneLine)
            }
            .padding(.vertical, 12).padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(on ? Color.amber.opacity(0.06) : Color.stoneRaise,
                        in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .strokeBorder(on ? Color.amber.opacity(0.5) : Color.stoneLine.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

extension EditorDraft: Identifiable {
    var id: String { (item?.id.uuidString ?? "new") + (kind == .reminder ? "-r" : "-q") }
}

// ── A single curation row ───────────────────────────────────────────────────
private struct ComposerRow: View {
    let item: GaletItem
    let lang: Lang
    @Environment(\.modelContext) private var context
    @State private var thumb: UIImage?
    @State private var albumCount: Int?

    var body: some View {
        HStack(spacing: 12) {
            thumbView
            VStack(alignment: .leading, spacing: 3) {
                Text(displayText)
                    .font(item.kind == .quote ? Typo.serif(16, .light) : Typo.sans(15))
                    .foregroundStyle(item.kind == .quote ? Color.quoteInk : Color.mist)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(tag.uppercased()).font(Typo.sans(10, .medium)).tracking(1.4)
                        .foregroundStyle(Color.mistFaint)
                }
            }
            Spacer()
            WeightDots(item: item)
        }
        .padding(12)
        .background(Color.stoneRaise, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.stoneLine.opacity(0.5), lineWidth: 1))
        .opacity(item.active ? 1 : 0.5)
        .task(id: item.photoLocalId) {
            if item.kind == .photo {
                thumb = await PhotoLoader.shared.image(for: item.photoLocalId, target: CGSize(width: 90, height: 90))
            } else if item.kind == .album {
                // Capture the id (a Sendable String) before hopping off the main
                // actor — the GaletItem model itself must not cross into the
                // detached, non-isolated context.
                let collectionID = item.photoLocalId
                albumCount = await Task.detached(priority: .userInitiated) {
                    AlbumKit.imageCount(collectionID: collectionID)
                }.value
                thumb = await PhotoLoader.shared.albumCover(collectionID: collectionID,
                                                            target: CGSize(width: 90, height: 90))
            }
        }
    }

    @ViewBuilder private var thumbView: some View {
        if (item.kind == .photo || item.kind == .album), let thumb {
            Image(uiImage: thumb).resizable().scaledToFill()
                .frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(alignment: .bottomTrailing) {
                    if item.kind == .album {
                        Image(systemName: "square.stack.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 5))
                            .padding(3)
                    }
                }
        } else {
            Image(systemName: icon).font(.system(size: 16, weight: .light))
                .foregroundStyle(Color.mistFaint)
                .frame(width: 44, height: 44)
                .background(Color.stoneCard, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private var icon: String {
        switch item.kind {
        case .quote: return "quote.bubble"
        case .reminder: return "bell"
        case .album: return "rectangle.stack"
        default: return "photo"
        }
    }
    private var displayText: String {
        if item.kind == .album { return item.text.isEmpty ? S.addAlbum(lang) : item.text }
        return item.text.isEmpty ? (item.kind == .photo ? "—" : "") : item.text
    }
    private var tag: String {
        switch item.kind {
        case .quote: return item.author.isEmpty ? S.addQuote(lang) : item.author
        case .reminder: return (item.startAt != nil || item.endAt != nil) ? S.addReminder(lang) : S.always(lang)
        case .album:
            guard let n = albumCount else { return S.albumTag(lang) }
            let count = n == 0 ? S.noPhotos(lang)
                      : (n == 1 ? S.onePhoto(lang) : String(format: S.photoCount(lang), n))
            return "\(S.albumTag(lang)) · \(count)"
        default: return S.addPhoto(lang)
        }
    }
}

private struct WeightDots: View {
    @Bindable var item: GaletItem
    @Environment(\.modelContext) private var context
    @Environment(\.lang) private var lang
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...3, id: \.self) { w in
                Circle()
                    .fill(item.weight >= w ? Color.amber : Color.stoneLine)
                    .frame(width: 7, height: 7)
                    .onTapGesture { item.weight = w; try? context.save() }
            }
        }
        // VoiceOver hears a single adjustable "Frequency, 2 of 3" control.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(S.frequencyA11y(lang))
        .accessibilityValue("\(item.weight)")
        .accessibilityAdjustableAction { dir in
            switch dir {
            case .increment: if item.weight < 3 { item.weight += 1; try? context.save() }
            case .decrement: if item.weight > 1 { item.weight -= 1; try? context.save() }
            @unknown default: break
            }
        }
    }
}

// ── Album picker ────────────────────────────────────────────────────────────
// A sheet of the user's albums (cover + photo count). Select one or more; Done
// adds each as an album item whose photos drift in and refresh over time. The
// album list is loaded off the main thread so the sheet opens instantly even on
// a large iCloud library (a synchronous load froze it for many seconds).
private struct AlbumPickerView: View {
    @Environment(\.lang) private var lang
    @Environment(\.dismiss) private var dismiss
    var fullAccess: Bool = true
    let onAdd: ([AlbumKit.Info]) -> Void
    @State private var albums: [AlbumKit.Info]?   // nil = still loading
    @State private var selected: Set<String> = []

    var body: some View {
        ZStack {
            Color.stoneBase.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                content
            }
        }
        .task {
            albums = await Task.detached(priority: .userInitiated) { AlbumKit.albums() }.value
        }
    }

    @ViewBuilder private var content: some View {
        if let albums {
            if albums.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(S.albumPickerHint(lang))
                            .font(Typo.sans(12)).foregroundStyle(Color.mistFaint).padding(.bottom, 4)
                        if !fullAccess { limitedNote }   // limited access hides real albums
                        ForEach(albums) { album in
                            AlbumPickerRow(album: album, selected: selected.contains(album.id)) {
                                if selected.contains(album.id) { selected.remove(album.id) }
                                else { selected.insert(album.id) }
                            }
                        }
                    }
                    .padding(22)
                }
            }
        } else {
            Spacer()
            ProgressView().tint(.amber)
            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 34, weight: .ultraLight)).foregroundStyle(Color.mistFaint.opacity(0.6))
            Text(fullAccess ? S.noAlbums(lang) : S.albumsNeedFullAccess(lang))
                .font(Typo.sans(14)).foregroundStyle(Color.mistFaint)
                .multilineTextAlignment(.center).padding(.horizontal, 40).lineSpacing(3)
            if !fullAccess { openSettingsButton }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var limitedNote: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(S.albumsNeedFullAccess(lang))
                .font(Typo.sans(12)).foregroundStyle(Color.amberSoft).lineSpacing(2)
            openSettingsButton
        }
        .padding(12)
        .background(Color.amber.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.amber.opacity(0.3), lineWidth: 1))
        .padding(.bottom, 4)
    }

    private var openSettingsButton: some View {
        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            Text(S.openSettings(lang)).font(Typo.sans(13, .medium)).foregroundStyle(Color.amber)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .overlay(Capsule().strokeBorder(Color.amber.opacity(0.6), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        HStack {
            Text(S.chooseAlbums(lang)).font(Typo.serif(22, .light)).foregroundStyle(Color.mist)
            Spacer()
            Button(S.done(lang)) {
                let chosen = (albums ?? []).filter { selected.contains($0.id) }
                if !chosen.isEmpty { onAdd(chosen) }
                dismiss()
            }
            .font(Typo.sans(15, .medium))
            .foregroundStyle(selected.isEmpty ? Color.mistFaint : Color.amber)
            .disabled(selected.isEmpty)
        }
        .padding(.horizontal, 22).padding(.top, 24).padding(.bottom, 16)
    }
}

private struct AlbumPickerRow: View {
    @Environment(\.lang) private var lang
    let album: AlbumKit.Info
    let selected: Bool
    let toggle: () -> Void
    @State private var cover: UIImage?

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 12) {
                coverView
                VStack(alignment: .leading, spacing: 3) {
                    Text(album.title.isEmpty ? S.addAlbum(lang) : album.title)
                        .font(Typo.sans(15)).foregroundStyle(Color.mist).lineLimit(1)
                    if !countLabel.isEmpty {
                        Text(countLabel).font(Typo.sans(11)).foregroundStyle(Color.mistFaint)
                    }
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(selected ? Color.amber : Color.stoneLine)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? Color.amber.opacity(0.06) : Color.stoneRaise,
                        in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .strokeBorder(selected ? Color.amber.opacity(0.5) : Color.stoneLine.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
        // Only the cover loads per row, and off the main thread — the title and
        // count come straight from the (instant) Info, so rows render immediately.
        .task(id: album.id) {
            cover = await PhotoLoader.shared.albumCover(collectionID: album.id,
                                                        target: CGSize(width: 110, height: 110))
        }
    }

    @ViewBuilder private var coverView: some View {
        if let cover {
            Image(uiImage: cover).resizable().scaledToFill()
                .frame(width: 52, height: 52).clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            Image(systemName: "rectangle.stack").font(.system(size: 18, weight: .light))
                .foregroundStyle(Color.mistFaint).frame(width: 52, height: 52)
                .background(Color.stoneCard, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private var countLabel: String {
        let n = album.count
        if n < 0 { return "" }   // unknown
        return n == 0 ? S.noPhotos(lang)
             : (n == 1 ? S.onePhoto(lang) : String(format: S.photoCount(lang), n))
    }
}
