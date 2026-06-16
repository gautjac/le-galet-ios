import SwiftUI
import SwiftData

struct SouffleurView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.lang) private var lang
    let items: [GaletItem]
    let settings: GaletSettings
    let onBack: () -> Void

    @State private var loading = false
    @State private var error: String?
    @State private var greetings: [GreetingCard] = []
    @State private var quotes: [QuoteSuggestion] = []
    @State private var added: Set<String> = []

    private var hasResults: Bool { !greetings.isEmpty || !quotes.isEmpty }

    var body: some View {
        ZStack {
            Color.stoneBase.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Text(S.souffleurSub(lang))
                            .font(Typo.sans(14, .light)).foregroundStyle(Color.mistSoft)
                            .lineSpacing(4).frame(maxWidth: 560, alignment: .leading)

                        conjureButton

                        if let error {
                            Text(error).font(Typo.sans(14)).foregroundStyle(Color.slateSoft)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.stoneRaise, in: RoundedRectangle(cornerRadius: 14))
                        }

                        if loading && !hasResults { skeletons }

                        if !greetings.isEmpty {
                            group(S.greetings(lang)) {
                                ForEach(greetings) { g in
                                    suggestionCard(key: "g-\(g.id)", body: AnyView(
                                        Text(g.text).font(Typo.serif(18, .light).italic())
                                            .foregroundStyle(Color.quoteInk)),
                                        meta: g.note,
                                        add: { keep("g-\(g.id)", g.text, "") })
                                }
                            }
                        }
                        if !quotes.isEmpty {
                            group(S.quotes(lang)) {
                                ForEach(quotes) { q in
                                    suggestionCard(key: "q-\(q.id)", body: AnyView(
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(q.text).font(Typo.serif(18, .light)).foregroundStyle(Color.quoteInk)
                                            if !q.author.isEmpty {
                                                Text(q.author.uppercased()).font(Typo.sans(11)).tracking(1.5)
                                                    .foregroundStyle(Color.amber.opacity(0.8))
                                            }
                                        }),
                                        meta: q.windowLabel.isEmpty ? "" : "\(S.suggestedWindow(lang)) · \(q.windowLabel)",
                                        add: { keep("q-\(q.id)", q.text, q.author) })
                                }
                            }
                        }
                    }
                    .padding(22)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            BackButton(action: onBack)
            HStack(spacing: 8) {
                Image(systemName: "sparkles").foregroundStyle(Color.amber)
                Text(S.souffleur(lang)).font(Typo.serif(24, .light)).foregroundStyle(Color.mist)
            }
            Spacer()
        }
        .padding(.horizontal, 22).padding(.top, 24).padding(.bottom, 12)
    }

    private var conjureButton: some View {
        Button(action: conjure) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles").symbolEffect(.pulse, isActive: loading)
                Text(loading ? S.conjuring(lang) : (hasResults ? S.again(lang) : S.conjure(lang)))
                    .font(Typo.sans(15, .medium)).tracking(0.5)
            }
            .foregroundStyle(Color.stoneDeep)
            .padding(.horizontal, 24).padding(.vertical, 13)
            .background(Color.amber, in: Capsule())
        }
        .disabled(loading)
        .opacity(loading ? 0.7 : 1)
    }

    private var skeletons: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 16).fill(Color.stoneRaise)
                    .frame(height: 76).overlay(RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.stoneLine.opacity(0.4), lineWidth: 1))
            }
        }
    }

    private func group<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: title)
            content()
        }
    }

    private func suggestionCard(key: String, body: AnyView, meta: String, add: @escaping () -> Void) -> some View {
        let isAdded = added.contains(key)
        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                body
                if !meta.isEmpty {
                    Text(meta).font(Typo.sans(11)).foregroundStyle(Color.mistFaint)
                }
            }
            Spacer()
            Button(action: add) {
                HStack(spacing: 5) {
                    if !isAdded { Image(systemName: "plus") }
                    Text(isAdded ? S.added(lang) : S.add(lang))
                }
                .font(Typo.sans(12, .medium)).tracking(0.5)
                .foregroundStyle(isAdded ? Color.mistFaint : Color.stoneDeep)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(isAdded ? Color.clear : Color.amber, in: Capsule())
                .overlay(Capsule().strokeBorder(isAdded ? Color.stoneLine : .clear, lineWidth: 1))
            }
            .disabled(isAdded)
        }
        .padding(16)
        .background(Color.stoneRaise, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.stoneLine.opacity(0.5), lineWidth: 1))
    }

    // ── Actions ─────────────────────────────────────────────────────────────────
    private func conjure() {
        loading = true; error = nil
        Task {
            do {
                let existing = items.filter { $0.kind == .quote }.map { $0.text }.prefix(16).map { $0 }
                let res = try await Souffleur.suggest(lang: settings.lang, tone: settings.tone, existing: Array(existing))
                greetings = res.greetings; quotes = res.quotes; added = []
            } catch {
                self.error = error.localizedDescription
            }
            loading = false
        }
    }

    private func keep(_ key: String, _ text: String, _ author: String) {
        let order = (items.map { $0.order }.max() ?? -1) + 1
        context.insert(GaletItem(typeRaw: PebbleKind.quote.rawValue, text: text, author: author,
                                 order: order, sourceRaw: "souffleur"))
        try? context.save()
        added.insert(key)
    }
}
