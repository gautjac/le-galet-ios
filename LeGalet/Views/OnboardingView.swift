import SwiftUI

struct OnboardingView: View {
    @Environment(\.lang) private var lang
    @State private var step = 0
    let onDone: () -> Void

    private var pages: [(title: String, body: String)] {
        [(S.ob1Title(lang), S.ob1Body(lang)),
         (S.ob2Title(lang), S.ob2Body(lang)),
         (S.ob3Title(lang), S.ob3Body(lang))]
    }
    private var isLast: Bool { step == pages.count - 1 }

    var body: some View {
        ZStack {
            Color.stoneBase.ignoresSafeArea()
            RadialGradient(colors: [.clear, Color.stoneDeep.opacity(0.34)],
                           center: .init(x: 0.5, y: 0.45), startRadius: 280, endRadius: 760)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button(action: onDone) {
                        Text(S.skip(lang).uppercased())
                            .font(Typo.sans(11)).tracking(3)
                            .foregroundStyle(Color.mistFaint)
                    }
                }
                .padding(24)

                Spacer()

                VStack(spacing: 0) {
                    Image(systemName: "water.waves")
                        .font(.system(size: 48, weight: .ultraLight))
                        .foregroundStyle(Color.amber)
                        .padding(.bottom, 32)
                    Text(pages[step].title)
                        .font(Typo.serif(32, .light))
                        .foregroundStyle(Color.mist)
                        .multilineTextAlignment(.center)
                    Text(pages[step].body)
                        .font(Typo.sans(15, .light))
                        .foregroundStyle(Color.mistSoft)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.top, 20)
                        .frame(maxWidth: 460)
                }
                .id(step)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.45), value: step)

                Spacer()

                HStack(spacing: 10) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == step ? Color.amber : Color.stoneLine)
                            .frame(width: i == step ? 22 : 6, height: 6)
                            .animation(.easeInOut(duration: 0.4), value: step)
                    }
                }
                .padding(.bottom, 36)

                Button {
                    if isLast { onDone() } else { withAnimation { step += 1 } }
                } label: {
                    Text(isLast ? S.letItDrift(lang) : S.next(lang))
                        .font(Typo.sans(15, .medium)).tracking(1)
                        .foregroundStyle(Color.stoneDeep)
                        .padding(.horizontal, 34).padding(.vertical, 13)
                        .background(Color.amber, in: Capsule())
                }
                .padding(.bottom, 60)
            }
        }
    }
}
