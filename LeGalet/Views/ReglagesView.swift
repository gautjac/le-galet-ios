import SwiftUI
import SwiftData

struct ReglagesView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.lang) private var lang
    @Bindable var settings: GaletSettings
    @ObservedObject var events: EventBridge
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Color.stoneBase.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 26) {
                        pace
                        order
                        typeface
                        dayNight
                        texture
                        household
                        language
                        footnote
                    }
                    .padding(22)
                }
            }
        }
        .onChange(of: settings.langRaw) { _, _ in persist() }
    }

    private var header: some View {
        HStack(spacing: 14) {
            BackButton(action: { persist(); onBack() })
            Text(S.reglagesTitle(lang)).font(Typo.serif(24, .light)).foregroundStyle(Color.mist)
            Spacer()
        }
        .padding(.horizontal, 22).padding(.top, 24).padding(.bottom, 12)
    }

    private var pace: some View {
        section(S.pace(lang)) {
            GaletCard {
                slider(S.fade(lang), value: $settings.fadeSeconds, range: 0.8...6, step: 0.2,
                       display: String(format: "%.1f s", settings.fadeSeconds))
                slider(S.dwell(lang), value: $settings.dwellSeconds, range: 4...40, step: 1,
                       display: "\(Int(settings.dwellSeconds)) s")
            }
        }
    }

    private var order: some View {
        section(S.order(lang)) {
            GaletCard { CalmToggle(title: S.shuffleOn(lang), isOn: $settings.shuffle) }
        }
    }

    private var typeface: some View {
        section(S.quoteTypeface(lang)) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(QuoteFont.allCases) { f in fontCard(f) }
            }
        }
    }

    private func fontCard(_ f: QuoteFont) -> some View {
        let on = settings.quoteFont == f
        return Button {
            settings.quoteFontRaw = f.rawValue
            persist()
        } label: {
            VStack(spacing: 10) {
                // A live sample set in the typeface itself.
                Text("Aa")
                    .font(f.font(38))
                    .foregroundStyle(on ? Color.quoteInk : Color.mist)
                Text(f.name(lang))
                    .font(Typo.sans(12, .medium)).tracking(1)
                    .foregroundStyle(on ? Color.amber : Color.mistSoft)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(on ? Color.amber.opacity(0.08) : Color.stoneRaise,
                        in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .strokeBorder(on ? Color.amber : Color.stoneLine.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var dayNight: some View {
        section(S.nightDayTitle(lang)) {
            GaletCard {
                timeRow(S.dayStart(lang), minutes: $settings.dayStartMinutes)
                timeRow(S.nightStart(lang), minutes: $settings.nightStartMinutes)
                slider(S.nightDim(lang), value: $settings.nightDim, range: 0...0.9, step: 0.05,
                       display: "\(Int(settings.nightDim * 100)) %")
            }
        }
    }

    private var texture: some View {
        section(S.texture(lang)) {
            GaletCard {
                CalmToggle(title: S.kenBurns(lang), isOn: $settings.kenBurns)
                CalmToggle(title: S.showClock(lang), isOn: $settings.showClock)
            }
        }
    }

    private var household: some View {
        section(S.household(lang)) {
            GaletCard {
                Text(S.toneLabel(lang)).font(Typo.sans(14)).foregroundStyle(Color.mistSoft)
                TextField(S.tonePlaceholder(lang), text: $settings.tone, axis: .vertical)
                    .font(Typo.sans(15)).foregroundStyle(Color.mist)
                    .lineLimit(2...4)
                    .padding(12)
                    .background(Color.stoneBase, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.stoneLine, lineWidth: 1))
                Text(S.toneHelp(lang)).font(Typo.sans(12)).foregroundStyle(Color.mistFaint).lineSpacing(2)
            }
        }
    }

    private var language: some View {
        section(S.language(lang)) {
            HStack(spacing: 10) {
                langChip("Français", .fr)
                langChip("English", .en)
            }
        }
    }

    private func langChip(_ title: String, _ l: Lang) -> some View {
        let on = settings.lang == l
        return Button { settings.langRaw = l.rawValue } label: {
            Text(title).font(Typo.sans(14)).tracking(1)
                .foregroundStyle(on ? Color.amber : Color.mistSoft)
                .frame(maxWidth: .infinity).padding(.vertical, 13)
                .background(on ? Color.amber.opacity(0.1) : .clear, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(on ? Color.amber : Color.stoneLine, lineWidth: 1))
        }
    }

    private var footnote: some View {
        Text(S.staysAwake(lang)).font(Typo.sans(12)).foregroundStyle(Color.mistFaint)
            .frame(maxWidth: .infinity, alignment: .center).padding(.top, 4)
    }

    // ── Building blocks ─────────────────────────────────────────────────────────
    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: title)
            content()
        }
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>,
                        step: Double, display: String) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(title).font(Typo.sans(15)).foregroundStyle(Color.mist)
                Spacer()
                Text(display).font(Typo.sans(14)).foregroundStyle(Color.amber).monospacedDigit()
            }
            Slider(value: value, in: range, step: step) { _ in persist() }
                .tint(.amber)
        }
    }

    private func timeRow(_ title: String, minutes: Binding<Int>) -> some View {
        HStack {
            Text(title).font(Typo.sans(15)).foregroundStyle(Color.mist)
            Spacer()
            DatePicker("", selection: Binding(
                get: { dateFrom(minutes.wrappedValue) },
                set: { minutes.wrappedValue = minutesFrom($0); persist() }
            ), displayedComponents: .hourAndMinute)
            .labelsHidden().tint(.amber)
        }
    }

    private func dateFrom(_ m: Int) -> Date {
        Calendar.current.date(bySettingHour: m / 60, minute: m % 60, second: 0, of: Date()) ?? Date()
    }
    private func minutesFrom(_ d: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: d)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    private func persist() { try? context.save() }
}
