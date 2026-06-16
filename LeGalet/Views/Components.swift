import SwiftUI

// A round, low-contrast chrome button — the only visible affordance, and only
// when the display is tapped.
struct CircleButton: View {
    let symbol: String
    var label: String = ""
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Color.mistSoft)
                .frame(width: 46, height: 46)
                .background(Color.stoneBase.opacity(0.6), in: Circle())
                .overlay(Circle().strokeBorder(Color.stoneLine.opacity(0.7), lineWidth: 1))
        }
        .accessibilityLabel(label)
    }
}

// Back chevron used atop every curation screen.
struct BackButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.mistSoft)
                .frame(width: 42, height: 42)
                .overlay(Circle().strokeBorder(Color.stoneLine, lineWidth: 1))
        }
    }
}

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(Typo.sans(11, .medium))
            .tracking(2.4)
            .foregroundStyle(Color.mistFaint)
    }
}

// A settings card holding rows.
struct GaletCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.stoneRaise, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(Color.stoneLine.opacity(0.5), lineWidth: 1))
    }
}

struct CalmToggle: View {
    let title: String
    @Binding var isOn: Bool
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title).font(Typo.sans(15)).foregroundStyle(Color.mist)
        }
        .tint(.amber)
    }
}
