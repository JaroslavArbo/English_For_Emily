import SwiftUI

extension Color {
    static let emilyBlue = Color(red: 0.75, green: 0.91, blue: 1.0)
    static let emilyDeepBlue = Color(red: 0.12, green: 0.48, blue: 0.78)
    static let emilyPink = Color(red: 1.0, green: 0.74, blue: 0.88)
    static let emilyYellow = Color(red: 1.0, green: 0.93, blue: 0.55)
}

struct EmilyTheme {
    static let background = LinearGradient(
        colors: [Color.emilyBlue, Color.white],
        startPoint: .top,
        endPoint: .bottom
    )

    static let card = Color.white.opacity(0.88)
    static let blue = Color.emilyDeepBlue
    static let darkBlue = Color.emilyDeepBlue
    static let pink = Color.emilyPink
    static let yellow = Color.emilyYellow
}

struct EmilyBackground: View {
    var body: some View {
        ZStack {
            EmilyTheme.background
                .ignoresSafeArea()

            Text("🦄")
                .font(.system(size: 320))
                .opacity(0.11)
                .rotationEffect(.degrees(-10))
                .offset(x: 125, y: -150)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            Text("🦄")
                .font(.system(size: 180))
                .opacity(0.06)
                .rotationEffect(.degrees(12))
                .scaleEffect(x: -1, y: 1)
                .offset(x: -150, y: 250)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

struct UnicornBadge: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.9))
                .shadow(radius: 4)
            Text("🦄")
                .font(.system(size: 52))
        }
        .frame(width: 90, height: 90)
        .accessibilityLabel("Unicorn")
    }
}

struct EmilyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(Color.emilyDeepBlue.opacity(configuration.isPressed ? 0.72 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(radius: configuration.isPressed ? 1 : 4)
    }
}
