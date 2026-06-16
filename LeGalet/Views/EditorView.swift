import SwiftUI

struct EditorDraft {
    enum Kind { case quote, reminder }
    let kind: Kind
    var item: GaletItem?   // present when editing
}

struct EditorResult {
    var text: String
    var author: String
    var startAt: Date?
    var endAt: Date?
    var recurrence: Recurrence
}

struct EditorView: View {
    @Environment(\.lang) private var lang
    @Environment(\.dismiss) private var dismiss
    let draft: EditorDraft
    let onSave: (EditorResult) -> Void

    @State private var text: String
    @State private var author: String
    @State private var timed: Bool
    @State private var start: Date
    @State private var end: Date
    @State private var recurrence: Recurrence

    init(draft: EditorDraft, onSave: @escaping (EditorResult) -> Void) {
        self.draft = draft
        self.onSave = onSave
        let it = draft.item
        _text = State(initialValue: it?.text ?? "")
        _author = State(initialValue: it?.author ?? "")
        _timed = State(initialValue: it?.startAt != nil || it?.endAt != nil)
        _start = State(initialValue: it?.startAt ?? Date())
        _end = State(initialValue: it?.endAt ?? Date().addingTimeInterval(3600))
        _recurrence = State(initialValue: it?.recurrence ?? .once)
    }

    private var isReminder: Bool { draft.kind == .reminder }
    private var canSave: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.stoneBase.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(isReminder ? S.reminderTitle(lang) : S.quoteTitle(lang))
                            .font(Typo.serif(22, .light))
                            .foregroundStyle(Color.mist)

                        if isReminder {
                            field(S.reminderPlaceholder(lang), text: $text)
                        } else {
                            quoteField
                            field(S.authorPlaceholder(lang), text: $author)
                                .textInputAutocapitalization(.words)
                        }

                        if isReminder { reminderTiming }
                    }
                    .padding(22)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(S.cancel(lang)) { dismiss() }.tint(.mistSoft)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(S.save(lang)) {
                        onSave(EditorResult(
                            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                            author: author.trimmingCharacters(in: .whitespacesAndNewlines),
                            startAt: isReminder && timed ? start : nil,
                            endAt: isReminder && timed ? end : nil,
                            recurrence: isReminder ? recurrence : .once))
                        dismiss()
                    }
                    .tint(.amber)
                    .disabled(!canSave)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
    }

    private var quoteField: some View {
        TextEditor(text: $text)
            .font(Typo.serif(20, .light))
            .foregroundStyle(Color.quoteInk)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 120)
            .padding(12)
            .background(Color.stoneRaise, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.stoneLine, lineWidth: 1))
    }

    private func field(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text, axis: .vertical)
            .font(Typo.sans(16))
            .foregroundStyle(Color.mist)
            .padding(14)
            .background(Color.stoneRaise, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.stoneLine, lineWidth: 1))
    }

    private var reminderTiming: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(isOn: $timed) {
                Text(timed ? S.whenWindow(lang) : S.always(lang))
                    .font(Typo.sans(15)).foregroundStyle(Color.mist)
            }
            .tint(.amber)

            if timed {
                VStack(alignment: .leading, spacing: 14) {
                    DatePicker(S.fromDate(lang), selection: $start)
                        .tint(.amber).foregroundStyle(Color.mistSoft)
                    DatePicker(S.toDate(lang), selection: $end)
                        .tint(.amber).foregroundStyle(Color.mistSoft)
                    HStack {
                        Text(S.recurrence(lang)).font(Typo.sans(13)).foregroundStyle(Color.mistFaint)
                        Spacer()
                        Picker("", selection: $recurrence) {
                            Text(S.recOnce(lang)).tag(Recurrence.once)
                            Text(S.recDaily(lang)).tag(Recurrence.daily)
                            Text(S.recWeekly(lang)).tag(Recurrence.weekly)
                            Text(S.recYearly(lang)).tag(Recurrence.yearly)
                        }
                        .tint(.amber)
                    }
                }
                .padding(16)
                .background(Color.stoneRaise.opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}
