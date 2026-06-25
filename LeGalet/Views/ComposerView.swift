import SwiftUI
import SwiftData
import Photos
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
    @State private var showingImporter = false
    @State private var importMessage: String?

    private var anyModalOpen: Bool { showingPhotoPicker || showingImporter || editing != nil }

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
        .fileImporter(isPresented: $showingImporter,
                      allowedContentTypes: [.plainText, .text, .json, .commaSeparatedText],
                      allowsMultipleSelection: false) { result in handleImport(result) }
        .alert(S.importFile(lang),
               isPresented: Binding(get: { importMessage != nil },
                                    set: { if !$0 { importMessage = nil } }),
               presenting: importMessage) { _ in
            Button("OK") { importMessage = nil }
        } message: { Text($0) }
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
                      isOn: settings.useCalendar,
                      toggle: { toggleCalendar() })
            sourceRow(symbol: "checklist", title: S.remindersToggle(lang),
                      granted: events.reminderGranted, denied: events.reminderStatus == .denied,
                      isOn: settings.useReminders,
                      toggle: { toggleReminders() })
        }
        .padding(16)
        .background(Color.stoneRaise.opacity(0.5), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.stoneLine.opacity(0.4), lineWidth: 1))
        .padding(.horizontal, 22).padding(.bottom, 14)
    }

    private func sourceRow(symbol: String, title: String, granted: Bool, denied: Bool,
                           isOn: Bool, toggle: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 16, weight: .light))
                .foregroundStyle(Color.mistSoft).frame(width: 22)
            Text(title).font(Typo.sans(14)).foregroundStyle(Color.mist)
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
                    // Swipe LEFT to remove (full swipe), with Hide as a second action.
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) { delete(item) } label: {
                            Label(S.remove(lang), systemImage: "trash")
                        }
                        Button { item.active.toggle(); try? context.save() } label: {
                            Label(item.active ? S.hide(lang) : S.show(lang),
                                  systemImage: item.active ? "eye.slash" : "eye")
                        }.tint(.stoneLine)
                    }
                    // Swipe RIGHT to remove, too — either direction works.
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button(role: .destructive) { delete(item) } label: {
                            Label(S.remove(lang), systemImage: "trash")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { if item.kind != .photo { editing = EditorDraft(kind: item.kind == .reminder ? .reminder : .quote, item: item) } }
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
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            if status == .notDetermined { _ = await PhotoLoader.requestAccess() }
            showingPhotoPicker = true
        }
    }

    private func addPhotos(_ ids: [String]) {
        var order = nextOrder()
        for id in ids {
            context.insert(GaletItem(typeRaw: PebbleKind.photo.rawValue, photoLocalId: id, order: order))
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
        } else {
            Task { await events.requestCalendar(); if events.calendarGranted { settings.useCalendar = true; try? context.save() } }
        }
    }

    private func toggleReminders() {
        if events.reminderGranted {
            settings.useReminders.toggle(); try? context.save()
            Task { await events.refresh() }
        } else {
            Task { await events.requestReminders(); if events.reminderGranted { settings.useReminders = true; try? context.save() } }
        }
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
                    if item.isSouffleur {
                        Text("· \(S.bySouffleur(lang))").font(Typo.sans(10)).foregroundStyle(Color.amber.opacity(0.7))
                    }
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
            }
        }
    }

    @ViewBuilder private var thumbView: some View {
        if item.kind == .photo, let thumb {
            Image(uiImage: thumb).resizable().scaledToFill()
                .frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            Image(systemName: icon).font(.system(size: 16, weight: .light))
                .foregroundStyle(Color.mistFaint)
                .frame(width: 44, height: 44)
                .background(Color.stoneCard, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private var icon: String {
        switch item.kind { case .quote: return "quote.bubble"; case .reminder: return "bell"; default: return "photo" }
    }
    private var displayText: String {
        item.text.isEmpty ? (item.kind == .photo ? "—" : "") : item.text
    }
    private var tag: String {
        switch item.kind {
        case .quote: return item.author.isEmpty ? S.addQuote(lang) : item.author
        case .reminder: return (item.startAt != nil || item.endAt != nil) ? S.addReminder(lang) : S.always(lang)
        default: return S.addPhoto(lang)
        }
    }
}

private struct WeightDots: View {
    @Bindable var item: GaletItem
    @Environment(\.modelContext) private var context
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...3, id: \.self) { w in
                Circle()
                    .fill(item.weight >= w ? Color.amber : Color.stoneLine)
                    .frame(width: 7, height: 7)
                    .onTapGesture { item.weight = w; try? context.save() }
            }
        }
    }
}
